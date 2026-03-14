extends Node

const PLAYER = preload("res://scenes/main_character.tscn")

var player : Player
var player_spawned : bool = false
var level_node : Node2D


func _ready() -> void:
	add_player_instance()


func add_player_instance() -> void:
	player = PLAYER.instantiate()
	#add_child(player)
	pass


func set_player_postion(spawn_node : Node2D, _new_pos : Vector2) -> void:
	player.global_position = _new_pos
	spawn_node.add_child.call_deferred(player)
	pass
