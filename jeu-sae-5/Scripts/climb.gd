extends State

@onready var player: Player = $"../.."
@onready var sprite: AnimatedSprite2D = $"../../sprite"

var ladder: Ladder
var platform_disabled := false

func enter() -> void:
	sprite.play("climb")
	player.velocity = Vector2.ZERO
	platform_disabled = false
	ladder = player.current_ladder()
	if ladder:
		player.global_position.x = ladder.get_climb_center_x()

func exit() -> void:
	if ladder:
		ladder.enable_collision()
	ladder = null
	platform_disabled = false

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

	# La plateforme du haut est en one-way : elle ne gêne pas la montée.
	# On ne la désactive que pour pouvoir redescendre à travers.
	if y_direction > 0 and not platform_disabled:
		ladder.disable_collision()
		platform_disabled = true
	elif y_direction < 0 and platform_disabled:
		ladder.enable_collision()
		platform_disabled = false

	player.velocity.x = 0.0
	player.velocity.y = y_direction * player.CLIMB_SPEED

	if Input.is_action_just_pressed("jump"):
		transition("Jump")
		return

	# Arrivé en haut : on se pose sur la plateforme et on sort de l'échelle
	var top_stand_y := ladder.get_top_surface_y() - player.get_feet_offset()

	# On repart vers le bas depuis le haut : on se recale pile sur la surface
	# pour ne pas accrocher le coin du sol supérieur adjacent à l'échelle.
	if y_direction > 0 and player.global_position.y <= top_stand_y:
		player.global_position.y = top_stand_y

	if player.global_position.y <= top_stand_y and y_direction <= 0:
		player.global_position.y = top_stand_y
		# Petite vitesse vers le bas pour être au sol dès le frame suivant
		player.velocity = Vector2(0, 20)
		transition("Idle")
		return

	# Arrivé en bas
	if y_direction > 0 and player.get_feet_y() >= ladder.get_bottom_y() - 1.0:
		transition("Idle")
