extends Node2D
class_name Board


signal player_entered_room(room_name: String)
signal player_entered_corridor()

const COLS      = 24
const ROWS      = 25
const CELL_SIZE = 32


const COLOR_ROOM        = Color(0.75, 0.65, 0.45)   # tan
const COLOR_CORRIDOR    = Color(0.92, 0.88, 0.78)   # light cream
const COLOR_WALL        = Color(0.15, 0.12, 0.10)   # near black
const COLOR_HIGHLIGHT   = Color(0.3,  0.8,  0.3, 0.5) # translucent green
const COLOR_ROOM_LABEL  = Color(0.1,  0.1,  0.1)
const COLOR_DOOR        = Color(0.6,  0.35, 0.1)    # brown door marker

const STARTING_CELLS: Dictionary = {
	"Miss Scarlett": Vector2i(7,  24),
	"Col Mustard":   Vector2i(14, 24),
	"Prof Plum":     Vector2i(23, 19),
	"Rev Green":     Vector2i(23, 6),
	"Mrs Peacock":   Vector2i(6,  1),
	"Mrs White":     Vector2i(0,  9)
}

const TOKEN_COLORS: Dictionary = {
	"Miss Scarlett": Color(0.85, 0.1,  0.1),
	"Col Mustard":   Color(0.85, 0.75, 0.1),
	"Prof Plum":     Color(0.55, 0.1,  0.75),
	"Rev Green":     Color(0.1,  0.65, 0.2),
	"Mrs Peacock":   Color(0.1,  0.3,  0.85),
	"Mrs White":     Color(0.9,  0.9,  0.9)
}

var rooms: Dictionary = {}                   
var tokens: Dictionary = {}                  
var _room_cells: Dictionary = {}              
var _highlighted_cells: Array[Vector2i] = []
var _active_token: BoardToken = null

func _ready() -> void:
	_define_rooms()
	_build_room_cell_lookup()

func setup_board(players: Array) -> void:
	_spawn_tokens(players)
	queue_redraw()

func _define_rooms() -> void:
	_add_room("Kitchen",       _rect(0,0,5,5),        [Vector2i(4,6), Vector2i(6,3)],            "Study")
	_add_room("Ballroom",      _rect(8,0,15,6),        [Vector2i(7,5), Vector2i(9,6), Vector2i(14,6), Vector2i(16,5)], "")
	_add_room("Conservatory",  _rect(18,0,23,5),       [Vector2i(18,6)],                          "Lounge")
	_add_room("Billiard Room", _rect(18,8,23,14),      [Vector2i(17,9), Vector2i(22,14)],         "")
	_add_room("Dining Room",   _rect(18,16,23,22),     [Vector2i(17,17), Vector2i(20,22)],        "")
	_add_room("Library",       _rect(15,16,21,20),     [Vector2i(17,15), Vector2i(14,18)],        "")
	_add_room("Study",         _rect(0,7,5,11),        [Vector2i(6,9)],                           "Kitchen")
	_add_room("Hall",          _rect(0,15,5,23),       [Vector2i(5,15), Vector2i(5,19)],          "")
	_add_room("Lounge",        _rect(8,18,15,24),      [Vector2i(8,17), Vector2i(13,17)],         "Conservatory")

func _add_room(name: String, cells: Array[Vector2i], doors: Array[Vector2i], passage_to: String) -> void:
	var r               = RoomData.new()
	r.room_name         = name
	r.cells             = cells
	r.door_cells        = doors
	r.secret_passage_to = passage_to
	rooms[name]         = r

func _rect(x1: int, y1: int, x2: int, y2: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(y1, y2 + 1):
		for x in range(x1, x2 + 1):
			cells.append(Vector2i(x, y))
	return cells

func _build_room_cell_lookup() -> void:
	_room_cells.clear()
	for room in rooms.values():
		for cell in room.cells:
			_room_cells[cell] = room.room_name

func _draw() -> void:
	_draw_grid()
	_draw_highlights()
	_draw_room_labels()
	_draw_doors()

func _draw_grid() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var cell = Vector2i(col, row)
			var rect = _cell_rect(cell)
			var color = COLOR_ROOM if _room_cells.has(cell) else COLOR_CORRIDOR
			draw_rect(rect, color)
			draw_rect(rect, COLOR_WALL, false, 0.5)  

func _draw_highlights() -> void:
	for cell in _highlighted_cells:
		draw_rect(_cell_rect(cell), COLOR_HIGHLIGHT)

func _draw_room_labels() -> void:
	var font = ThemeDB.fallback_font
	for room in rooms.values():
		var centre = room.centre_cell()
		var pos    = _cell_to_world(centre) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		var parts = room.room_name.split(" ")
		if parts.size() == 1:
			draw_string(font, pos + Vector2(-CELL_SIZE * 0.9, 4), room.room_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_ROOM_LABEL)
		else:
			var line1 = parts[0]
			var line2 = " ".join(parts.slice(1))
			draw_string(font, pos + Vector2(-CELL_SIZE * 0.9, -3), line1,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_ROOM_LABEL)
			draw_string(font, pos + Vector2(-CELL_SIZE * 0.9, 10), line2,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_ROOM_LABEL)

func _draw_doors() -> void:
	for room in rooms.values():
		for door_cell in room.door_cells:
			var rect = _cell_rect(door_cell)
			var inset = rect.grow(-3)
			draw_rect(inset, COLOR_DOOR)

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)

func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))

func map_to_local(cell: Vector2i) -> Vector2:
	return _cell_to_world(cell) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)

func _spawn_tokens(players: Array) -> void:
	for player in players:
		var token          = BoardToken.new()
		token.suspect_name = player.suspect_name
		token.set_color(TOKEN_COLORS.get(player.suspect_name, Color.GRAY))
		add_child(token)
		tokens[player.suspect_name] = token
		var start_cell = STARTING_CELLS.get(player.suspect_name, Vector2i(12, 12))
		token.move_to_cell(start_cell, "", self)

func highlight_reachable_cells(suspect_name: String, steps: int) -> void:
	_active_token = tokens.get(suspect_name, null)
	if _active_token == null:
		return
	_highlighted_cells = _get_reachable_cells(_active_token.current_cell, steps)
	queue_redraw()

func _clear_highlights() -> void:
	_highlighted_cells.clear()
	queue_redraw()

func _get_reachable_cells(from: Vector2i, steps: int) -> Array[Vector2i]:
	var visited:   Dictionary      = { from: true }
	var reachable: Array[Vector2i] = []
	var queue:     Array           = [[from, steps]]
	var occupied                   = _get_occupied_corridor_cells()

	while not queue.is_empty():
		var entry     = queue.pop_front()
		var cell: Vector2i = entry[0]
		var remaining: int = entry[1]

		var in_room = _room_cells.has(cell)
		if in_room and cell != from:
			reachable.append(cell)
			continue

		if remaining == 0:
			if not in_room:  
				reachable.append(cell)
			continue

		for nb in _orthogonal_neighbours(cell):
			if visited.has(nb):
				continue
			if not _is_walkable(nb):
				continue
			if not _room_cells.has(nb) and occupied.has(nb):
				continue  
			visited[nb] = true
			queue.append([nb, remaining - 1])

	return reachable

func _orthogonal_neighbours(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0), cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1), cell + Vector2i(0, -1)
	]

func _is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= COLS or cell.y < 0 or cell.y >= ROWS:
		return false
	return true

func _room_for_cell(cell: Vector2i) -> RoomData:
	var name = _room_cells.get(cell, "")
	if name == "":
		return null
	return rooms.get(name, null)

func _get_occupied_corridor_cells() -> Dictionary:
	var occupied: Dictionary = {}
	for token in tokens.values():
		if token.current_room == "":
			occupied[token.current_cell] = true
	return occupied

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _highlighted_cells.is_empty() or _active_token == null:
		return

	var clicked_cell = world_to_cell(get_local_mouse_position())
	if not clicked_cell in _highlighted_cells:
		return

	var room      = _room_for_cell(clicked_cell)
	var room_name = room.room_name if room != null else ""

	_active_token.move_to_cell(clicked_cell, room_name, self)
	_active_token = null
	_clear_highlights()

	if room_name != "":
		emit_signal("player_entered_room", room_name)
	else:
		emit_signal("player_entered_corridor")

func get_secret_passage_destination(suspect_name: String) -> String:
	var token = tokens.get(suspect_name, null)
	if token == null or token.current_room == "":
		return ""
	var room = rooms.get(token.current_room, null)
	return room.secret_passage_to if room != null else ""

func use_secret_passage(suspect_name: String) -> void:
	var dest_name = get_secret_passage_destination(suspect_name)
	if dest_name == "":
		return
	var dest_room = rooms.get(dest_name, null)
	if dest_room == null:
		return
	tokens[suspect_name].move_to_cell(dest_room.centre_cell(), dest_name, self)
	emit_signal("player_entered_room", dest_name)

func move_token_to_room(suspect_name: String, room_name: String) -> void:
	var token = tokens.get(suspect_name, null)
	var room  = rooms.get(room_name, null)
	if token == null or room == null:
		push_warning("Board: cannot move %s to %s" % [suspect_name, room_name])
		return
	token.move_to_cell(room.centre_cell(), room_name, self)
	queue_redraw()

func get_token_room(suspect_name: String) -> String:
	var token = tokens.get(suspect_name, null)
	return token.current_room if token != null else ""
