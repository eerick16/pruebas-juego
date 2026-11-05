extends Camera3D

# Referencia al jugador (lo puedes arrastrar en el Inspector)
@export var target: Node3D

# Offset o distancia fija de la cámara respecto al jugador (X, Y, Z)
@export var offset: Vector3 = Vector3(0.0, 1.5, 7.5)
# Suavizado de seguimiento (Lerp)
@export var smooth_speed: float = 5.0

func _physics_process(delta):
	if target:
		# Posición deseada manteniendo el offset Z constante
		var target_position = target.global_position + offset
		
		# Movimiento suave hacia la nueva posición
		global_position = global_position.lerp(target_position, smooth_speed * delta)
