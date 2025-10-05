extends Area2D

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
	var all_demons = get_tree().get_nodes_in_group("demons")
	var nearest_demon = null
	var nearest_distance = 200.0
	
	for demon in all_demons:
		if demon is CharacterBody2D:
			var distance = global_position.distance_to(demon.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_demon = demon
	
	if nearest_demon and nearest_demon.has_method("take_damage"):
		var actual_damage = damage + (time_alive * 2)
		nearest_demon.take_damage(actual_damage)

func enable_sacrifice():
	can_be_sacrificed = true
	input_pickable = true
	print("Sacrifice enabled on follower")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if can_be_sacrificed:
			var mouse_pos = get_global_mouse_position()
			var distance = global_position.distance_to(mouse_pos)
			if distance < 30:
				var all_followers = get_tree().get_nodes_in_group("followers")
				var closest_follower = null
				var closest_distance = 999999
				
				for follower in all_followers:
					var follower_distance = follower.global_position.distance_to(mouse_pos)
					if follower_distance < closest_distance:
						closest_distance = follower_distance
						closest_follower = follower
				
				if closest_follower == self:
					sacrifice()
					get_viewport().set_input_as_handled()

func sacrifice():
	var heal_amount = 20.0 + (time_alive * 5.0)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("sacrifice_heal"):
		player.sacrifice_heal(heal_amount)
		print("Sacrificed! Healed: ", heal_amount)
	queue_free()

func take_damage(amount):
	# Followers are invincible - they don't take damage
	pass
