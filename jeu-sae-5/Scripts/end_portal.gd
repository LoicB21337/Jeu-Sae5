extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var flagID := "end_portal"

func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	hide()


func _on_portal_used(node: Node) -> void:
	if not is_node_ready() or not node is Player:
		return
	sprite.stop()
	sprite.play("use")


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "use":
		sprite.play("idle")


func switch_portal(flag: String):
	if flag!=flagID:
		return

	if visible:
		hide()
	else:
		show()
