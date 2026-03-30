extends Node2D

@onready var bg_music: AudioStreamPlayer2D = $BGMusic
@onready var basement: Node2D = $PlayerSpawnerFromBasement
@onready var office: Node2D = $PlayerSpawnerFromOffice
@onready var outside: Node2D = $PlayerSpawnerFromOutside

func _ready() -> void:
	GlobalUI.show_ui()
	SceneManager.set_spawn.connect(set_spawn_node)
	bg_music.play()
	
	#Spawn testing/ temp code
	#if PlayerManager.player_spawned == false:
		#PlayerManager.set_player_postion(outside.global_position)
		#PlayerManager.player_spawned = true

func set_spawn_node(spawn_name: String) -> void:
	var spawn_pos: Vector2
	
	match(spawn_name):
		"Basement":
			spawn_pos = basement.global_position
		"Office":
			spawn_pos = office.global_position
		"Outside":
			spawn_pos = outside.global_position
		"Minigame":
			spawn_pos = PlayerManager.get_prev_player_pos()
		_:
			print("No spawn node available")
	
	if PlayerManager.player_spawned == false:
		PlayerManager.set_player_postion(spawn_pos)
		PlayerManager.player_spawned = true

func _exit_tree() -> void:
	SceneManager.set_spawn.disconnect(set_spawn_node)
