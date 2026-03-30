extends VBoxContainer

const ALL_TYPES = [
	"straight_h", "straight_v",
	"elbow_ne", "elbow_es", "elbow_sw", "elbow_nw",
]
const ELBOW_FRAMES = preload("res://scenes/minigames/pipedream/elbow_frames.tres")
const STRAIGHT_FRAMES = preload("res://scenes/minigames/pipedream/straight_frames.tres")

var queue: Array = []
const QUEUE_SIZE: int = 5

@onready var slots: Array = [
	$TextureRect/MarginContainer/VBoxContainer/Control/Slot1,
	$TextureRect/MarginContainer/VBoxContainer/Control2/Slot2,
	$TextureRect/MarginContainer/VBoxContainer/Control3/Slot3,
	$TextureRect/MarginContainer/VBoxContainer/Control4/Slot4,
	$TextureRect/MarginContainer/VBoxContainer/Control5/Slot5,
]

func _ready() -> void:
	for i in QUEUE_SIZE:
		queue.append(_random_type())
	_update_display()

func peek() -> String:
	return queue[0]

func pop() -> String:
	var next = queue.pop_front()
	queue.append(_random_type())
	_update_display()
	return next

func _random_type() -> String:
	return ALL_TYPES[randi() % ALL_TYPES.size()]

func _update_display() -> void:
	for i in slots.size():
		var type = queue[i]
		var slot: AnimatedSprite2D = slots[i]

		if type.begins_with("elbow"):
			slot.sprite_frames = ELBOW_FRAMES
		else:
			slot.sprite_frames = STRAIGHT_FRAMES

		var anim = "idle" if slot.sprite_frames.has_animation("idle") else slot.sprite_frames.get_animation_names()[0]
		slot.play(anim)

		var transforms = PipeData.ELBOW_TRANSFORMS if type.begins_with("elbow") else PipeData.STRAIGHT_TRANSFORMS
		var t = transforms.get(type, {})
		slot.rotation_degrees = t.get("rotation", 0.0)
		slot.flip_h = t.get("flip_h", false)
		slot.flip_v = t.get("flip_v", false)
		
		if i == 0:
			slots[i].modulate = Color(1.2, 1.2, 0.3)  # yellow tint
		else:
			slots[i].modulate = Color.WHITE
