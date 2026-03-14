extends Node2D

@onready var bg_music : AudioStreamPlayer2D = $BGMusic

func _ready() -> void:
	bg_music.play()
