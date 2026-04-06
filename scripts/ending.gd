extends Control

@onready var title_label: Label = $OuterMargin/InnerMargin/VBoxContainer/Title
@onready var body_label: Label = $OuterMargin/InnerMargin/VBoxContainer/Body
@onready var sprite: Sprite2D = $OuterMargin/InnerMargin/VBoxContainer/Control/Sprite2D

const ENDINGS = {
	"activation_success": {
		"title": "Asset Reactivated",
		"body": "The words settled into you like old furniture. You remembered everything — the training, the names, the mission. It felt like coming home.\n\nYou walked out of Siltwater the next morning without saying goodbye. You didn't need to.\n\nAgent Cid was back on the board.",
		"sprite": ""
	},
	"activation_broken": {
		"title": "Signal Lost",
		"body": "The words worked. But something didn't reconnect right.\n\nYou sat behind the counter for three more days before Rick called someone. By then you'd stopped answering to your name.\n\nThey found you a bench near the highway. You seemed happy enough.\n\nYou wave at cars sometimes.",
		"sprite": ""
	},
	"escape_frank": {
		"title": "Down the Unmarked Road",
		"body": "Frank's truck smelled like coffee and old newspapers. He didn't talk much for the first two hours, which suited you fine.\n\nEventually he turned on the radio. You watched the mountains disappear in the mirror.\n\nYou didn't know where you were going. For the first time in four years, that felt like enough.",
		"sprite": ""
	},
	"escape_woods": {
		"title": "Into the Tree Line",
		"body": "You ran. You don't remember deciding to.\n\nThe trees closed in fast and the town lights faded faster. Deputy Hayes filed a report in the morning.\n\nThird one in two years. Sheriff closed it inside a week.\n\nSaid you probably just moved on.",
		"sprite": ""
	},
	"bliss": {
		"title": "Just Another Day",
		"body": "You locked up at the usual time. Ruth waved from across the street. Earl tipped his hat.\n\nHarlow's car was gone by morning. You didn't notice.\n\nThe dreams got a little quieter after that. The town settled back into its routine.\n\nSo did you.",
		"sprite": ""
	}
}

func _ready() -> void:
	GlobalUI.hide_ui()
	GlobalUI.game_clock.pause_clock()
	var ending = _determine_ending()
	var data = ENDINGS[ending]
	title_label.text = data["title"]
	body_label.text = data["body"]
 	#sprite.texture = data["sprite"]

func _determine_ending() -> String:
	var sanity = PlayerManager.sanity
	
	# Activation path
	if FlagManager.has_event_flag("ending_activation_flag"):
		if sanity >= 60:
			return "activation_success"
		else:
			return "activation_broken"

	# Escape path
	if FlagManager.has_event_flag("ending_escape_frank"):
		return "escape_frank"

	# Bad escape - ran but no Frank
	if FlagManager.has_event_flag("cid_refused_escape") and FlagManager.has_event_flag("cid_choosing_escape"):
		return "escape_woods"

	# Default - bliss
	return "bliss"

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
