extends Control

@onready var notes_edit = %TextEdit 
##hides notepad when game is run
func _ready():
	hide()

##when ctrl is pressed opens the panel
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_CTRL:
		visible = !visible
		if visible:
			notes_edit.grab_focus()
		else:
			notes_edit.release_focus()
