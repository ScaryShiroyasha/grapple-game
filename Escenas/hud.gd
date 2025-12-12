# hud.gd
# Si tu HUD es un Control (no CanvasLayer), cambia la 1ª línea a: extends Control
extends CanvasLayer

@export var label: Label    # ← Asigna aquí tu Label en el Inspector (drag & drop)
@export var victory_label: Label  # ← Label para mostrar "Ganaste!"

var player: Node = null
var game_controller: Node = null
var tokens_needed: int = 10  # Valor por defecto, se actualizará

func _ready() -> void:
	# 1) Encontrar Player (primero por grupo, si no, usa el padre)
	player = get_tree().get_first_node_in_group("PlayerCoins")
	if player == null and get_parent() != null:
		player = get_parent()

	# 2) Si no asignaste el Label en el inspector, intenta encontrar uno automáticamente
	if label == null:
		# Busca un Label hijo llamado "TokenLabel", o el primer Label que encuentre
		label = get_node_or_null("TokenLabel") as Label
		if label == null:
			label = _find_first_label(self)
	
	# 3) Buscar victory_label
	if victory_label == null:
		victory_label = get_node_or_null("VictoryLabel") as Label
	
	# Ocultar victoria al inicio
	if victory_label:
		victory_label.visible = false

	# 4) Conectar señal del player
	if player and player.has_signal("collectibles_changed"):
		if not player.collectibles_changed.is_connected(_on_collectibles_changed):
			player.collectibles_changed.connect(_on_collectibles_changed)
	else:
		print("[HUD] No encontré Player con señal 'collectibles_changed' (grupo PlayerCoins).")
	
	# 5) Conectar con GameController para victoria y objetivo de tokens
	game_controller = get_tree().get_first_node_in_group("GameController")
	if not game_controller:
		# Buscar en toda la escena
		game_controller = _find_game_controller(get_tree().root)
	
	if game_controller:
		if game_controller.has_signal("victory_achieved"):
			game_controller.victory_achieved.connect(_on_victory_achieved)
		if game_controller.has_signal("tokens_goal_changed"):
			game_controller.tokens_goal_changed.connect(_on_tokens_goal_changed)
		# Obtener el objetivo actual directamente
		if "TOKENS_TO_WIN" in game_controller:
			tokens_needed = game_controller.TOKENS_TO_WIN
			print("[HUD] Objetivo de tokens establecido: ", tokens_needed)

	# 6) Valor inicial
	_refresh_now()

func _on_tokens_goal_changed(goal: int) -> void:
	tokens_needed = goal
	_refresh_now()

func _on_collectibles_changed(value: int) -> void:
	if label:
		label.text = "Recolecta %d Monos para ganar!\nTokens: %d/%d" % [tokens_needed, value, tokens_needed]

func _on_victory_achieved() -> void:
	# Ocultar el contador y mostrar victoria
	if label:
		label.visible = false
	if victory_label:
		victory_label.text = "¡Ganaste!"
		victory_label.visible = true

# Fallback: mantiene el texto correcto aunque la señal no llegue
func _process(_delta: float) -> void:
	_refresh_now()

func _refresh_now() -> void:
	if player and label and ("collectibles" in player):
		var tokens = int(player.collectibles)
		label.text = "Recolecta %d Monos para ganar!\nTokens: %d/%d" % [tokens_needed, tokens, tokens_needed]

# ---- helpers ----
func _find_first_label(n: Node) -> Label:
	for c in n.get_children():
		if c is Label:
			return c as Label
		var r := _find_first_label(c)
		if r != null:
			return r
	return null

func _find_game_controller(n: Node) -> Node:
	if n.name == "GameController" or n.get_script() != null:
		var script_path = str(n.get_script().resource_path) if n.get_script() else ""
		if "game_controller" in script_path:
			return n
	for c in n.get_children():
		var r = _find_game_controller(c)
		if r != null:
			return r
	return null
