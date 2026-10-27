extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _on_pressure_plate_pressed() -> void:
	sprite.stop()
	sprite.play("open")


func _on_pressure_plate_released() -> void:
	sprite.stop()
	sprite.play("close")
