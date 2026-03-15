extends Area2D

const LINES: Array[String] = [
	"Weird weather lately, huh?",
	"Don't often get visitors up here.",
	"Whoa buddy, too close."
]

func interact() -> void:
	GlobalUI.start_dialogue(global_position, LINES)
