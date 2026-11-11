extends State

@onready var player: Player = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

func enter() -> void:
	sprite.play("jump")
	player.velocity.y = player.JUMP_VELOCITY

func physics_update(delta: float) -> void:
	if player.paused:
		return

	player.velocity += player.get_gravity() * delta

	var x_direction := Input.get_axis("left", "right")
	if x_direction != 0:
		sprite.flip_h = x_direction < 0
		player.velocity.x = x_direction * player.SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)

	if player.velocity.y >= 0:
		transition("Falling")
