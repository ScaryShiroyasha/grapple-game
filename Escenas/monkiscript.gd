extends Area3D

@export var rotate_speed_deg: float = 60.0
@export var bob_amplitude: float = 0.1
@export var bob_speed: float = 2.0
@export var magnet_distance: float = 2.5
@export var magnet_speed: float = 6.0
@export var visual_path: NodePath = NodePath()	# hijo visual que rota (opcional)
@export var rotate_enabled: bool = true
@export var rotate_axis: Vector3 = Vector3.UP	# eje de giro (Y)

# Configuración del efecto de luz pulsante
@export var glow_fade_time: float = 5.0		# segundos para que la luz desaparezca
@export var glow_wait_time: float = 5.0		# segundos que permanece apagada
@export var glow_max_energy: float = 2.0	# energía máxima de la luz
@export var glow_max_range: float = 8.0		# rango máximo de la luz

var _t: float = 0.0
var _base_pos: Vector3
var _base_ready: bool = false
var _collected: bool = false
var _glow_cycle_time: float = 0.0
var _glow_state: int = 0  # 0 = brillando, 1 = esperando

@onready var _visual: Node3D = get_node_or_null(visual_path) as Node3D
@onready var _light: OmniLight3D = get_node_or_null("OmniLight3D") as OmniLight3D

func _ready() -> void:
	# Capa 8 (token), ve al Player en capa 1
	collision_layer = 1 << 7
	collision_mask  = 1 << 0
	monitoring = true
	monitorable = true

	# Capturar posición base cuando el spawner ya colocó el nodo
	call_deferred("_capture_base")

	# Conectar señales sin duplicar
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# Grupo para que el spawner pueda contarlos si quiere
	if not is_in_group("monkitoken"):
		add_to_group("monkitoken")

func _capture_base() -> void:
	_base_pos = global_position
	_base_ready = true

func reset_base_from_current() -> void:
	_base_pos = global_position
	_base_ready = true

func _process(delta: float) -> void:
	if _collected or not _base_ready:
		return

	# --- ROTACIÓN ---
	if rotate_enabled:
		var ang: float = deg_to_rad(rotate_speed_deg * delta)
		if _visual:
			_visual.rotate(rotate_axis, ang)
		else:
			rotate(rotate_axis, ang)

	# --- FLOTACIÓN ---
	_t += delta
	var pos: Vector3 = _base_pos
	pos.y += sin(_t * bob_speed) * bob_amplitude
	global_position = pos

	# --- EFECTO DE LUZ PULSANTE ---
	if _light:
		_glow_cycle_time += delta
		
		if _glow_state == 0:  # Brillando y disminuyendo
			var progress = _glow_cycle_time / glow_fade_time
			if progress >= 1.0:
				# Termina el brillo, inicia la espera
				_glow_state = 1
				_glow_cycle_time = 0.0
				_light.light_energy = 0.0
				_light.omni_range = 0.0
			else:
				# Disminuye gradualmente
				var intensity = 1.0 - progress
				_light.light_energy = glow_max_energy * intensity
				_light.omni_range = glow_max_range * intensity
		
		elif _glow_state == 1:  # Esperando apagado
			if _glow_cycle_time >= glow_wait_time:
				# Termina la espera, vuelve a brillar
				_glow_state = 0
				_glow_cycle_time = 0.0

	# --- IMÁN ---
	var player_node: Node3D = _get_player_if_close()
	if player_node:
		var dir: Vector3 = (player_node.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta

# --- Señales ---
func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.is_in_group("PlayerCoins") or body.is_in_group("player"):
		_collect(body)

func _on_area_entered(a: Area3D) -> void:
	if _collected:
		return
	if a.is_in_group("PlayerCoins") or a.is_in_group("player"):
		_collect(a)

# --- Recolección ---
func _collect(actor: Node) -> void:
	_collected = true

	# Detener lógica y colisiones del token
	set_process(false)
	set_physics_process(false)
	set_deferred("monitoring", false)
	_disable_all_collisions(self)
	_hide_all_visuals(self)

	# Notificar al Player
	if actor.has_method("add_collectible"):
		actor.add_collectible(1)
	elif actor.has_method("add_token"):
		actor.add_token()
	else:
		print("[MonkiToken] Aviso: el actor no tiene add_collectible ni add_token")

	print("[MonkiToken] Recolectado por:", actor.name)

	# Efectos opcionales
	if has_node("GPUParticles3D"):
		$GPUParticles3D.one_shot = true
		$GPUParticles3D.emitting = true
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.play()

	await get_tree().process_frame
	queue_free()

# --- Utilidades ---
func _get_player_if_close() -> Node3D:
	var players := get_tree().get_nodes_in_group("PlayerCoins")
	if players.is_empty():
		players = get_tree().get_nodes_in_group("player")	# por si usas otro grupo
	if players.is_empty():
		return null

	var me: Vector3 = global_position
	var best: Node3D = null
	var best_d2: float = INF
	for n in players:
		if n is Node3D:
			var pos: Vector3 = (n as Node3D).global_position
			var d2: float = me.distance_squared_to(pos)
			if d2 < best_d2:
				best_d2 = d2
				best = n as Node3D
	return best if best and best_d2 <= magnet_distance * magnet_distance else null

func _hide_all_visuals(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).visible = false
	for c in n.get_children():
		_hide_all_visuals(c)

func _disable_all_collisions(n: Node) -> void:
	if n is CollisionShape3D:
		(n as CollisionShape3D).disabled = true
	elif n is Area3D:
		(n as Area3D).set_deferred("monitoring", false)
		(n as Area3D).set_deferred("monitorable", false)
	elif n is CollisionObject3D:
		(n as CollisionObject3D).set_deferred("disabled", true)
	for c in n.get_children():
		_disable_all_collisions(c)
