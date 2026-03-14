extends Node2D

@onready var level_node : Node2D = $".."

func _ready() -> void:
	visible = false
	
	if PlayerManager.player_spawned == false:
		PlayerManager.set_player_postion(level_node, global_position)
		PlayerManager.player_spawned = true
	
	pass
