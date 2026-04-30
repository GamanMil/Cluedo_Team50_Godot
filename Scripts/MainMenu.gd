extends Control

##starts a new game against computer controlled ai opponents
func _on_button_pressed() -> void:
	GameState.play_mode = GameState.PLAY_VS_AI
	get_tree().change_scene_to_file("res://Scenes/test_board.tscn")

##starts a new local multiplayer game with human players
func _on_button_2_pressed() -> void:
	GameState.play_mode = GameState.PLAY_WITH_PEOPLE
	get_tree().change_scene_to_file("res://Scenes/test_board.tscn")
