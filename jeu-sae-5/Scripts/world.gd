extends Node2D
class_name World
# À attacher au nœud racine de chaque niveau, puis connecter les signaux.
# Chaque monde (passé / présent) définit sa propre scène de joueur via `player_scene`.

const CUBE_SCENE := preload("uid://b4fqnb8sicky2")

## Scène du joueur propre à ce monde (passé ou présent).
@export var player_scene: PackedScene

@onready var players: Node = $Players
@onready var cubes: Node2D = $Cubes
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

signal add_flag(flag: String)
signal remove_flag(flag: String)
signal update(flag: String)


func _enter_tree() -> void:
	# Spawn personnalisé : le serveur et les clients exécutent `_create_player`
	# avec le même id, ce qui garantit une autorité identique des deux côtés.
	var spawner := get_node_or_null("PlayerSpawner") as MultiplayerSpawner
	if spawner:
		spawner.spawn_function = _create_player


func _ready() -> void:
	if not multiplayer.is_server():
		return
	_spawn_cube()


func _spawn_player(id: int) -> void:
	if not multiplayer.is_server():
		return
	if player_spawner == null or players == null:
		push_error("World '%s' : PlayerSpawner/Players manquant." % name)
		return
	if player_scene == null:
		push_error("World '%s' : player_scene n'est pas défini." % name)
		return
	if players.has_node(str(id)):
		return
	player_spawner.spawn(id)


# Exécuté sur le serveur et sur chaque client avec le même id.
func _create_player(id: int) -> Node:
	var player := player_scene.instantiate()
	player.name = str(id)
	# Autorité réseau explicite et identique sur tous les pairs.
	player.set_multiplayer_authority(id, true)
	return player


func _remove_player(id: int) -> void:
	if players == null:
		return
	var player := players.get_node_or_null(str(id))
	if player:
		player.queue_free()


func _spawn_cube() -> void:
	var cube := CUBE_SCENE.instantiate()
	cubes.add_child(cube, true)


func _on_death_zone_respawn_prop(prop: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if not prop is Player:
		_spawn_cube()

func _on_flag_changed(flag: String):
	update.emit(flag)
 
func _send_add_flag(flag):
	add_flag.emit(flag)

func _send_remove_flag(flag: String):
	remove_flag.emit(flag)
