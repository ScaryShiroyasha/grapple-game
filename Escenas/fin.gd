extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Desbloquear el mouse en la pantalla de victoria
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Esperar 5 segundos y luego volver al menú
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://Escenas/Menu.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
