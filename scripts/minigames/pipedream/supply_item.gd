extends Area2D

func slide_to(target_pos: Vector2, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, duration)
	await tween.finished
