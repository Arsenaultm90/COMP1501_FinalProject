extends Label

var float_speed = 40.0
var fade_speed = 0.5

func _process(delta):
	position.y -= float_speed * delta
	position.x += float_speed * delta
	modulate.a -= fade_speed * delta
	
	if modulate.a <= 0:
		queue_free()
