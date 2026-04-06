extends CanvasLayer

signal dialogue_finished

var pipedream_dialogue = "res://data/dialogue/pipedream.json"
var mindcatch_dialogue = "res://data/dialogue/mindcatch.json"
var codewords_dialogue = "res://data/dialogue/codewords.json"

@onready var player_interact_label : Label = $PlayerInteractLabel
@onready var game_clock : Label = $GameClock
@onready var text_box = $TextBox
@onready var name_container = $NameTag
@onready var name_label = $NameTag/NameLabel
@onready var dialogue_label = $TextBox/VBoxContainer/DialogueLabel
@onready var choice_box = $TextBox/VBoxContainer/ChoiceContainer
@onready var choice_buttons: Array = [
	$TextBox/VBoxContainer/ChoiceContainer/Choice1, 
	$TextBox/VBoxContainer/ChoiceContainer/Choice2, 
	$TextBox/VBoxContainer/ChoiceContainer/Choice3]

const MAX_WIDTH = 512

var dialogue_tree: Dictionary = {}
var current_node_id: String = ""
var is_dialogue_active: bool = false
var is_preparing: bool = false
var can_advance_line: bool = false
var text_box_pos: Vector2
var interact_label_target: Node2D = null
var pipedream_played: bool = false
var mindcatch_played: bool = false
var codewords_played: bool = false

func _ready() -> void:
	text_box.visible = false

func _process(_delta: float) -> void:
	if interact_label_target and player_interact_label.visible:
		var screen_pos = get_viewport().get_canvas_transform() * interact_label_target.global_position
		player_interact_label.position = Vector2(
			screen_pos.x - player_interact_label.size.x / 2.0,
			screen_pos.y - player_interact_label.size.y - 50.0
		)
	
	if game_clock.hour == 10 and not pipedream_played:
		pipedream_played = true
		start_pipedream()
	
	if  game_clock.hour == 15 and not mindcatch_played:
		mindcatch_played = true
		start_mindcatch()
	
	if game_clock.hour == 20 and not codewords_played:
		codewords_played = true
		start_codewords()

func hide_ui() -> void:
	visible = false

func show_ui() -> void:
	visible = true

########################
### INTERACT METHODS ###
########################
func show_interact_label(target : Node2D) -> void:
	interact_label_target = target
	player_interact_label.visible = true

func hide_interact_label() -> void:
	interact_label_target = null
	player_interact_label.visible = false


########################
### DIALOGUE METHODS ###
########################
func start_dialogue(position: Vector2, json_path: String) -> void:
	if is_dialogue_active:
		return

	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Could not load dialogue file: " + json_path)
		return

	dialogue_tree = JSON.parse_string(file.get_as_text())
	file.close()

	is_dialogue_active = true
	text_box_pos = position
	current_node_id = _resolve_start()
	game_clock.pause_clock()

	if not text_box.finished_displaying.is_connected(_on_text_box_finished_displaying):
		text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	_show_node(current_node_id)

func _resolve_start() -> String:
	if "conditional_start" in dialogue_tree:
		for entry in dialogue_tree["conditional_start"]:
			if "require_flag" in entry:
				var has_it = _check_flag(entry["require_flag"])
				if has_it:
					return entry["node"]
			else:
				return entry["node"]
	return dialogue_tree["start"]

func _show_node(node_id: String) -> void:
	if node_id == "end" or node_id == "":
		_end_dialogue()
		return

	var node = dialogue_tree["nodes"][node_id]
	var dialogue_name = dialogue_tree["nodes"]["greeting"]["speaker"]

	if node.has("flags"):
		for flag_name in node["flags"]:
			var flag_type = node["flags"][flag_name].get("type", "session")
			if flag_type == "event":
				FlagManager.set_event_flag(flag_name)
			else:
				FlagManager.set_session_flag(flag_name)
			print("Flag set: ", flag_name, " type: ", flag_type)
	
	can_advance_line = false
	is_preparing = true
	text_box.visible = true
	text_box.hide_choices()
	
	await text_box.prepare_text(node["text"])
	is_preparing = false
	
	var screen_pos = get_viewport().get_canvas_transform() * text_box_pos
	text_box.position = Vector2(
		screen_pos.x - text_box.size.x / 2.0,
		screen_pos.y - text_box.size.y - 30.0
	)
	
	name_label.text = dialogue_name
	name_container.position = text_box.position + Vector2(5, -50)
	name_container.visible = true
	text_box.start_display(node["text"])

func _on_text_box_finished_displaying() -> void:
	can_advance_line = true
	var node = dialogue_tree["nodes"][current_node_id]
	if node.has("choices"):
		var valid_choices = node["choices"].filter(func(c):
			if c.has("require_flag"):
				return _check_flag(c["require_flag"])
			return true
		)
		text_box.show_choices(valid_choices)
		name_container.visible = false


func _on_choice_selected(index: int) -> void:
	var node = dialogue_tree["nodes"][current_node_id]
	var next_id = node["choices"][index].get("next", "end")
	var choice = node["choices"][index]

	if choice.has("flags"):
		for flag_name in choice["flags"]:
			var flag_type = choice["flags"][flag_name].get("type", "session")
			var flag_value = choice["flags"][flag_name].get("value", true)
			if flag_type == "event":
				FlagManager.set_event_flag(flag_name)
			else:
				FlagManager.set_session_flag(flag_name)
			
			PlayerManager.data.set_flag(flag_name, flag_value)

	if next_id == null or next_id == "":
		_end_dialogue()
		return
	current_node_id = next_id
	_show_node(current_node_id)

func _show_choices(choices: Array) -> void:
	choice_box.position = Vector2(
		text_box.position.x,
		text_box.position.y + text_box.size.y + 8.0
	)
	choice_box.visible = true

	for i in range(choice_buttons.size()):
		if i < choices.size():
			choice_buttons[i].visible = true
			choice_buttons[i].text = choices[i]["text"]
			# disconnect previous connection if any
			if choice_buttons[i].pressed.is_connected(_on_choice_selected.bind(i)):
				choice_buttons[i].pressed.disconnect(_on_choice_selected.bind(i))
			choice_buttons[i].pressed.connect(_on_choice_selected.bind(i))
		else:
			choice_buttons[i].visible = false

func _end_dialogue() -> void:
	is_dialogue_active = false
	can_advance_line = false
	current_node_id = ""
	dialogue_tree = {}
	text_box.visible = false
	text_box.hide_choices()
	name_container.visible = false
	
	if text_box.finished_displaying.is_connected(_on_text_box_finished_displaying):
		text_box.finished_displaying.disconnect(_on_text_box_finished_displaying)
	
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.enable_controls()
	game_clock.start_clock()
	dialogue_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("advance_dialogue") or not is_dialogue_active:
		return
	if is_preparing:
		return
	if text_box.choices_visible():
		return
	if not can_advance_line:
		text_box.skip_display()
		return
	var node = dialogue_tree["nodes"][current_node_id]
	if node.has("next"):
		current_node_id = node["next"]
		_show_node(current_node_id)

func _check_flag(flag: String) -> bool:
	return FlagManager.has_session_flag(flag) or FlagManager.has_event_flag(flag)

func _show_text_box() -> void:
	text_box.visible = true;

func _hide_text_box() -> void:
	text_box.visible = false


#####################
### CLOCK METHODS ###
#####################
func _get_day_hour() -> int:
	return game_clock.hour

func _get_day_minute() -> int:
	return game_clock.minute


########################
### MINIGAME METHODS ###
########################
func start_pipedream() -> void:
	PlayerManager.player.disable_controls()
	PlayerManager.set_prev_player_pos(PlayerManager.player.global_position)
	start_dialogue(PlayerManager.get_prev_player_pos(), pipedream_dialogue)
	await GlobalUI.dialogue_finished
	GlobalUI.game_clock.day_active = false
	SceneManager.fade_to_scene("res://scenes/minigames/pipedream/pipe_dream.tscn", "Minigame")
	pass

func start_mindcatch() -> void:
	PlayerManager.player.disable_controls()
	PlayerManager.set_prev_player_pos(PlayerManager.player.global_position)
	start_dialogue(PlayerManager.get_prev_player_pos(), mindcatch_dialogue)
	await GlobalUI.dialogue_finished
	GlobalUI.game_clock.day_active = false
	SceneManager.fade_to_scene("res://scenes/minigames/mindcatch/mind_catch.tscn", "Minigame")
	pass

func start_codewords() -> void:
	PlayerManager.player.disable_controls()
	PlayerManager.set_prev_player_pos(PlayerManager.player.global_position)
	start_dialogue(PlayerManager.get_prev_player_pos(), codewords_dialogue)
	await GlobalUI.dialogue_finished
	GlobalUI.game_clock.day_active = false
	SceneManager.fade_to_scene("res://scenes/minigame_codewords.tscn", "Minigame")
	pass
