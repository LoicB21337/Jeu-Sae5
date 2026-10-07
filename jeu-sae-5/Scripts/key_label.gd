extends Node2D

@onready var color_rect: ColorRect = $ColorRect
@onready var area_2d: Area2D = $Area2D
@onready var label: Label = $ColorRect/Label

@export var key: = ""

func _ready() -> void:
	label.text = key
	var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(0, 1), 0.1)
	color_rect.visible = false


func _on_area_2d_body_entered(_body: Node2D) -> void:
	var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(1, 1), 0.1)
	color_rect.visible = true


func _on_area_2d_body_exited(_body: Node2D) -> void:
	var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(0, 1), 0.1)
	await tween.finished
	color_rect.visible = false
