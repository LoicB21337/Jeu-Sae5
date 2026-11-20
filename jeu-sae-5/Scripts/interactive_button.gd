extends InteractiveObject
class_name InteractiveButton

@export_enum("up", "down", "left", "right") var animation = "down"
@export var need_pressing := false

@onready var sprite: AnimatedSprite2D = $sprite

signal action_over(String)

func _ready() -> void:
	super._ready()
	sprite.animation = animation

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	super._on_area_2d_body_entered(body)
	if !body.stop_interact.is_connected(_on_player_stop_interact):
		body.connect("stop_interact", _on_player_stop_interact)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	super._on_area_2d_body_exited(body)
	if body.stop_interact.is_connected(_on_player_stop_interact):
		_on_player_stop_interact(body)
		body.disconnect("stop_interact", _on_player_stop_interact)

func _on_player_interact(_player: CharacterBody2D) -> void:
	super._on_player_interact(_player)
	sprite.stop()
	if not need_pressing:
		sprite.play(animation)
		await get_tree().create_timer(3).timeout
	else:
		sprite.set_frame_and_progress(1,sprite.frame_progress)

func _on_player_stop_interact(_player: CharacterBody2D) -> void:
	sprite.play(animation)
	sprite.stop()
	action_over.emit(flag)
