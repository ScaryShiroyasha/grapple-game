extends CharacterBody3D

@export var speed = 15.0
@export var jump_force = 10.0
@export var gravity = 0.5

@export var acceleration = 10.0
@export var deceleration = 8.0

@export var sensitivity = 0.01

@export var vida := 100.0
@export var damage := 30.0
var maxvida = 100.0
var onCD = false
var targets: Array = []

# === POWER UP: doble salto ===
@export var doble_salto: bool = false
@export var max_air_jumps: int = 1
var air_jumps_left: int = 0

# === POWER UP: DASH (1 por aire) ===
@export var PowerUp_Dash: bool = false        # activar con pickup/set_dash_enabled(true)
@export var dash_speed: float = 28.0
@export var dash_duration: float = 0.16
@export var dash_cancel_vertical: bool = true # corta velocidad vertical al iniciar dash
@export var max_air_dashes: int = 1           # 1 = un dash por aire

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_dir: Vector3 = Vector3.ZERO
var air_dashes_left: int = 0                  # dashes disponibles hasta tocar el suelo
var rng = RandomNumberGenerator.new()

@onready var hpbar = $HUD/HpBar
@onready var cam = $Camera3D
@onready var gc = $GrappleController
@onready var animationPlayer = $AnimationPlayer
@onready var AtackCD = $AttackCD

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not is_in_group("PlayerCoins"):
		add_to_group("PlayerCoins")
	# Resetear contador de tokens al iniciar
	collectibles = 0
	# recarga inicial segun power-ups
	air_jumps_left  = max_air_jumps  if doble_salto  else 0
	air_dashes_left = max_air_dashes if PowerUp_Dash else 0

func _process(_delta: float) -> void:
	update_HUD()
	if Input.is_action_just_pressed("attack") and not onCD:
		animationPlayer.play("Sword_animation")
		AtackCD.start()
		onCD = true
		if targets.is_empty():
			$sfx_miss.set_pitch_scale(rng.randf_range(0.8, 1.2))
			$sfx_miss.play()
			
		else:
			$sfx_hit.set_pitch_scale(rng.randf_range(0.8, 1.2))
			$sfx_hit.play()
			for target in targets:
				print(damage)
				target.getHit(damage)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# terminar dash por tiempo
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0.0:
			is_dashing = false

	# gravedad (no mientras dashing)
	if not is_on_floor() and not is_dashing:
		velocity.y -= gravity
	elif is_on_floor():
		# recarga SOLO al tocar suelo
		air_jumps_left  = max_air_jumps  if doble_salto  else 0
		air_dashes_left = max_air_dashes if PowerUp_Dash else 0

	# direccion deseada
	var input_vec := Input.get_vector("left", "right", "forward", "back")
	var wish_dir := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()

	# === Disparar DASH (1 por aire) ===
	if PowerUp_Dash and Input.is_action_just_pressed("dash") and not is_dashing and air_dashes_left > 0:
		is_dashing = true
		dash_time_left = dash_duration
		dash_dir = wish_dir
		if dash_dir == Vector3.ZERO:
			dash_dir = -transform.basis.z # adelante local
		if dash_cancel_vertical:
			velocity.y = 0.0
		air_dashes_left -= 1
		# print("[Dash] start dir=", dash_dir, " dashes_left=", air_dashes_left)

	# saltos
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_force
		elif doble_salto and air_jumps_left > 0:
			velocity.y = jump_force
			air_jumps_left -= 1

	# movimiento horizontal
	if is_dashing:
		var h := dash_dir * dash_speed
		velocity.x = h.x
		velocity.z = h.z
	else:
		if wish_dir != Vector3.ZERO:
			velocity.x = lerpf(velocity.x, wish_dir.x * speed, acceleration * delta)
			velocity.z = lerpf(velocity.z, wish_dir.z * speed, acceleration * delta)
		else:
			velocity.x = lerpf(velocity.x, 0.0, deceleration * delta)
			velocity.z = lerpf(velocity.z, 0.0, deceleration * delta)

	move_and_slide()

func attack():
	if Input.is_action_just_pressed("attack") and not onCD:
		animationPlayer.play("sword_animation")
		AtackCD.start()
		onCD = true
		
func getHit(damage_enemie: float):
	vida = vida - damage_enemie
	hpbar.value = vida
	
	# Perder entre 1-3 tokens al recibir daño
	if collectibles > 0:
		var tokens_lost = randi_range(1, 3)
		# No perder más tokens de los que tienes
		tokens_lost = min(tokens_lost, collectibles)
		collectibles -= tokens_lost
		emit_signal("collectibles_changed", collectibles)
		print("[Player] ¡Perdiste ", tokens_lost, " tokens! Tokens restantes: ", collectibles)
	
	# Si muere, volver al menú
	if (vida <= 0):
		print("Muerte - Volviendo al menú...")
		# Desbloquear el mouse antes de cambiar de escena
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://Escenas/Menu.tscn")

func update_HUD():
	hpbar.value = vida

func _on_attack_cd_timeout() -> void:
	onCD = false

func _on_rangodeataque_body_entered(body: Node3D) -> void:
	if body.has_method("enemy"):
		targets.append(body)

func _on_rangodeataque_body_exited(body: Node3D) -> void:
	if body.has_method("enemy"):
		targets.erase(body)

# === Power-ups ===
func set_doble_salto_enabled(enabled: bool) -> void:
	doble_salto = enabled
	if is_on_floor():
		air_jumps_left = max_air_jumps if doble_salto else 0
	# print("[PowerUp] doble_salto =", doble_salto, " air_jumps_left=", air_jumps_left)

func set_dash_enabled(enabled: bool) -> void:
	PowerUp_Dash = enabled
	# si estas en el suelo al activarlo, quedas con 1 dash listo
	if is_on_floor():
		air_dashes_left = max_air_dashes if PowerUp_Dash else 0
	# print("[PowerUp] dash =", PowerUp_Dash, " air_dashes_left=", air_dashes_left)

signal collectibles_changed(value: int)
var collectibles: int = 0
var enemies_killed: int = 0  # Contador de enemigos matados

func add_collectible(n: int) -> void:
	collectibles += n
	emit_signal("collectibles_changed", collectibles)
	print("[Player] tokens =", collectibles)

func enemy_killed() -> void:
	enemies_killed += 1
	print("[Player] Enemigos matados: ", enemies_killed)
	
	# Cada 3 enemigos matados, dar un token
	if enemies_killed >= 3:
		enemies_killed = 0  # Resetear contador
		add_collectible(1)
		print("[Player] ¡Recompensa! +1 Monki Token por matar 3 enemigos!")
