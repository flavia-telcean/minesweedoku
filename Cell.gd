class_name Cell

var id : int
var lines : Array[int] = []

func next_subposition() -> int:
	return len(lines)

func _init(i : int):
	id = i
