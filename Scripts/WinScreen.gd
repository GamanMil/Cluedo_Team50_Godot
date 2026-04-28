extends PanelContainer

signal play_again

@onready var title_label   = $VBox/TitleLabel
@onready var message_label = $VBox/MessageLabel
@onready var again_button  = $VBox/AgainButton

func _ready() -> void:
	again_button.pressed.connect(func(): emit_signal("play_again"))
	hide()

func show_win(player_name: String, suspect: String, weapon: String, room: String) -> void:
	title_label.text   = "%s wins!" % player_name
	message_label.text = "The murder was committed by\n%s\nwith the %s\nin the %s" % [suspect, weapon, room]
	again_button.text  = "Play Again"
	show()

func show_loss(player_name: String) -> void:
	title_label.text   = "%s is eliminated!" % player_name
	message_label.text = "Wrong accusation.\nThey can no longer take turns\nbut must still show cards when asked."
	again_button.text  = "OK"
	show()

func show_no_winner() -> void:
	title_label.text   = "Nobody won!"
	message_label.text = "All players have been eliminated."
	again_button.text  = "Play Again"
	show()
