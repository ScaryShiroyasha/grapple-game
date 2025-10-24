extends Button

const LEVEL := preload("res://Escenas/Level.tscn")

func _pressed() -> void:
	get_tree().change_scene_to_packed(LEVEL)


func start_on_pressed() -> void:
	pass # Replace with function body.
