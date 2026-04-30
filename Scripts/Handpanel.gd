extends PanelContainer

@onready var player_label  = $VBox/PlayerLabel
@onready var cards_hbox    = $VBox/CardsContainer/CardsHBox
@onready var cards_container = $VBox/CardsContainer

var _is_collapsed := false

func _ready() -> void:
	custom_minimum_size = Vector2(600, 140)
	hide()

func show_hand(player) -> void:
	player_label.text = "%s's cards" % player.player_name
	show()
	for child in cards_hbox.get_children():
		child.queue_free()
	for card in player.hand:
		var panel      = PanelContainer.new()
		var vbox       = VBoxContainer.new()
		var name_label = Label.new()
		var type_label = Label.new()

		name_label.text                    = card.card_name
		name_label.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode           = TextServer.AUTOWRAP_WORD
		name_label.custom_minimum_size     = Vector2(80, 0)

		type_label.text                    = _type_string(card.type)
		type_label.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER

		var style                          = StyleBoxFlat.new()
		style.bg_color                     = _card_color(card.type)
		style.corner_radius_top_left       = 6
		style.corner_radius_top_right      = 6
		style.corner_radius_bottom_left    = 6
		style.corner_radius_bottom_right   = 6
		style.content_margin_left          = 8
		style.content_margin_right         = 8
		style.content_margin_top           = 8
		style.content_margin_bottom        = 8
		panel.add_theme_stylebox_override("panel", style)
		panel.custom_minimum_size          = Vector2(85, 90)

		vbox.add_child(name_label)
		vbox.add_child(type_label)
		panel.add_child(vbox)
		cards_hbox.add_child(panel)
	cards_container.visible = not _is_collapsed
	show()


func hide_hand() -> void:
	hide()

func toggle_hand_visibility() -> void:
	_is_collapsed = not _is_collapsed
	if _is_collapsed:
		hide()
	else:
		show()

func _type_string(type) -> String:
	match type:
		ClueCard.CardType.SUSPECT: return "Suspect"
		ClueCard.CardType.WEAPON:  return "Weapon"
		ClueCard.CardType.ROOM:    return "Room"
	return ""

func _card_color(type) -> Color:
	match type:
		ClueCard.CardType.SUSPECT: return Color(0.70, 0.20, 0.20)
		ClueCard.CardType.WEAPON:  return Color(0.20, 0.40, 0.70)
		ClueCard.CardType.ROOM:    return Color(0.20, 0.55, 0.25)
	return Color(0.3, 0.3, 0.3)
