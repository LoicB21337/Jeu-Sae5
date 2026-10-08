extends Area2D
class_name Interactive_object

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $ColorRect/Label

var tween: Tween
@export var key: = ""


signal action

func _ready() -> void:
	label.text = key
	color_rect.visible = false
	tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(0, 1), 0.1)


func _on_area_2d_body_entered(_body: Node2D) -> void:
	color_rect.visible = true
	tween.stop()
	tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(1, 1), 0.1)


func _on_area_2d_body_exited(_body: Node2D) -> void:
	tween.stop()
	tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(0, 1), 0.1)
	await tween.finished
	color_rect.visible = false


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("interact"):
		action.emit()
