extends Area2D

const DETECTION_RADIUS = 200.0
const SACRIFICE_CLICK_RANGE = 30.0
const DAMAGE_SCALING_PER_SECOND = 2.0
const HEAL_BASE = 20.0
const HEAL_SCALING_PER_SECOND = 5.0

@export var shoot_cooldown = 0.5
@export var damage = 30.0
@export var max_health = 100.0

var shoot_timer = 0.0
var time_alive = 0.0
var can_be_sacrificed = false
var current_health = max_health

@onready var detection_range = $DetectionRange

func _ready():
	add_to_group("followers")
	
	# Ensure collision shape exists for click detection
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(30, 30)
		collision.shape = shape
		add_child(collision)

func _process(delta):
	time_alive += delta
	shoot_timer -= delta
	
	if shoot_timer <= 0:
		find_and_shoot_demon()
		shoot_timer = shoot_cooldown

func find_and_shoot_demon():
	# Get all demons and check distance manually (more reliable than Area2D detection)
	var all_demons = get_tree().get_nodes_in_group("demons")
	var nearest_demon = null
	var nearest_distance = DETECTION_RADIUS
	
	for demon in all_demons:
		if demon is CharacterBody2D and is_instance_valid(demon):
			var distance = global_position.distance_to(demon.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_demon = demon
	
	# Shoot the nearest demon
	if nearest_demon and nearest_demon.has_method("take_damage"):
		var actual_damage = damage + (time_alive * DAMAGE_SCALING_PER_SECOND)
		nearest_demon.take_damage(actual_damage)

func enable_sacrifice():
	can_be_sacrificed = true
	input_pickable = true

func _input(event):
	if not can_be_sacrificed:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var distance = global_position.distance_to(mouse_pos)
		
		# Only check if click is near this follower
		if distance < SACRIFICE_CLICK_RANGE:
			# Find closest follower to click to prevent multiple sacrifices
			var all_followers = get_tree().get_nodes_in_group("followers")
			var closest_follower = null
			var closest_distance = INF
			
			for follower in all_followers:
				if is_instance_valid(follower) and follower.has_method("sacrifice"):
					var follower_distance = follower.global_position.distance_to(mouse_pos)
					if follower_distance < closest_distance:
						closest_distance = follower_distance
						closest_follower = follower
			
			# Only sacrifice if this follower is the closest one
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
	# Followers are invincible - no damage taken
	# If you want them to take damage later, implement health system here
	pass
