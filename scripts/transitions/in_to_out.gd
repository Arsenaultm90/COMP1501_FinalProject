extends Area2D

func interact() -> void:
	PlayerManager.player_spawned = false
	SceneManager.fade_to_scene("res://scenes/outside.tscn", "Outside")
