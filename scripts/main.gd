extends Node2D

var follower_scene = load("res://scenes/follower.tscn")
var demon_scene = load("res://scenes/demon.tscn")

var player
var start_button
var wave_label

var current_wave = 1
var followers_to_place = 3
var followers_placed = 0
var placement_phase = true
var wave_active = false

var demons_alive = 0
var demons_to_spawn = 5
var demons_spawned = 0

var spawn_timer

func _ready():
	randomize()
	add_to_group("main")
	player = $Player
	
	if has_node("UI/StartWaveButton"):
		start_button = $UI/StartWaveButton
		start_button.pressed.connect(start_wave)
		start_button.visible = false
	
	if has_node("UI/WaveLabel"):
		wave_label = $UI/WaveLabel
	
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(spawn_demon)
	add_child(spawn_timer)
	
	update_ui()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if placement_phase and followers_placed < followers_to_place:
			place_follower(get_global_mouse_position())

func place_follower(pos):
	var follower = follower_scene.instantiate()
	follower.global_position = pos
	add_child(follower)
	followers_placed += 1
	
	if followers_placed >= followers_to_place and start_button:
		start_button.visible = true

func start_wave():
	placement_phase = false
	wave_active = true
	
	if start_button:
		start_button.visible = false
	
	enable_follower_sacrifice()
	
	demons_to_spawn = 5 + (current_wave - 1) * 2
	demons_spawned = 0
	spawn_timer.wait_time = 1.5
	spawn_timer.start()

func enable_follower_sacrifice():
	for follower in get_tree().get_nodes_in_group("followers"):
		if follower.has_method("enable_sacrifice"):
			follower.enable_sacrifice()

func spawn_demon():
	if demons_spawned >= demons_to_spawn:
		spawn_timer.stop()
		return
	
	var angle = randf() * TAU
	var spawn_distance = randf_range(550, 650)
	
	var offset = Vector2(cos(angle), sin(angle)) * spawn_distance
	var spawn_pos = player.global_position + offset
	
	var demon = demon_scene.instantiate()
	add_child(demon)
	demon.global_position = spawn_pos
	
	var base_health = 50 + (current_wave * 10)
	var base_damage = 15 + (current_wave * 3)
	var base_speed = 150 + (current_wave * 20)
	
	demon.health = base_health
	demon.current_health = base_health
	demon.damage = base_damage
	demon.speed = base_speed
	
	demons_spawned += 1
	demons_alive += 1

func on_demon_died():
	demons_alive -= 1
	if demons_alive <= 0 and wave_active:
		complete_wave()

func complete_wave():
	wave_active = false
	current_wave += 1
	clear_all_followers()
	await get_tree().create_timer(2.0).timeout
	start_placement_phase()

func clear_all_followers():
	for follower in get_tree().get_nodes_in_group("followers"):
		follower.queue_free()

func start_placement_phase():
	placement_phase = true
	followers_placed = 0
	followers_to_place = 3 + (current_wave - 1)
	update_ui()

func update_ui():
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave)
	if start_button:
		start_button.visible = false
