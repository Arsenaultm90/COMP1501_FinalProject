extends ColorRect

signal word_missed(lane: int)

@onready var word_label: Label = $WordLabel

var lane: int = 0
var start_center: Vector2
var end_center: Vector2
var screen_height: float
var elapsed: float = 0.0
var fall_duration: float = 2.0
var falling: bool = false
var has_missed: bool = false
var beat_id: int = -1

const START_SCALE: float = 0.1
const END_SCALE: float = 1.0
const CODEWORDS = [
	"KANGAROO", "BEACHBALL", "LOLLIPOP",
	"CREEDENCE", "VITRIOL", "STAIRCASE",
	"NIRVANA", "STROLLER", "CALTROP",
	"CASCADE", "OPTICAL", "OVERMORROW",
	"GALLOP", "CUMMULUS", "PURPOSE"
]

func _ready():
	add_to_group("Words")
	screen_height = get_viewport_rect().size.y
	word_label.text = CODEWORDS[randi() % CODEWORDS.size()]

func setup(p_lane: int, p_start: Vector2, p_end: Vector2):
	lane = p_lane
	start_center = p_start
	end_center = p_end
	position = p_start
	size = Vector2(200, 60)
	scale = Vector2(START_SCALE, START_SCALE)

func start_fall():
	falling = true

func _process(delta):
	if not falling:
		return

	elapsed += delta
	var t = elapsed / fall_duration

	position = start_center.lerp(end_center, t)
	var s = lerp(START_SCALE, END_SCALE, t)
	scale = Vector2(s, s)
	
	if not has_missed and position.y > end_center.y + 50:
		has_missed = true
		word_missed.emit(beat_id)
	
	if position.y > screen_height + 100:
		queue_free()
