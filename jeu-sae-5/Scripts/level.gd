extends Control
class_name Level

@onready var present: SubViewport = $presentContainer/present
@onready var past: SubViewport = $pastContainer/past
@onready var present_container: SubViewportContainer = $presentContainer
@onready var past_container: SubViewportContainer = $pastContainer

signal flag_changed(flag: String)
signal flag_added(flag: String)
signal flag_removed(flag: String)
# Autoritaire sur le serveur, miroir local sur les clients.
var flags: Array = []

const LEVELS := [
	["res://Scenes/world_one_present.tscn", "res://Scenes/world_one_past.tscn"],
]

var present_world: Node
var past_world: Node

var present_id := 0
var past_id := 0


func _ready() -> void:
	present.world_2d = World2D.new()
	past.world_2d = World2D.new()
	add_to_group("level")
	present_container.visible = false
	past_container.visible = false
	load_level(0)

	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		# Au cas où des joueurs seraient déjà connectés
		for id in multiplayer.get_peers():
			_on_peer_connected(id)
	else:
		_request_flags.rpc_id(1)

func show_viewport(vp: Viewport) -> void:
	present_container.visible = (vp == present)
	past_container.visible = (vp == past)


func load_level(level: int) -> void:
	var paths: Array = LEVELS[level]
	present_world = _add_world(paths[0], "Present")
	past_world = _add_world(paths[1], "Past")
	# Flags
	# PAST
	flag_changed.connect(past_world._on_flag_changed)
	past_world.connect("add_flag", _add_flag)
	past_world.connect("remove_flag", _remove_flag)
	# PRESENT
	flag_changed.connect(present_world._on_flag_changed)
	present_world.connect("add_flag", _add_flag)
	present_world.connect("remove_flag", _remove_flag)
	


func _add_world(path: String, node_name: String) -> Node:
	var world: Node = (load(path) as PackedScene).instantiate()
	world.name = node_name
	if node_name == "Past":
		past.add_child(world)
	else:
		present.add_child(world)
	return world


func _on_peer_connected(id: int) -> void:
	# 1er joueur -> présent, 2e joueur -> passé
	if present_id == 0:
		present_id = id
		present_world._spawn_player(id)
	elif past_id == 0:
		past_id = id
		past_world._spawn_player(id)


func _on_peer_disconnected(id: int) -> void:
	if id == present_id:
		present_id = 0
		present_world._remove_player(id)
	elif id == past_id:
		past_id = 0
		past_world._remove_player(id)


func _add_flag(flag: String) -> void:
	_change_flag(flag, true)


func _remove_flag(flag: String) -> void:
	_change_flag(flag, false)


func _change_flag(flag: String, added: bool) -> void:
	if flag.is_empty():
		return
	if multiplayer.is_server():
		_apply_flag(flag, added)
		if multiplayer.has_multiplayer_peer():
			_apply_flag_remote.rpc(flag, added)
	else:
		_request_flag.rpc_id(1, flag, added)


# Client -> serveur : demande d'ajout ou de retrait.
@rpc("any_peer", "call_remote", "reliable")
func _request_flag(flag: String, added: bool) -> void:
	if not multiplayer.is_server():
		return
	_change_flag(flag, added)


# Client -> serveur : demande de l'état courant à la connexion.
@rpc("any_peer", "call_remote", "reliable")
func _request_flags() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		return
	for flag in flags:
		_apply_flag_remote.rpc_id(sender, flag, true)


# Serveur -> clients : application autoritaire d'un événement.
@rpc("authority", "call_remote", "reliable")
func _apply_flag_remote(flag: String, added: bool) -> void:
	_apply_flag(flag, added)


# Met à jour la liste et notifie les scènes de niveau.
func _apply_flag(flag: String, added: bool) -> void:
	if added:
		if flags.has(flag):
			return
		flags.append(flag)
	else:
		if not flags.has(flag):
			return
		flags.erase(flag)

	flag_changed.emit(flag)
	if added:
		flag_added.emit(flag)
	else:
		flag_removed.emit(flag)
