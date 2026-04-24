extends PanelContainer

signal suggestion_confirmed(suspect: String, weapon: String)
signal suggestion_skipped

@onready var room_label      = $VBox/RoomLabel
@onready var suspect_option  = $VBox/SuspectOption
@onready var weapon_option   = $VBox/WeaponOption
@onready var confirm_button  = $VBox/Buttons/ConfirmButton
@onready var skip_button     = $VBox/Buttons/SkipButton

var suspects: Array = []
var weapons: Array  = []

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm)
	skip_button.pressed.connect(_on_skip)
	hide()

func populate(suspect_cards: Array, weapon_cards: Array) -> void:
	suspects = suspect_cards
	weapons  = weapon_cards

	suspect_option.clear()
	for card in suspects:
		suspect_option.add_item(card.card_name)

	weapon_option.clear()
	for card in weapons:
		weapon_option.add_item(card.card_name)

func show_for_room(room_name: String) -> void:
	room_label.text = "Room: %s" % room_name
	show()

func _on_confirm() -> void:
	var suspect = suspects[suspect_option.selected].card_name
	var weapon  = weapons[weapon_option.selected].card_name
	hide()
	emit_signal("suggestion_confirmed", suspect, weapon)

func _on_skip() -> void:
	hide()
	emit_signal("suggestion_skipped")
