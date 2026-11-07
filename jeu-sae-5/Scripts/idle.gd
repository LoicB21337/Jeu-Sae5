extends State

@onready var player: Player = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

func enter() -> void:
	sprite.play("idle")

func physics_update(_delta: float) -> void:
	if player.paused:
		return

	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)

	if not player.is_on_floor():
		transition("Falling")
		return
	if Input.is_action_just_pressed("jump"):
		transition("Jump")
		return
	if player.can_climb() and Input.is_action_pressed("up"):
		transition("Climb")
		return
	if Input.get_axis("left", "right") != 0:
		transition("Walk")
