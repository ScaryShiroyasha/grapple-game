extends AnimatableBody3D

@export var offset: Vector3 = Vector3(10, 0, 6)  # direccion y distancia total
@export var period: float = 6.0                  # segundos para ir y volver

var p0: Vector3

func _ready() -> void:
	p0 = global_position
	var tw := create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_loops()
	tw.tween_property(self, "global_position", p0 + offset, period * 0.5)
	tw.tween_property(self, "global_position", p0,          period * 0.5)
