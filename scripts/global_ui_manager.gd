extends CanvasLayer

@onready var player_interact_label : Label = $PlayerInteractLabel
@onready var game_clock : Label = $GameClock
@onready var text_box = $TextBox
@onready var dialogue_label = $TextBox/MarginContainer/DialogueLabel

const MAX_WIDTH = 512

var dialogue_lines: Array[String] = []
var current_line_index: int = 0
var text_box_pos: Vector2
var is_dialogue_active: bool = false
var can_advance_line: bool = false
var interact_label_target: Node2D = null


func _process(delta: float) -> void:
	if interact_label_target and player_interact_label.visible:
		var screen_pos = get_viewport().get_canvas_transform() * interact_label_target.global_position
		player_interact_label.position = Vector2(
			screen_pos.x - player_interact_label.size.x / 2.0,
			screen_pos.y - player_interact_label.size.y - 50.0
		)


func show_interact_label(target : Node2D) -> void:
	interact_label_target = target
	player_interact_label.visible = true

func hide_interact_label() -> void:
	player_interact_label.visible = false


########################
### DIALOGUE METHODS ###
########################
func start_dialogue(position : Vector2, lines : Array[String]) -> void:
	if is_dialogue_active:
		return
	
	is_dialogue_active = true
	dialogue_lines = lines
	text_box_pos = position
	if not text_box.finished_displaying.is_connected(_on_text_box_finished_displaying):
		text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	_show_next_line()


func _show_next_line() -> void:
	text_box.visible = true
	can_advance_line = false

	await text_box.prepare_text(dialogue_lines[current_line_index])

	var screen_pos = get_viewport().get_canvas_transform() * text_box_pos
	text_box.position = Vector2(
		screen_pos.x - text_box.size.x / 2.0,
		screen_pos.y - text_box.size.y - 24.0
	)
	
	text_box.start_display(dialogue_lines[current_line_index])


func _on_text_box_finished_displaying() -> void:
	can_advance_line = true


func _end_dialogue() -> void:
	is_dialogue_active = false
	can_advance_line = false
	current_line_index = 0
	text_box.visible = false

	if text_box.finished_displaying.is_connected(_on_text_box_finished_displaying):
		text_box.finished_displaying.disconnect(_on_text_box_finished_displaying)
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.enable_controls()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance_dialogue"):
		if is_dialogue_active and can_advance_line:
			current_line_index += 1
			if current_line_index >= dialogue_lines.size():
				_end_dialogue()
				return
			_show_next_line()


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
