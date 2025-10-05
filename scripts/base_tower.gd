extends Area2D
class_name BaseTower

const SACRIFICE_CLICK_RANGE = 30.0
const HEAL_BASE = 20.0
const HEAL_SCALING_PER_SECOND = 5.0

# Tower stats - override these in child classes
@export var shoot_cooldown = 0.5
@export var damage = 30.0
@export var detection_radius = 200.0
@export var tower_color = Color.WHITE
@export var tower_name = "Basic Tower"

var shoot_timer = 0.0
var time_alive = 0.0
var can_be_sacrificed = false

func _ready():
	add_to_group("followers")
	create_collision_shape()
	create_visual()
	create_detection_range()

func create_collision_shape():
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(30, 30)
		collision.shape = shape
		add_child(collision)

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
		add_child(polygon)

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

func shoot_at_demon(demon):
	# Override this for custom shooting behavior
	var actual_damage = damage + (time_alive * 2.0)
	demon.take_damage(actual_damage)

func enable_sacrifice():
	can_be_sacrificed = true
	input_pickable = true

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
	var heal_amount = HEAL_BASE + (time_alive * HEAL_SCALING_PER_SECOND)
	var player = get_tree().get_first_node_in_group("player")
	
	if is_instance_valid(player) and player.has_method("sacrifice_heal"):
		player.sacrifice_heal(heal_amount)
	
	queue_free()

func take_damage(amount):
	pass
