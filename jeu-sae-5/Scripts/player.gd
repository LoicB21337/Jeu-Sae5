extends CharacterBody2D
class_name Player


@export var SPEED = 300.0
@export var JUMP_VELOCITY = -300.0
@export var sync_position := Vector2.ZERO

const PUSH_FORCE = 20
const MIN_PUSH_FORCE = 15
var paused := false

signal interact(player: CharacterBody2D)

@onready var sprite: AnimatedSprite2D = $sprite
@onready var pause_menu: CanvasLayer = $pause_menu
@onready var camera: Camera2D = $camera

func _ready() -> void:
	pause_menu.visible = false
	sync_position = position
	# Seule la caméra du joueur que je contrôle est active chez moi
	if is_multiplayer_authority():
		camera.make_current()
	else:
		camera.enabled = false

func _enter_tree() -> void:
	# Le nom du nœud est l'id du joueur : c'est lui qui contrôle ce personnage
	set_multiplayer_authority(name.to_int())


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		return
	position = position.lerp(sync_position, 1.0 - exp(-delta * 20.0))


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not paused:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	var direction := Input.get_axis("left", "right")
	if direction and not paused:
		if direction < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	
	
	sync_position = position

	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			var push_force = (PUSH_FORCE * velocity.length() / SPEED) + MIN_PUSH_FORCE
			var vector = -c.get_normal() * push_force
			if vector.y > 0:
				vector.y = 0
			c.get_collider().apply_central_impulse(vector)

func _input(event: InputEvent) -> void:
	# Sans ce test, appuyer sur "interact" le déclencherait aussi
	# pour le personnage de l'autre joueur
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("interact"):
		interact.emit(self)
	if event.is_action_pressed("pause"):
		paused = not paused
		pause_menu.visible = not pause_menu.visible
