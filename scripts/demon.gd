extends CharacterBody2D

const ATTACK_RANGE = 50.0

@export var speed = 150.0
@export var health = 50.0
@export var damage = 15.0
@export var attack_cooldown = 1.5

var current_health
var attack_timer = 0.0
var player_ref = null

func _ready():
	current_health = health
	add_to_group("demons")
	
	if has_node("Hitbox"):
		$Hitbox.add_to_group("demons")
	
	# Cache player reference once instead of searching every frame
	player_ref = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	# Verify player still exists (might have died)
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
		if not player_ref:
			return
	
	# Move toward player
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Attack if in range
	var distance = global_position.distance_to(player_ref.global_position)
	if distance < ATTACK_RANGE:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_player()
			attack_timer = attack_cooldown

func attack_player():
	if is_instance_valid(player_ref) and player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)

func take_damage(amount):
	current_health -= amount
	
	if current_health <= 0:
		die()

func die():
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_demon_died"):
		main.on_demon_died()
	
	queue_free()
