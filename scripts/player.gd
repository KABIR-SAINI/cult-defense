extends CharacterBody2D

const DEATH_HEALTH = 0.0

@export var speed = 300.0
@export var max_health = 100.0
@export var health_drain_rate = 1.0

var current_health = max_health
var main_ref = null

func _ready():
	current_health = max_health
	add_to_group("player")
	
	# Cache main reference
	main_ref = get_tree().get_first_node_in_group("main")

func _physics_process(delta):
	handle_movement(delta)
	handle_health_drain(delta)

func handle_movement(delta):
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()

func handle_health_drain(delta):
	# Only drain health during active waves
	if not is_instance_valid(main_ref):
		main_ref = get_tree().get_first_node_in_group("main")
		return
	
	if main_ref.wave_active:
		current_health -= health_drain_rate * delta
		
		if current_health <= DEATH_HEALTH:
			die()

func take_damage(amount):
	current_health -= amount
	
	if current_health <= DEATH_HEALTH:
		die()

func sacrifice_heal(amount):
	current_health = min(current_health + amount, max_health)

func die():
	get_tree().reload_current_scene()
