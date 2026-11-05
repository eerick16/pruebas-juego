extends CharacterBody3D

# Configuración de movimiento
const SPEED = 2.0
var health: int = 3
var moving_right: bool = true

# Control de estado de pausa en paredes
var is_waiting: bool = false
var wait_timer: float = 0.0
const WAIT_TIME: float = 3.0  # Permanecerá 3 segundos parado en la pared

@onready var anim_player = $Ch15_nonPBR/AnimationPlayer
@onready var model = $Ch15_nonPBR

func _ready():
	add_to_group("guard")
	global_position.z = 0.0

func _physics_process(delta):
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# SI ESTÁ EN PAUSA JUNTO A LA PARED (Estará en Rifle Idle 3 segundos)
	if is_waiting:
		velocity.x = 0.0
		wait_timer -= delta
		
		# Reproducir animación de respiración / Idle con rifle
		if anim_player:
			if anim_player.has_animation("Rifle Idle/mixamo_com"):
				anim_player.play("Rifle Idle/mixamo_com", 0.15)
			elif anim_player.has_animation("RifleIdle/mixamo_com"):
				anim_player.play("RifleIdle/mixamo_com", 0.15)

		# Cuando terminan los 3 segundos, reanuda la caminata hacia el otro lado
		if wait_timer <= 0.0:
			is_waiting = false
			moving_right = !moving_right
			# Dar micro-paso en X para despegarse del muro
			global_position.x += 0.15 if moving_right else -0.15

	# SI ESTÁ PATRULLANDO (Caminando)
	else:
		if moving_right:
			velocity.x = SPEED
			if model: model.rotation.y = deg_to_rad(90)
		else:
			velocity.x = -SPEED
			if model: model.rotation.y = deg_to_rad(-90)

		# Reproducir animación de caminata con rifle
		if anim_player:
			if anim_player.has_animation("Rifle Walk/mixamo_com"):
				anim_player.play("Rifle Walk/mixamo_com", 0.15)
			elif anim_player.has_animation("RifleWalk/mixamo_com"):
				anim_player.play("RifleWalk/mixamo_com", 0.15)

		# REGLA: Si toca una pared o al jugador, inicia la pausa de 3 segundos
		if is_on_wall():
			is_waiting = true
			wait_timer = WAIT_TIME

	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0

# Función invocada cuando el RayCast3D del jugador impacta
func recibir_dano(cantidad: int):
	health -= cantidad
	print("¡GUARDIA RECIBIÓ IMPACTO! Vida restante: ", health)
	
	if health <= 0:
		morir()

func morir():
	print("¡Guardia eliminado!")
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true
	queue_free()
