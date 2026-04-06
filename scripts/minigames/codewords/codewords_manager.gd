extends Node2D

enum Phase { SLOW, DIALOGUE, FAST, END }
var current_phase: Phase = Phase.SLOW

@export var slow_song: AudioStream
@export var fast_song: AudioStream
@export var bpm: float = 120.0
@export var beats_per_spawn: int = 4      # spawn every nth beat
@export var double_spawn_chance: float = 0.3
@export var fall_duration: float = 2.0

@onready var music: AudioStreamPlayer2D = $Music
@onready var instructions : MarginContainer = $BrainUI/Instructions
@onready var brain: Sprite2D = $BrainUI/BrainSprite
@onready var quality_label: Label = $BrainUI/QualityLabel
@onready var dialogue_box: Label = $BrainUI/Dialogue
@onready var word_container: Node2D = $BrainUI/WordContainer
@onready var hit_lights: Array = [
	$BrainUI/Light1,
	$BrainUI/Light2,
	$BrainUI/Light3,
	$BrainUI/Light4
]

const LANE_KEYS = [KEY_J, KEY_I, KEY_K, KEY_L]
const WORD_SCENE = preload("res://scenes/word.tscn")

var minigame_dialogue: Array[String] = [
	"Listen slowly... Deepen your breaths...",
	"No questions, no thoughts, no mind",
	"The sounds are noise, hear only my words.",
	"And when we arrive, we wake up..."
]

var beat_interval: float
var next_spawn_time: float
var beat_count: int = 0
var song_length: float = 0.0
var music_playing: bool = false
var spawning_active: bool = true
var song_pos
var active_beat_groups: Dictionary = {}

var resistance: float = 1.0
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5
var current_dialogue_index: int = 0
var can_advance: bool = false
var returning: bool = false

@onready var hit_zones: Array = [
	$BrainUI/HitZone/Hit_J,
	$BrainUI/HitZone/Hit_I,
	$BrainUI/HitZone/Hit_K,
	$BrainUI/HitZone/Hit_L
]
@onready var spawn_zones: Array = [
	$BrainUI/Spawner/Spawner1,
	$BrainUI/Spawner/Spawner2,
	$BrainUI/Spawner/Spawner3,
	$BrainUI/Spawner/Spawner4
]

func _ready():
	GlobalUI.hide_ui()
	quality_label.text = ""
	beat_interval = 60.0 / bpm
	next_spawn_time = (beat_interval * beats_per_spawn) - fall_duration
	song_length = music.stream.get_length()
	await get_tree().create_timer(1.0).timeout

func _process(_delta):
	if instructions.visible == true:
		return
	
	song_pos = music.get_playback_position()
	
	### TESTING SCENE TRANSITIONS
	if current_phase == Phase.END:
		if not returning:
			returning = true
			return_to_game()
		return
		
	if not spawning_active:
		return
		
	if current_phase == Phase.DIALOGUE:
		return
		
	if current_phase == Phase.FAST:
		if song_pos >= song_length - fall_duration:
			return
	
	if current_phase == Phase.FAST and not music.playing:
		if not returning:
			returning = true
			return_to_game()
		return
	
	if song_pos >= next_spawn_time:
		beat_count += 1
		on_spawn_beat()
		next_spawn_time += beat_interval * beats_per_spawn
		
	if current_phase == Phase.SLOW and not music.playing:
		spawning_active = false
		start_dialogue()
		return

func spawn_word(lane: int):
	var word = WORD_SCENE.instantiate()
	word_container.add_child(word)
	word.z_index = 10
	word.word_missed.connect(on_word_missed)
	word.fall_duration = fall_duration

	var spawner = spawn_zones[lane]
	var hit_zone = hit_zones[lane]
	var start = word_container.to_local(spawner.global_position + spawner.size / 2)
	var end = word_container.to_local(hit_zone.global_position + Vector2(25, 0))

	word.setup(lane, start, end)
	word.start_fall()
	return word

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		for i in range(LANE_KEYS.size()):
			if event.keycode == LANE_KEYS[i]:
				check_hit(i)
	
	if instructions.visible == true and Input.is_action_just_pressed("pluck"):
		music.play()
		instructions.visible = false
		await get_tree().create_timer(1.0).timeout

func check_hit(lane: int):
	var zone = hit_zones[lane]
	var zone_rect = Rect2(zone.global_position, zone.size)
	var best_word = null
	var best_overlap = 0.0

	for word in get_tree().get_nodes_in_group("Words"):
		if word.lane != lane:
			continue
		var word_rect = Rect2(word.global_position, word.size)
		var intersection = zone_rect.intersection(word_rect)
		if intersection.size.x > 0 and intersection.size.y > 0:
			var overlap = intersection.get_area() / word_rect.get_area()
			if overlap > best_overlap:
				best_overlap = overlap
				best_word = word

	if best_word:
		grade_hit(best_word, best_overlap)
	else:
		show_feedback("TOO EARLY", Color.GRAY)

func grade_hit(word, overlap: float):
	var bid = word.beat_id
	var lane = word.lane
	word.queue_free()
	
	if bid in active_beat_groups:
		var group = active_beat_groups[bid]
		group["hit_count"] += 1
		group["words"].erase(word)
		
		# Only reward if all words in this beat are hit
		if group["hit_count"] >= group["total"]:
			active_beat_groups.erase(bid)
			var glow_color: Color
			if overlap >= 0.75:
				resistance = min(resistance + 15, 100)
				glow_color = Color.GREEN
				show_feedback("PERFECT RESIST!", Color.GREEN)
			elif overlap >= 0.5:
				resistance = min(resistance + 8, 100)
				glow_color = Color.YELLOW
				show_feedback("RESIST!", Color.YELLOW)
			else:
				resistance = min(resistance + 3, 100)
				glow_color = Color.ORANGE
				show_feedback("WEAK...", Color.ORANGE)
		
			for l in group["lanes"]:
				flash_hit_light(l, glow_color)

func on_word_missed(beat_id: int):
	if beat_id in active_beat_groups:
		for word in active_beat_groups[beat_id]["words"]:
			flash_hit_light(word.lane, Color.RED)
		active_beat_groups.erase(beat_id)
	resistance = max(resistance - 15, 0)
	show_feedback("PROGRAMMED!", Color.RED)

func show_feedback(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.position = quality_label.position
	label.size = Vector2(200, 50)                       
	word_container.add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 80, 1.5)  
	tween.tween_property(label, "modulate:a", 0.0, 0.8)                    
	tween.chain().tween_callback(func(): label.queue_free())

func on_spawn_beat():
	beat_count += 1
	var lanes = range(4)
	lanes.shuffle()

	var words_this_beat = []
	var lanes_this_beat = []

	var word_a = spawn_word(lanes[0])
	words_this_beat.append(word_a)
	lanes_this_beat.append(lanes[0])

	if randf() < double_spawn_chance:
		var word_b = spawn_word(lanes[1])
		words_this_beat.append(word_b)
		lanes_this_beat.append(lanes[1])

	active_beat_groups[beat_count] = {
		"words": words_this_beat,
		"hit_count": 0,
		"total": words_this_beat.size(),
		"lanes": lanes_this_beat
	}

	for word in words_this_beat:
		word.beat_id = beat_count

func start_dialogue():
	current_phase = Phase.DIALOGUE
	for word in get_tree().get_nodes_in_group("Words"):
		word.queue_free()
	dialogue_box.visible = true
	_show_dialogue_line()

func start_fast():
	current_phase = Phase.FAST
	dialogue_box.visible = false
	beats_per_spawn = 2
	beat_count = 0
	next_spawn_time = INF
	music.stream = fast_song
	music.play()
	song_length = music.stream.get_length()
	
	await get_tree().create_timer(1.0).timeout
	next_spawn_time = music.get_playback_position() + (beat_interval * beats_per_spawn) - fall_duration
	spawning_active = true

func flash_hit_light(lane: int, color: Color):
	var light = hit_lights[lane]
	light.color = color
	light.enabled = true
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func(): light.enabled = false)

func _show_dialogue_line():
	can_advance = false
	dialogue_box.text = ""
	var full_text = minigame_dialogue[current_dialogue_index]
	var tween = create_tween()
	tween.tween_method(
		func(i: int): dialogue_box.text = full_text.left(i),
		0,
		full_text.length(),
		full_text.length() * 0.05
	)
	tween.tween_callback(func(): can_advance = true)

func _unhandled_input(event: InputEvent):
	if current_phase == Phase.DIALOGUE and event.is_action_pressed("advance_dialogue") and can_advance:
		current_dialogue_index += 1
		if current_dialogue_index >= minigame_dialogue.size():
			dialogue_box.visible = false
			start_fast()
		else:
			_show_dialogue_line()

func return_to_game() -> void:
	$BrainUI.visible = false
	print("Resistance: ", resistance)
	PlayerManager.player_spawned = false
	SceneManager.fade_to_scene("res://scenes/ending.tscn", "")
