extends Node2D
class_name BoardToken

var suspect_name: String   = ""
var current_cell: Vector2i = Vector2i.ZERO
var current_room: String   = ""
var _color:  Color  = Color.WHITE
var _label:  String = ""

##extracts the first letter of the character's last name for the token label
func _ready() -> void:
	var parts = suspect_name.split(" ")
	_label = parts[parts.size() - 1].left(1) 

##renders the circular token graphic and text label on the screen
func _draw() -> void:
	draw_circle(Vector2.ZERO, 11, _color)
	draw_arc(Vector2.ZERO, 11, 0, TAU, 24, Color(0.1, 0.1, 0.1), 1.5)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-5, 5),
		_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color.BLACK
	)

##updates grid position and snaps the token's visual position to the board
func move_to_cell(cell: Vector2i, room_name: String, board: Node) -> void:
	current_cell = cell
	current_room = room_name
	position     = board.map_to_local(cell)
	queue_redraw()

##changes the token's fill color and queues a visual update
func set_color(color: Color) -> void:
	_color = color
	queue_redraw()
