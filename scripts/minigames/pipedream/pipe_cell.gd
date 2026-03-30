extends TextureRect
signal cell_clicked(cell)

const EMPTY_TEXTURE = preload("res://art/minigames/pipedream/GridBG.png")
const ELBOW_FRAMES = preload("res://scenes/minigames/pipedream/elbow_frames.tres")
const STRAIGHT_FRAMES = preload("res://scenes/minigames/pipedream/straight_frames.tres")
const BLOCKED_TEXTURE = preload("res://art/minigames/pipedream/Blocked.png")
const START_BLOCK = preload("res://art/minigames/pipedream/Truck.png")
const END_BLOCK = preload("res://art/minigames/pipedream/End.png")

var pipe_type: String = "empty"
var connections: Array = []
var is_flowing: bool = false
var grid_pos: Vector2i = Vector2i.ZERO

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func setup(type: String, pos: Vector2i) -> void:
	grid_pos = pos
	set_pipe_type(type)

func set_pipe_type(type: String) -> void:
	pipe_type = type
	connections = PipeData.PIPE_CONNECTIONS[type].duplicate()
	modulate = Color.WHITE

	if type == "empty":
		texture = EMPTY_TEXTURE
		anim_sprite.visible = false
		anim_sprite.rotation_degrees = 0.0
		return

	if type == "blocked":
		texture = BLOCKED_TEXTURE
		anim_sprite.visible = false
		return
	
	if type == "start":
		texture = START_BLOCK
		anim_sprite.visible = false
		return
	
	if type == "end":
		texture = END_BLOCK
		anim_sprite.visible = false
		return
	
	texture = EMPTY_TEXTURE 
	anim_sprite.visible = true

	if type.begins_with("elbow"):
		anim_sprite.sprite_frames = ELBOW_FRAMES
	else:
		anim_sprite.sprite_frames = STRAIGHT_FRAMES

	anim_sprite.play("flow")

	var transforms = PipeData.ELBOW_TRANSFORMS if type.begins_with("elbow") else PipeData.STRAIGHT_TRANSFORMS
	var t = transforms.get(type, {})
	anim_sprite.rotation_degrees = t.get("rotation", 0.0)
	anim_sprite.flip_h = t.get("flip_h", false)
	anim_sprite.flip_v = t.get("flip_v", false)

func get_center() -> Vector2:
	return global_position + size / 2.0

func start_flow() -> void:
	is_flowing = true
	anim_sprite.modulate = Color.CYAN

func has_connection(direction: int) -> bool:
	return direction in connections

func _gui_input(event: InputEvent) -> void:
	if is_flowing or pipe_type == "blocked":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cell_clicked.emit(self)
		accept_event()
