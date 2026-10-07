extends CharacterBody2D


@export var SPEED = 300.0
@export var JUMP_VELOCITY = -300.0
enum States {IDLE, WALKING, JUMPING}
var state: States = States.IDLE

signal interact(player: CharacterBody2D)

@onready var sprite: AnimatedSprite2D = $sprite
@onready var pause_menu: CanvasLayer = $pause_menu

func _ready() -> void:
	pause_menu.visible = false

func _process(_delta: float) -> void:
	if state == States.IDLE:
		sprite.play("idle")
	elif state == States.WALKING:
		sprite.play("walk")
	elif state == States.JUMPING:
		sprite.play("jump")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if not is_on_floor():
		state = States.JUMPING

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	var direction := Input.get_axis("left", "right")
	if direction:
		if is_on_floor():
			state = States.WALKING
		if direction < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			state = States.IDLE
	move_and_slide()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact.emit(self)
	if event.is_action_pressed("pause"):
		if !pause_menu.visible:
			Engine.time_scale = 0
			pause_menu.visible = true
		else:
			Engine.time_scale = 1
			pause_menu.visible = false
