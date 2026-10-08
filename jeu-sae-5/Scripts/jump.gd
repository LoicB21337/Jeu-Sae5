extends State
@onready var player: CharacterBody2D = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

func enter() -> void:
	sprite.play("jump")

func update(delta: float) -> void:
	if player.is_on_floor():
		transition("Idle")
