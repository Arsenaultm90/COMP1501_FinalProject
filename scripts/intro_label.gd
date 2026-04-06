extends Label

var fade_time: float = 1.0

func _ready() -> void:
	fade_out()

func fade_out() -> void:
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	
	await tween.finished
	
	fade_in()

func fade_in() -> void:
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 1.0, fade_time)
	
	await tween.finished
	
	fade_out()
