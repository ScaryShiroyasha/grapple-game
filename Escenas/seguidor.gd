# FollowSphereWithChain.gd (Godot 4) — limpio
extends CharacterBody3D

# Fuente de tokens en el Player
@export var token_property_name: String = "collectibles"	# nombre exacto de la propiedad en Player
@export var collectibles_key: String = "MonkiToken"		# si es Dictionary, clave a contar

# Ocultar solo la malla de la "cabeza" (esfera)
@export var hide_head_mesh: bool = true
@export var head_mesh_path: NodePath

# Movimiento del seguidor
@export var speed: float = 5.0
@export var stop_radius: float = 1.2
@export var height_lock: bool = false
@export var target_path: NodePath = ^"../Player"

# Cadena de Monkis
@export var segment_scene: PackedScene
@export var link_spacing: float = 1.0
@export var follow_speed: float = 12.0
@export var max_segments: int = 30
@export var look_at_prev: bool = true

var target: Node3D
var segments: Array[Node3D] = []
var _token_count_cache: int = 0

func _ready() -> void:
	target = get_node_or_null(target_path)

	# Ocultar solo la malla de la cabeza (no afecta la cadena)
	if hide_head_mesh and head_mesh_path != NodePath():
		var head_mesh := get_node_or_null(head_mesh_path)
		if head_mesh and head_mesh is VisualInstance3D:
			(head_mesh as VisualInstance3D).visible = false

	# Escuchar cambios de tokens si el Player emite esa señal (opcional)
	if target != null and target.has_signal("tokens_changed"):
		target.connect("tokens_changed", Callable(self, "_on_tokens_changed"))

	# Sincroniza cantidad inicial de segmentos
	_sync_chain_to_tokens(_read_tokens_from_target())

func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Seguir al Player
	var to_vec: Vector3 = target.global_position - global_position
	if height_lock:
		to_vec.y = 0.0

	var dist: float = to_vec.length()
	if dist <= stop_radius:
		velocity = Vector3.ZERO
	else:
		var dir: Vector3 = to_vec.normalized()
		velocity = dir * speed
		look_at(target.global_position, Vector3.UP)

	move_and_slide()

	# Mantener sincronizada la cantidad de segmentos
	var tokens_now: int = _read_tokens_from_target()
	if tokens_now != _token_count_cache:
		_sync_chain_to_tokens(tokens_now)

	# Actualizar posiciones de la cadena
	_update_chain_follow(delta)

# API para setear tokens manualmente desde otro lado
func set_token_count(n: int) -> void:
	var clamped: int = clampi(n, 0, max_segments)
	if clamped != _token_count_cache:
		_sync_chain_to_tokens(clamped)

func _on_tokens_changed(new_total: int) -> void:
	set_token_count(new_total)

# Lee "collectibles" del Player
func _read_tokens_from_target() -> int:
	if target == null:
		return _token_count_cache

	var prop_value: Variant = target.get(token_property_name)	# null si no existe

	# A) Entero directo
	if prop_value is int:
		return (prop_value as int)

	# B) Arreglo (lista de pickups)
	if prop_value is Array:
		var arr: Array = prop_value
		return arr.size()

	# C) Diccionario { "MonkiToken": n, ... }
	if prop_value is Dictionary:
		var d: Dictionary = prop_value
		var count_val: Variant = d.get(collectibles_key, 0)
		if count_val is int:
			return (count_val as int)
		elif count_val is float:
			return int(count_val)
		return _token_count_cache

	# Fallback opcional: método get_token_count()
	if target.has_method("get_token_count"):
		var got: Variant = target.call("get_token_count")
		if got is int:
			return (got as int)
		elif got is float:
			return int(got)

	return _token_count_cache

func _sync_chain_to_tokens(tokens: int) -> void:
	var desired: int = clampi(tokens, 0, max_segments)

	# Crear faltantes
	while segments.size() < desired:
		if segment_scene == null:
			break
		var seg: Node3D = segment_scene.instantiate() as Node3D
		add_child(seg)
		segments.append(seg)

	# Borrar sobrantes
	while segments.size() > desired:
		var last: Node3D = segments.pop_back() as Node3D
		if is_instance_valid(last):
			last.queue_free()

	_token_count_cache = desired

	# Reubicar toda la fila para que se vea desde el primer frame
	_layout_chain_initial()

func _layout_chain_initial() -> void:
	if segments.is_empty():
		return
	var fwd: Vector3 = -transform.basis.z.normalized()
	var anchor: Vector3 = global_position
	for i in range(segments.size()):
		var seg: Node3D = segments[i]
		seg.global_position = anchor + fwd * (-(i + 1) * link_spacing)
		if look_at_prev:
			var look_target: Vector3 = global_position if i == 0 else segments[i - 1].global_position
			seg.look_at(look_target, Vector3.UP)

func _update_chain_follow(delta: float) -> void:
	if segments.is_empty():
		return

	var prev_pos: Vector3 = global_position
	for seg: Node3D in segments:
		var to_prev: Vector3 = prev_pos - seg.global_position
		if height_lock:
			to_prev.y = 0.0

		var dist: float = to_prev.length()
		if dist > 0.0001:
			var desired_pos: Vector3 = prev_pos - to_prev.normalized() * link_spacing
			var t: float = clampf(follow_speed * delta, 0.0, 1.0)
			seg.global_position = seg.global_position.lerp(desired_pos, t)
			if look_at_prev:
				seg.look_at(prev_pos, Vector3.UP)

		prev_pos = seg.global_position
