extends CharacterBody2D

@export var arrival_hour: float = 9.0
@export var departure_hour: float = 17.0
@export var walk_path: Path2D

var active: bool = false

func _ready():
	#GameClock.time_updated.connect(_on_time_updated)
	pass

func _on_time_updated(hour: float):
	if hour >= arrival_hour and not active:
		arrive()
	elif hour >= departure_hour and active:
		depart()

func arrive():
	active = true
	visible = true
	follow_path()

func depart():
	active = false
	visible = false 

func follow_path():
	var tween = create_tween()
	tween.tween_property($PathFollow2D, "progress_ratio", 1.0, 5.0)
	tween.tween_callback(start_waiting)

func start_waiting():
	# Play idle animation, enable interaction
	$InteractionArea.monitorable= true
