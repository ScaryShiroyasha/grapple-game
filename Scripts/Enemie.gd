extends CharacterBody3D

enum States {Attack, idle, chase, dead}

var state = States.idle
@export var hp = 50
@export var speed = 5.0

func getHit(damage: float):
	hp = hp - damage
	if (hp <= 0):
		queue_free()




func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
