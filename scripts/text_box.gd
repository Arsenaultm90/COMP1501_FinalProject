extends MarginContainer

@onready var label = $MarginContainer/DialogueLabel
@onready var timer = $LetterDisplayTimer

const MAX_WIDTH = 512

var text = ""
var letter_index = 0
var letter_time = 0.03
var space_time = 0.06
var punctuation_time = 0.2

signal finished_displaying()

func prepare_text(text_to_display: String) -> void:
	text = ""
	timer.stop()
	
	# Hide text box to avoid flickering
	modulate.a = 0.0
	
	# Reset text box size and await flush before setting label text
	custom_minimum_size = Vector2.ZERO
	label.text = ""
	await get_tree().process_frame
	await get_tree().process_frame
	
	size = Vector2.ZERO
	label.text = text_to_display
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	custom_minimum_size.x = min(size.x, MAX_WIDTH)

	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await get_tree().process_frame
		await get_tree().process_frame
		custom_minimum_size.y = size.y

	await get_tree().process_frame
	label.text = ""
	
	modulate.a = 1.0


func start_display(text_to_display: String) -> void:
	text = text_to_display
	letter_index = 0
	label.text = ""
	_display_letter()


func _display_letter() -> void:
	label.text += text[letter_index]
	
	letter_index += 1
	if letter_index >= text.length():
		finished_displaying.emit()
		return
	
	match text[letter_index]:
		"!", ".",",","?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)


func skip_display() -> void:
	timer.stop()
	label.text = text
	letter_index = text.length()
	finished_displaying.emit()


func _on_letter_display_timer_timeout() -> void:
	_display_letter()
