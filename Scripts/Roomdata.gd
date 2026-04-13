extends Resource
class_name RoomData

var room_name: String = ""

var cells: Array[Vector2i] = []

var door_cells: Array[Vector2i] = []


var secret_passage_to: String = ""

func centre_cell() -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	var sum = Vector2i.ZERO
	for cell in cells:
		sum += cell
	return Vector2i(sum.x / cells.size(), sum.y / cells.size())
