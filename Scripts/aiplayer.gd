extends Player
class_name AIPlayer

func choose_move(reachable_rooms: Array) -> String:
	if reachable_rooms.is_empty():
		return ""
	return reachable_rooms[randi() % reachable_rooms.size()]

func choose_suggestion(all_suspects: Array[ClueCard], all_weapons: Array[ClueCard]) -> Dictionary:
	var unknown_suspects = all_suspects.filter(func(c): return not _in_hand(c))
	var unknown_weapons  = all_weapons.filter(func(c): return not _in_hand(c))

	if unknown_suspects.is_empty(): unknown_suspects = all_suspects
	if unknown_weapons.is_empty():  unknown_weapons  = all_weapons

	return {
		"suspect": unknown_suspects[randi() % unknown_suspects.size()],
		"weapon":  unknown_weapons[randi()  % unknown_weapons.size()]
	}

func should_accuse(all_suspects: Array[ClueCard], all_weapons: Array[ClueCard], all_rooms: Array[ClueCard]) -> bool:
	var unknown_suspects = all_suspects.filter(func(c): return not _in_hand(c))
	var unknown_weapons  = all_weapons.filter(func(c): return not _in_hand(c))
	var unknown_rooms    = all_rooms.filter(func(c): return not _in_hand(c))
	return unknown_suspects.size() == 1 and unknown_weapons.size() == 1 and unknown_rooms.size() == 1

func choose_accusation(all_suspects: Array[ClueCard], all_weapons: Array[ClueCard], all_rooms: Array[ClueCard]) -> Dictionary:
	var unknown_suspects = all_suspects.filter(func(c): return not _in_hand(c))
	var unknown_weapons  = all_weapons.filter(func(c): return not _in_hand(c))
	var unknown_rooms    = all_rooms.filter(func(c): return not _in_hand(c))
	return {
		"suspect": unknown_suspects[0],
		"weapon":  unknown_weapons[0],
		"room":    unknown_rooms[0]
	}
	
func choose_card_to_show(matches: Array[ClueCard]) -> ClueCard:
	if matches.is_empty():
		return null
	return matches[randi() % matches.size()]


func _in_hand(card: ClueCard) -> bool:
	for c in hand:
		if c.card_name == card.card_name:
			return true
	return false
