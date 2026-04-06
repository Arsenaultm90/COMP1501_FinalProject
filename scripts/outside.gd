extends Node2D

@onready var spawn_point: Node2D = $Level/PlayerSpawner
@onready var intro_camera: Camera2D = $IntroCam
@onready var intro_label: Label = $IntroLabel
@onready var pump_lights: Array = [$Level/Pumps/PumpLight1, $Level/Pumps/PumpLight2]

var intro_enabled: bool = false

func _ready() -> void:
	if not PlayerManager.intro_played:
		intro_camera.global_position = $Logo.global_position
		intro_camera.enabled = true
		GlobalUI.hide_ui()
		GlobalUI.game_clock.pause_clock()
		PlayerManager.add_player_instance()
	else:
		GlobalUI.show_ui()
		intro_camera.enabled = false
		if is_instance_valid(PlayerManager.player):
			var cam = PlayerManager.player.get_node_or_null("Camera2D")
			if cam:
				cam.enabled = true
	
	if GlobalUI.game_clock.hour >= 18:
		pump_lights[0].visible = true
		pump_lights[1].visible = true
	
	if not SceneManager.set_spawn.is_connected(set_spawn_node):
		SceneManager.set_spawn.connect(set_spawn_node)

func _process(_delta: float) -> void:
	if PlayerManager.intro_played:
		return
	
	if Input.is_action_just_pressed("pluck") and not intro_enabled:
		intro_enabled = true
		intro_label.visible = false
		_pan_to_player()

func _pan_to_player() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	PlayerManager.player.disable_controls()
	
	if not player:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		intro_camera,
		"global_position",
		player.global_position,
		5
	)
	await tween.finished
	
	var cam = PlayerManager.player.get_node_or_null("Camera2D")
	if cam:
		cam.enabled = true
		GlobalUI.show_ui()
		GlobalUI.game_clock.start_clock()
		intro_camera.enabled = false
		PlayerManager.intro_played = true
	
	PlayerManager.player.enable_controls()

func set_spawn_node(_spawn_name: String) -> void:
	print("Spawning player, spawn_name: ", _spawn_name)
	var spawn_pos: Vector2
	
	if _spawn_name == "Minigame":
		spawn_pos = PlayerManager.get_prev_player_pos()
		print("Using prev pos: ", spawn_pos)
	else:
		spawn_pos = spawn_point.global_position
		print("Using spawn point: ", spawn_pos)
	
	if not PlayerManager.player_spawned:
		PlayerManager.set_player_postion(spawn_pos)
		PlayerManager.player_spawned = true
