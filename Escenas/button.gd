extends Button

const LEVEL: PackedScene = preload("res://Escenas/Level.tscn")

func _pressed() -> void:
	get_tree().change_scene_to_packed(LEVEL)
