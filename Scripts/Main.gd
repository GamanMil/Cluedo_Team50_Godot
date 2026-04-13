extends Node

@onready var game_manager = $GameManager
@onready var turn_manager = $TurnManager
@onready var board        = $test_board

func _ready() -> void:
	board.setup_board(game_manager.players)
	turn_manager.start_game(game_manager, board)
