extends CharacterBody2D
const DEATH_HEALTH = 0.0
const TRAIL_LENGTH = 8
const TRAIL_SPACING = 0.06

@export var speed = 300.0
@export var max_health = 100.0
@export var health_drain_rate = 1.0

var current_health = max_health
var main_ref = null
var trail_positions = []
var trail_timer = 0.0
var pulse_timer = 0.0

func _ready():
	current_health = max_health
	add_to_group("player")
	main_ref = get_tree().get_first_node_in_group("main")

func _physics_process(delta):
	handle_movement(delta)
	handle_health_drain(delta)
	update_trail(delta)
	pulse_timer += delta
	queue_redraw()

func handle_movement(delta):
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()

func update_trail(delta):
	trail_timer += delta
	
	if trail_timer >= TRAIL_SPACING and velocity.length() > 100:
		trail_positions.append(global_position)
		trail_timer = 0.0
		
		if trail_positions.size() > TRAIL_LENGTH:
			trail_positions.pop_front()

func _draw():
	# Pulsating circle effect
	var pulse_scale = 1.0 + sin(pulse_timer * 3.0) * 0.3
	var pulse_radius = 20.0 * pulse_scale
	var pulse_alpha = 0.4 + sin(pulse_timer * 3.0) * 0.2
	
	draw_circle(Vector2.ZERO, pulse_radius, Color(0.3, 0.6, 1.0, pulse_alpha))
	draw_arc(Vector2.ZERO, pulse_radius + 3, 0, TAU, 32, Color(0.5, 0.8, 1.0, pulse_alpha * 1.5), 2.0)
	
	if trail_positions.size() < 2:
		return
	
	for i in range(trail_positions.size() - 1):
		var alpha = float(i) / float(TRAIL_LENGTH)
		var trail_color = Color(0.3, 0.6, 1.0, alpha * 0.5)
		
		var local_pos = to_local(trail_positions[i])
		draw_circle(local_pos, 25 * (1 - alpha * 0.3), trail_color)  # Was 12, now 25

func handle_health_drain(delta):
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
