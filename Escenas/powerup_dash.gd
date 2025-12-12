# PowerupDash.gd (Godot 4)
extends Area3D

@export var grant_sound: AudioStreamPlayer3D
@export var consume_on_pick: bool = true

var taken := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if taken:
		return
	if not is_instance_valid(body):
		return
	
	# Prioriza método; si no existe, intenta propiedad.
	if body.has_method("set_dash_enabled"):
		body.set_dash_enabled(true)
	elif "PowerUp_Dash" in body:
		body.PowerUp_Dash = true
	else:
		return  # no es el Player o no tiene el flag

	taken = true
	if grant_sound:
		grant_sound.play()
	if consume_on_pick:
		queue_free()
