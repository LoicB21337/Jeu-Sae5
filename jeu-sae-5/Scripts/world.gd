extends Node2D
class_name World
# À attacher au nœud racine de chaques niveau, puis conecter les signaux

const PLAYER_SCENE := preload("uid://qtnaxythxvq0")
const CUBE_SCENE = preload("uid://b4fqnb8sicky2")

@onready var players: Node = $Players
@onready var cubes: Node2D = $Cubes

signal add_flag(flag: String)
signal remove_flag(flag: String)
signal update(flag: String)

func _ready() -> void:
	if not multiplayer.is_server():
		return

	_spawn_cube()


func _spawn_player(id: int) -> void:
	var player := PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.position = cubes.position
	players.add_child(player, true)


func _remove_player(id: int) -> void:
	var player := players.get_node_or_null(str(id))
	if player:
		player.queue_free()


func _spawn_cube() -> void:
	var cube := CUBE_SCENE.instantiate()
	cube.position = cubes.position
	cubes.add_child(cube, true)


func _on_death_zone_respawn_prop(prop: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if not prop is Player:
		_spawn_cube()

func _on_flag_changed(flag: String):
	update.emit(flag)
 
func _send_add_flag(node: String):
	add_flag.emit(node)
	owner

func _send_remove_flag(node: String):
	remove_flag.emit(node)
