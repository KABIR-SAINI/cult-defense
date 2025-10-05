extends CanvasLayer

@onready var health_bar = $HealthBar

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		health_bar.value = player.current_health
		health_bar.max_value = player.max_health
