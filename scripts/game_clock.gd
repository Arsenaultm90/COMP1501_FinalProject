extends Label

signal time_changed(hour: int, minute: int)

var hour: int = 8
var minute: int = 0
var second_accumulator: float = 0.0
var day_active: bool = true


func _ready() -> void:
	update_time_label()


func _process(delta: float) -> void:
	if not day_active:
		return
	
	second_accumulator += delta
	
	### SET LOWER FOR TESTING
	if second_accumulator >= 0.1:
		second_accumulator -= 0.1
		minute += 1
		
		if minute >= 60:
			minute = 0
			hour += 1
			
			if hour >= 20:
				hour = 20
				minute = 0
				day_active = false
		
		time_changed.emit(hour, minute)
		update_time_label()


func update_time_label() -> void:
	var display_minute := int(minute / 10) * 10
	self.text = format_time(hour, display_minute)


func format_time(h: int, m: int) -> String:
	var suffix := "AM"
	var display_hour := h
	
	if h >= 12:
		suffix = "PM"
	
	if h == 0:
		display_hour = 12
	elif h > 12:
		display_hour = h - 12
	
	return "%02d:%02d %s" % [display_hour, m, suffix]
