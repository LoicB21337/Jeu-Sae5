extends StaticBody2D
class_name  SwitchingPlatform

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tile_map: TileMapLayer = $TileMapLayer

@export var flag_id: String = ""
@export var x_lenght = 1
@export var y_lenght = 1

var solid: bool = false

func _ready() -> void:
	collision_shape.shape.size = Vector2(x_lenght, y_lenght) * 16
	collision_shape.position = Vector2(x_lenght, y_lenght) *8
	collision_shape.disabled = true
	for x in range(x_lenght):
		for y in range(y_lenght):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 2))
	modulate = Color("ffffff46")

func turn_to_platform():
	solid = true
	collision_shape.disabled = false
	modulate = Color("ffffffff")
	for x in range(x_lenght):
		for y in range(y_lenght):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(7, 3))


func turn_to_air():
	solid = false
	collision_shape.disabled = true
	modulate = Color("ffffff46")
	for x in range(x_lenght):
		for y in range(y_lenght):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 2))

func switch_platform():
	print(solid)
	if solid:
		turn_to_air()
	else:
		turn_to_platform()
