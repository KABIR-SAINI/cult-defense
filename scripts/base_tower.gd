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

func _ready():
	add_to_group("followers")
	create_collision_shape()
	create_range_indicator()
	create_visual()
	create_detection_range()

func create_collision_shape():
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(30, 30)
		collision.shape = shape
		add_child(collision)

func create_range_indicator():
	# Semi-transparent circle showing attack range
	if not has_node("RangeIndicator"):
		var range_circle = Polygon2D.new()
		range_circle.name = "RangeIndicator"
		
		# Create circle points
		var points = PackedVector2Array()
		var segments = 32
		for i in range(segments):
			var angle = (i / float(segments)) * TAU
			points.append(Vector2(cos(angle), sin(angle)) * detection_radius)
		
		range_circle.polygon = points
		range_circle.color = Color(tower_color.r, tower_color.g, tower_color.b, 0.1)
		range_circle.z_index = -1
		add_child(range_circle)
		range_indicator = range_circle

func create_visual():
	# Override this in child classes for different visuals
	if not has_node("Visual"):
		var polygon = Polygon2D.new()
		polygon.name = "Visual"
		polygon.polygon = PackedVector2Array([
			Vector2(-15, -15), Vector2(15, -15),
			Vector2(15, 15), Vector2(-15, 15)
		])
		polygon.color = tower_color
		
		# Add outline
		var line = Line2D.new()
		line.name = "Outline"
		line.add_point(Vector2(-15, -15))
		line.add_point(Vector2(15, -15))
		line.add_point(Vector2(15, 15))
		line.add_point(Vector2(-15, 15))
		line.add_point(Vector2(-15, -15))
		line.default_color = Color.BLACK
		line.width = 2
		polygon.add_child(line)
		
		add_child(polygon)
		visual_node = polygon

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
	
	if shoot_timer <= 0:
		find_and_shoot_demon()
		shoot_timer = shoot_cooldown
	
	# Pulse effect when shooting
	if visual_node and shoot_timer > shoot_cooldown - 0.1:
		var scale_factor = 1.0 + (0.1 - (shoot_cooldown - shoot_timer)) * 2.0
		visual_node.scale = Vector2(scale_factor, scale_factor)
	else:
		if visual_node:
			visual_node.scale = Vector2.ONE

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
	# Create a line that fades out
	var line = Line2D.new()
	line.add_point(Vector2.ZERO)
	line.add_point(to_local(target_pos))
	line.default_color = tower_color
	line.width = 3
	add_child(line)
	
	# Fade and remove
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)

func enable_sacrifice():
	can_be_sacrificed = true
	input_pickable = true
	
	# Highlight when sacrificeable
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
	# Death effect
	create_sacrifice_effect()
	
	var heal_amount = HEAL_BASE + (time_alive * HEAL_SCALING_PER_SECOND)
	var player = get_tree().get_first_node_in_group("player")
	
	if is_instance_valid(player) and player.has_method("sacrifice_heal"):
		player.sacrifice_heal(heal_amount)
	
	queue_free()

func create_sacrifice_effect():
	# Expanding circle effect
	var particles = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(8):
		var angle = (i / 8.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 20)
	particles.polygon = points
	particles.color = tower_color
	particles.global_position = global_position
	get_parent().add_child(particles)
	
	var tween = create_tween()
	tween.parallel().tween_property(particles, "scale", Vector2(3, 3), 0.5)
	tween.parallel().tween_property(particles, "modulate:a", 0.0, 0.5)
	tween.tween_callback(particles.queue_free)

func take_damage(amount):
	pass
