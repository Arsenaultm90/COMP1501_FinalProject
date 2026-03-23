extends Node

@onready var save_button = $VBoxContainer/Save
@onready var load_button = $VBoxContainer/Load
@onready var exit_button = $VBoxContainer/Exit

var player = null
var is_paused: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not player:
			player = get_tree().get_first_node_in_group("Player")
		if not is_paused:
			show_pause_menu()
		else:
			hide_pause_menu()
		get_viewport().set_input_as_handled()

func show_pause_menu() -> void:
	is_paused = true
	player.disable_controls()
	self.visible = true

func hide_pause_menu() -> void:
	is_paused = false
	SceneManager.day_active = true
	player.enable_controls()
	self.visible = false

func _on_save_pressed() -> void:
	if not is_paused:
		return
	PlayerManager.save()
	hide_pause_menu()

func _on_load_pressed() -> void:
	if not is_paused:
		return
	PlayerManager.load_save()
	hide_pause_menu()

func _on_exit_pressed() -> void:
	get_tree().quit()
