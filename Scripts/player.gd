extends CharacterBody3D

@export var speed = 15.0
@export var jump_force = 10
@export var gravity = 0.5

@export var acceleration = 10.0
@export var deceleration = 8.0

@export var sensitivity = 0.01

@export var vida := 100
@export var damage := 30
var maxvida = 100
var onCD = false
var targets = []

@onready var hpbar = $HUD/HpBar
@onready var cam = $Camera3D
@onready var gc = $GrappleController
@onready var animationPlayer = $AnimationPlayer
@onready var AtackCD = $AttackCD


const SPEED = 5.0
const JUMP_VELOCITY = 5

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	update_HUD()
	if Input.is_action_just_pressed("attack") and !onCD:
		print("animacion")
		animationPlayer.play("Sword_animation")
		AtackCD.start()
		onCD = true

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
	
func attack():
	if Input.is_action_just_pressed("attack") and !onCD:
		animationPlayer.play("sword_animation")
		AtackCD.start()
		onCD = true
		targets

func update_HUD():
	hpbar.value = vida
	
#func _unhandled_input(event: InputEvent) -> void:
#	if event is InputEventMouseMotion:
#		rotate_y(-event.relativex * sensitivity)
#		cam.rotate_x(-)


func _on_attack_cd_timeout() -> void:
	onCD = false


func _on_rangodeataque_body_entered(body: Node3D) -> void:
	print("entra body: ", body)
	if body.has_method("enemy"):
		targets.append(body)


func _on_rangodeataque_body_exited(body: Node3D) -> void:
	if body.has_method("enemy"):
		targets.erase(body)
