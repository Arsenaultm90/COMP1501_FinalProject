extends Area2D

@export var dialogue : DialogueResource
@export var npc_name: String = ""

func interact() -> void:
	if not dialogue or dialogue.path == "":
		push_error(npc_name + " has no dialogue assigned")
		return
	GlobalUI.start_dialogue(global_position, dialogue.path)
