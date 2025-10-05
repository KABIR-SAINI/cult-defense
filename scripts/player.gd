extends CharacterBody2D

const DEATH_HEALTH = 0.0
const TRAIL_LENGTH = 8
const TRAIL_SPACING = 0.03

@export var speed = 300.0
@export var max_health = 100.0
@export var health_drain_rate = 1.0

var current_health = max_health
var main_ref = null
var visual_node = null
var trail_positions = []
var trail_timer = 0.0

func _ready():
	current_health = max_health
	add_to_group("player")
	main_ref = get_tree().get_first_node_in_group("main")
	create_visual()

func create_visual():
	if not has_node("Visual"):
		var body = Polygon2D.new()
		body.name = "Visual"
		body.polygon = PackedVector2Array([
			Vector2(0, -25),
			Vector2(12, -15),
			Vector2(10, 5),
			Vector2(15, 20),
			Vector2(5, 20),
			Vector2(0, 10),
			Vector2(-5, 20),
			Vector2(-15, 20),
			Vector2(-10, 5),
			Vector2(-12, -15)
		])
		body.color = Color(0.3, 0.6, 1.0)
		
		var face = Polygon2D.new()
		face.polygon = PackedVector2Array([
			Vector2(-3, -18), Vector2(-1, -18),
			Vector2(-1, -16), Vector2(-3, -16)
		])
		face.color = Color.WHITE
		body.add_child(face)
		
		var face2 = Polygon2D.new()
		face2.polygon = PackedVector2Array([
			Vector2(1, -18), Vector2(3, -18),
			Vector2(3, -16), Vector2(1, -16)
		])
		face2.color = Color.WHITE
		body.add_child(face2)
		
		add_child(body)
		visual_node = body

func _physics_process(delta):
	handle_movement(delta)
	handle_health_drain(delta)
	update_trail(delta)

func handle_movement(delta):
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	
	if direction.length() > 0:
		direction = direction.normalized()
		if visual_node:
			visual_node.rotation = direction.angle() + PI/2
	
	velocity = direction * speed
	move_and_slide()

func update_trail(delta):
	trail_timer += delta
	
	if trail_timer >= TRAIL_SPACING and velocity.length() > 100:
		trail_positions.append(global_position)
		trail_timer = 0.0
		
		if trail_positions.size() > TRAIL_LENGTH:
			trail_positions.pop_front()
	
	queue_redraw()

func _draw():
	if trail_positions.size() < 2:
		return
	
	for i in range(trail_positions.size() - 1):
		var alpha = float(i) / float(TRAIL_LENGTH)
		var trail_color = Color(0.3, 0.6, 1.0, alpha * 0.4)
		
		var local_pos = to_local(trail_positions[i])
		draw_circle(local_pos, 12 * (1 - alpha * 0.4), trail_color)

func handle_health_drain(delta):
	if not is_instance_valid(main_ref):
		main_ref = get_tree().get_first_node_in_group("main")
		return
	
	if main_ref.wave_active:
		current_health -= health_drain_rate * delta
		
		if current_health < 30 and visual_node:
			var flash_speed = 2.0
			visual_node.modulate = Color(1.0, 0.5 + sin(Time.get_ticks_msec() * 0.01 * flash_speed) * 0.5, 0.5)
		
		if current_health <= DEATH_HEALTH:
			die()

func take_damage(amount):
	current_health -= amount
	
	if visual_node:
		visual_node.modulate = Color(2, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(visual_node):
			visual_node.modulate = Color.WHITE
	
	if current_health <= DEATH_HEALTH:
		die()

func sacrifice_heal(amount):
	current_health = min(current_health + amount, max_health)
	
	if visual_node:
		visual_node.modulate = Color(0.5, 2, 0.5)
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(visual_node):
			visual_node.modulate = Color.WHITE

func die():
	get_tree().reload_current_scene()
