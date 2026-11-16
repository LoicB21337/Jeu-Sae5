extends State

@onready var player: Player = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

func enter() -> void:
	sprite.play("walk")

func physics_update(_delta: float) -> void:
	if player.paused:
		return

	if not player.is_on_floor():
		transition("Falling")
		return
	if Input.is_action_just_pressed("jump"):
		transition("Jump")
		return
	if Input.is_action_pressed("up") and player.can_climb_up():
		transition("Climb")
		return
	if Input.is_action_pressed("down") and player.can_climb_down():
		transition("Climb")
		return

	var x_direction := Input.get_axis("left", "right")
	if x_direction == 0:
		transition("Idle")
		return

	sprite.flip_h = x_direction < 0
	player.velocity.x = x_direction * player.SPEED
