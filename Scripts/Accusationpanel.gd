extends PanelContainer

signal accusation_confirmed(suspect: String, weapon: String, room: String)
signal accusation_cancelled

@onready var suspect_option = $VBox/SuspectOption
@onready var weapon_option  = $VBox/WeaponOption
@onready var room_option    = $VBox/RoomOption
@onready var confirm_button = $VBox/Buttons/ConfirmButton
@onready var cancel_button  = $VBox/Buttons/CancelButton

var suspects: Array = []
var weapons:  Array = []
var rooms:    Array = []

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm)
	cancel_button.pressed.connect(_on_cancel)
	hide()

func populate(suspect_cards: Array, weapon_cards: Array, room_cards: Array) -> void:
	suspects = suspect_cards
	weapons  = weapon_cards
	rooms    = room_cards

	suspect_option.clear()
	for card in suspects:
		suspect_option.add_item(card.card_name)

	weapon_option.clear()
	for card in weapons:
		weapon_option.add_item(card.card_name)

	room_option.clear()
	for card in rooms:
		room_option.add_item(card.card_name)

func _on_confirm() -> void:
	var suspect = suspects[suspect_option.selected].card_name
	var weapon  = weapons[weapon_option.selected].card_name
	var room    = rooms[room_option.selected].card_name
	hide()
	emit_signal("accusation_confirmed", suspect, weapon, room)

func _on_cancel() -> void:
	hide()
	emit_signal("accusation_cancelled")
