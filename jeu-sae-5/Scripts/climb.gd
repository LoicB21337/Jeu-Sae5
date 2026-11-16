extends State

@onready var player: Player = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

var ladder: Ladder

func enter() -> void:
	sprite.play("climb")
	player.velocity = Vector2.ZERO
	ladder = player.current_ladder()
	if ladder:
		player.global_position.x = ladder.get_climb_center_x()
		ladder.disable_collision()

func exit() -> void:
	if ladder:
		ladder.enable_collision()
	ladder = null

func physics_update(_delta: float) -> void:
	if player.paused:
		return
	if ladder == null:
		transition("Falling")
		return

	var y_direction := Input.get_axis("up", "down")
	if y_direction == 0:
		sprite.pause()
	else:
		sprite.play()

	player.velocity.x = 0.0
	player.velocity.y = y_direction * player.CLIMB_SPEED

	if Input.is_action_just_pressed("jump"):
		transition("Jump")
		return

	# Arrivé en haut : on se pose sur la plateforme et on sort de l'échelle
	var top_stand_y := ladder.get_top_surface_y() - player.get_feet_offset()
	if player.global_position.y <= top_stand_y and y_direction <= 0:
		player.global_position.y = top_stand_y
		player.velocity = Vector2.ZERO
		transition("Idle")
		return

	# Arrivé en bas
	if y_direction > 0 and player.is_on_floor():
		transition("Idle")
