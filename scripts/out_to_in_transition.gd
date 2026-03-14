extends Area2D

@onready var collision : CollisionShape2D = $CollisionShape2D

func interact() -> void:
	PlayerManager.player_spawned = false
	SceneManager.fade_to_scene("res://scenes/gas_station_inside.tscn")
