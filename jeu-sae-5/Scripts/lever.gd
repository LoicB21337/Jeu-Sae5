extends InteractiveObject
class_name Lever

@export_enum("up", "down", "left", "right") var animation = "down"

@onready var sprite: AnimatedSprite2D = $sprite
var enabled := false

signal disable(flag: String)

func _ready() -> void:
	super._ready()
	sprite.animation = animation

func _on_player_interact(_player: CharacterBody2D) -> void:
	if not enabled:
		super._on_player_interact(_player)
		sprite.stop()
		sprite.play(animation)
	else:
		disable.emit(flag)
		sprite.stop()
		sprite.play_backwards(animation)
	enabled = not enabled
