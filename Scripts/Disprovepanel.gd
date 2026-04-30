extends PanelContainer
signal card_shown(card_name: String)
@onready var prompt_label  = $VBox/PromptLabel
@onready var cards_vbox    = $VBox/CardsVBox
@onready var no_cards_label = $VBox/NoCardsLabel

var _buttons: Array = []

##hides the ui panel when it first enters the scene
func _ready() -> void:
	hide()

##displays matching cards as buttons or shows a brief message if none match
func show_for_player(player_name: String, matching_cards: Array) -> void:
	prompt_label.text = "%s — show one card:" % player_name

	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()

	if matching_cards.is_empty():
		no_cards_label.visible = true
		show()
		await get_tree().create_timer(1.5).timeout
		hide()
		emit_signal("card_shown", "")
		return

	no_cards_label.visible = false

	for card in matching_cards:
		var btn = Button.new()
		btn.text = card.card_name
		var card_name = card.card_name
		btn.pressed.connect(func(): _on_card_selected(card_name))
		cards_vbox.add_child(btn)
		_buttons.append(btn)

	show()

##hides the panel and broadcasts the chosen card back to the game
func _on_card_selected(card_name: String) -> void:
	hide()
	emit_signal("card_shown", card_name)
