extends Area2D

func interact() -> void:
		PlayerManager.set_prev_player_pos(PlayerManager.player.global_position)
		GlobalUI.game_clock.day_active = false
		SceneManager.fade_to_scene("res://scenes/minigame_codewords.tscn", "Outside")
