extends Area2D
class_name BaseTower

const SACRIFICE_CLICK_RANGE = 30.0
const HEAL_BASE = 20.0
const HEAL_SCALING_PER_SECOND = 5.0

@export var shoot_cooldown = 0.5
@export var damage = 30.0
@export var detection_radius = 200.0
@export var tower_color = Color.WHITE
@export var tower_name = "Basic Tower"

var shoot_timer = 0.0
var time_alive = 0.0
var can_be_sacrificed = false
var visual_node = null
var range_indicator = null
var glow_particles = []

func _ready():
	add_to_group("followers")
	create_collision_shape()
	create_range_indicator()
	create_visual()
	create_detection_range()
	create_ambient_particles()

func create_collision_shape():
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(30, 30)
		collision.shape = shape
		add_child(collision)

func create_range_indicator():
	if not has_node("RangeIndicator"):
		var range_circle = Line2D.new()
		range_circle.name = "RangeIndicator"
		range_circle.width = 2
		range_circle.default_color = Color(tower_color.r, tower_color.g, tower_color.b, 0.3)
		
		# Create circle points
		var segments = 32
		for i in range(segments + 1):
			var angle = (i / float(segments)) * TAU
			var point = Vector2(cos(angle), sin(angle)) * detection_radius
			range_circle.add_point(point)
		
		range_circle.z_index = -1
		add_child(range_circle)
		range_indicator = range_circle

func create_visual():
	if not has_node("Visual"):
		var polygon = Polygon2D.new()
		polygon.name = "Visual"
		polygon.polygon = PackedVector2Array([
			Vector2(-15, -15), Vector2(15, -15),
			Vector2(15, 15), Vector2(-15, 15)
		])
		polygon.color = tower_color
		

		var outline = Line2D.new()
		outline.name = "Outline"
		outline.add_point(Vector2(-15, -15))
		outline.add_point(Vector2(15, -15))
		outline.add_point(Vector2(15, 15))
		outline.add_point(Vector2(-15, 15))
		outline.add_point(Vector2(-15, -15))
		outline.default_color = Color(tower_color.r * 1.5, tower_color.g * 1.5, tower_color.b * 1.5)
		outline.width = 3
		polygon.add_child(outline)
		
		add_child(polygon)
		visual_node = polygon

func create_ambient_particles():
	
	for i in range(3):
		var particle = Polygon2D.new()
		particle.polygon = PackedVector2Array([
			Vector2(-2, -2), Vector2(2, -2),
			Vector2(2, 2), Vector2(-2, 2)
		])
		particle.color = tower_color
		particle.modulate.a = 0.6
		add_child(particle)
		glow_particles.append(particle)

func create_detection_range():
	if not has_node("DetectionRange"):
		var detection = Area2D.new()
		detection.name = "DetectionRange"
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = detection_radius
		collision.shape = shape
		detection.add_child(collision)
		add_child(detection)

func _process(delta):
	time_alive += delta
	shoot_timer -= delta
	

	for i in range(glow_particles.size()):
		var particle = glow_particles[i]
		var orbit_angle = time_alive * 2.0 + (i * TAU / 3.0)
		var orbit_radius = 25.0 + sin(time_alive * 3.0 + i) * 5.0
		particle.position = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		particle.modulate.a = 0.4 + sin(time_alive * 4.0 + i) * 0.3
	
	if shoot_timer <= 0:
		find_and_shoot_demon()
		shoot_timer = shoot_cooldown
	

	if visual_node and shoot_timer > shoot_cooldown - 0.15:
		var t = (shoot_cooldown - shoot_timer) / 0.15
		var scale_factor = 1.0 + sin(t * PI) * 0.2
		visual_node.scale = Vector2(scale_factor, scale_factor)
		visual_node.modulate = Color(2, 2, 2)
	else:
		if visual_node:
			visual_node.scale = Vector2.ONE
			visual_node.modulate = Color.WHITE

func find_and_shoot_demon():
	var all_demons = get_tree().get_nodes_in_group("demons")
	var nearest_demon = null
	var nearest_distance = detection_radius
	
	for demon in all_demons:
		if demon is CharacterBody2D and is_instance_valid(demon):
			var distance = global_position.distance_to(demon.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_demon = demon
	
	if nearest_demon and nearest_demon.has_method("take_damage"):
		shoot_at_demon(nearest_demon)
		create_shoot_effect(nearest_demon.global_position)

func shoot_at_demon(demon):
	var actual_damage = damage + (time_alive * 2.0)
	demon.take_damage(actual_damage)

func create_shoot_effect(target_pos: Vector2):
	
	var line = Line2D.new()
	line.add_point(Vector2.ZERO)
	line.add_point(to_local(target_pos))
	line.default_color = tower_color
	line.width = 4
	line.z_index = 10
	add_child(line)
	
	
	var glow_line = Line2D.new()
	glow_line.add_point(Vector2.ZERO)
	glow_line.add_point(to_local(target_pos))
	glow_line.default_color = Color(tower_color.r * 2, tower_color.g * 2, tower_color.b * 2, 0.5)
	glow_line.width = 12
	glow_line.z_index = 9
	add_child(glow_line)
	
	
	var tween = create_tween()
	tween.parallel().tween_property(line, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(glow_line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): 
		line.queue_free()
		glow_line.queue_free()
	)

func enable_sacrifice():
	can_be_sacrificed = true
	input_pickable = true
	
	if visual_node:
		visual_node.modulate = Color(1.5, 1.5, 1.5)

func _input(event):
	if not can_be_sacrificed:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var distance = global_position.distance_to(mouse_pos)
		
		if distance < SACRIFICE_CLICK_RANGE:
			var all_followers = get_tree().get_nodes_in_group("followers")
			var closest_follower = null
			var closest_distance = INF
			
			for follower in all_followers:
				if is_instance_valid(follower):
					var follower_distance = follower.global_position.distance_to(mouse_pos)
					if follower_distance < closest_distance:
						closest_distance = follower_distance
						closest_follower = follower
			
			if closest_follower == self:
				sacrifice()
				get_viewport().set_input_as_handled()

func sacrifice():
	create_sacrifice_effect()
	
	var heal_amount = HEAL_BASE + (time_alive * HEAL_SCALING_PER_SECOND)
	var player = get_tree().get_first_node_in_group("player")
	
	if is_instance_valid(player) and player.has_method("sacrifice_heal"):
		player.sacrifice_heal(heal_amount)
	
	queue_free()

func create_sacrifice_effect():
	
	for ring in range(3):
		var circle = Line2D.new()
		circle.width = 3
		circle.default_color = tower_color
		
		var segments = 24
		for i in range(segments + 1):
			var angle = (i / float(segments)) * TAU
			circle.add_point(Vector2(cos(angle), sin(angle)) * 20)
		
		circle.global_position = global_position
		get_parent().add_child(circle)
		
		var tween = create_tween()
		var delay = ring * 0.1
		tween.tween_interval(delay)
		tween.parallel().tween_property(circle, "scale", Vector2(4, 4), 0.5)
		tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(circle.queue_free)
	
	
	for i in range(12):
		var particle = Polygon2D.new()
		var angle = (i / 12.0) * TAU
		particle.polygon = PackedVector2Array([
			Vector2(-3, -3), Vector2(3, -3),
			Vector2(3, 3), Vector2(-3, 3)
		])
		particle.color = tower_color
		particle.global_position = global_position
		get_parent().add_child(particle)
		
		var end_pos = global_position + Vector2(cos(angle), sin(angle)) * 60
		
		var tween = create_tween()
		tween.parallel().tween_property(particle, "global_position", end_pos, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_callback(particle.queue_free)

func take_damage(amount):
	pass
