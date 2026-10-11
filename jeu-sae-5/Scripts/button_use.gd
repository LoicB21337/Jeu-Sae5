extends Node

@onready var sprite: AnimatedSprite2D = $"../sprite"
var animation

func _on_button_action() -> void:
	animation = sprite.animation
	sprite.stop()
	sprite.play(animation)
