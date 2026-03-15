extends CanvasLayer

@onready var player_interact_label : Label = $PlayerInteractLabel
@onready var game_clock : Label = $GameClock
@onready var text_box : MarginContainer = $TextBox


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _show_text_box() -> void:
	text_box.visible = true;

func _hide_text_box() -> void:
	text_box.visible = false
