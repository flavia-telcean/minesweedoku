extends GridContainer
class_name SymbolGrid

signal symbol_flagged

var width: int
var height: int
var tiles: Array[Tile]
var permutation: Array
var symbols: Array[String] = ["A", "B", "C", "D", "E", "F"]

var x_icon : Texture2D = load("res://x.svg")
var o_icon : Texture2D = load("res://o.svg")
var empty_icon := Texture2D.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	self.width = 6
	self.height = self.width
	self.set_columns(self.width + 1)

	var label := Label.new()
	self.add_child(label)
	for i in range(width):
		label = Label.new()
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		label.set_text(str(i))
		self.add_child(label)
	for i in range(width):
		label = Label.new()
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		label.set_text(symbols[i])
		self.add_child(label)
		for j in range(width):
			var a := Tile.new()
			a.custom_minimum_size = Vector2(35,35)
			a.connect("left_click", func(): indexize(_flago, i * width + j))
			a.connect("right_click", func(): indexize(_flagx, i * width + j))
			a.connect("middle_click", func(): indexize(_clear, i * width + j))
			self.add_child(a)
			self.tiles.append(a)
	_place()

func _has_up(i: int) -> bool:
	return i >= self.width
func _has_down(i: int) -> bool:
	return i < self.width * (self.height - 1)
func _has_left(i: int) -> bool:
	return i % self.width > 0
func _has_right(i: int) -> bool:
	return i % self.width < self.width - 1

func _directions_ortho_extended(i : int, f : Callable):
	if(i < 0 or i >= self.height * self.width):
		return
	var t : int = i
	while(_has_up(t)):
		t -= self.width
		f.call(t)
	t = i
	while(_has_left(t)):
		t -= 1
		f.call(t)
	t = i
	while(_has_right(t)):
		t += 1
		f.call(t)
	t = i
	while(_has_down(t)):
		t += self.width
		f.call(t)

func _get_symbol(i : int) -> String:
	return symbols[permutation[i]]

func can_autoreveal(t : Tile) -> bool:
	for i in range(self.width):
		if(self.tiles[permutation[t.number] * self.width + i].flag):
			return true
	return false

func get_number(t : Tile) -> int:
	if(t.number == -1):
		return -1
	for i in range(self.width):
		if(self.tiles[permutation[t.number] * self.width + i].flag):
			return i
	return 9

func _place():
	permutation = range(self.width)
	permutation.shuffle()
	for i in range(self.width):
		self.tiles[permutation[i] * self.width + i].mine = true

func check_spots():
	var count_vertical : Array[int]
	var indices_vertical : Array[int]
	count_vertical.resize(self.width)
	indices_vertical.resize(self.width)
	for i in range(self.height):
		var count : int
		var index : int
		for j in range(self.width):
			var t : Tile = self.tiles[i * self.width + j]
			if(not t.reveal and not t.flag):
				count += 1
				index = i * self.width + j
				count_vertical[j] += 1
				indices_vertical[j] = index
		if(count == 1):
			indexize(_flagx, index)
	for i in range(self.width):
		if(count_vertical[i] == 1):
			indexize(_flagx, indices_vertical[i])

func _flago(t : Tile, i : int):
	var was_x : bool = t.flag
	if(was_x):
		_directions_ortho_extended(i, func(x): self.tiles[x].ref.erase(i))
		_clear_dereferenced()
	if(not was_x and t.reveal):
		return

	t.flag = false
	t.set_button_icon(o_icon)
	t.reveal = true
	t.ref.append(-1)

	if(was_x):
		emit_signal("symbol_flagged")
	check_spots()

func _flago_reference(t : Tile, i : int, ref : int = -1):
	t.flag = false
	t.set_button_icon(o_icon)
	t.reveal = true
	t.ref.append(ref)

func _flagx(t : Tile, i : int):
	if(not t.flag and t.reveal):
		return
	if(t.flag):
		return

	_directions_ortho_extended(i, func(x): _flago_reference(self.tiles[x], x, i))
	t.flag = true
	t.set_button_icon(x_icon)
	t.ref.append(i)

	emit_signal("symbol_flagged")
	check_spots()

func _clear_dereferenced():
	for t in self.tiles:
		if(len(t.ref) == 0):
			t.flag = false
			t.set_button_icon(empty_icon)
			t.reveal = false

func _clear(t : Tile, i : int):
	var was_x : bool = t.flag
	if(not was_x and t.ref.find(-1) == -1):
		return
	if(was_x):
		_directions_ortho_extended(i, func(x): self.tiles[x].ref.erase(i))
		_clear_dereferenced()
	t.flag = false
	t.set_button_icon(empty_icon)
	t.reveal = false
	t.ref.clear()

	if(was_x):
		emit_signal("symbol_flagged")

func indexize(f: Callable, i: int):
	f.call(self.tiles[i], i)

func _process(delta):
	pass
