extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Buscar el botón y conectarlo
	var button = find_button(self)
	if button:
		button.pressed.connect(_on_button_pressed)
	else:
		print("[Volver] Advertencia: No se encontró un Button hijo")


func find_button(node: Node) -> Button:
	# Si este nodo es un Button, lo devolvemos
	if node is Button:
		return node
	# Si no, buscamos en sus hijos
	for child in node.get_children():
		var result = find_button(child)
		if result:
			return result
	return null


func _on_button_pressed() -> void:
	# Desbloquear el mouse y volver al menú
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Escenas/Menu.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
