extends CharacterBody2D

const ATTACK_RANGE = 50.0
const TRAIL_LENGTH = 5
const TRAIL_SPACING = 0.05

@export var speed = 150.0
@export var health = 50.0
@export var damage = 15.0
@export var attack_cooldown = 1.5

var current_health
var attack_timer = 0.0
var player_ref = null
var visual_node = null
var trail_positions = []
var trail_timer = 0.0
var current_angle = 0.0  # Track rotation angle

func _ready():
	current_health = health
	add_to_group("demons")
	
	if has_node("Hitbox"):
		$Hitbox.add_to_group("demons")
	
	player_ref = get_tree().get_first_node_in_group("player")
	create_visual()

func create_visual():
	# Demons have no visual sprite - just motion blur trail
	pass

func _physics_process(delta):
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
		if not player_ref:
			return
	
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Update rotation angle to face player
	current_angle = direction.angle()
	
	# Update motion blur trail
	update_trail(delta)
	
	# Force redraw every frame to update triangle rotation
	queue_redraw()
	
	var distance = global_position.distance_to(player_ref.global_position)
	if distance < ATTACK_RANGE:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_player()
			attack_timer = attack_cooldown
			if visual_node:
				flash_red()

func update_trail(delta):
	trail_timer += delta
	
	if trail_timer >= TRAIL_SPACING and velocity.length() > 50:
		trail_positions.append(global_position)
		trail_timer = 0.0
		
		if trail_positions.size() > TRAIL_LENGTH:
			trail_positions.pop_front()
	
	queue_redraw()

func _draw():
	# Draw main triangle at current position, using stored angle
	var size = 15.0
	
	# Triangle pointing in movement direction
	var point1 = Vector2(cos(current_angle), sin(current_angle)) * size
	var point2 = Vector2(cos(current_angle + 2.5), sin(current_angle + 2.5)) * (size * 0.7)
	var point3 = Vector2(cos(current_angle - 2.5), sin(current_angle - 2.5)) * (size * 0.7)
	
	draw_colored_polygon(PackedVector2Array([point1, point2, point3]), Color(0.8, 0.2, 0.2))
	
	# Draw fading trail
	if trail_positions.size() < 2:
		return
	
	for i in range(trail_positions.size() - 1):
		var alpha = float(i) / float(TRAIL_LENGTH)
		var trail_color = Color(0.8, 0.2, 0.2, alpha * 0.3)
		
		var local_pos = to_local(trail_positions[i])
		draw_circle(local_pos, 8 * (1 - alpha * 0.5), trail_color)

func attack_player():
	if is_instance_valid(player_ref) and player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)

func flash_red():
	# No visual sprite to flash
	pass

func take_damage(amount):
	current_health -= amount
	
	if current_health <= 0:
		die()

func die():
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_demon_died"):
		main.on_demon_died()
	
	create_death_effect()
	queue_free()

func create_death_effect():
	for i in range(8):
		var particle = Polygon2D.new()
		var angle = (i / 8.0) * TAU
		particle.polygon = PackedVector2Array([
			Vector2(-3, -3), Vector2(3, -3),
			Vector2(3, 3), Vector2(-3, 3)
		])
		particle.color = Color(1, 0.5, 0)
		particle.global_position = global_position
		get_parent().add_child(particle)
		
		var end_pos = global_position + Vector2(cos(angle), sin(angle)) * 40
		
		var tween = create_tween()
		tween.parallel().tween_property(particle, "global_position", end_pos, 0.3)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.tween_callback(particle.queue_free)
