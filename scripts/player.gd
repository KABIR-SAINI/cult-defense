extends CharacterBody2D

@export var speed = 300.0
@export var max_health = 100.0
@export var health_drain_rate = 1.0

var current_health = max_health

func _ready():
	current_health = max_health
	add_to_group("player")

func _physics_process(delta):
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	current_health -= health_drain_rate * delta
	
	if current_health <= 0:
		die()

func die():
	get_tree().reload_current_scene()

func take_damage(amount):
	current_health -= amount
	if current_health <= 0:
		die()

func sacrifice_heal(amount):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
