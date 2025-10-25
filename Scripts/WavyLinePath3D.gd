@tool
extends LinePath3D


# --- VARIABLES DE LA LÍNEA ONDULADA ---
# Estas se añaden a las variables exportadas del padre
var _time: float = 0.0

@export_group("Wavy Line (Runtime)")
@export var wavy_effect_enabled: bool = true
@export var amplitude: float = 0.5
@export var frequency: float = 3.0
@export var speed: float = 2.0
@export var segments: int = 40

# Variables para guardar los valores por defecto del inspector
var default_amplitude: float
var default_frequency: float
var default_speed: float
var default_segments: int

var is_straight = false


# --- SOBRESCRITURA DE FUNCIONES ---

# Sobrescribimos _ready() para añadir nuestra lógica
func _ready():
	# Llama a la función _ready() del padre (LinePath3D)
	# Esto es VITAL para que conecte la señal "curve_changed" [cite: 5]
	super._ready() 
	
	# Ahora añadimos nuestra lógica
	default_amplitude = amplitude
	default_frequency = frequency
	default_speed = speed
	default_segments = segments

# Creamos _process() (el padre no tiene uno)
func _process(delta):
	# Si estamos en el juego y el efecto está activado...
	if not Engine.is_editor_hint() and wavy_effect_enabled:
		# Solo avanzamos el tiempo si NO estamos en modo recto
		if not is_straight:
			_time += delta * speed

# Sobrescribimos _draw() para controlar CÓMO se dibuja
func _draw():
	# Si estamos en el juego y el efecto ondulado está activo...
	if not Engine.is_editor_hint() and wavy_effect_enabled:
		# ...NO llames a la función _draw() original del padre.
		# Nuestro dibujo se maneja externamente por update_wavy_line().
		
		# Opcional: Limpia la malla si no se está actualizando
		if _mesh_instance.mesh != null:
			_mesh_instance.mesh = null
		return

	# Si estamos en el editor O el efecto está desactivado...
	# ...deja que el script LinePath3D original haga su trabajo.
	super._draw()


# --- NUEVAS FUNCIONES (Exclusivas de WavyLinePath3D) ---

func set_state_wavy():
	is_straight = false
	amplitude = default_amplitude
	frequency = default_frequency
	speed = default_speed
	segments = default_segments
	
func set_state_straight():
	is_straight = true
	amplitude = 0.0
	frequency = 1.0 # 1 es más seguro que 0
	speed = 0.0
	segments = 1 # 1 segmento = 2 puntos (inicio y fin)

# Esta es nuestra función principal de dibujo procedural
func update_wavy_line(start_pos_global: Vector3, end_pos_global: Vector3):
	# _mesh_instance es heredado del padre
	if _mesh_instance == null:
		return

	var points = PackedVector3Array()
	
	var direction = (end_pos_global - start_pos_global).normalized()
	
	var up_vector = Vector3.UP
	if direction.abs().dot(Vector3.UP) > 0.99:
		up_vector = Vector3.RIGHT
	var perpendicular = direction.cross(up_vector).normalized()
	
	# 'segments' y otras variables usarán los valores actuales
	for i in range(segments + 1):
		var t = float(i) / segments
		
		var straight_pos = start_pos_global.lerp(end_pos_global, t)
		
		var wave_input = (t * frequency * TAU) + _time
		var sine_value = sin(wave_input)
		var offset = perpendicular * sine_value * amplitude
		
		points.push_back(to_local(straight_pos + offset))

	# 'uv_size', 'uv_mode' y 'UVMode' son heredados
	var length = uv_size
	if uv_mode == UVMode.REPEAT:
		length *= start_pos_global.distance_to(end_pos_global)
		
	# '_linegen' y '_update_material()' son heredados
	_mesh_instance.mesh = _linegen.draw_from_points_strip(points, length)
	_update_material()
