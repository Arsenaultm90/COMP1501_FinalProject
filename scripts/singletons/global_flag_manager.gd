extends Node

var session_flags: Dictionary = {}
var event_flags: Dictionary = {}

# SESSION FLAGS
func set_session_flag(flag: String) -> void:
	session_flags[flag] = true

func clear_session_flag(flag: String) -> void:
	session_flags.erase(flag)

func has_session_flag(flag: String) -> bool:
	return session_flags.get(flag, false)

func clear_all_session_flags() -> void:
	session_flags.clear()

# EVENT FLAGS
func set_event_flag(flag: String) -> void:
	event_flags[flag] = true

func clear_event_flag(flag: String) -> void:
	event_flags.erase(flag)

func has_event_flag(flag: String) -> bool:
	return event_flags.get(flag, false)

# SAVE/LOAD
func save_flags() -> Dictionary:
	return event_flags.duplicate()

func load_flags(data: Dictionary) -> void:
	event_flags = data
