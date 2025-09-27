extends CharacterBody3D

@export var speed = 15.0
@export var jump_force = 10
@export var gravity = 0.5

@export var acceleration = 10.0
@export var deceleration = 8.0

@export var sensitivity = 0.01

@onready var cam = $Camera3D
@onready var gc = $GrappleController

const SPEED = 5.0
const JUMP_VELOCITY = 5

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_force

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = lerpf(velocity.z, direction.z * speed, acceleration * delta)
		#velocity.z = direction.z * speed
	else:
		#velocity.x = move_toward(velocity.x, 0, speed)
		velocity.x = lerpf(velocity.x, 0.0, deceleration * delta)
		velocity.z = lerpf(velocity.z, 0.0, deceleration * delta)

	move_and_slide()
	
#func _unhandled_input(event: InputEvent) -> void:
#	if event is InputEventMouseMotion:
#		rotate_y(-event.relativex * sensitivity)
#		cam.rotate_x(-)
