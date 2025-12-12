extends CharacterBody3D

enum States {Attack, idle, chase, dead}

# --- Variables ---
@export var hp = 50
@export var chase_speed = 5.25 # Aumentado de 5.0 a 5.25 (1.05x)
@export var push_force = 55.0 # Fuerza del empuje al jugador
@export var explosion_time = 1.0 # Tiempo antes de explotar (reducido a la mitad)
@export var explosion_scene: PackedScene

# --- Referencias a Nodos ---
@onready var VFXExplosion = $VFX_Explosion
@onready var mesh = $MeshInstance3D
@onready var collision = $CollisionShape3D
@onready var nav_agent = $NavigationAgent3D
@onready var explosion_area = $AreaDeteccion
@onready var explosion_timer = $Timer

var state = States.chase # Empezamos persiguiendo
var is_dead = false
var player = null # NUEVO: Referencia al jugador

# --- Inicialización ---
func _ready():
	# Busca al jugador en la escena (asegúrate que tu player está en el grupo "player")
	player = get_tree().get_first_node_in_group("player")
	print(player)
	# Configurar el tiempo de explosión
	explosion_timer.wait_time = explosion_time
	# Asegúrate de que el timer no esté corriendo
	explosion_timer.stop()
	state = States.chase


# --- Bucle de Física y Lógica de IA ---
func _physics_process(delta: float):
	# Si no estamos en el suelo, aplicamos gravedad
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# Máquina de estados
	match state:
		States.idle:
			print("en idle")
			# No hacer nada, esperar
			velocity = velocity.move_toward(Vector3.ZERO, delta * 10.0) # Frenar
			pass
			
		States.chase:
			# Lógica de persecución con Navegación
			if player:
				
				# Actualiza el objetivo del agente de navegación
				nav_agent.set_target_position(player.global_position)
				
				# Obtiene el siguiente punto en la ruta calculada
				var next_path_pos = nav_agent.get_next_path_position()
				
				# Calcula la dirección hacia ese punto
				var new_velocity = global_position.direction_to(next_path_pos) * chase_speed
				
				# Mantenemos la velocidad Y (gravedad)
				new_velocity.y = velocity.y 
				velocity = new_velocity
			
		States.Attack:
			
			velocity = velocity.move_toward(Vector3.ZERO, delta * 10.0) # Frenar
			# El timer se encarga del resto
			
		States.dead:
			# Ya no hacemos nada, la explosión está en curso
			velocity = Vector3.ZERO
	
	# Aplicamos el movimiento
	move_and_slide()

# --- Funciones de Combate ---

func getHit(damage: float):
	print("gothit")
	if is_dead:
		return
	hp = hp - damage
	print("hp: ", hp)
	if (hp <= 0):
		is_dead = true
		# Notificar al jugador que mató un enemigo
		if player and player.has_method("enemy_killed"):
			player.enemy_killed()
		die_by_player()

func die_explosion():
	state = States.dead # Cambiamos de estado
	
	# 1. Desactivar al enemigo
	set_physics_process(false) 
	collision.disabled = true
	mesh.visible = false
	VFXExplosion.visible = true	
	
	# 2. Empujar al jugador en lugar de quitarle vida
	var bodies = explosion_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			# Calcular dirección del empuje (desde el enemigo hacia el jugador)
			var push_direction = (body.global_position - global_position).normalized()
			push_direction.y = 0.5 # Añadir componente vertical para lanzar hacia arriba
			push_direction = push_direction.normalized()
			
			# Aplicar empuje al jugador
			if body is CharacterBody3D:
				body.velocity = push_direction * push_force
			
			print("¡Jugador empujado con fuerza:", push_force, "!")
	
	# 3. Conectar la señal (como ya lo tenías)
	VFXExplosion.explosion_finished.connect(queue_free)

	# 4. Iniciar la explosión
	VFXExplosion.StartExplosion()
	
func die_by_player():
	state = States.dead # Cambiamos de estado
	
	# 1. Desactivar al enemigo
	set_physics_process(false) 
	collision.disabled = true
	mesh.visible = false
	
# --- Señales de la Zona de Explosión ---





func _on_explosion_area_deteccion_body_entered(body):
	# Si el que entró es el jugador y no estamos muertos
	if body.is_in_group("player") and not is_dead:
		print("¡Jugador en rango! Iniciando cuenta regresiva...")
		state = States.Attack # Cambia al estado de ataque
		explosion_timer.start() # Inicia el timer


func _on_explosion_area_deteccion_body_exited(body: Node3D) -> void:
	# Si el que salió es el jugador y no estamos muertos
	if body.is_in_group("player") and not is_dead:
		print("¡Jugador escapó! Abortando...")
		state = States.chase # Vuelve al estado de persecución
		explosion_timer.stop() # Detiene el timer


func _on_timer_timeout() -> void:
	if is_dead: # Por si acaso
		return
		
	print("¡KABOOM!")
	is_dead = true
	# MODIFICADO: Pasa 'true' porque SÍ es una explosión kamikaze
	die_explosion()

func enemy():
	pass
