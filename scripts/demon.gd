extends CharacterBody2D

@export var speed = 150.0
@export var health = 50.0
@export var damage = 15.0
@export var attack_cooldown = 1.5

var current_health
var attack_timer = 0.0

func _ready():
	current_health = health
	add_to_group("demons")
	if has_node("Hitbox"):
		$Hitbox.add_to_group("demons")

func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		var distance = global_position.distance_to(player.global_position)
		if distance < 50:
			attack_timer -= delta
			if attack_timer <= 0:
				player.take_damage(damage)
				attack_timer = attack_cooldown

func take_damage(amount):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_demon_died"):
		main.on_demon_died()
	queue_free()
