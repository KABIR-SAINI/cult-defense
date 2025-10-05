extends BaseTower

func _ready():
	tower_name = "Basic Tower"
	shoot_cooldown = 0.5
	damage = 30.0
	detection_radius = 200.0
	tower_color = Color(0.5, 0.5, 1.0)  # Light blue
	super._ready()
