extends Node

enum TimeOfDay { MORNING, NOON, NIGHT }
var current_time: TimeOfDay = TimeOfDay.MORNING

const DIALOGUE_PATHS = {
	"earl": {
		TimeOfDay.MORNING: "res://data/dialogue/earl/earl_morning.json",
		TimeOfDay.NOON:    "res://data/dialogue/earl/earl_noon.json",
		TimeOfDay.NIGHT:   "res://data/dialogue/earl/earl_night.json",
	},
	"frank": {
		TimeOfDay.MORNING: "res://data/dialogue/frank/frank_morning.json",
		TimeOfDay.NOON:    "res://data/dialogue/frank/frank_noon.json",
		TimeOfDay.NIGHT:   "res://data/dialogue/frank/frank_night.json",
	},
	"hayes": {
		TimeOfDay.MORNING: "res://data/dialogue/hayes/hayes_morning.json",
		TimeOfDay.NOON:    "res://data/dialogue/hayes/hayes_noon.json",
		TimeOfDay.NIGHT:   "res://data/dialogue/hayes/hayes_night.json",
	},
	"rick": {
		TimeOfDay.MORNING: "res://data/dialogue/rick/rick_morning.json",
		TimeOfDay.NOON:    "res://data/dialogue/rick/rick_noon.json",
		TimeOfDay.NIGHT:   "res://data/dialogue/rick/rick_night.json",
	},
	"ruth": {
		TimeOfDay.MORNING: "res://data/dialogue/ruth/ruth_morning.json",
		TimeOfDay.NOON:    "res://data/dialogue/ruth/ruth_noon.json",
		TimeOfDay.NIGHT:   "res://data/dialogue/ruth/ruth_night.json",
	},
	"harlow": {
		TimeOfDay.MORNING: "",
		TimeOfDay.NOON:    "res://data/dialogue/agent_harlow/harlow_noon.json",
		TimeOfDay.NIGHT:   "res://data/dialogue/agent_harlow/harlow_night.json",
	},
}

var dialogue_lines : Array[String] = []
var current_line_index : int = 0
var text_box_pos : Vector2
var custom_text_box = null

var is_dialogue_active : bool = false
var can_advance_line : bool = false

func start_dialogue(position : Vector2, lines : Array[String],text_box = null) -> void:
	if is_dialogue_active:
		return
	
	custom_text_box = text_box
	dialogue_lines = lines
	text_box_pos = position
	_show_text_box()
	
	is_dialogue_active = true

func _get_text_box():
	return custom_text_box if custom_text_box else GlobalUI.text_box

func _show_text_box() -> void:
	GlobalUI._show_text_box()
	
	if not GlobalUI.text_box.finished_displaying.is_connected(_on_text_box_finished_displaying):
		GlobalUI.text_box.finished_displaying.connect(_on_text_box_finished_displaying)
		
	var screen_pos = get_viewport().get_canvas_transform() * text_box_pos
	GlobalUI.text_box.position = screen_pos
	await GlobalUI.text_box.display_text(dialogue_lines[current_line_index], screen_pos)
	can_advance_line = false
	
func _on_text_box_finished_displaying() -> void:
	can_advance_line = true

func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("advance_dialogue") && 
		is_dialogue_active && 
		can_advance_line
	):
		GlobalUI._hide_text_box()
		
		current_line_index += 1
		if current_line_index >= dialogue_lines.size():
			is_dialogue_active = false
			current_line_index = 0
			GlobalUI._hide_text_box()
			var player = get_tree().get_first_node_in_group("Player")
			if player:
				player.enable_controls()
			return
		
		_show_text_box()

func get_dialogue(npc_id: String) -> String:
	return DIALOGUE_PATHS.get(npc_id, {}).get(current_time, "")

func advance_time() -> void:
	current_time = (current_time + 1) as TimeOfDay
