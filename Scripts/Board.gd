extends Node2D
class_name Board

signal player_entered_room(room_name: String)
signal player_entered_corridor()

const COLS := 24
const ROWS := 25
const CELL_SIZE := 32
const WALL_W := 2.0

const COLOR_BG := Color8(166, 213, 157)
const COLOR_CORRIDOR := Color8(238, 208, 76)
const COLOR_GRID := Color8(206, 174, 62)
const COLOR_WALL := Color8(52, 34, 28)
const COLOR_HIGHLIGHT := Color(0.20, 0.95, 0.25, 0.45)
const COLOR_LABEL := Color(0.96, 0.92, 0.80)
const COLOR_CENTER_FILL := Color8(198, 176, 135)
const COLOR_CENTER_BORDER := Color8(120, 90, 56)

const ROOM_COLORS := {
	"Study": Color8(104, 61, 28),
	"Hall": Color8(166, 122, 66),
	"Lounge": Color8(110, 52, 136),
	"Library": Color8(89, 48, 26),
	"Dining Room": Color8(142, 62, 34),
	"Billiard Room": Color8(66, 112, 58),
	"Conservatory": Color8(77, 135, 69),
	"Ballroom": Color8(151, 118, 84),
	"Kitchen": Color8(169, 164, 150),
}

const STARTING_CELLS := {
	"Miss Scarlett": Vector2i(7, 24),
	"Col Mustard": Vector2i(16, 24),
	"Prof Plum": Vector2i(23, 16),
	"Rev Green": Vector2i(23, 7),
	"Mrs Peacock": Vector2i(0, 6),
	"Mrs White": Vector2i(9, 0),
}

const TOKEN_COLORS := {
	"Miss Scarlett": Color(0.85, 0.10, 0.10),
	"Col Mustard": Color(0.85, 0.75, 0.10),
	"Prof Plum": Color(0.55, 0.10, 0.75),
	"Rev Green": Color(0.10, 0.65, 0.20),
	"Mrs Peacock": Color(0.10, 0.30, 0.85),
	"Mrs White": Color(0.92, 0.92, 0.92),
}

class BoardRoomData:
	var room_name: String = ""
	var cells: Array[Vector2i] = []
	var door_cells: Array[Vector2i] = []
	var secret_passage_to: String = ""

	func centre_cell() -> Vector2i:
		if cells.is_empty():
			return Vector2i.ZERO
		var sx: int = 0
		var sy: int = 0
		for c in cells:
			sx += c.x
			sy += c.y
		return Vector2i(roundi(float(sx) / float(cells.size())), roundi(float(sy) / float(cells.size())))

var rooms: Dictionary = {}
var tokens: Dictionary = {}
var _room_cells: Dictionary = {}
var _highlighted_cells: Array[Vector2i] = []
var _active_token: BoardToken = null

func _ready() -> void:
	_define_rooms()
	_build_room_cell_lookup()
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)
	queue_redraw()

func setup_board(players: Array) -> void:
	_spawn_tokens(players)
	queue_redraw()

func _fit_to_viewport() -> void:
	var board_size := Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	var vp_size: Vector2 = get_viewport_rect().size

	var margin := 24.0
	var sx: float = (vp_size.x - margin) / board_size.x
	var sy: float = (vp_size.y - margin) / board_size.y
	var s: float = min(sx, sy)
	s = max(s, 0.1)

	s = floor(s * 1000.0) / 1000.0

	scale = Vector2(s, s)
	var scaled := board_size * s
	position = ((vp_size - scaled) * 0.5).round()

func _define_rooms() -> void:
	rooms.clear()

	_add_room("Study", _rect(0, 0, 5, 6), [Vector2i(6, 4), Vector2i(4, 7)], "Kitchen")
	_add_room("Hall", _rect(9, 0, 14, 8), [Vector2i(8, 4), Vector2i(11, 9), Vector2i(13, 9)], "")
	_add_room("Lounge", _rect(18, 0, 23, 6), [Vector2i(17, 4)], "Conservatory")

	_add_room("Library", _rect(0, 9, 5, 14), [Vector2i(6, 12), Vector2i(3, 8)], "")
	_add_room("Dining Room", _rect(17, 10, 23, 17), [Vector2i(16, 13), Vector2i(16, 16)], "")

	_add_room("Billiard Room", _rect(0, 16, 5, 21), [Vector2i(6, 19), Vector2i(3, 15)], "")

	_add_room("Conservatory", _rect(0, 23, 4, 24), [Vector2i(5, 23)], "Lounge")
	_add_room("Ballroom", _rect(8, 22, 15, 24), [Vector2i(7, 23), Vector2i(10, 21), Vector2i(13, 21), Vector2i(16, 23)], "")
	_add_room("Kitchen", _rect(18, 22, 23, 24), [Vector2i(17, 23), Vector2i(20, 21)], "Study")

func _add_room(name: String, cells: Array[Vector2i], doors: Array[Vector2i], passage: String) -> void:
	var r := BoardRoomData.new()
	r.room_name = name
	r.cells = cells
	r.door_cells = doors
	r.secret_passage_to = passage
	rooms[name] = r

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
	var board_px := Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	draw_rect(Rect2(Vector2.ZERO - Vector2(8, 8), board_px + Vector2(16, 16)), COLOR_BG)

func _draw_cells() -> void:
	for y in range(ROWS):
		for x in range(COLS):
			var c := Vector2i(x, y)
			var r := _cell_rect(c)
			if _room_cells.has(c):
				draw_rect(r, ROOM_COLORS.get(_room_cells[c], Color.DIM_GRAY))
			else:
				draw_rect(r, COLOR_CORRIDOR)

	var board_w: float = float(COLS * CELL_SIZE)
	var board_h: float = float(ROWS * CELL_SIZE)

	for x in range(COLS + 1):
		var px: float = float(x * CELL_SIZE) + 0.5
		draw_line(Vector2(px, 0.5), Vector2(px, board_h - 0.5), COLOR_GRID, 1.0, true)

	for y in range(ROWS + 1):
		var py: float = float(y * CELL_SIZE) + 0.5
		draw_line(Vector2(0.5, py), Vector2(board_w - 0.5, py), COLOR_GRID, 1.0, true)

	for y2 in range(ROWS):
		for x2 in range(COLS):
			var c2 := Vector2i(x2, y2)
			if _room_cells.has(c2):
				draw_rect(_cell_rect(c2), ROOM_COLORS.get(_room_cells[c2], Color.DIM_GRAY))

func _draw_room_outlines_and_doors() -> void:
	for room in rooms.values():
		var b: Rect2i = _room_cell_bounds(room)
		var pr := Rect2(
			Vector2(b.position.x * CELL_SIZE, b.position.y * CELL_SIZE),
			Vector2(b.size.x * CELL_SIZE, b.size.y * CELL_SIZE)
		)
		draw_rect(pr, COLOR_WALL, false, WALL_W)

		for door in room.door_cells:
			var dr := Rect2(
				Vector2(door.x * CELL_SIZE + 1, door.y * CELL_SIZE + 1),
				Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
			)
			draw_rect(dr, COLOR_CORRIDOR)

func _draw_centre_marker() -> void:
	var cx: int = 10
	var cy: int = 12
	var w: int = 4
	var h: int = 4
	var r := Rect2(Vector2(cx, cy) * CELL_SIZE, Vector2(w, h) * CELL_SIZE)
	draw_rect(r, COLOR_CENTER_FILL)
	draw_rect(r, COLOR_CENTER_BORDER, false, 2.0)

	var font := ThemeDB.fallback_font
	draw_string(font, r.get_center() + Vector2(-6, 6), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.BLACK)

func _draw_room_labels() -> void:
	var font := ThemeDB.fallback_font
	var size: int = 16

	for room in rooms.values():
		var b: Rect2i = _room_cell_bounds(room)
		var center := Vector2(
			(float(b.position.x) + float(b.size.x) * 0.5) * CELL_SIZE,
			(float(b.position.y) + float(b.size.y) * 0.5) * CELL_SIZE
		)

		var lines: PackedStringArray = room.room_name.split(" ")
		var lh: float = float(size + 2)
		var total_h: float = float(lines.size()) * lh

		for i in range(lines.size()):
			var t: String = lines[i]
			var tw: float = font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var pos := center + Vector2(-tw * 0.5, -total_h * 0.5 + float(i) * lh + float(size))
			draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, COLOR_LABEL)

func _draw_highlights() -> void:
	for c in _highlighted_cells:
		draw_rect(_cell_rect(c), COLOR_HIGHLIGHT)

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)

func map_to_local(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local_unscaled := to_local(world_pos) / scale
	return Vector2i(int(local_unscaled.x / CELL_SIZE), int(local_unscaled.y / CELL_SIZE))

func _room_cell_bounds(room: BoardRoomData) -> Rect2i:
	if room.cells.is_empty():
		return Rect2i()
	var mn: Vector2i = room.cells[0]
	var mx: Vector2i = room.cells[0]
	for c in room.cells:
		mn = Vector2i(min(mn.x, c.x), min(mn.y, c.y))
		mx = Vector2i(max(mx.x, c.x), max(mx.y, c.y))
	return Rect2i(mn, mx - mn + Vector2i.ONE)

func _spawn_tokens(players: Array) -> void:
	for player in players:
		var token := BoardToken.new()
		token.suspect_name = player.suspect_name
		token.set_color(TOKEN_COLORS.get(player.suspect_name, Color.GRAY))
		add_child(token)
		tokens[player.suspect_name] = token
		token.move_to_cell(STARTING_CELLS.get(player.suspect_name, Vector2i(12, 12)), "", self)

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
	var visited: Dictionary = {from: true}
	var reachable: Array[Vector2i] = []
	var queue: Array = [[from, steps]]
	var occupied: Dictionary = _get_occupied_corridor_cells()

	while not queue.is_empty():
		var e = queue.pop_front()
		var cell: Vector2i = e[0]
		var rem: int = e[1]
		var in_room: bool = _room_cells.has(cell)

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
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1)
	]

func _is_walkable(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS

func _room_for_cell(cell: Vector2i):
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

	var clicked: Vector2i = world_to_cell(get_global_mouse_position())
	if not clicked in _highlighted_cells:
		return

	var room: BoardRoomData = _room_for_cell(clicked) as BoardRoomData
	var room_name: String = ""
	if room != null:
		room_name = room.room_name

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
	var dest_name: String = get_secret_passage_destination(suspect_name)
	if dest_name == "":
		return
	var dest_room = rooms.get(dest_name, null)
	if dest_room == null:
		return
	tokens[suspect_name].move_to_cell(dest_room.centre_cell(), dest_name, self)
	emit_signal("player_entered_room", dest_name)

func move_token_to_room(suspect_name: String, room_name: String) -> void:
	var token = tokens.get(suspect_name, null)
	var room = rooms.get(room_name, null)
	if token == null or room == null:
		push_warning("Board: cannot move %s to %s" % [suspect_name, room_name])
		return
	token.move_to_cell(room.centre_cell(), room_name, self)
	queue_redraw()

func get_token_room(suspect_name: String) -> String:
	var token = tokens.get(suspect_name, null)
	return token.current_room if token != null else ""
