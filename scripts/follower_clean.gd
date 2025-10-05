extends Area2D

@export var shoot_cooldown = 0.5
@export var damage = 30.0

var shoot_timer = 0.0
var time_alive = 0.0
var can_be_sacrificed = false

@onready var detection_range = $DetectionRange

func _ready():
	add_to_group("followers")
	input_pickable = false

func _process(delta):
	time_alive += delta
	shoot_timer -= delta
	
	if shoot_timer <= 0:
		find_and_shoot_demon()
		shoot_timer = shoot_cooldown

func find_and_shoot_demon():
	var areas = detection_range.get_overlapping_areas()
	var nearest_demon = null
	var nearest_distance = 999999
	
	for area in areas:
		if area.is_in_group("demons"):
			var demon = area.get_parent()
			if demon and demon.is_in_group("demons"):
				var distance = global_position.distance_to(demon.global_position)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_demon = demon
	
	if nearest_demon and nearest_demon.has_method("take_damage"):
		var actual_damage = damage + (time_alive * 2)
		nearest_demon.take_damage(actual_damage)
		print("Follower shot demon for ", actual_damage, " damage!")

func enable_sacrifice():
	can_be_sacrificed = true
	input_pickable = true

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if can_be_sacrificed:
			sacrifice()

func sacrifice():
	var heal_amount = 20.0 + (time_alive * 5.0)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("sacrifice_heal"):
		player.sacrifice_heal(heal_amount)
		print("Sacrificed follower! Healed for: ", heal_amount)
	queue_free()
