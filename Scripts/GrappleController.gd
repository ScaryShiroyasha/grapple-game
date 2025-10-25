extends Node

@export var ray: RayCast3D

@export var rope: Path3D

@export var rest_lenght = 2.0
@export var stiffnes = 10.0
@export var damping = 1.0
@export var launch_speed = 50.0

@onready var player: CharacterBody3D = get_parent()


var target: Vector3
var launched = false
var targetobj
var diff

var launch_progress: float = 0.0
var is_attached = false

func _ready() -> void:
	if !rope or !player:
		print("Error: Faltan referencias (Rope o Player) en el script del grapple.")
		return
		
	rope.set("wavy_effect_enabled", true)
	rope.visible = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		launch()
	if Input.is_action_just_released("shoot"):
		retract()
		
	if launched:
		# Calculamos el punto final
		var anchor_pos = targetobj.global_position + diff
		
		# 2. Comprobamos si la cuerda aún se está estirando
		if launch_progress < 1.0:
			# Calculamos la distancia total que debe recorrer la cuerda
			var total_dist = player.global_position.distance_to(anchor_pos)
			if !is_zero_approx(total_dist):
				# (velocidad * tiempo) / distancia = progreso
				launch_progress += (launch_speed * delta) / total_dist
			else:
				launch_progress = 1.0 # Ya estamos ahí
			
			# Aseguramos que no se pase de 1.0
			launch_progress = min(launch_progress, 1.0)
			
			# Calculamos el punto final ACTUAL de la cuerda usando lerp()
			var current_rope_end = player.global_position.lerp(anchor_pos, launch_progress)
			# Dibujamos la cuerda hasta ese punto intermedio
			rope.update_wavy_line(player.global_position, current_rope_end)
		
		else:
			
			if not is_attached:
				rope.set_state_straight()
				is_attached = true
			
			# La física se aplica
			handle_grapple(delta, anchor_pos)
			rope.update_wavy_line(player.global_position, anchor_pos)
		
	elif rope.visible:
		#rope.update_wavy_line(player.global_position, player.global_position)
		rope.visible = false
# Called when the node enters the scene tree for the first time.
	#update_rope()
	
func launch():
	if ray.is_colliding():
		print("colissiona el ray")
		target = ray.get_collision_point()
		targetobj = ray.get_collider()
		launched = true
		launch_progress = 0.0
		diff = target - targetobj.global_position
		rope.set_state_wavy()
		rope.visible = true


func retract():
	launched = false
	launch_progress = 0.0
	rope.visible = false
	is_attached = false
	
func handle_grapple(delta: float, anchor_pos: Vector3):
	#var targetposition = targetobj.position
	
	
	
	var target_dir = player.global_position.direction_to(anchor_pos)
	var target_dist = player.global_position.distance_to(anchor_pos)
	
	
	
	var displacement = target_dist - rest_lenght
	
	var force = Vector3.ZERO
	
	if displacement > 0:
		var spring_force_magnitude = stiffnes * displacement
		var spring_force = target_dir * spring_force_magnitude
		
		var vel_dot = player.velocity.dot(target_dir)
		#print(damping)
		var damping1 = -damping * vel_dot * target_dir
		
		force = spring_force + damping1
		
	player.velocity += force * delta

func update_rope():
	if !launched:
		rope.visible = false
		return
	
	#rope.visible = true
	DebugDraw3D.draw_line(player.global_position, (targetobj.global_position + diff), Color())
	#var dist= player.global_position.distance_to(target)
	
	#rope.look_at(target)
	#rope.scale = Vector3(1, 1, dist)
