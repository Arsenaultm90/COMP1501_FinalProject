extends Node2D

@onready var bg_music : AudioStreamPlayer2D = $BGMusic

func _ready() -> void:
	bg_music.play()

func _on_new_game_pressed() -> void:
	# Initialize save file dictionary
	# Load first scene
	pass # Replace with function body.


func _on_load_game_pressed() -> void:
	# Show saved files
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()
