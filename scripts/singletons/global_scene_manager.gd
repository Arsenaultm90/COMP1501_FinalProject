extends CanvasLayer

signal set_spawn

@onready var fade_rect: ColorRect = $FadeRect
@onready var sound_fx: AudioStreamPlayer2D = $SoundFX
@onready var music: AudioStreamPlayer2D = $Music

var player = null
var fade_time : float = 1.0
var is_transitioning : bool = false

func _ready() -> void:
	fade_in()

func fade_out() -> void:
	if is_transitioning:
		return
		
	is_transitioning = true
	
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	
	await tween.finished

func fade_in() -> void:
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_time)
	
	await tween.finished
	
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.enable_controls()
	is_transitioning = false

func fade_to_scene(scene_path: String, audio_name: String) -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.disable_controls()
	
	GlobalUI.game_clock.pause_clock()
	sound_fx.stream = load("res://sounds/fx/" + audio_name + ".ogg")
	sound_fx.play()
	await fade_out()
	await sound_fx.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	set_spawn.emit(audio_name)
	await fade_in()
	GlobalUI.game_clock.start_clock()
	player = get_tree().get_first_node_in_group("Player")
	
	if player:
		player.enable_controls()

func play_music(track_name: String) -> void:
	var path = "res://sounds/music/minigames/" + track_name + ".wav"
	if music.stream and music.playing:
		if music.stream.resource_path == path:
			return
	music.stream = load(path)
	music.play()

func stop_music() -> void:
	music.stop()
