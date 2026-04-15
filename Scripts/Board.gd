extends Node2D
class_name Board

signal player_entered_room(room_name: String)
signal player_entered_corridor()

const COLS      = 24
const ROWS      = 25
const CELL_SIZE = 32
const WALL_W    = 2.5

const COLOR_BG         = Color(0.18, 0.52, 0.18)
const COLOR_CORRIDOR   = Color(0.96, 0.82, 0.16)
const COLOR_WALL       = Color(0.08, 0.06, 0.05)
const COLOR_HIGHLIGHT  = Color(0.20, 0.95, 0.25, 0.50)
const COLOR_LABEL      = Color(0.96, 0.92, 0.80)
const COLOR_CENTRE_TXT = Color(0.10, 0.10, 0.10)

const ROOM_COLORS: Dictionary = {
	"Study":         Color(0.32, 0.20, 0.10),
	"Hall":          Color(0.64, 0.46, 0.24),
	"Lounge":        Color(0.42, 0.18, 0.50),
	"Library":       Color(0.26, 0.15, 0.08),
	"Dining Room":   Color(0.52, 0.22, 0.12),
	"Billiard Room": Color(0.10, 0.36, 0.14),
	"Conservatory":  Color(0.24, 0.48, 0.22),
	"Ballroom":      Color(0.54, 0.40, 0.28),
	"Kitchen":       Color(0.70, 0.68, 0.62),
}

const STARTING_CELLS: Dictionary = {
	"Miss Scarlett": Vector2i(7,  24),
	"Col Mustard":   Vector2i(17, 24),
	"Prof Plum":     Vector2i(23, 16),
	"Rev Green":     Vector2i(23,  7),
	"Mrs Peacock":   Vector2i(6,  22),
	"Mrs White":     Vector2i(0,  20),
}

const TOKEN_COLORS: Dictionary = {
	"Miss Scarlett": Color(0.85, 0.10, 0.10),
	"Col Mustard":   Color(0.85, 0.75, 0.10),
	"Prof Plum":     Color(0.55, 0.10, 0.75),
	"Rev Green":     Color(0.10, 0.65, 0.20),
	"Mrs Peacock":   Color(0.10, 0.30, 0.85),
	"Mrs White":     Color(0.92, 0.92, 0.92),
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
	_add_room("Study",
		_rect(0, 0, 5, 5),
		[Vector2i(6, 3), Vector2i(4, 6)],
		"Kitchen")

	_add_room("Hall",
		_rect(9, 0, 14, 7),
		[Vector2i(8, 4), Vector2i(11, 8), Vector2i(13, 8)],
		"")

	_add_room("Lounge",
		_rect(18, 0, 23, 5),
		[Vector2i(17, 3)],
		"Conservatory")

	_add_room("Library",
		_rect(0, 8, 5, 12),
		[Vector2i(6, 10), Vector2i(3, 7)],
		"")

	_add_room("Dining Room",
		_rect(17, 9, 23, 15),
		[Vector2i(16, 11), Vector2i(16, 14)],
		"")

	_add_room("Billiard Room",
		_rect(0, 14, 5, 19),
		[Vector2i(6, 16), Vector2i(3, 13)],
		"")

	_add_room("Conservatory",
		_rect(0, 21, 4, 24),
		[Vector2i(5, 22)],
		"Lounge")

	_add_room("Ballroom",
		_rect(8, 18, 15, 24),
		[Vector2i(7, 20), Vector2i(7, 17), Vector2i(14, 17)],
		"")

	_add_room("Kitchen",
		_rect(18, 18, 23, 24),
		[Vector2i(17, 20), Vector2i(20, 17)],
		"Study")

func _add_room(name: String, cells: Array[Vector2i], doors: Array[Vector2i], passage: String) -> void:
	var r               = RoomData.new()
	r.room_name         = name
	r.cells             = cells
	r.door_cells        = doors
	r.secret_passage_to = passage
	rooms[name]         = r

func _rect(x1: int, y1: int, x2: int, y2: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(y1, y2 + 1):
		for x in range(x1, x2 + 1):
			out.append(Vector2i(x, y))
	return out

func _build_room_cell_lookup() -> void:
	_room_cells.clear()
	for room in rooms.values():
		for cell in room.cells:
			_room_cells[cell] = room.room_name

func _draw() -> void:
	_draw_background()
	_draw_cells()
	_draw_room_outlines_and_doors()
	_draw_centre_marker()
	_draw_room_labels()
	_draw_highlights()

func _draw_background() -> void:
	var board_px = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	draw_rect(Rect2(Vector2.ZERO - Vector2(8, 8), board_px + Vector2(16, 16)), COLOR_BG)

func _draw_cells() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var cell  = Vector2i(col, row)
			var color = ROOM_COLORS.get(_room_cells.get(cell, ""), COLOR_CORRIDOR)
			draw_rect(_cell_rect(cell), color)

func _draw_room_outlines_and_doors() -> void:
	for room in rooms.values():
		var pr = _room_pixel_rect(room)
		draw_rect(pr, COLOR_WALL, false, WALL_W)
		var bounds = _room_cell_bounds(room)
		for door in room.door_cells:
			_draw_door_gap(bounds, pr, door)

func _draw_door_gap(bounds: Rect2i, pr: Rect2, door: Vector2i) -> void:
	var gap = WALL_W + 1
	if door.y < bounds.position.y:
		draw_rect(Rect2(door.x * CELL_SIZE, pr.position.y - gap, CELL_SIZE, gap * 2), COLOR_CORRIDOR)
	elif door.y >= bounds.position.y + bounds.size.y:
		draw_rect(Rect2(door.x * CELL_SIZE, pr.end.y - gap, CELL_SIZE, gap * 2), COLOR_CORRIDOR)
	elif door.x < bounds.position.x:
		draw_rect(Rect2(pr.position.x - gap, door.y * CELL_SIZE, gap * 2, CELL_SIZE), COLOR_CORRIDOR)
	elif door.x >= bounds.position.x + bounds.size.x:
		draw_rect(Rect2(pr.end.x - gap, door.y * CELL_SIZE, gap * 2, CELL_SIZE), COLOR_CORRIDOR)

func _draw_centre_marker() -> void:
	var centre = Vector2(11 * CELL_SIZE + CELL_SIZE * 0.5, 11 * CELL_SIZE + CELL_SIZE * 0.5)
	var font   = ThemeDB.fallback_font
	draw_string(font, centre + Vector2(-6, 6), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_WALL)

func _draw_room_labels() -> void:
	var font      = ThemeDB.fallback_font
	var font_size = 10
	for room in rooms.values():
		var pr     = _room_pixel_rect(room)
		var centre = pr.get_center()
		var parts  = room.room_name.split(" ")
		var line_h = font_size + 3
		var total_h = parts.size() * line_h
		for i in range(parts.size()):
			var word  = parts[i]
			var tw    = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var pos   = centre + Vector2(-tw * 0.5, -total_h * 0.5 + i * line_h + font_size)
			draw_string(font, pos, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_LABEL)

func _draw_highlights() -> void:
	for cell in _highlighted_cells:
		draw_rect(_cell_rect(cell), COLOR_HIGHLIGHT)

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)

func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

func map_to_local(cell: Vector2i) -> Vector2:
	return _cell_to_world(cell) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))

func _room_cell_bounds(room: RoomData) -> Rect2i:
	if room.cells.is_empty():
		return Rect2i()
	var mn = room.cells[0]
	var mx = room.cells[0]
	for c in room.cells:
		mn = Vector2i(min(mn.x, c.x), min(mn.y, c.y))
		mx = Vector2i(max(mx.x, c.x), max(mx.y, c.y))
	return Rect2i(mn, mx - mn + Vector2i(1, 1))

func _room_pixel_rect(room: RoomData) -> Rect2:
	var b = _room_cell_bounds(room)
	return Rect2(b.position.x * CELL_SIZE, b.position.y * CELL_SIZE,
				 b.size.x * CELL_SIZE, b.size.y * CELL_SIZE)

func _spawn_tokens(players: Array) -> void:
	for player in players:
		var token          = BoardToken.new()
		token.suspect_name = player.suspect_name
		token.set_color(TOKEN_COLORS.get(player.suspect_name, Color.GRAY))
		add_child(token)
		tokens[player.suspect_name] = token
		var start = STARTING_CELLS.get(player.suspect_name, Vector2i(12, 12))
		token.move_to_cell(start, "", self)

func highlight_reachable_cells(suspect_name: String, steps: int) -> void:
	_active_token = tokens.get(suspect_name, null)
	if _active_token == null:
		return
	_highlighted_cells = _get_reachable_cells(_active_token.current_cell, steps)
	queue_redraw()

func _clear_highlights() -> void:
	_highlighted_cells.clear()
	_active_token = null
	queue_redraw()

func _get_reachable_cells(from: Vector2i, steps: int) -> Array[Vector2i]:
	var visited:   Dictionary      = { from: true }
	var reachable: Array[Vector2i] = []
	var queue:     Array           = [[from, steps]]
	var occupied                   = _get_occupied_corridor_cells()

	while not queue.is_empty():
		var entry      = queue.pop_front()
		var cell: Vector2i = entry[0]
		var rem: int       = entry[1]
		var in_room        = _room_cells.has(cell)

		if in_room and cell != from:
			reachable.append(cell)
			continue

		if rem == 0:
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
			queue.append([nb, rem - 1])

	return reachable

func _orthogonal_neighbours(cell: Vector2i) -> Array[Vector2i]:
	return [cell + Vector2i(1,0), cell + Vector2i(-1,0),
			cell + Vector2i(0,1), cell + Vector2i(0,-1)]

func _is_walkable(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS

func _room_for_cell(cell: Vector2i) -> RoomData:
	var name = _room_cells.get(cell, "")
	return rooms.get(name, null) if name != "" else null

func _get_occupied_corridor_cells() -> Dictionary:
	var occ: Dictionary = {}
	for token in tokens.values():
		if token.current_room == "":
			occ[token.current_cell] = true
	return occ

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _highlighted_cells.is_empty() or _active_token == null:
		return
	var clicked = world_to_cell(get_local_mouse_position())
	if not clicked in _highlighted_cells:
		return
	var room      = _room_for_cell(clicked)
	var room_name = room.room_name if room != null else ""
	_active_token.move_to_cell(clicked, room_name, self)
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
