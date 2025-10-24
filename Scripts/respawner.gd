extends Node3D

@export var enemigo : PackedScene

@onready var timer = $Timer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if (get_child_count() <= 1) and timer.is_stopped():
		timer.start()
		


func _on_timer_timeout() -> void:
	var instancia = enemigo.instantiate()
	var spawn_range = Vector3(10.0, 0.0, 10.0) 
	
	var random_offset = Vector3(
		randf_range(-spawn_range.x, spawn_range.x),
		1.0,
		randf_range(-spawn_range.z, spawn_range.z)
	)
	
	add_child(instancia)
	instancia.global_position = global_position + random_offset
	
