extends Node2D

@onready var color_rect: ColorRect = $ColorRect
@onready var area_2d: Area2D = $Area2D



func _on_area_2d_body_entered(_body: Node2D) -> void:
	color_rect.visible = true


func _on_area_2d_body_exited(_body: Node2D) -> void:
	color_rect.visible = false




func _on_player_interact(player: CharacterBody2D) -> void:
	if player in area_2d.get_overlapping_bodies():
		print("Action")
