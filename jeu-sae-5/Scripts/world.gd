extends Node2D
# À attacher au nœud racine "Game" de Game.tscn

const PLAYER_SCENE := preload("res://Scenes/player.tscn")
const CUBE_SCENE = preload("uid://b4fqnb8sicky2")

@onready var players: Node = $Players
@onready var cubes: Node2D = $Cubes


func _ready() -> void:
	# Seul le serveur crée les joueurs : le MultiplayerSpawner
	# les réplique automatiquement chez les clients.
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(_spawn_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	spawn_cube()
	# Au cas où des joueurs seraient déjà connectés
	for id in multiplayer.get_peers():
		_spawn_player(id)


func _spawn_player(id: int) -> void:
	var player := PLAYER_SCENE.instantiate()
	player.name = str(id) # le nom = l'id du joueur, utilisé pour l'autorité
	player.position = Vector2(200 + 100 * players.get_child_count(), 200)
	players.add_child(player)


func _remove_player(id: int) -> void:
	var player := players.get_node_or_null(str(id))
	if player:
		player.queue_free()

func spawn_cube() -> void:
	var cube := CUBE_SCENE.instantiate()
	cubes.add_child(cube)
