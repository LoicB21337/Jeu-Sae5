extends State
@onready var player: CharacterBody2D = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

func enter() -> void:
	sprite.play("idle")

func update(delta: float) -> void:
	if player.velocity.length() > 0:
		transition("Walk")
	elif Input.is_action_just_pressed("jump"):
		transition("Jump")
