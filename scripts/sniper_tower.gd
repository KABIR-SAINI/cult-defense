extends BaseTower

func _ready():
	tower_name = "Sniper Tower"
	shoot_cooldown = 2.0  # Slow fire rate
	damage = 100.0  # High damage
	detection_radius = 350.0  # Long range
	tower_color = Color(1.0, 0.2, 0.2)  # Red
	super._ready()

func create_visual():
	if not has_node("Visual"):
		var polygon = Polygon2D.new()
		polygon.name = "Visual"
		# Triangle shape for sniper
		polygon.polygon = PackedVector2Array([
			Vector2(0, -20), Vector2(15, 15), Vector2(-15, 15)
		])
		polygon.color = tower_color
		add_child(polygon)
