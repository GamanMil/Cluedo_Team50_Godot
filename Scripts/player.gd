extends Resource
class_name Player

var player_id:   int            = 0
var player_name: String         = ""
var hand:        Array[ClueCard] = []
var is_eliminated: bool         = false   # true if they made a wrong accusation

## Returns true if this player can disprove the given suggestion.
func can_disprove(suspect_name: String, weapon_name: String, room_name: String) -> bool:
	for card in hand:
		if card.card_name in [suspect_name, weapon_name, room_name]:
			return true
	return false
