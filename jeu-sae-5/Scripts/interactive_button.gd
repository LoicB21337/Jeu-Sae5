extends InteractiveObject
class_name InteractiveButton

@onready var sprite: AnimatedSprite2D = $sprite
var animation

signal action_over(String)

func _on_player_interact(_player: CharacterBody2D) -> void:
	super._on_player_interact(_player)
	animation = sprite.animation
	sprite.stop()
	sprite.play(animation)
	await get_tree().create_timer(1).timeout
	action_over.emit(flag)
