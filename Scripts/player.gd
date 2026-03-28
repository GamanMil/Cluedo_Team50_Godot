extends Resource
class_name Player

var player_id:    int             = 0
var player_name:  String          = ""
var suspect_name: String          = ""   
var hand:         Array[ClueCard] = []
var is_eliminated: bool           = false 
var is_human:     bool            = true  
var is_spare:     bool            = false 

func can_disprove(suspect_name_: String, weapon_name: String, room_name: String) -> bool:
	for card in hand:
		if card.card_name in [suspect_name_, weapon_name, room_name]:
			return true
	return false
