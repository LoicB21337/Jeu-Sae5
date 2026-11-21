extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)


func _on_child_entered_tree(node: Node) -> void:
	if not is_node_ready() or not node is Player:
		return
	sprite.stop()
	sprite.play("use")


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "use":
		sprite.play("idle")
