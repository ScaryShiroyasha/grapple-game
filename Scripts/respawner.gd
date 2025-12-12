extends Node3D

# ---- Escena del token ----
const PICKUP_SCENE: PackedScene = preload("res://Escenas/monkitoken.tscn")

# ----- Límite inferior -----
@export var use_min_y: bool = true
@export var min_y_world: float = 0.0      # pon aquí el Y del piso/umbral de tu mundo
@export var min_y_margin: float = 0.5     # pequeño offset para evitar tocar exacto el límite
# Si prefieres RECHAZAR puntos por debajo (en vez de clamping), pon:
@export var reject_below_min_y: bool = false


# ---- Límite y ritmo ----
@export var max_alive: int = 1           # cuántos tokens máximos al mismo tiempo
@export var initial_fill: int = 1        # cuántos crear al inicio
@export var respawn_seconds: float = 5.0 # cada cuánto intentar crear otro

# ---- Volumen de spawn (caja 3D centrada en este nodo) ----
@export var extent_x: float = 30.0       # ancho a los lados (±X)
@export var extent_y: float = 30.0       # altura (±Y). Si quieres “aire”, sube esto.
@export var extent_z: float = 30.0       # profundidad (±Z)

# ---- Opcional: pegar al suelo ----
@export var snap_to_ground: bool = false
@export var spawn_height_probe: float = 40.0  # altura desde la que se lanza el rayo hacia abajo
@export var ground_offset_y: float = 0.6      # separa el token del piso
@export var floor_mask: int = -1              # capas que cuentan como "suelo" ( -1 = todas )

# ---- Separaciones ----
@export var min_dist_from_player: float = 12.0      # no spawnear cerca del player
@export var min_dist_between_tokens: float = 5.0    # no spawnear pegado a otro token

# ---- Anti-repetición (variedad) ----
@export var min_dist_from_last_spawn: float = 8.0   # no repetir muy cerca del último punto
@export var remember_last_n: int = 5                # cuántos puntos recordar

# ---- Intentos por tick ----
@export var max_attempts: int = 40

# ---- Internos ----
@onready var _timer: Timer = $Timer as Timer
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _last_spawns: Array[Vector3] = []

func _ready() -> void:
	rng.randomize()

	# Asegurar el Timer
	if _timer == null:
		_timer = Timer.new()
		add_child(_timer)
	_timer.one_shot = false
	_timer.wait_time = respawn_seconds
	if not _timer.timeout.is_connected(_on_timer_timeout):
		_timer.timeout.connect(_on_timer_timeout)
	_timer.start()

	# Llenado inicial diferido (da tiempo a que el Player entre a su grupo)
	call_deferred("_do_initial_fill")

func _do_initial_fill() -> void:
	var to_spawn: int = min(initial_fill, max_alive - _alive_count_global())
	for _i in range(to_spawn):
		_spawn_one_if_room()

func _on_timer_timeout() -> void:
	if _alive_count_global() < max_alive:
		_spawn_one_if_room()

# -------------------------------------------------------------

func _spawn_one_if_room() -> void:
	if _alive_count_global() >= max_alive:
		return

	var pos_ok: Vector3 = Vector3.ZERO
	var found: bool = false

	for _i in range(max_attempts):
		# 1) punto aleatorio en la caja 3D
		var candidate: Vector3 = _random_point_in_box()

		# 2) si quieres suelo, pegar con raycast; si no, usa tal cual (aire)
		var pos: Vector3 = _maybe_snap_ground(candidate)
		if pos == Vector3.INF:
			continue

		# 3) filtros de distancia
		if not _clear_of_player(pos):            # lejos del player
			continue
		if not _clear_of_tokens(pos):            # lejos de otros tokens
			continue
		if not _clear_of_recent(pos):            # lejos de últimos spawns
			continue

		pos_ok = pos
		found = true
		break

	if not found:
		return

	# 4) instanciar token
	var inst: Node3D = PICKUP_SCENE.instantiate() as Node3D
	if not inst.is_in_group("monkitoken"):
		inst.add_to_group("monkitoken")
	add_child(inst)

	inst.global_transform = Transform3D(Basis(), pos_ok)
	# muy recomendable: fijar su base de bobbing a esta posición
	if inst.has_method("reset_base_from_current"):
		inst.call_deferred("reset_base_from_current")

	# 5) recordar este punto para variedad
	_last_spawns.push_front(pos_ok)
	while _last_spawns.size() > max(1, remember_last_n):
		_last_spawns.pop_back()

# -------------------------------------------------------------
# Helpers de criterios
# -------------------------------------------------------------

func _alive_count_global() -> int:
	return get_tree().get_nodes_in_group("monkitoken").size()

func _random_point_in_box() -> Vector3:
	var rx: float = rng.randf_range(-extent_x, extent_x)
	var ry: float = rng.randf_range(-extent_y, extent_y)
	var rz: float = rng.randf_range(-extent_z, extent_z)
	return global_position + Vector3(rx, ry, rz)

func _maybe_snap_ground(cand: Vector3) -> Vector3:
	if not snap_to_ground:
		# SIN snap: aplicamos límite inferior si corresponde
		if use_min_y and (cand.y < min_y_world):
			if reject_below_min_y:
				return Vector3.INF
			else:
				cand.y = min_y_world + min_y_margin
		return cand

	# CON snap: raycast al piso
	var state := get_world_3d().direct_space_state
	var from_pos := cand + Vector3(0.0, spawn_height_probe, 0.0)
	var to_pos := from_pos + Vector3(0.0, -spawn_height_probe * 2.0, 0.0)
	var q := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.collision_mask = floor_mask
	var hit := state.intersect_ray(q)
	if hit.is_empty():
		# Si no golpea “piso”, aplica límite inferior si quieres
		if use_min_y and (cand.y < min_y_world):
			return Vector3.INF if reject_below_min_y else Vector3(cand.x, min_y_world + min_y_margin, cand.z)
		return cand

	var pos := (hit["position"] as Vector3) + Vector3(0.0, ground_offset_y, 0.0)
	# Aun con snap, garantizamos límite inferior
	if use_min_y and (pos.y < min_y_world):
		if reject_below_min_y:
			return Vector3.INF
		pos.y = min_y_world + min_y_margin
	return pos


func _clear_of_player(pos: Vector3) -> bool:
	var player: Node3D = get_tree().get_first_node_in_group("PlayerCoins") as Node3D
	return true if player == null else pos.distance_to(player.global_position) >= min_dist_from_player

func _clear_of_tokens(pos: Vector3) -> bool:
	for n in get_tree().get_nodes_in_group("monkitoken"):
		if n is Node3D:
			if pos.distance_to((n as Node3D).global_position) < min_dist_between_tokens:
				return false
	return true

func _clear_of_recent(pos: Vector3) -> bool:
	for p in _last_spawns:
		if pos.distance_to(p) < min_dist_from_last_spawn:
			return false
	return true
