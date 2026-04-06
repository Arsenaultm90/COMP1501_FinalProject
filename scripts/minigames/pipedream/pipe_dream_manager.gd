extends Node2D

enum Direction { NORTH, EAST, SOUTH, WEST }
const SUPPLY_ITEM = preload("res://scenes/minigames/pipedream/supply_item.tscn")
const GRID_WIDTH = 8
const GRID_HEIGHT = 6

var grid: Array = []
var path_history: Array = []
var flow_pos: Vector2i = Vector2i.ZERO
var flow_dir: int = Direction.EAST
var flow_timer: float = 0.0
var flow_interval: float = 4.0
var game_active: bool = false
var countdown: float = 10.0
var counting_down: bool = true
var score: int = 0
var item: Node = null
var item_path_index: int = 0 
var item_lerp_t: float = 0.0 
var current_level: int = 1
var stuck_frames: int = 0

var source_pos: Vector2i = Vector2i(0, 2)
var exit_pos: Vector2i = Vector2i(7, 3)

@onready var pipe_queue = $GameArea/HBoxContainer/QueuePanel
@onready var countdown_label = $GameArea/HBoxContainer/VBoxContainer/UI/CountdownLabel
@onready var score_label = $GameArea/HBoxContainer/VBoxContainer/UI/ScoreLabel
@onready var result_label = $GameArea/HBoxContainer/VBoxContainer/UI/ResultLabel
@onready var timer_bar = $GameArea/HBoxContainer/VBoxContainer/UI/TimerBar
@onready var grid_container: GridContainer = $GameArea/HBoxContainer/VBoxContainer/GridContainer
@onready var instructions : MarginContainer = $CanvasLayer/Instructions
@onready var canvas_layer : CanvasLayer = $CanvasLayer

func _ready() -> void:
	GlobalUI.hide_ui()
	GlobalUI.game_clock.pause_clock()
	if PlayerManager.pipe_dream_level == 1:
		instructions.visible = true
	else:
		_set_up_level()

func _build_grid_from_children() -> void:
	var cells = grid_container.get_children()
	grid = []
	for y in GRID_HEIGHT:
		var row = []
		for x in GRID_WIDTH:
			var cell = cells[y * GRID_WIDTH + x]
			cell.setup("empty", Vector2i(x, y))
			cell.cell_clicked.connect(_on_cell_clicked)
			row.append(cell)
		grid.append(row)

func _set_up_level() -> void:
	SceneManager.play_music("pipedream/BG_Music")
	current_level = PlayerManager.pipe_dream_level
	_build_grid_from_children()
	_apply_level(current_level)
	_mark_source_and_exit()
	result_label.visible = false
	timer_bar.max_value = 180.0
	timer_bar.value = 180.0

func _process(delta: float) -> void:
	if instructions.visible == true:
		return
	
	if counting_down:
		countdown -= delta
		countdown_label.text = "Flow starts in: " + str(ceil(countdown))
		if countdown <= 0:
			counting_down = false
			countdown_label.visible = false
			game_active = true
			flow_pos = source_pos
			_spawn_item()
		return

	if not game_active:
		return

	timer_bar.value -= delta
	if timer_bar.value <= 0:
		_end_game(false, "Time's up!")
		return

	if is_instance_valid(item) and item_path_index < path_history.size():
		item_lerp_t += delta / flow_interval
		var from_cell = _get_cell(path_history[max(0, item_path_index - 1)])
		var to_cell = _get_cell(path_history[item_path_index])
		item.global_position = from_cell.get_center().lerp(to_cell.get_center(), clamp(item_lerp_t, 0.0, 1.0))
		if item_lerp_t >= 1.0:
			item_lerp_t = 0.0
			item_path_index += 1

	flow_timer += delta
	if flow_timer >= flow_interval:
		flow_timer = 0.0
		_advance_flow()

func _input(_event: InputEvent) -> void:
	if instructions.visible == true and Input.is_action_pressed("pluck"):
		instructions.visible = false
		_set_up_level()
		

func _apply_level(level: int) -> void:
	var data = PipeData.LEVELS[level]
	flow_interval = data["flow_interval"]
	for pos in data["blocked_cells"]:
		_get_cell(pos).set_pipe_type("blocked")

func _mark_source_and_exit() -> void:
	_get_cell(source_pos).set_pipe_type("start")
	_get_cell(exit_pos).set_pipe_type("end")

func _on_cell_clicked(cell) -> void:
	if not game_active and not counting_down:
		return
	if cell.is_flowing:
		return
	if cell.pipe_type == "start" or cell.pipe_type == "end" or cell.pipe_type == "blocked":
		return
	var next_type = pipe_queue.pop()
	cell.set_pipe_type(next_type)

func _spawn_item() -> void:
	item = SUPPLY_ITEM.instantiate()
	grid_container.add_child(item)
	item.global_position = _get_cell(source_pos).get_center()

func _advance_flow() -> void:
	var current_cell = _get_cell(flow_pos)
	current_cell.start_flow()
	path_history.append(flow_pos)

	if flow_pos == exit_pos:
		await get_tree().create_timer(flow_interval).timeout
		score += 1
		score_label.text = "Deliveries: " + str(score)
		flow_pos = source_pos
		flow_dir = Direction.EAST
		item_path_index = 0
		item_lerp_t = 0.0
		path_history.clear()
		_end_game(true, "Product Delivered")

		return

	var opposite = _opposite_direction(flow_dir)
	var moved = false

	for direction in [Direction.NORTH, Direction.EAST, Direction.SOUTH, Direction.WEST]:
		if direction == opposite:
			continue
		if not current_cell.has_connection(direction):
			continue
		var next_pos = _pos_in_direction(flow_pos, direction)
		if not _is_valid_pos(next_pos):
			continue
		var next_cell = _get_cell(next_pos)
		if next_cell.has_connection(_opposite_direction(direction)):
			flow_pos = next_pos
			flow_dir = direction
			moved = true
			break
	
	if not moved:
		stuck_frames += 1
		if stuck_frames >= 2:
			_end_game(false, "Path blocked!")
	else:
		stuck_frames = 0

func _end_game(success: bool, reason: String) -> void:
	print("Sucess: ", success, " Reason: ", reason)
	game_active = false
	result_label.visible = true
	if success:
		if current_level < 3:
			PlayerManager.pipe_dream_level += 1
			result_label.text = "✓ Level " + str(current_level) + " complete!"
			result_label.modulate = Color.GREEN
			await get_tree().create_timer(2.5).timeout
			get_tree().reload_current_scene()
		else:
			PlayerManager.pipe_dream_level = 1
			result_label.text = "✓ All levels complete!"
			result_label.modulate = Color.GREEN
			await get_tree().create_timer(2.5).timeout
			GlobalUI.game_clock.start_clock()
			SceneManager.stop_music()
			DialogueManager.advance_time()
			PlayerManager.player_spawned = false
			SceneManager.fade_to_scene("res://scenes/outside.tscn", "")
	else:
		PlayerManager.pipe_dream_level = 1
		result_label.text = "✗ " + reason
		result_label.modulate = Color.RED
		await get_tree().create_timer(2.5).timeout
		PlayerManager.change_sanity(-2)
		GlobalUI.game_clock.start_clock()
		SceneManager.stop_music()
		DialogueManager.advance_time()
		PlayerManager.player_spawned = false
		SceneManager.fade_to_scene("res://scenes/outside.tscn", "")

func _get_cell(pos: Vector2i) -> TextureRect:
	return grid[pos.y][pos.x]

func _is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT

func _pos_in_direction(pos: Vector2i, direction: int) -> Vector2i:
	match direction:
		Direction.NORTH: return pos + Vector2i(0, -1)
		Direction.EAST:  return pos + Vector2i(1, 0)
		Direction.SOUTH: return pos + Vector2i(0, 1)
		Direction.WEST:  return pos + Vector2i(-1, 0)
	return pos

func _opposite_direction(direction: int) -> int:
	match direction:
		Direction.NORTH: return Direction.SOUTH
		Direction.SOUTH: return Direction.NORTH
		Direction.EAST:  return Direction.WEST
		Direction.WEST:  return Direction.EAST
	return direction
