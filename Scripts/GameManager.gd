extends Node

signal game_setup_complete
signal cards_dealt

const SUSPECTS = ["Miss Scarlett", "Colonel Mustard", "Mrs. White", "Mr. Green", "Mrs. Peacock", "Professor Plum"]
const WEAPONS  = ["Candlestick", "Dagger", "Lead Pipe", "Revolver", "Rope", "Wrench"]
const ROOMS    = ["Kitchen", "Ballroom", "Conservatory", "Dining Room", "Billiard Room", "Library", "Lounge", "Hall", "Study"]

var all_suspect_cards: Array[ClueCard] = []
var all_weapon_cards:  Array[ClueCard] = []
var all_room_cards:    Array[ClueCard] = []

var solution: Dictionary = {}   
var players:  Array[Player] = []

func _ready() -> void:
	_generate_all_cards()
	setup_game(3)

#card gen
func _generate_all_cards() -> void:
	all_suspect_cards = _make_cards(SUSPECTS, ClueCard.CardType.SUSPECT)
	all_weapon_cards  = _make_cards(WEAPONS,  ClueCard.CardType.WEAPON)
	all_room_cards    = _make_cards(ROOMS,    ClueCard.CardType.ROOM)

func _make_cards(names: Array, type: ClueCard.CardType) -> Array[ClueCard]:
	var cards: Array[ClueCard] = []
	for card_name in names:
		var card      = ClueCard.new()
		card.card_name = card_name
		card.type      = type
		cards.append(card)
	return cards

#game set up
func setup_game(player_count: int) -> void:
	var suspects_deck: Array[ClueCard] = _deep_copy_cards(all_suspect_cards)
	var weapons_deck:  Array[ClueCard] = _deep_copy_cards(all_weapon_cards)
	var rooms_deck:    Array[ClueCard] = _deep_copy_cards(all_room_cards)

	suspects_deck.shuffle()
	weapons_deck.shuffle()
	rooms_deck.shuffle()

	_pick_solution(suspects_deck, weapons_deck, rooms_deck)

	var playing_deck: Array[ClueCard] = _build_playing_deck(suspects_deck, weapons_deck, rooms_deck)

	_create_players(player_count)
	_deal_cards(playing_deck)

	emit_signal("game_setup_complete")

#helpers
func _pick_solution(suspects: Array[ClueCard], weapons: Array[ClueCard], rooms: Array[ClueCard]) -> void:
	solution["suspect"] = suspects.pop_back()
	solution["weapon"]  = weapons.pop_back()
	solution["room"]    = rooms.pop_back()

func _build_playing_deck(suspects: Array[ClueCard], weapons: Array[ClueCard], rooms: Array[ClueCard]) -> Array[ClueCard]:
	var deck: Array[ClueCard] = []
	deck.append_array(suspects)
	deck.append_array(weapons)
	deck.append_array(rooms)
	deck.shuffle()
	return deck

func _create_players(player_count: int) -> void:
	players.clear()
	for i in range(player_count):
		var p        = Player.new()
		p.player_id  = i
		p.player_name = "Player %d" % (i + 1)
		players.append(p)

func _deal_cards(deck: Array[ClueCard]) -> void:
	var index := 0
	while deck.size() > 0:
		players[index].hand.append(deck.pop_back())
		index = (index + 1) % players.size()
	emit_signal("cards_dealt")

func _deep_copy_cards(source: Array[ClueCard]) -> Array[ClueCard]:
	var copy: Array[ClueCard] = []
	for card in source:
		copy.append(card.duplicate())
	return copy

func check_accusation(suspect: ClueCard, weapon: ClueCard, room: ClueCard) -> bool:
	return (
		suspect.card_name == solution["suspect"].card_name and
		weapon.card_name  == solution["weapon"].card_name  and
		room.card_name    == solution["room"].card_name
	)

func get_matching_cards(player: Player, suspect: ClueCard, weapon: ClueCard, room: ClueCard) -> Array[ClueCard]:
	var matches: Array[ClueCard] = []
	for card in player.hand:
		if card.card_name in [suspect.card_name, weapon.card_name, room.card_name]:
			matches.append(card)
	return matches
