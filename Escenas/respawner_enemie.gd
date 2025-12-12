extends Node3D

@export var enemigo : PackedScene

@onready var timer = $Timer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var live_enemy_count = 0
	
	# Revisamos todos los nodos hijos del spawner
	for child in get_children():
		# 1. Comprobamos si este hijo es un enemigo
		if child.has_method("enemy"):
			# 2. Comprobamos si NO está muerto
			#    (El 'get("is_dead")' es seguro por si acaso)
			if not child.get("is_dead"):
				live_enemy_count += 1
				
	# TU LÓGICA ORIGINAL, pero usando la nueva variable
	if (live_enemy_count == 0) and timer.is_stopped():
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
