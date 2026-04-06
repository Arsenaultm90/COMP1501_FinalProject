extends Area2D

@export var npc_id: String = ""
@export var npc_name: String = ""

func interact() -> void:
	var path = DialogueManager.get_dialogue(npc_id)
	if path == "":
		push_error(npc_name + " has no dialogue for current time")
		return
	GlobalUI.start_dialogue(global_position, path)
