extends CanvasModulate

@export var gradient: GradientTexture1D
@export var sunrise_curve: float = 0.8
@export var sunset_curve: float = 3.5

func _ready() -> void:
	GlobalUI.game_clock.time_changed.connect(update_from_time)
	update_from_time(GlobalUI._get_day_hour(), GlobalUI._get_day_minute())

func update_from_time(hour: int, minute: int) -> void:
	var start_minutes := 8 * 60
	var end_minutes := 20 * 60
	var current_minutes := hour * 60 + minute

	var day_progress := float(current_minutes - start_minutes) / float(end_minutes - start_minutes)
	day_progress = clamp(day_progress, 0.0, 1.0)

	var gradient_pos: float

	if day_progress <= 0.5:
		var morning_progress := day_progress / 0.5
		morning_progress = pow(morning_progress, sunrise_curve)
		gradient_pos = lerp(0.5, 1.0, morning_progress)
	else:
		var afternoon_progress := (day_progress - 0.5) / 0.5
		afternoon_progress = pow(afternoon_progress, sunset_curve)
		gradient_pos = lerp(1.0, 0.0, afternoon_progress)

	color = gradient.gradient.sample(gradient_pos)
