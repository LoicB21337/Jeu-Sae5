extends CharacterBody2D
class_name Player


@export var SPEED = 300.0
@export var JUMP_VELOCITY = -300.0

const PUSH_FORCE = 20
const MIN_PUSH_FORCE = 15

signal interact(player: CharacterBody2D)

@onready var sprite: AnimatedSprite2D = $sprite
@onready var pause_menu: CanvasLayer = $pause_menu

func _ready() -> void:
	pause_menu.visible = false


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	var direction := Input.get_axis("left", "right")
	if direction:
		if direction < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			var push_force = (PUSH_FORCE * velocity.length() / SPEED) + MIN_PUSH_FORCE
			var vector = -c.get_normal() * push_force
			if vector.y > 0:
				vector.y = 0
			c.get_collider().apply_central_impulse(vector)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact.emit(self)
