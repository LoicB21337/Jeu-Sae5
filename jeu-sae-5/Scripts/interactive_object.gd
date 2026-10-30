extends Area2D
class_name Interactive_object

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $ColorRect/Label

var tween: Tween
var player: Player = null
@export var key: = ""


signal action

func _ready() -> void:
	label.text = key
	color_rect.visible = false
	tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(0, 1), 0.1)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	player = body
	if !player.interact.is_connected(_on_player_interact):
		player.connect("interact", _on_player_interact)
	color_rect.visible = true
	tween.stop()
	tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(1, 1), 0.1)


func _on_area_2d_body_exited(_body: Node2D) -> void:
	if player and player.interact.is_connected(_on_player_interact):
		player.disconnect("interact", _on_player_interact)
	player = null
	tween.stop()
	tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(color_rect, "scale", Vector2(0, 1), 0.1)
	await tween.finished
	color_rect.visible = false


func _on_player_interact(_player: CharacterBody2D) -> void:
	action.emit()
