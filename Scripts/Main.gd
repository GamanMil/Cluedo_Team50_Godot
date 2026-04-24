extends Node2D

@onready var game_manager = $GameManager
@onready var turn_manager = $TurnManager
@onready var board        = $test_board
@onready var roll_button  = $UI/Button
@onready var hud          = $UI/HUD
@onready var suggestion_panel = $UI/SuggestionPanel

func _ready() -> void:
	var data = game_manager._load_data("res://Resources/clue_data.json")
	game_manager._generate_all_cards(data)
	game_manager.setup_game(3, 0)

	roll_button.pressed.connect(turn_manager.action_roll_dice)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.phase_changed.connect(_on_phase_changed)
	turn_manager.dice_rolled.connect(_on_dice_rolled)
	roll_button.visible = false

	board.setup_board(game_manager.players)
	turn_manager.start_game(game_manager, board)
	suggestion_panel.populate(game_manager.all_suspect_cards, game_manager.all_weapon_cards)
	turn_manager.suggestion_phase_started.connect(_on_suggestion_phase_started)
	suggestion_panel.suggestion_confirmed.connect(_on_suggestion_confirmed)
	suggestion_panel.suggestion_skipped.connect(_on_suggestion_skipped)

func _on_suggestion_phase_started(room_name: String) -> void:
	hud.text = "Make a suggestion — you are in the %s" % room_name
	suggestion_panel.show_for_room(room_name)

func _on_suggestion_confirmed(suspect_name: String, weapon_name: String) -> void:
	var suspect = game_manager.get_suspect_card_by_name(suspect_name)
	var weapon  = game_manager.get_weapon_card_by_name(weapon_name)
	turn_manager.action_make_suggestion(suspect, weapon)

func _on_suggestion_skipped() -> void:
	turn_manager.action_make_suggestion(null, null)
	
func _on_turn_started(player) -> void:
	hud.text = "%s's turn" % player.player_name
	roll_button.visible = true

func _on_phase_changed(phase) -> void:
	match phase:
		TurnManager.Phase.ROLL:
			roll_button.visible = true
		TurnManager.Phase.MOVE:
			roll_button.visible = false
			hud.text = hud.text + " — click a highlighted cell to move"
			print("Highlights set: ", board._highlighted_cells.size())
		TurnManager.Phase.SUGGEST:
			hud.text = hud.text + " — in " + turn_manager.current_room
		TurnManager.Phase.END_TURN:
			roll_button.visible = false

func _on_dice_rolled(total, die1, die2) -> void:
	hud.text = hud.text + " — rolled %d + %d = %d" % [die1, die2, total]
	print("Dice rolled, highlighting cells for: ", turn_manager._current_player().suspect_name)
	print("Highlighted cells: ", board._highlighted_cells.size())
