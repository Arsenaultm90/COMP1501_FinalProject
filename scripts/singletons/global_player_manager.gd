extends Node

const PLAYER = preload("res://scenes/main_character.tscn")
const SAVE_PATH = "user://save.sav"

var current_save: Dictionary = {
	scene_path = "",
	player = {
		inventory = {},
		pos_x = 0,
		pos_y = 0,
		day = "",
		time_hour = 0,
		time_min = 0
	},
	flags = {}
}
var player: Player
var player_spawned: bool = false
var level_node: Node2D
var intro_played: bool = false
var data: PlayerData = PlayerData.new()
var prev_player_pos: Vector2
var pipe_dream_level: int = 1
var sanity: int = 10

func add_player_instance() -> void:
	player = PLAYER.instantiate()
	pass

func set_player_postion(_new_pos: Vector2) -> void:
	if not is_instance_valid(player):
		add_player_instance()
	
	if player.get_parent() != null:
		player.get_parent().remove_child(player)
	
	var target_scene = get_tree().current_scene
	call_deferred("_deferred_add_to_scene", target_scene, _new_pos)

func _deferred_add_to_scene(target_scene: Node, _pos: Vector2) -> void:
	if not is_instance_valid(target_scene):
		print("Target scene invalid!")
		return
	if not is_instance_valid(player):
		print("Player invalid!")
		return
	target_scene.add_child(player)
	player.global_position = _pos
	print("Player added to: ", target_scene.name, " at: ", player.global_position)

func set_prev_player_pos(player_pos: Vector2) -> void:
	prev_player_pos = player_pos

func get_prev_player_pos() -> Vector2:
	return prev_player_pos

### SAVE/LOAD FUNCTIONS
func set_flag(key: String, value: bool) -> void:
	current_save["flags"][key] = value

func get_flag(key: String) -> bool:
	return current_save["flags"].get(key, false)

func save() -> void:
	ResourceSaver.save(data, SAVE_PATH)
	print("GAME SAVED")

func load_save() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		data = ResourceLoader.load(SAVE_PATH)
	else:
		data = PlayerData.new()
	if not data.flags is Dictionary:
		data.flags = {}

func change_sanity(amount: int) -> void:
	sanity += amount
