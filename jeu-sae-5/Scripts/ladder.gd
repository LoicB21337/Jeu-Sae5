extends Area2D
class_name Ladder

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var player_collision: StaticBody2D = $player_collision
@onready var player_collision_shape: CollisionShape2D = $player_collision/CollisionShape2D2

@export var y_lenght = 4
@export var top_margin = 4

func _ready() -> void:
	var ladder_size = Vector2(1, y_lenght) * 16 + Vector2(0, top_margin)
	collision_shape.shape.size = ladder_size
	player_collision.position.y = -(ladder_size.y - top_margin)
	collision_shape.position = Vector2(0, -ladder_size.y / 2.0)
	tile_map.clear()
	for y in range(y_lenght):
		var tile = Vector2i(10, 3)
		if y == 0:
			tile = Vector2i(12, 3)
		elif y == y_lenght - 1:
			tile = Vector2i(11, 3)
		tile_map.set_cell(Vector2i(0, -1 - y), 0, tile)

func get_climb_center_x() -> float:
	return collision_shape.global_position.x

# y monde de la surface sur laquelle le joueur se tient en haut de l'échelle
func get_top_surface_y() -> float:
	var rect := player_collision_shape.shape as RectangleShape2D
	return player_collision_shape.global_position.y - rect.size.y * 0.5

# y monde du bas de l'échelle (le sol sur lequel elle repose)
func get_bottom_y() -> float:
	return global_position.y

func disable_collision():
	player_collision_shape.set_deferred("disabled", true)

func enable_collision():
	player_collision_shape.set_deferred("disabled", false)
