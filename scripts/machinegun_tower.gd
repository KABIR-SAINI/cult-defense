extends BaseTower
func _ready():
	tower_name = "Machine Gun Tower"
	shoot_cooldown = 0.15  # Very fast fire rate
	damage = 10.0  # Low damage
	detection_radius = 150.0  # Short range
	tower_color = Color(1.0, 0.8, 0.2)  # Yellow/gold
	super._ready()
func create_visual():
	if not has_node("Visual"):
		var polygon = Polygon2D.new()
		polygon.name = "Visual"
		# Hexagon shape for machine gun
		var points = []
		for i in range(6):
			var angle = i * PI / 3.0
			points.append(Vector2(cos(angle) * 12, sin(angle) * 12))
		polygon.polygon = PackedVector2Array(points)
		polygon.color = tower_color
		add_child(polygon)
