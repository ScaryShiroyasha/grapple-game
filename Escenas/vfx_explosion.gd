extends Node3D

signal explosion_finished

# Asegúrate de que el nombre $AnimationPlayer coincida con el de tu escena
@onready var anim_player = $AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	

func StartExplosion():
	anim_player.play("explosion_animation")
	print("inicio explosion")
	$AudioStreamPlayer3D.play()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	explosion_finished.emit()
