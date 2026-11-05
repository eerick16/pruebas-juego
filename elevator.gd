extends Area3D

# Esta línea es la que hace la magia en el Inspector:
@export var destination_elevator: Area3D

@onready var travel_timer = $Timer

# Estado global de viaje
static var is_elevator_busy: bool = false
var body_inside: Node3D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if travel_timer:
		travel_timer.timeout.connect(_on_travel_timeout)

func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("guard"):
		body_inside = body

func _on_body_exited(body):
	if body == body_inside:
		body_inside = null

func _unhandled_input(event):
	# Si el jugador presiona W o Flecha Arriba estando dentro
	if body_inside and body_inside.is_in_group("player") and not is_elevator_busy:
		if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			start_elevator_travel(body_inside)

func start_elevator_travel(passenger: Node3D):
	if not destination_elevator:
		print("¡OJO!: Asigna el destination_elevator en el Inspector.")
		return

	is_elevator_busy = true
	print("Viajando en elevador... (2 segundos)")
	
	if "velocity" in passenger:
		passenger.velocity = Vector3.ZERO
		
	travel_timer.start()

func _on_travel_timeout():
	if body_inside and destination_elevator:
		# Teletransporte al destino
		body_inside.global_position = destination_elevator.global_position
		body_inside.global_position.z = 0.0  # Mantener carril 2.5D
		print("¡Llegada al destino exitosa!")

	is_elevator_busy = false
