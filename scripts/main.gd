extends Node2D

const INITIAL_FOLLOWERS = 3
const INITIAL_DEMONS = 5
const DEMONS_PER_WAVE = 2
const SPAWN_INTERVAL = 1.5
const SPAWN_DISTANCE_MIN = 550
const SPAWN_DISTANCE_MAX = 650

var basic_tower_scene = preload("res://scenes/basic_tower.tscn")
var sniper_tower_scene = preload("res://scenes/sniper_tower.tscn")
var machinegun_tower_scene = preload("res://scenes/machinegun_tower.tscn")
var demon_scene = preload("res://scenes/demon.tscn")

var selected_tower_type = "basic"

var player
var start_button
var wave_label
var spawn_timer

var current_wave = 1
var followers_to_place = INITIAL_FOLLOWERS
var followers_placed = 0
var placement_phase = true
var wave_active = false
var demons_alive = 0
var demons_to_spawn = INITIAL_DEMONS
var demons_spawned = 0

func _ready():
	add_to_group("main")
	player = $Player
	
	if has_node("UI/StartWaveButton"):
		start_button = $UI/StartWaveButton
		start_button.pressed.connect(start_wave)
		start_button.visible = false
	
	if has_node("UI/WaveLabel"):
		wave_label = $UI/WaveLabel
	
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(spawn_demon)
	add_child(spawn_timer)
	
	update_ui()

func _unhandled_input(event):
	if placement_phase and followers_placed < followers_to_place:
		# Number keys to select tower type
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_1:
					selected_tower_type = "basic"
					print("Selected: Basic Tower")
				KEY_2:
					selected_tower_type = "sniper"
					print("Selected: Sniper Tower")
				KEY_3:
					selected_tower_type = "machinegun"
					print("Selected: Machine Gun Tower")
		
		# Click to place selected tower
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			place_follower(get_global_mouse_position())

func place_follower(pos):
	var tower_scene
	match selected_tower_type:
		"basic":
			tower_scene = basic_tower_scene
		"sniper":
			tower_scene = sniper_tower_scene
		"machinegun":
			tower_scene = machinegun_tower_scene
		_:
			tower_scene = basic_tower_scene
	
	var tower = tower_scene.instantiate()
	tower.global_position = pos
	add_child(tower)
	followers_placed += 1
	
	if followers_placed >= followers_to_place and start_button:
		start_button.visible = true

func start_wave():
	placement_phase = false
	wave_active = true
	
	if start_button:
		start_button.visible = false
	
	enable_follower_sacrifice()
	
	demons_to_spawn = INITIAL_DEMONS + (current_wave - 1) * DEMONS_PER_WAVE
	demons_spawned = 0
	demons_alive = 0
	
	spawn_timer.wait_time = SPAWN_INTERVAL
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
	var spawn_distance = randf_range(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
	var offset = Vector2(cos(angle), sin(angle)) * spawn_distance
	var spawn_pos = player.global_position + offset
	
	var demon = demon_scene.instantiate()
	call_deferred("add_child", demon)
	demon.global_position = spawn_pos
	
	var base_health = 50.0 + (current_wave * 10.0)
	var base_damage = 15.0 + (current_wave * 3.0)
	var base_speed = 350.0 + (current_wave * 25.0)
	
	demon.health = base_health
	demon.current_health = base_health
	demon.damage = base_damage
	demon.speed = base_speed
	
	demons_spawned += 1
	demons_alive += 1

func on_demon_died():
	demons_alive -= 1
	
	if demons_alive <= 0 and wave_active and demons_spawned >= demons_to_spawn:
		complete_wave()

func complete_wave():
	wave_active = false
	spawn_timer.stop()
	current_wave += 1
	
	await get_tree().create_timer(2.0).timeout
	clear_all_followers()
	start_placement_phase()

func clear_all_followers():
	for follower in get_tree().get_nodes_in_group("followers"):
		follower.queue_free()

func start_placement_phase():
	placement_phase = true
	followers_placed = 0
	followers_to_place = INITIAL_FOLLOWERS + (current_wave - 1)
	selected_tower_type = "basic"  # Reset to basic tower
	update_ui()

func update_ui():
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave)
	if start_button:
		start_button.visible = false
