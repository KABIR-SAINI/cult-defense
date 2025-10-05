extends CanvasLayer

@onready var health_bar = $HealthBar

var player_ref = null

func _ready():
	# Cache player reference
	player_ref = get_tree().get_first_node_in_group("player")
	
	if player_ref and health_bar:
		health_bar.max_value = player_ref.max_health
		health_bar.value = player_ref.current_health

func _process(delta):
	# Verify player still exists
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
		if not player_ref:
			return
	
	if health_bar:
		health_bar.value = player_ref.current_health
