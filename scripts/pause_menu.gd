extends Node

@onready var save_button = $VBoxContainer/Save
@onready var load_button = $VBoxContainer/Load
@onready var exit_button = $VBoxContainer/Exit

const SAVE_PATH = "user://save.sav"

var current_save : Dictionary = {
	scene_path = "",
	player = {
		inventory = {},
		pos_x = 0,
		pos_y = 0,
		day = "",
		time_hour = 0,
		time_min = 0 
	}
}
var player = null
var is_paused : bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not player:
			player = get_tree().get_first_node_in_group("Player")
		
		if not is_paused:
			show_pause_menu()
		else:
			hide_pause_menu()
		get_viewport().set_input_as_handled()

func show_pause_menu():
	is_paused = true
	player.disable_controls()
	self.visible = true
	save_button.grab_focus()
	pass

func hide_pause_menu():
	is_paused = false
	SceneManager.day_active = true
	player.enable_controls()
	self.visible = false
	pass

func _on_save_pressed() -> void:
	if is_paused == false:
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var save_json = JSON.stringify(current_save)
	file.store_line(save_json)
	file.flush()
	
	print("GAME SAVED")
	print("Saved to: ", ProjectSettings.globalize_path(SAVE_PATH))
	
	hide_pause_menu()

func _on_load_pressed() -> void:
	if is_paused == false:
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dict : Dictionary = json.get_data() as Dictionary
	current_save = save_dict
	
	# Load scene from scene path
	# Set player position from pos_x, pos_y
	# Set day and time
	# Set night/day cycle from time
	
	hide_pause_menu()


func _on_exit_pressed() -> void:
	get_tree().quit()
