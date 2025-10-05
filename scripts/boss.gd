extends CharacterBody2D

const ATTACK_RANGE = 80.0
const TRAIL_LENGTH = 8
const TRAIL_SPACING = 0.04
const GLOW_RADIUS = 150.0

@export var speed = 100.0
@export var health = 500.0
@export var damage = 30.0
@export var attack_cooldown = 2.0

var current_health
var attack_timer = 0.0
var player_ref = null
var trail_positions = []
var trail_timer = 0.0
var current_angle = 0.0
var range_indicator = null
var pulse_timer = 0.0

func _ready():
	current_health = health
	add_to_group("demons")
	add_to_group("boss")
	
	player_ref = get_tree().get_first_node_in_group("player")
	create_range_indicator()

func create_range_indicator():
	var range_circle = Line2D.new()
	range_circle.name = "RangeIndicator"
	range_circle.width = 4
	range_circle.default_color = Color(1.0, 0.2, 0.2, 0.5)
	
	var segments = 16
	for i in range(segments + 1):
		var angle = (i / float(segments)) * TAU
		var point = Vector2(cos(angle), sin(angle)) * GLOW_RADIUS
		range_circle.add_point(point)
	
	range_circle.z_index = -1
	add_child(range_circle)
	range_indicator = range_circle

func _physics_process(delta):
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
		if not player_ref:
			return
	
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	current_angle = direction.angle()
	update_trail(delta)
	pulse_timer += delta
	queue_redraw()
	
	var distance = global_position.distance_to(player_ref.global_position)
	if distance < ATTACK_RANGE:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_player()
			attack_timer = attack_cooldown

func update_trail(delta):
	trail_timer += delta
	
	if trail_timer >= TRAIL_SPACING and velocity.length() > 20:
		trail_positions.append(global_position)
		trail_timer = 0.0
		
		if trail_positions.size() > TRAIL_LENGTH:
			trail_positions.pop_front()

func _draw():
	# Boss is much larger - draw pentagon shape
	var size = 40.0
	var pulse = 1.0 + sin(pulse_timer * 3.0) * 0.15
	size *= pulse
	
	var points = []
	for i in range(5):
		var angle = current_angle + (i * TAU / 5.0) - PI / 2
		points.append(Vector2(cos(angle), sin(angle)) * size)
	
	draw_colored_polygon(PackedVector2Array(points), Color(1.0, 0.1, 0.1))
	
	# Draw glowing outline
	for i in range(5):
		var p1 = points[i]
		var p2 = points[(i + 1) % 5]
		draw_line(p1, p2, Color(1.5, 0.3, 0.3), 3.0)
	
	# Draw trail
	if trail_positions.size() < 2:
		return
	
	for i in range(trail_positions.size() - 1):
		var alpha = float(i) / float(TRAIL_LENGTH)
		var trail_color = Color(1.0, 0.2, 0.2, alpha * 0.4)
		var local_pos = to_local(trail_positions[i])
		draw_circle(local_pos, 20 * (1 - alpha * 0.3), trail_color)

func attack_player():
	if is_instance_valid(player_ref) and player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)

func take_damage(amount):
	current_health -= amount
	
	# Flash effect
	if range_indicator:
		var tween = create_tween()
		tween.tween_property(range_indicator, "default_color", Color(2, 2, 2, 0.8), 0.1)
		tween.tween_property(range_indicator, "default_color", Color(1.0, 0.2, 0.2, 0.5), 0.1)
	
	if current_health <= 0:
		die()

func die():
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_boss_died"):
		main.on_boss_died()
	
	create_death_effect()
	queue_free()

func create_death_effect():
	# Larger explosion for boss
	for i in range(24):
		var particle = Polygon2D.new()
		var angle = (i / 24.0) * TAU
		particle.polygon = PackedVector2Array([
			Vector2(-6, -6), Vector2(6, -6),
			Vector2(6, 6), Vector2(-6, 6)
		])
		particle.color = Color(1, 0.3, 0)
		particle.global_position = global_position
		get_parent().add_child(particle)
		
		var end_pos = global_position + Vector2(cos(angle), sin(angle)) * 100
		
		var tween = create_tween()
		tween.parallel().tween_property(particle, "global_position", end_pos, 0.6)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.tween_callback(particle.queue_free)
