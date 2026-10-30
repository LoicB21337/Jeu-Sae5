extends Control
class_name Level
# Scène chargée par le serveur ET par les clients.
# Elle contient les deux mondes (présent / passé) de chaque niveau.

@onready var present: SubViewport = $presentContainer/present
@onready var past: SubViewport = $pastContainer/past
@onready var present_container: SubViewportContainer = $presentContainer
@onready var past_container: SubViewportContainer = $pastContainer


const LEVELS := [
	["res://Scenes/world_one_present.tscn", "res://Scenes/world_one_past.tscn"],
]

var present_world: Node
var past_world: Node

# Ids des joueurs, 0 = place libre
var present_id := 0
var past_id := 0


func _ready() -> void:
	# Serveur ET clients chargent les mondes : les nœuds (et leurs
	# MultiplayerSpawner) doivent exister des deux côtés, avec les mêmes noms.
	present.world_2d = World2D.new()
	past.world_2d = World2D.new()
	add_to_group("level")
	present_container.visible = false
	past_container.visible = false
	load_level(0)

	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	# Au cas où des joueurs seraient déjà connectés
	for id in multiplayer.get_peers():
		_on_peer_connected(id)

func show_viewport(vp: Viewport) -> void:
	present_container.visible = (vp == present)
	past_container.visible = (vp == past)


func load_level(level: int) -> void:
	var paths: Array = LEVELS[level]
	present_world = _add_world(paths[0], "Present")
	past_world = _add_world(paths[1], "Past")


func _add_world(path: String, node_name: String) -> Node:
	var world: Node = (load(path) as PackedScene).instantiate()
	world.name = node_name
	if node_name == "Past":
		past.add_child(world)
	else:
		present.add_child(world)
	return world


# ---------- Serveur : attribution des joueurs aux mondes ----------

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
