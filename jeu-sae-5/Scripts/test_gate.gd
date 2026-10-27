extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_pressure_plate_pressed() -> void:
	animation_player.play("open")


func _on_pressure_plate_released() -> void:
	animation_player.play("close")
