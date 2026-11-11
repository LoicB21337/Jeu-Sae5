extends State

@onready var player: Player = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

func enter() -> void:
	sprite.play("climb")
	player.velocity = Vector2.ZERO
	var ladder := player.current_ladder()
	if ladder:
		player.global_position.x = ladder.get_climb_center_x()

func physics_update(_delta: float) -> void:
	if player.paused:
		return

	var y_direction := Input.get_axis("up", "down")
	player.velocity.x = 0.0
	player.velocity.y = y_direction * player.CLIMB_SPEED

	if Input.is_action_just_pressed("jump"):
		transition("Jump")
		return
	if not player.can_climb():
		transition("Falling")
		return
	if y_direction > 0 and player.is_on_floor():
		transition("Idle")
