extends Node2D

@onready var basement: Node2D = $PlayerSpawner

func _ready() -> void:
	SceneManager.set_spawn.connect(set_spawn_node)

func set_spawn_node(_spawn_name: String) -> void:
	if PlayerManager.player_spawned == false:
		PlayerManager.set_player_postion(basement.global_position)
		PlayerManager.player_spawned = true

func _exit_tree() -> void:
	SceneManager.set_spawn.disconnect(set_spawn_node)
