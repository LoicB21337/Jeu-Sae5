extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tile_map: TileMapLayer = $TileMapLayer

@export var x = 1
@export var y = 1

func _ready() -> void:
	collision_shape.shape.size = Vector2(x, y) * 32
	collision_shape.disabled = true
	for x in range(x):
		for y in range(y):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 2))
	modulate = Color("ffffff46")

func turn_to_platform():
	collision_shape.disabled = false
	modulate = Color("ffffffff")
	for x in range(x):
		for y in range(y):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(7, 3))


func turn_to_air():
	collision_shape.disabled = true
	modulate = Color("ffffff46")
	for x in range(x):
		for y in range(y):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 2))
