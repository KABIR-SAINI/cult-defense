extends Control

var pulse_timer = 0.0
var can_start = true
var is_transitioning = false

var background: ColorRect
var circle: ColorRect
var title_label: Label
var prompt_label: Label
var circle_glow: ColorRect
var music_player: AudioStreamPlayer

func _ready():
	setup_background()
	setup_circle()
	setup_circle_glow()
	setup_title()
	setup_prompt()
	setup_music()

func setup_background():
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.02, 0.02, 0.05, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)

func setup_circle():
	circle = ColorRect.new()
	circle.name = "Circle"
	circle.color = Color(0.3, 0.6, 1.0, 0.9)
	circle.size = Vector2(250, 250)
	circle.position = Vector2(get_viewport_rect().size.x / 2 - 125, get_viewport_rect().size.y / 2 - 125)
	circle.pivot_offset = circle.size / 2
	add_child(circle)

func setup_circle_glow():
	circle_glow = ColorRect.new()
	circle_glow.name = "CircleGlow"
	circle_glow.color = Color(0.4, 0.7, 1.0, 0.3)
	circle_glow.size = Vector2(280, 280)
	circle_glow.position = Vector2(get_viewport_rect().size.x / 2 - 140, get_viewport_rect().size.y / 2 - 140)
	circle_glow.pivot_offset = circle_glow.size / 2
	circle_glow.z_index = -1
	add_child(circle_glow)

func setup_title():
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "TOWER DEFENSE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.position = Vector2(get_viewport_rect().size.x / 2 - 300, get_viewport_rect().size.y / 2 - 50)
	title_label.size = Vector2(600, 100)
	title_label.pivot_offset = title_label.size / 2
	add_child(title_label)

func setup_prompt():
	prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = "PRESS SPACE"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 28)
	prompt_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1.0))
	prompt_label.position = Vector2(get_viewport_rect().size.x / 2 - 150, get_viewport_rect().size.y / 2 + 100)
	prompt_label.size = Vector2(300, 50)
	add_child(prompt_label)

func setup_music():
	music_player = AudioStreamPlayer.new()
	music_player.name = "MenuMusic"
	music_player.stream = load("res://Music/Menu Music.mp3")
	music_player.autoplay = true
	music_player.volume_db = -10
	add_child(music_player)

func _process(delta):
	if is_transitioning:
		return
	
	pulse_timer += delta
	
	# Smooth pulsating circle
	var circle_pulse = 1.0 + sin(pulse_timer * 1.8) * 0.08
	circle.scale = Vector2(circle_pulse, circle_pulse)
	
	# Glow pulses slightly offset
	var glow_pulse = 1.0 + sin(pulse_timer * 2.2) * 0.12
	circle_glow.scale = Vector2(glow_pulse, glow_pulse)
	circle_glow.modulate.a = 0.25 + sin(pulse_timer * 2.5) * 0.15
	
	# Subtle title pulse
	var title_pulse = 1.0 + sin(pulse_timer * 1.5) * 0.02
	title_label.scale = Vector2(title_pulse, title_pulse)
	
	# Prominent prompt pulse
	var prompt_pulse = 0.6 + abs(sin(pulse_timer * 2.5)) * 0.4
	prompt_label.modulate.a = prompt_pulse

func _input(event):
	if is_transitioning or not can_start:
		return
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		start_transition()

func start_transition():
	is_transitioning = true
	can_start = false
	
	# Fade out menu music smoothly
	var music_fade = create_tween()
	music_fade.tween_property(music_player, "volume_db", -80, 1.5)
	music_fade.tween_callback(music_player.stop)
	
	# Fade out title and prompt quickly
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(title_label, "modulate:a", 0.0, 0.4)
	fade_tween.tween_property(prompt_label, "modulate:a", 0.0, 0.4)
	fade_tween.tween_property(circle_glow, "modulate:a", 0.0, 0.5)
	
	# Slide circle up elegantly
	await get_tree().create_timer(0.2).timeout
	
	var slide_tween = create_tween()
	slide_tween.tween_property(circle, "position:y", -400, 1.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	slide_tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.8)
	slide_tween.tween_callback(load_game)

func load_game():
	# Update this path to match your game scene location
	var result = get_tree().change_scene_to_file("res://main.tscn")
	if result != OK:
		print("ERROR: Could not load game scene. Check the path in load_game()")
