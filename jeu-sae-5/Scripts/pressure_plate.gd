extends Node2D

@onready var sprite: AnimatedSprite2D = $sprite
@onready var area_2d: Area2D = $Area2D


func _on_area_2d_body_entered(_body: Node2D) -> void:
	sprite.stop()
	sprite.play("pressed")


func _on_area_2d_body_exited(_body: Node2D) -> void:
	if area_2d.get_overlapping_bodies() == []:
		sprite.stop()
		sprite.play("released")
