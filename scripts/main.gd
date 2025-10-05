extends Node2D

# Game constants
const INITIAL_FOLLOWERS = 0
const INITIAL_DEMONS = 5
const DEMONS_PER_WAVE = 2
const SPAWN_INTERVAL = 1.5
const SPAWN_DISTANCE_MIN = 550
const SPAWN_DISTANCE_MAX = 650

# Economy constants
const STARTING_CASH = 150
const CASH_PER_KILL = 30
const BOSS_CASH_REWARD = 200
const BASIC_TOWER_COST = 50
const SNIPER_TOWER_COST = 100
const MACHINEGUN_TOWER_COST = 75

# Boss constants
const BOSS_ROUND_INTERVAL = 5

# Preloaded scenes
var basic_tower_scene = preload("res://scenes/basic_tower.tscn")
var sniper_tower_scene = preload("res://scenes/sniper_tower.tscn")
var machinegun_tower_scene = preload("res://scenes/machinegun_tower.tscn")
var demon_scene = preload("res://scenes/demon.tscn")
var boss_scene = preload("res://scenes/boss.tscn")

# References
var player
var start_button
var wave_label
var tower_select_label
var cash_label
var spawn_timer
var game_music: AudioStreamPlayer
var boss_music: AudioStreamPlayer
var game_music_playlist = []
var current_song_index = 0

# Game state
var selected_tower_type = "basic"
var current_cash = STARTING_CASH
var current_wave = 1
var followers_placed = 0
var placement_phase = true
var wave_active = false

# Wave tracking
var demons_alive = 0
var demons_to_spawn = INITIAL_DEMONS
var demons_spawned = 0
var is_boss_round = false

func _ready():
	add_to_group("main")
	cache_references()
	setup_spawn_timer()
	setup_music()
	update_ui()

func cache_references():
	player = $Player
	
	if has_node("UI/StartWaveButton"):
		start_button = $UI/StartWaveButton
		start_button.pressed.connect(start_wave)
		start_button.visible = true
	
	if has_node("UI/WaveLabel"):
		wave_label = $UI/WaveLabel
	
	if has_node("UI/TowerSelectLabel"):
		tower_select_label = $UI/TowerSelectLabel
	
	if has_node("UI/CashLabel"):
		cash_label = $UI/CashLabel

func setup_spawn_timer():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(spawn_demon)
	add_child(spawn_timer)

func setup_music():
	# Load game music playlist
	game_music_playlist = [
		load("res://audio/game_music_1.ogg"),
		load("res://audio/game_music_2.ogg"),
		load("res://audio/game_music_3.ogg")
		# Add more songs here as needed
	]
	
	# Game music player - start with first song
	game_music = AudioStreamPlayer.new()
	game_music.name = "GameMusic"
	game_music.stream = game_music_playlist[0]
	game_music.volume_db = -10
	game_music.autoplay = true
	game_music.finished.connect(_on_game_music_finished)
	add_child(game_music)
	
	# Boss music
	boss_music = AudioStreamPlayer.new()
	boss_music.name = "BossMusic"
	boss_music.stream = load("res://audio/boss_music.ogg")
	boss_music.volume_db = -8
	add_child(boss_music)

func _unhandled_input(event):
	if not placement_phase:
		return
	
	handle_tower_selection(event)
	handle_tower_placement(event)

func handle_tower_selection(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				selected_tower_type = "basic"
				update_tower_selection_ui()
			KEY_2:
				selected_tower_type = "sniper"
				update_tower_selection_ui()
			KEY_3:
				selected_tower_type = "machinegun"
				update_tower_selection_ui()

func handle_tower_placement(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		place_tower(get_global_mouse_position())

func place_tower(pos: Vector2):
	var tower_data = get_tower_data()
	
	if current_cash < tower_data.cost:
		return
	
	current_cash -= tower_data.cost
	
	var tower = tower_data.scene.instantiate()
	tower.global_position = pos
	add_child(tower)
	
	followers_placed += 1
	update_ui()
	
	if followers_placed >= INITIAL_FOLLOWERS and start_button:
		start_button.visible = true

func get_tower_data() -> Dictionary:
	match selected_tower_type:
		"sniper":
			return {"scene": sniper_tower_scene, "cost": SNIPER_TOWER_COST}
		"machinegun":
			return {"scene": machinegun_tower_scene, "cost": MACHINEGUN_TOWER_COST}
		_:
			return {"scene": basic_tower_scene, "cost": BASIC_TOWER_COST}

func start_wave():
	placement_phase = false
	wave_active = true
	
	if start_button:
		start_button.visible = false
	
	enable_follower_sacrifice()
	setup_demon_spawning()
	
	# Start appropriate music with fade in
	if is_boss_round:
		transition_to_boss_music()
	else:
		transition_to_game_music()

func enable_follower_sacrifice():
	for follower in get_tree().get_nodes_in_group("followers"):
		if follower.has_method("enable_sacrifice"):
			follower.enable_sacrifice()

func setup_demon_spawning():
	# Check if this is a boss round
	is_boss_round = (current_wave % BOSS_ROUND_INTERVAL == 0)
	
	if is_boss_round:
		spawn_boss()
		demons_to_spawn = 0
		demons_spawned = 0
		demons_alive = 1
	else:
		demons_to_spawn = INITIAL_DEMONS + (current_wave - 1) * DEMONS_PER_WAVE
		demons_spawned = 0
		demons_alive = 0
		spawn_timer.wait_time = SPAWN_INTERVAL
		spawn_timer.start()
	
	update_ui()

func spawn_boss():
	var spawn_pos = get_random_spawn_position()
	var boss = boss_scene.instantiate()
	
	call_deferred("add_child", boss)
	boss.global_position = spawn_pos
	
	# Scale boss stats with wave
	var wave_multiplier = current_wave / BOSS_ROUND_INTERVAL
	boss.health = 500.0 * wave_multiplier
	boss.current_health = boss.health
	boss.damage = 30.0 + (wave_multiplier * 10.0)
	boss.speed = 100.0 + (wave_multiplier * 10.0)

func spawn_demon():
	if demons_spawned >= demons_to_spawn:
		spawn_timer.stop()
		return
	
	var spawn_pos = get_random_spawn_position()
	var demon = demon_scene.instantiate()
	
	call_deferred("add_child", demon)
	demon.global_position = spawn_pos
	
	set_demon_stats(demon)
	
	demons_spawned += 1
	demons_alive += 1

func get_random_spawn_position() -> Vector2:
	var angle = randf() * TAU
	var spawn_distance = randf_range(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
	var offset = Vector2(cos(angle), sin(angle)) * spawn_distance
	return player.global_position + offset

func set_demon_stats(demon):
	var base_health = 50.0 + (current_wave * 10.0)
	var base_damage = 15.0 + (current_wave * 3.0)
	var base_speed = 350.0 + (current_wave * 25.0)
	
	demon.health = base_health
	demon.current_health = base_health
	demon.damage = base_damage
	demon.speed = base_speed

func on_demon_died():
	demons_alive -= 1
	current_cash += CASH_PER_KILL
	update_ui()
	
	if should_complete_wave():
		complete_wave()

func on_boss_died():
	demons_alive -= 1
	current_cash += BOSS_CASH_REWARD
	update_ui()
	
	if should_complete_wave():
		complete_wave()

func should_complete_wave() -> bool:
	return demons_alive <= 0 and wave_active and (demons_spawned >= demons_to_spawn or is_boss_round)

func complete_wave():
	wave_active = false
	spawn_timer.stop()
	
	# Don't fade out music - keep it playing continuously
	
	current_wave += 1
	
	await get_tree().create_timer(2.0).timeout
	clear_all_followers()
	start_placement_phase()

func fade_out_all_music():
	# This function is no longer used but kept for compatibility
	pass

func transition_to_game_music():
	# Stop and fade out boss music if playing
	if boss_music.playing:
		var fade_out = create_tween()
		fade_out.tween_property(boss_music, "volume_db", -80, 1.0)
		fade_out.tween_callback(boss_music.stop)
	
	# Resume game music if it was stopped, or just fade it back in
	if not game_music.playing:
		game_music.play()
	
	game_music.volume_db = -80
	var fade_in = create_tween()
	fade_in.tween_property(game_music, "volume_db", -10, 1.5)

func _on_game_music_finished():
	# Play next song in playlist
	current_song_index = (current_song_index + 1) % game_music_playlist.size()
	game_music.stream = game_music_playlist[current_song_index]
	game_music.play()

func transition_to_boss_music():
	# Stop and fade out game music if playing
	if game_music.playing:
		var fade_out = create_tween()
		fade_out.tween_property(game_music, "volume_db", -80, 1.0)
		fade_out.tween_callback(game_music.stop)
	
	# Start boss music from silent and fade in
	boss_music.volume_db = -80
	boss_music.play()
	var fade_in = create_tween()
	fade_in.tween_property(boss_music, "volume_db", -8, 1.5)

func clear_all_followers():
	for follower in get_tree().get_nodes_in_group("followers"):
		follower.queue_free()

func start_placement_phase():
	placement_phase = true
	followers_placed = 0
	selected_tower_type = "basic"
	is_boss_round = false
	update_ui()

func update_ui():
	update_wave_label()
	update_cash_label()
	update_start_button()
	update_tower_selection_ui()

func update_wave_label():
	if wave_label:
		if is_boss_round and wave_active:
			wave_label.text = "Wave: " + str(current_wave) + " - BOSS!"
			wave_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			wave_label.text = "Wave: " + str(current_wave)
			wave_label.modulate = Color.WHITE

func update_cash_label():
	if cash_label:
		cash_label.text = "Cash: $" + str(current_cash)

func update_start_button():
	if start_button:
		start_button.visible = false

func update_tower_selection_ui():
	if not tower_select_label:
		return
	
	if placement_phase:
		show_tower_selection()
	else:
		tower_select_label.visible = false

func show_tower_selection():
	var tower_info = get_tower_info()
	var tower_cost = get_tower_cost()
	
	tower_select_label.text = tower_info
	tower_select_label.modulate = Color.WHITE if current_cash >= tower_cost else Color.RED
	tower_select_label.visible = true

func get_tower_info() -> String:
	match selected_tower_type:
		"sniper":
			return "[2] SNIPER TOWER ($100) - High Damage (350 range)"
		"machinegun":
			return "[3] MACHINE GUN ($75) - Fast Fire (150 range)"
		_:
			return "[1] BASIC TOWER ($50) - Balanced (200 range)"

func get_tower_cost() -> int:
	match selected_tower_type:
		"sniper":
			return SNIPER_TOWER_COST
		"machinegun":
			return MACHINEGUN_TOWER_COST
		_:
			return BASIC_TOWER_COST
