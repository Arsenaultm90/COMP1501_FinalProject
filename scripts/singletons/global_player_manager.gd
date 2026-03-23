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
var player : Player
var player_spawned : bool = false
var level_node : Node2D
var data: PlayerData = PlayerData.new()


func _ready() -> void:
	add_player_instance()


func add_player_instance() -> void:
	player = PLAYER.instantiate()
	pass


func set_player_postion(spawn_node : Node2D, _new_pos : Vector2) -> void:
	if not is_instance_valid(player):
		add_player_instance()

	if player.get_parent() != null:
		player.get_parent().remove_child(player)
		
	player.global_position = _new_pos
	spawn_node.add_child.call_deferred(player)
	pass


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
