extends InteractiveObject
class_name InteractiveButton

@onready var sprite: AnimatedSprite2D = $sprite
var animation


func _on_player_interact(_player: CharacterBody2D) -> void:
	super._on_player_interact(_player)
	animation = sprite.animation
	sprite.stop()
	sprite.play(animation)
