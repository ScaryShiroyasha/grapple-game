extends Node

#  Clase interna para guardar el estado de UN gancho
class HookData:
	var ray: RayCast3D
	var rope: Path3D
	
	var target: Vector3
	var launched = false
	var targetobj
	var diff: Vector3
	
	var launch_progress: float = 0.0
	var is_attached = false
	
	var origin_offset: Vector3
	# Constructor para configurar las referencias
	func _init(p_ray: RayCast3D, p_rope: Path3D, p_offset: Vector3):
		ray = p_ray
		rope = p_rope
		origin_offset = p_offset # Guardamos el offset
		if rope:
			rope.set("wavy_effect_enabled", true)
			rope.visible = false

# --- Variables de Física (Compartidas) ---
@export_group("Physics")
@export var rest_lenght = 2.0
@export var stiffnes = 10.0
@export var damping = 1.0
@export var launch_speed = 50.0
@export var retract_speed = 40.0 

# --- Referencias de Nodos ---
@export_group("Left Hook (Q)")
@export var ray_left: RayCast3D
@export var rope_left: Path3D

@export_group("Right Hook (E)")
@export var ray_right: RayCast3D
@export var rope_right: Path3D

@export_group("UI")
@export var crosshair: Label

@onready var player: CharacterBody3D = get_parent()
@onready var hook_sound: AudioStreamPlayer = $"../HookSound"

# NUEVO: Instancias de estado para cada gancho
var left_hook: HookData
var right_hook: HookData

# --- Configuración ---
func _ready() -> void:
	# Valida que todos los nodos estén asignados
	if !ray_left or !rope_left or !ray_right or !rope_right or !player:
		push_error("¡Faltan referencias de nodos en el script del gancho!")
		return
		
	#  Definimos los offsets en el espacio local del jugador
	# player.basis.x (derecha) * 0.2
	var left_offset = Vector3(-0.2, 0, 0) # 0.2m a la izquierda local
	var right_offset = Vector3(0.2, 0, 0) # 0.2m a la derecha local
		
	# NUEVO: Inicializa los objetos de estado
	left_hook = HookData.new(ray_left, rope_left, left_offset)
	right_hook = HookData.new(ray_right, rope_right, right_offset)


# --- Bucle Principal ---
func _physics_process(delta: float) -> void:
	# --- Manejo de Input ---

	_update_reticle_visuals()
	# Gancho Izquierdo (Q)
	if Input.is_action_just_pressed("grapple_left"):
		launch_hook(left_hook)
	if Input.is_action_just_released("grapple_left"):
		retract_hook(left_hook)
		
	# Gancho Derecho (E)
	if Input.is_action_just_pressed("grapple_right"):
		launch_hook(right_hook)
	if Input.is_action_just_released("grapple_right"):
		retract_hook(right_hook)
	
	# Retracción (Click Derecho / Rueda)
	if Input.is_action_pressed("grapple_retract"):
		_handle_retraction(delta)

	# --- Actualización de Ganchos ---
	# Llama a la lógica de actualización para CADA gancho
	_update_hook(delta, left_hook)
	_update_hook(delta, right_hook)

func _update_reticle_visuals():
	if !crosshair:
		return
	# Lógica: Si CUALQUIERA de los dos puede enganchar, se pone verde.
	# Si ninguno llega, se pone rojo.
	var new_color = Color.RED
	if ray_left.is_colliding() or ray_right.is_colliding():
		new_color = Color.GREEN
	crosshair.add_theme_color_override("font_color", new_color)

# --- Lógica Genérica de Ganchos ---

#  Lógica de actualización genérica 
func _update_hook(delta: float, hook: HookData):
	var hook_origin = player.global_position + (player.global_transform.basis * hook.origin_offset)
	if hook.launched:
		# Calculamos el punto final
		var anchor_pos = hook.targetobj.global_position + hook.diff
		
		# 2. Comprobamos si la cuerda aún se está estirando
		if hook.launch_progress < 1.0:
			
			var total_dist = hook_origin.distance_to(anchor_pos)
			if !is_zero_approx(total_dist):
				hook.launch_progress += (launch_speed * delta) / total_dist
			else:
				hook.launch_progress = 1.0
			
			hook.launch_progress = min(hook.launch_progress, 1.0)
			
			var current_rope_end = hook_origin.lerp(anchor_pos, hook.launch_progress)
			hook.rope.update_wavy_line(hook_origin, current_rope_end)
		
		else:
			# Enganchado
			if not hook.is_attached:
				hook.rope.set_state_straight()
				hook.is_attached = true
			
			# La física se aplica
			handle_grapple(delta, anchor_pos) 
			hook.rope.update_wavy_line(hook_origin, anchor_pos)
			
	elif hook.rope.visible:
		hook.rope.visible = false

# Lógica de lanzamiento
func launch_hook(hook: HookData):
	# Si ya está lanzado, no hacer nada (evita relanzar)
	if hook.launched:
		return
		
	if hook.ray.is_colliding():
		hook.target = hook.ray.get_collision_point()
		hook.targetobj = hook.ray.get_collider()
		hook.launched = true
		hook.launch_progress = 0.0
		hook.diff = hook.target - hook.targetobj.global_position
		
		hook.rope.set_state_wavy()
		hook.rope.visible = true
		hook_sound.play()

#  Lógica de retracción (desconectar)
func retract_hook(hook: HookData):
	hook.launched = false
	hook.launch_progress = 0.0
	hook.rope.visible = false
	hook.is_attached = false

# --- Física del Gancho ---

func handle_grapple(delta: float, anchor_pos: Vector3):
	var target_dir = player.global_position.direction_to(anchor_pos)
	var target_dist = player.global_position.distance_to(anchor_pos)
	
	var displacement = target_dist - rest_lenght
	
	var force = Vector3.ZERO
	
	if displacement > 0:
		var spring_force_magnitude = stiffnes * displacement
		var spring_force = target_dir * spring_force_magnitude
		
		var vel_dot = player.velocity.dot(target_dir)
		var damping1 = -damping * vel_dot * target_dir
		
		force = spring_force + damping1
		
	player.velocity += force * delta

#  Lógica para la mecánica de pull
func _handle_retraction(delta: float):
	var total_retract_force = Vector3.ZERO
	
	# Comprobar si el gancho izquierdo está anclado
	if left_hook.is_attached:
		var anchor_pos = left_hook.targetobj.global_position + left_hook.diff
		var dir = player.global_position.direction_to(anchor_pos)
		total_retract_force += dir * retract_speed
	
	# Comprobar si el gancho derecho está anclado
	if right_hook.is_attached:
		var anchor_pos = right_hook.targetobj.global_position + right_hook.diff
		var dir = player.global_position.direction_to(anchor_pos)
		total_retract_force += dir * retract_speed
		
	# Aplicar la fuerza de retracción 
	if total_retract_force != Vector3.ZERO:
		player.velocity += total_retract_force * delta
