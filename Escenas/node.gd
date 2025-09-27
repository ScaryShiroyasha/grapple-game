extends Node

@export var ray: RayCast3D
@export var rope: Node3D

@export var rest_lenght = 2.0
@export var stiffnes = 10.0
@export var damping = 1.0

@onready var player: CharacterBody3D = get_parent()


var target: Vector3
var launched = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		launch()
	if Input.is_action_just_released("shoot"):
		retract()
		
	if launched:
		handle_grapple(delta)
# Called when the node enters the scene tree for the first time.
	update_rope()
func launch():
	print("entra launch")
	if ray.is_colliding():
		print("colissiona el ray")
		target = ray.get_collision_point()
		launched = true


func retract():
	launched = false
	
func handle_grapple(delta: float):

	var target_dir = player.global_position.direction_to(target)
	var target_dist = player.global_position.distance_to(target)
	
	
	
	var displacement = target_dist - rest_lenght
	print(displacement)
	var force = Vector3.ZERO
	
	if displacement > 0:
		var spring_force_magnitude = stiffnes * displacement
		var spring_force = target_dir * spring_force_magnitude
		
		var vel_dot = player.velocity.dot(target_dir)
		var damping = -damping * vel_dot * target_dir
		
		force = spring_force + damping
		
	player.velocity += force * delta

func update_rope():
	if !launched:
		rope.visible = false
		return
	
	rope.visible = true
	
	var dist= player.global_position.distance_to(target)
	
	rope.look_at(target)
	rope.scale = Vector3(1, 1, dist)
