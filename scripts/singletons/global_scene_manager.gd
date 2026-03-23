extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@onready var sound_fx : AudioStreamPlayer2D = $SoundFX

var player = null
var fade_time := 1.0
var is_transitioning := false


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


func fade_to_scene(scene_path: String) -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.disable_controls()
	
	sound_fx.play()
	await fade_out()
	await sound_fx.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await fade_in()

	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.enable_controls()
