extends Control
class_name Level
# Le vrai jeu : une copie identique tourne chez chaque joueur et sur le serveur.
# Il lit le choix dans Session, charge les 2 scènes (présent/passé) et place
# le 1er joueur connecté dans le présent, le 2e dans le passé.

# Les deux écrans du jeu, rendus dans des SubViewport.
@onready var present: SubViewport = $presentContainer/present
@onready var past: SubViewport = $pastContainer/past

# Les cadres qui affichent ces SubViewport à l'écran.
@onready var present_container: SubViewportContainer = $presentContainer
@onready var past_container: SubViewportContainer = $pastContainer

# Prévient les deux mondes qu'un flag a changé (pour les objets à activer).
signal flag_changed(flag: String)

# Prévient qu'un flag a été ajouté.
signal flag_added(flag: String)

# Prévient qu'un flag a été retiré.
signal flag_removed(flag: String)

# Liste des flags actifs : le serveur fait autorité, les clients gardent un miroir.
# Autoritaire sur le serveur, miroir local sur les clients.
var flags: Array = []

# Table de traduction "monde / niveau → deux scènes à charger".
# Ici : LEVEL_PAIRS[monde][niveau] = [scène présente, scène passée].
# Les 6 cases du Monde 1 pointent provisoirement vers les mêmes scènes.
const LEVEL_PAIRS := {
	0: [
		["res://Scenes/world_one_present.tscn", "res://Scenes/world_one_past.tscn"],
		["res://Scenes/world_one_present.tscn", "res://Scenes/world_one_past.tscn"],
		["res://Scenes/world_one_present.tscn", "res://Scenes/world_one_past.tscn"],
		["res://Scenes/world_one_present.tscn", "res://Scenes/world_one_past.tscn"],
		["res://Scenes/world_one_present.tscn", "res://Scenes/world_one_past.tscn"],
		["res://Scenes/world_one_present.tscn", "res://Scenes/world_one_past.tscn"],
	],
	1: [
		["res://Scenes/world_two_present.tscn", "res://Scenes/world_two_past.tscn"],
		["res://Scenes/world_two_present.tscn", "res://Scenes/world_two_past.tscn"],
		["res://Scenes/world_two_present.tscn", "res://Scenes/world_two_past.tscn"],
		["res://Scenes/world_two_present.tscn", "res://Scenes/world_two_past.tscn"],
		["res://Scenes/world_two_present.tscn", "res://Scenes/world_two_past.tscn"],
		["res://Scenes/world_two_present.tscn", "res://Scenes/world_two_past.tscn"],
	],
}

# Scène de niveau instanciée dans le SubViewport présent.
var present_world: Node

# Scène de niveau instanciée dans le SubViewport passé.
var past_world: Node

# ID réseau du joueur affecté au présent (0 = personne pour l'instant).
var present_id := 0

# ID réseau du joueur affecté au passé (0 = personne pour l'instant).
var past_id := 0


# Appelé au démarrage de la scène : prépare les écrans, charge le niveau choisi
# dans Session, puis branche la synchronisation réseau des flags.
func _ready() -> void:
	present.world_2d = World2D.new()  # Monde 2D propre au présent.
	past.world_2d = World2D.new()     # Monde 2D propre au passé.
	add_to_group("level")            # Permet aux autres scripts de retrouver ce niveau.
	present_container.visible = false
	past_container.visible = false
	# LE LIEN AVEC LA SÉLECTION : on lit le carnet écrit par le bouton Lancer.
	load_pair(LEVEL_PAIRS[Session.selected_world][Session.selected_level])
	$BackToSelection.pressed.connect(_on_back_to_selection_pressed)

	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		# Au cas où des joueurs seraient déjà connectés
		for id in multiplayer.get_peers():
			_on_peer_connected(id)
	else:
		_request_flags.rpc_id(1)  # Le client demande l'état des flags au serveur.


# Affiche l'un ou l'autre des deux écrans (utile pour le split screen).
func show_viewport(vp: Viewport) -> void:
	present_container.visible = (vp == present)
	past_container.visible = (vp == past)


# Instancie la paire de scènes [présent, passé] et relie leurs flags entre eux.
func load_pair(pairs: Array) -> void:
	var paths: Array = pairs  # paths[0] = présent, paths[1] = passé.
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


# Charge une scène de niveau depuis son chemin et l'ajoute au bon SubViewport.
func _add_world(path: String, node_name: String) -> Node:
	var world: Node = (load(path) as PackedScene).instantiate()  # La scène devient un vrai node.
	world.name = node_name
	if node_name == "Past":
		past.add_child(world)
	else:
		present.add_child(world)
	return world


# Répartit les joueurs : le 1er connecté va au présent, le 2e au passé.
func _on_peer_connected(id: int) -> void:
	# 1er joueur -> présent, 2e joueur -> passé
	if present_id == 0:
		present_id = id
		present_world._spawn_player(id)
	elif past_id == 0:
		past_id = id
		past_world._spawn_player(id)


# Retire le joueur qui s'est déconnecté du monde où il était.
func _on_peer_disconnected(id: int) -> void:
	if id == present_id:
		present_id = 0
		present_world._remove_player(id)
	elif id == past_id:
		past_id = 0
		past_world._remove_player(id)


# Un monde demande à ajouter un flag : on transmet au changement centralisé.
func _add_flag(flag: String) -> void:
	_change_flag(flag, true)


# Un monde demande à retirer un flag : on transmet au changement centralisé.
func _remove_flag(flag: String) -> void:
	_change_flag(flag, false)


# Point d'entrée unique pour modifier un flag, côté serveur ou côté client.
func _change_flag(flag: String, added: bool) -> void:
	if flag.is_empty():
		return
	if multiplayer.is_server():
		_apply_flag(flag, added)
		if multiplayer.has_multiplayer_peer():
			_apply_flag_remote.rpc(flag, added)  # Le serveur diffuse aux clients.
	else:
		_request_flag.rpc_id(1, flag, added)  # Le client demande au serveur.


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
	var sender := multiplayer.get_remote_sender_id()  # Qui a envoyé la demande ?
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


# Bouton "Retour au choix" : ramène à la grille pour tester un autre niveau.
func _on_back_to_selection_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/level_select.tscn")
