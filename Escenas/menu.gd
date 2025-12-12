extends Control

const LEVEL: PackedScene = preload("res://Escenas/Level.tscn")
# Si tu escena Level.tscn está en otra carpeta, cambia la ruta de arriba.

@onready var btn_1: Button = $VBoxContainer/Button
@onready var btn_2: Button = $VBoxContainer/Button2
@onready var btn_3: Button = $VBoxContainer/Button3

func _ready() -> void:
	# Desbloquear el mouse al entrar al menú
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Button 1 -> cambiar a Level
	btn_1.pressed.connect(_on_button_1_pressed)
	# Button 2 -> ir a Créditos
	btn_2.pressed.connect(_on_button_2_pressed)
	# Button 3 -> salir del juego
	btn_3.pressed.connect(_on_button_3_pressed)


func _on_button_1_pressed() -> void:
	get_tree().change_scene_to_packed(LEVEL)


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Creditos.tscn")


func _on_button_3_pressed() -> void:
	get_tree().quit()
