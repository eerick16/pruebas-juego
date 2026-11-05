extends CharacterBody3D

# Velocidades de movimiento lateral
const SPEED_WALK = 4.0
const SPEED_CROUCH = 2.3

# --- FÍSICAS DE SALTO Y GRAVEDAD AJUSTADAS ---
const JUMP_VELOCITY = 6.0         # Impulso inicial más firme
const GRAVITY_MULTIPLIER = 2    # Gravedad más pesada (evita saltos flotantes de luna)
const AIR_CONTROL = 0.25          # Solo 25% de control manual en el aire (conserva inercia)

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * GRAVITY_MULTIPLIER

# Referencias a los nodos
@onready var anim_player = $Ch45_nonPBR/AnimationPlayer
@onready var model = $Ch45_nonPBR
@onready var raycast = $Ch45_nonPBR/Skeleton3D/BoneAttachment3D/RootScene/RayCast3D

# Estados del personaje
var is_crouched: bool = false
var ctrl_was_pressed: bool = false
var is_playing_transition: bool = false
var is_aiming: bool = false

# Control de cadencia de disparo al mantener J
var shoot_cooldown: float = 0.0
const SHOOT_RATE: float = 0.3

func _physics_process(delta):
	# 1. Aplicar Gravedad Aumentada cuando está en el aire
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Reducir cooldown de disparo
	if shoot_cooldown > 0:
		shoot_cooldown -= delta

	# 2. DETECCIÓN DE TECLAS
	var ctrl_currently_pressed = Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_SHIFT)
	is_aiming = Input.is_key_pressed(KEY_J)

	# 3. INTERRUPTOR DE AGACHADO (1 Solo clic)
	if is_on_floor() and ctrl_currently_pressed and not ctrl_was_pressed:
		is_crouched = !is_crouched
		is_playing_transition = true
		
		if is_crouched:
			if is_aiming and anim_player.has_animation("PistolStandToKneel/mixamo_com"):
				anim_player.play("PistolStandToKneel/mixamo_com", 0.15)
			elif anim_player.has_animation("StandToCrouch/mixamo_com"):
				anim_player.play("StandToCrouch/mixamo_com", 0.15)
		else:
			if is_aiming and anim_player.has_animation("PistolKneelToStand/mixamo_com"):
				anim_player.play("PistolKneelToStand/mixamo_com", 0.15)
			elif anim_player.has_animation("CrouchToStand/mixamo_com"):
				anim_player.play("CrouchToStand/mixamo_com", 0.15)
			else:
				anim_player.play("Idle/mixamo_com", 0.15)
				is_playing_transition = false

	ctrl_was_pressed = ctrl_currently_pressed

	# 4. SALTO
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouched and not is_aiming:
		velocity.y = JUMP_VELOCITY

	# 5. MOVIMIENTO HORIZONTAL Y CONTROL AÉREO
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if is_aiming:
		velocity.x = 0.0
	else:
		var current_speed = SPEED_CROUCH if is_crouched else SPEED_WALK

		if is_on_floor():
			# Control total en tierra
			if input_dir.x != 0:
				velocity.x = input_dir.x * current_speed
				is_playing_transition = false
				
				if model:
					if input_dir.x > 0:
						model.rotation.y = deg_to_rad(90)
					elif input_dir.x < 0:
						model.rotation.y = deg_to_rad(-90)
			else:
				velocity.x = move_toward(velocity.x, 0, current_speed)
		else:
			# CONTROL RESTREÑIDO EN EL AIRE (Limita cambios bruscos de dirección)
			if input_dir.x != 0:
				var target_vel = input_dir.x * current_speed
				velocity.x = move_toward(velocity.x, target_vel, current_speed * AIR_CONTROL)

	# --- BLOQUEO ESTRICTO EN 2.5D ---
	velocity.z = 0.0

	# 6. DISPARO
	if is_aiming and shoot_cooldown <= 0:
		_disparar_rayo()
		shoot_cooldown = SHOOT_RATE

	# 7. MÁQUINA DE ESTADOS DE ANIMACIÓN
	_update_animations(input_dir.x != 0)

	move_and_slide()

	global_position.z = 0.0

func _disparar_rayo():
	if raycast and raycast.is_colliding():
		var objetivo = raycast.get_collider()
		if objetivo and objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(1)

func _update_animations(is_moving: bool):
	# A) EN EL AIRE
	if not is_on_floor():
		is_playing_transition = false
		if anim_player.has_animation("FallingIdle/mixamo_com"):
			anim_player.play("FallingIdle/mixamo_com", 0.15)
		elif anim_player.has_animation("Falling Idle/mixamo_com"):
			anim_player.play("Falling Idle/mixamo_com", 0.15)
		else:
			anim_player.play("Idle/mixamo_com", 0.15)
		return

	# B) ESPERAR TRANSICIONES
	if is_playing_transition:
		if is_moving or not anim_player.is_playing():
			is_playing_transition = false
		else:
			return

	# C) APUNTANDO / DISPARANDO
	if is_aiming:
		if is_crouched:
			if anim_player.has_animation("PistolKneelingIdle/mixamo_com"):
				anim_player.play("PistolKneelingIdle/mixamo_com", 0.1)
		else:
			if anim_player.has_animation("PistolIdle/mixamo_com"):
				anim_player.play("PistolIdle/mixamo_com", 0.1)
		return

	# D) ESTADOS EN EL SUELO
	if is_crouched:
		if is_moving:
			anim_player.play("CrouchWalk/mixamo_com", 0.15)
		else:
			anim_player.play("CrouchIdle/mixamo_com", 0.15)
	else:
		if is_moving:
			anim_player.play("Walk/mixamo_com", 0.15)
		else:
			anim_player.play("Idle/mixamo_com", 0.15)
