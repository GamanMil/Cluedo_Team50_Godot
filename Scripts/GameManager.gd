extends Node

signal game_setup_complete
signal cards_dealt
const SECRET_PASSAGES: Dictionary = {
	"Study":        "Kitchen",
	"Kitchen":      "Study",
	"Conservatory": "Lounge",
	"Lounge":       "Conservatory"
}
var all_suspect_cards: Array[ClueCard] = []
var all_weapon_cards:  Array[ClueCard] = []
var all_room_cards:    Array[ClueCard] = []
var solution:          Dictionary = {} 
var players:           Array[Player] = []
var weapon_locations: Dictionary = {} 
var turn_manager_ref: Node = null

##loads game data from json and generates all clue cards
func _ready() -> void:
	var data = _load_data("res://Resources/clue_data.json")
	_generate_all_cards(data)

##reads and parses a json file from the given path
func _load_data(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	var json  = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	return json.data

#card gen
##creates card arrays for suspects, weapons, and rooms
func _generate_all_cards(data: Dictionary) -> void:
	all_suspect_cards = _make_cards(data["suspects"], ClueCard.CardType.SUSPECT)
	all_weapon_cards  = _make_cards(data["weapons"],  ClueCard.CardType.WEAPON)
	all_room_cards    = _make_cards(data["rooms"],    ClueCard.CardType.ROOM)

##instantiates clue card objects from a list of string names
func _make_cards(names: Array, type: ClueCard.CardType) -> Array[ClueCard]:
	var cards: Array[ClueCard] = []
	for card_name in names:
		var card       = ClueCard.new()
		card.card_name = card_name
		card.type      = type
		cards.append(card)
	return cards

#game set up
##initializes decks, picks the solution, creates players, and deals cards
func setup_game(player_count: int, ai_count: int = 0) -> void:
	var suspects_deck: Array[ClueCard] = _deep_copy_cards(all_suspect_cards)
	var weapons_deck:  Array[ClueCard] = _deep_copy_cards(all_weapon_cards)
	var rooms_deck:    Array[ClueCard] = _deep_copy_cards(all_room_cards)

	suspects_deck.shuffle()
	weapons_deck.shuffle()
	rooms_deck.shuffle()

	_pick_solution(suspects_deck, weapons_deck, rooms_deck)
	_place_weapons_in_rooms()

	var playing_deck: Array[ClueCard] = _build_playing_deck(suspects_deck, weapons_deck, rooms_deck)

	_create_players(player_count, ai_count)
	_deal_cards(playing_deck)

	emit_signal("game_setup_complete")

#helpers
##pops one random card of each type to form the murder solution
func _pick_solution(suspects: Array[ClueCard], weapons: Array[ClueCard], rooms: Array[ClueCard]) -> void:
	solution["suspect"] = suspects.pop_back()
	solution["weapon"]  = weapons.pop_back()
	solution["room"]    = rooms.pop_back()

##randomly assigns each weapon to a starting room
func _place_weapons_in_rooms() -> void:
	weapon_locations.clear()
	var room_names: Array = all_room_cards.map(func(c): return c.card_name)
	room_names.shuffle()
	for i in range(all_weapon_cards.size()):
		weapon_locations[all_weapon_cards[i].card_name] = room_names[i]

##combines and shuffles remaining cards into a single playing deck
func _build_playing_deck(suspects: Array[ClueCard], weapons: Array[ClueCard], rooms: Array[ClueCard]) -> Array[ClueCard]:
	var deck: Array[ClueCard] = []
	deck.append_array(suspects)
	deck.append_array(weapons)
	deck.append_array(rooms)
	deck.shuffle()
	return deck
	
##updates weapon location dictionary and triggers a board redraw
func move_weapon_to_room(weapon_name: String, room_name: String) -> void:
	if weapon_locations.has(weapon_name):
		weapon_locations[weapon_name] = room_name
		var board = get_node_or_null("/root/Main/test_board")
		if board:
			board.queue_redraw()
const AIPlayerScript = preload("res://Scripts/aiplayer.gd")

##instantiates human, ai, and spare players based on configuration
func _create_players(player_count: int, ai_count: int) -> void:
	players.clear()
	var total_suspects = all_suspect_cards.size()  # always 6

	for i in range(total_suspects):
		var suspect_card = all_suspect_cards[i]
		
		# Determine roles first
		var is_spare_val = false
		var is_human_val = false
		
		if i < player_count:
			is_spare_val = false
			is_human_val = (i >= player_count - ai_count) == false
		else:
			is_spare_val = true
			is_human_val = false

		var p
		if not is_spare_val and not is_human_val:
			p = AIPlayerScript.new()
		else:
			p = Player.new()

		p.player_id      = i
		p.suspect_name   = suspect_card.card_name
		p.player_name    = suspect_card.card_name 
		p.is_spare       = is_spare_val
		p.is_human       = is_human_val

		players.append(p)

##distributes the playing deck evenly among all active players
func _deal_cards(deck: Array[ClueCard]) -> void:
	var active = players.filter(func(p): return not p.is_spare)
	var index  := 0
	while deck.size() > 0:
		active[index].hand.append(deck.pop_back())
		index = (index + 1) % active.size()
	emit_signal("cards_dealt")

##creates a fresh copy of a card array to prevent reference issues
func _deep_copy_cards(source: Array[ClueCard]) -> Array[ClueCard]:
	var copy: Array[ClueCard] = []
	for card in source:
		var c      = ClueCard.new()
		c.card_name = card.card_name
		c.type      = card.type      
		copy.append(c)
	return copy

##finds and returns a room card object by its string name
func get_room_card_by_name(room_name: String) -> ClueCard:
	for card in all_room_cards:
		if card.card_name == room_name:
			return card
	return null
	
##compares a guessed suspect, weapon, and room against the true solution
func check_accusation(suspect: ClueCard, weapon: ClueCard, room: ClueCard) -> bool:
	return (
		suspect.card_name == solution["suspect"].card_name and
		weapon.card_name  == solution["weapon"].card_name  and
		room.card_name    == solution["room"].card_name
	)

##finds and returns a suspect card object by its string name
func get_suspect_card_by_name(suspect_name: String) -> ClueCard:
	for card in all_suspect_cards:
		if card.card_name == suspect_name:
			return card
	return null
	
##finds and returns a player object by their string name
func get_player_by_name(player_name: String) -> Player:
	for player in players:
		if player.player_name == player_name:
			return player
	return null
	
##finds and returns a weapon card object by its string name
func get_weapon_card_by_name(weapon_name: String) -> ClueCard:
	for card in all_weapon_cards:
		if card.card_name == weapon_name:
			return card
	return null

##checks a player's hand against the suggested cards and returns matches
func get_matching_cards(player: Player, suspect: ClueCard, weapon: ClueCard, room: ClueCard) -> Array[ClueCard]:
	var matches: Array[ClueCard] = []
	for card in player.hand:
		if card.card_name in [suspect.card_name, weapon.card_name, room.card_name]:
			matches.append(card)
	return matches

signal disprove_requested(player_name: String, matching_cards: Array)

##iterates through players to find who can disprove the current suggestion
func run_disprove_loop(suggesting_player: Player, suspect: ClueCard, weapon: ClueCard, room: ClueCard) -> void:
	var active  = players.filter(func(p): return not p.is_spare)
	var start   = active.find(suggesting_player)

	for i in range(1, active.size()):
		var player = active[(start + i) % active.size()]
		var matches = get_matching_cards(player, suspect, weapon, room)
		if matches.size() > 0 or true: 
			emit_signal("disprove_requested", player.player_name, matches)
			return 

	turn_manager_ref.finish_suggestion()
