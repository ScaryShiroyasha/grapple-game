extends Node

# --- VICTORIA ---
signal victory_achieved()
signal tokens_goal_changed(goal: int)  # Nueva señal para informar al HUD
var monkey_tokens_collected: int = 0
var TOKENS_TO_WIN: int = 10  # Ya no es constante, será aleatorio

var game_won: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Agregar al grupo GameController
	if not is_in_group("GameController"):
		add_to_group("GameController")
	
	# Generar un número aleatorio de tokens necesarios (entre 3 y 10)
	randomize()
	TOKENS_TO_WIN = randi_range(3, 10)
	print("[GameController] Tokens necesarios para ganar: ", TOKENS_TO_WIN)
	
	# Esperar un frame para que el HUD se inicialice
	await get_tree().process_frame
	
	# Emitir la señal para que el HUD se actualice
	emit_signal("tokens_goal_changed", TOKENS_TO_WIN)
	
	# Conectar con el player para escuchar cuando recoja tokens
	var player = get_tree().get_first_node_in_group("PlayerCoins")
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if player and player.has_signal("collectibles_changed"):
		player.collectibles_changed.connect(_on_player_collectibles_changed)

func _on_player_collectibles_changed(value: int) -> void:
	monkey_tokens_collected = value
	
	# Verificar si ganó
	if monkey_tokens_collected >= TOKENS_TO_WIN and not game_won:
		_trigger_victory()

func _trigger_victory() -> void:
	game_won = true
	emit_signal("victory_achieved")
	print("[GameController] ¡VICTORIA! Tokens recolectados:", monkey_tokens_collected)
	
	# Cambiar a la escena Fin en lugar de pausar
	await get_tree().create_timer(0.5).timeout  # Pequeña pausa para que se vea el efecto
	get_tree().change_scene_to_file("res://Escenas/Fin.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
