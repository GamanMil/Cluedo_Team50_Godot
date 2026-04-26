extends Node2D

@onready var game_manager = $GameManager
@onready var turn_manager = $TurnManager
@onready var board        = $test_board
@onready var roll_button  = $UI/Button
@onready var hud          = $UI/HUD
@onready var suggestion_panel = $UI/SuggestionPanel
@onready var disprove_panel = $UI/DisprovePanel
@onready var accusation_panel = $UI/AccusationPanel
@onready var accuse_button    = $UI/AccuseButton
@onready var hand_panel = $UI/HandPanel

func _ready() -> void:
	var data = game_manager._load_data("res://Resources/clue_data.json")
	game_manager._generate_all_cards(data)
	game_manager.setup_game(3, 0)
	
	game_manager.turn_manager_ref = turn_manager
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
	game_manager.turn_manager_ref = turn_manager
	game_manager.disprove_requested.connect(_on_disprove_requested)
	disprove_panel.card_shown.connect(_on_card_shown)
	accusation_panel.populate(
		game_manager.all_suspect_cards,
		game_manager.all_weapon_cards,
		game_manager.all_room_cards
	)
	accuse_button.pressed.connect(_on_accuse_button_pressed)
	accusation_panel.accusation_confirmed.connect(_on_accusation_confirmed)
	accusation_panel.accusation_cancelled.connect(_on_accusation_cancelled)
	accuse_button.visible = false
	turn_manager.game_over.connect(_on_game_over)


func _on_card_shown(card_name: String) -> void:
	if card_name != "":
		hud.text = "A card was shown privately"
	else:
		hud.text = "No card to show — passing..."
		turn_manager.finish_suggestion()
	
func _on_disprove_requested(player_name: String, matching_cards: Array) -> void:
	hud.text = "%s is disproving..." % player_name
	disprove_panel.show_for_player(player_name, matching_cards)
	
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
	hand_panel.show_hand(player)

func _on_phase_changed(phase) -> void:
	match phase:
		TurnManager.Phase.ROLL:
			roll_button.visible   = true
			accuse_button.visible = false
		TurnManager.Phase.MOVE:
			roll_button.visible   = false
			accuse_button.visible = false
			hud.text = hud.text + " — click a highlighted cell to move"
		TurnManager.Phase.SUGGEST:
			accuse_button.visible = true
		TurnManager.Phase.END_TURN:
			roll_button.visible   = false
			accuse_button.visible = false
			hand_panel.hide_hand() 

func _on_dice_rolled(total, die1, die2) -> void:
	hud.text = hud.text + " — rolled %d + %d = %d" % [die1, die2, total]
	print("Dice rolled, highlighting cells for: ", turn_manager._current_player().suspect_name)
	print("Highlighted cells: ", board._highlighted_cells.size())
	
func _on_accuse_button_pressed() -> void:
	accuse_button.visible = false
	suggestion_panel.hide()
	accusation_panel.show()

func _on_accusation_confirmed(suspect_name: String, weapon_name: String, room_name: String) -> void:
	var suspect = game_manager.get_suspect_card_by_name(suspect_name)
	var weapon  = game_manager.get_weapon_card_by_name(weapon_name)
	var room    = game_manager.get_room_card_by_name(room_name)
	turn_manager.action_make_accusation(suspect, weapon, room)
	
func _on_accusation_cancelled() -> void:
	accuse_button.visible = true
	if turn_manager.current_room != "":
		suggestion_panel.show_for_room(turn_manager.current_room)

func _on_game_over(winner, was_correct: bool) -> void:
	roll_button.visible   = false
	accuse_button.visible = false
	if winner == null:
		hud.text = "Nobody won — all players eliminated!"
	elif was_correct:
		hud.text = "%s solved the murder! Game over!" % winner.player_name
	else:
		hud.text = "%s made a wrong accusation and is eliminated!" % winner.player_name
