extends Control

@onready var notes_edit = %TextEdit 

func _ready():
	hide()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_CTRL:
		visible = !visible
		if visible:
			notes_edit.grab_focus()
		else:
			notes_edit.release_focus()
