class_name PlayerData extends Resource

@export var flags: Dictionary = {}
@export var inventory: Dictionary = {}
@export var pos_x: float = 0
@export var pos_y: float = 0
@export var time_hour: int = 0
@export var time_min: int = 0
@export var scene_path: String = ""

func set_flag(key: String, value: bool) -> void:
	flags[key] = value

func get_flag(key: String) -> bool:
	return flags.get(key, false)
