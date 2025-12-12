# PowerupDoubleJump.gd (Godot 4)
extends Area3D

@export var grant_sound: AudioStreamPlayer3D

var taken := false

func _ready() -> void:
	# Conecta la señal para detectar cuerpos que entran
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if taken:
		return
	# Solo aplica al Player que tenga el método
	if body.has_method("set_doble_salto_enabled"):
		taken = true
		body.set_doble_salto_enabled(true) # << habilita el doble salto
		if grant_sound:
			grant_sound.play()
		queue_free() # destruye el pickup
