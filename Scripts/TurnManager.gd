extends Node
class_name TurnManager

signal turn_started(player: Player)
signal phase_changed(new_phase: Phase)
signal dice_rolled(total: int, die1: int, die2: int)
signal move_required(steps: int)
signal suggestion_phase_started(current_room: String)
signal accusation_phase_started() 
signal turn_ended(player: Player)
signal game_over(winner: Player, was_correct: bool)

enum Phase { ROLL, MOVE, SUGGEST, ACCUSE, END_TURN }

var current_phase: Phase      = Phase.ROLL
var current_player_index: int = 0
var steps_remaining: int      = 0
var current_room: String      = ""
var game_manager: Node        = null
var board: Node               = null

##initializes references and starts the first turn with miss scarlett
func start_game(gm: Node, b: Node) -> void:
	game_manager = gm
	board        = b
	board.player_entered_room.connect(action_player_moved)
	board.player_entered_corridor.connect(_on_player_entered_corridor)
	current_player_index = _find_active_player_by_suspect("Miss Scarlett")
	_begin_turn()

##starts a new turn or skips if the player is eliminated or spare
func _begin_turn() -> void:
	var player = _current_player()
	if player.is_spare or player.is_eliminated:
		_advance_to_next_player()
		return
	_set_phase(Phase.ROLL)
	emit_signal("turn_started", player)

##calculates a random dice roll and triggers the movement phase
func action_roll_dice() -> void:
	if current_phase != Phase.ROLL:
		push_warning("TurnManager: action_roll_dice called outside ROLL phase")
		return
	var die1        = randi_range(1, 6)
	var die2        = randi_range(1, 6)
	var total       = die1 + die2
	steps_remaining = total
	emit_signal("dice_rolled", total, die1, die2)
	_set_phase(Phase.MOVE)
	emit_signal("move_required", steps_remaining)
	if board != null:
		board.highlight_reachable_cells(_current_player().suspect_name, steps_remaining)

##transitions to the suggestion phase if the player enters a room
func action_player_moved(room_name: String) -> void:
	if current_phase != Phase.MOVE:
		push_warning("TurnManager: action_player_moved called outside MOVE phase")
		return
	current_room = room_name
	if current_room != "":
		_set_phase(Phase.SUGGEST)
		emit_signal("suggestion_phase_started", current_room)
	else:
		_end_turn()
	if current_room == "Center": 
		_set_phase(Phase.ACCUSE)
		emit_signal("accusation_phase_started")
	elif current_room != "":
		_set_phase(Phase.SUGGEST)
		emit_signal("suggestion_phase_started", current_room)
	else:
		_end_turn()

##ends the turn immediately if the player stops in a corridor
func _on_player_entered_corridor() -> void:
	if current_phase != Phase.MOVE:
		return
	current_room = ""
	_end_turn()

##teleports the player via secret passage and starts suggestion phase
func action_use_secret_passage() -> void:
	if current_phase != Phase.ROLL:
		push_warning("TurnManager: secret passage can only be used at the start of a turn")
		return
	if board == null:
		return
	var dest = board.get_secret_passage_destination(_current_player().suspect_name)
	if dest == "":
		push_warning("TurnManager: no secret passage available for %s" % _current_player().suspect_name)
		return
	board.use_secret_passage(_current_player().suspect_name)
	current_room = dest
	_set_phase(Phase.SUGGEST)
	emit_signal("suggestion_phase_started", current_room)

##initiates the disprove loop with the chosen suspect and weapon
func action_make_suggestion(suspect: ClueCard, weapon: ClueCard) -> void:
	if current_phase != Phase.SUGGEST:
		push_warning("TurnManager: action_make_suggestion called outside SUGGEST phase")
		return
	if suspect == null or weapon == null:
		_end_turn()
		return
	var room_card = game_manager.get_room_card_by_name(current_room)
	if room_card == null:
		push_error("TurnManager: Could not find room card for '%s'" % current_room)
		_end_turn()
		return
	game_manager.run_disprove_loop(_current_player(), suspect, weapon, room_card)

##concludes the suggestion phase and ends the player's turn
func finish_suggestion() -> void:
	_end_turn()

##checks the final accusation and ends the game or eliminates the player
func action_make_accusation(suspect: ClueCard, weapon: ClueCard, room: ClueCard) -> void:
	_set_phase(Phase.ACCUSE)
	var correct = game_manager.check_accusation(suspect, weapon, room)
	if correct:
		emit_signal("game_over", _current_player(), true)
	else:
		_current_player().is_eliminated = true
		emit_signal("game_over", _current_player(), false)
		_end_turn()

##signals the end of the current turn and advances to the next player
func _end_turn() -> void:
	_set_phase(Phase.END_TURN)
	emit_signal("turn_ended", _current_player())
	_advance_to_next_player()

##updates the current internal game phase and broadcasts the change
func _set_phase(phase: Phase) -> void:
	current_phase = phase
	emit_signal("phase_changed", phase)

##returns the player object whose turn is currently active
func _current_player() -> Player:
	return game_manager.players[current_player_index]

##finds the next valid player in the rotation or ends the game if none remain
func _advance_to_next_player() -> void:
	var checked := 0
	while checked < game_manager.players.size():
		current_player_index = (current_player_index + 1) % game_manager.players.size()
		checked += 1
		var p = _current_player()
		if not p.is_spare and not p.is_eliminated:
			_begin_turn()
			return
	emit_signal("game_over", null, false)

##locates the starting index based on the specified suspect name
func _find_active_player_by_suspect(suspect_name: String) -> int:
	for i in range(game_manager.players.size()):
		var p = game_manager.players[i]
		if p.suspect_name == suspect_name and not p.is_spare:
			return i
	for i in range(game_manager.players.size()):
		if not game_manager.players[i].is_spare:
			return i
	return 0

##converts the phase enum value into a readable string
func phase_name(phase: Phase) -> String:
	match phase:
		Phase.ROLL:     return "Roll Dice"
		Phase.MOVE:     return "Move"
		Phase.SUGGEST:  return "Make Suggestion"
		Phase.ACCUSE:   return "Accusation"
		Phase.END_TURN: return "End Turn"
	return "Unknown"
