extends CanvasLayer

signal time_changed(hour: int, minute: int)

@onready var fade_rect: ColorRect = $FadeRect
@onready var time_label: Label = $TimeLabel
@onready var sound_fx : AudioStreamPlayer2D = $SoundFX

var player = null
var fade_time := 1.0
var is_transitioning := false
var hour: int = 8
var minute: int = 0
var second_accumulator: float = 0.0
var day_active: bool = true


func _ready() -> void:
	update_time_label()
	fade_in()

func _process(delta: float) -> void:
	if not day_active:
		return
	
	second_accumulator += delta
	
	if second_accumulator >= 0.1:
		second_accumulator -= 0.1
		minute += 1
		
		if minute >= 60:
			minute = 0
			hour += 1
			
			if hour >= 20:
				hour = 20
				minute = 0
				day_active = false
		
		time_changed.emit(hour, minute)
		update_time_label()


### SCENE TRANSITION METHODS
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


### TIME METHODS
func update_time_label() -> void:
	var display_minute := int(minute / 10) * 10
	time_label.text = format_time(hour, display_minute)

func format_time(h: int, m: int) -> String:
	var suffix := "AM"
	var display_hour := h
	
	if h >= 12:
		suffix = "PM"
	
	if h == 0:
		display_hour = 12
	elif h > 12:
		display_hour = h - 12
	
	return "%02d:%02d %s" % [display_hour, m, suffix]
