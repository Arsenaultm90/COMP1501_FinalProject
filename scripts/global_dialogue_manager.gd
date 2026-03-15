extends Node

var dialogue_lines : Array[String] = []
var current_line_index : int = 0
var text_box
var text_box_pos : Vector2

var is_dialogue_active : bool = false
var can_advance_line : bool = false

func start_dialogue(position : Vector2, lines : Array[String]) -> void:
	if is_dialogue_active:
		return
	
	dialogue_lines = lines
	text_box_pos = position
	_show_text_box()
	
	is_dialogue_active = true

func _show_text_box() -> void:
	UiManager._show_text_box()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	text_box.global_position = text_box_pos
	text_box.display_text(dialogue_lines[current_line_index])
	can_advance_line = false
	
func _on_text_box_finished_displaying() -> void:
	can_advance_line = true

func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("advance_dialogue") && 
		is_dialogue_active && 
		can_advance_line
	):
		text_box.queue_free()
		
		current_line_index += 1
		if current_line_index >= dialogue_lines.size():
			is_dialogue_active = false
			current_line_index = 0
			UiManager._hide_text_box()
			var player = get_tree().get_first_node_in_group("Player")
			if player:
				player.enable_controls()
			return
		
		_show_text_box()
