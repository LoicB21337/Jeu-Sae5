extends State

@onready var player: Player = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

func enter() -> void:
	sprite.play("jump") # ou "fall" si tu ajoutes une animation

func physics_update(delta: float) -> void:
	if player.paused:
		return

	player.velocity += player.get_gravity() * delta

	var x_direction := Input.get_axis("left", "right")
	if x_direction != 0:
		sprite.flip_h = x_direction < 0
		player.velocity.x = x_direction * player.SPEED

	if player.is_on_floor():
		if x_direction != 0:
			transition("Walk")
		else:
			transition("Idle")
		return

	if player.can_climb() and Input.is_action_pressed("up"):
		transition("Climb")
