extends Area2D

func interact() -> void:
	GlobalUI.start_npc_dialogue(global_position, "res://data/dialogue/npc_test.json")
