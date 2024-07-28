extends Grid
class_name SymbolGrid

signal symbol_flagged

var n_symbols : int = 5;

var permutation: Array
var symbols: Array[String];

var x_icon : Texture2D = load("res://x.svg")
var o_icon : Texture2D = load("res://o.svg")
var empty_icon := Texture2D.new()

func set_n_symbols(x : int):
	n_symbols = x

# Called when the node enters the scene tree for the first time.
func _ready():
	self.height = self.n_symbols
	self.width = self.n_symbols
	for i in range(n_symbols):
		symbols.append("ABCDEFGHI"[i])

	var h : Array[String]
	h.assign(range(width).map(func(x): return str(x)))
	setup_grid(symbols, h, flago, clear, flagx)
	place()

func get_symbol(i : int) -> String:
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

func place():
	permutation = range(self.width)
	permutation.shuffle()
	for i in range(self.width):
		self.tiles[permutation[i] * self.width + i].mine = true

func check_spots():
	var count_vertical : Array[int] = []
	var indices_vertical : Array[int] = []
	count_vertical.resize(self.width)
	indices_vertical.resize(self.width)
	for i in range(self.height):
		var count : int = 0
		var index : int = -1
		for j in range(self.width):
			var t : Tile = self.tiles[i * self.width + j]
			if(not t.reveal and not t.flag):
				count += 1
				index = i * self.width + j
				count_vertical[j] += 1
				indices_vertical[j] = index
		if(count == 1):
			indexize(flagx, index)
	for i in range(self.width):
		if(count_vertical[i] == 1):
			indexize(flagx, indices_vertical[i])

func flago(t : Tile, i : int):
	var was_x : bool = t.flag
	if(was_x):
		directions_ortho_extended(i, func(x): self.tiles[x].ref.erase(i))
		clear_dereferenced()
	if(not was_x and t.reveal):
		return

	t.flag = false
	t.set_button_icon(o_icon)
	t.reveal = true
	t.ref.append(-1)

	if(was_x):
		emit_signal("symbol_flagged")
	check_spots()

func flago_reference(t : Tile, i : int, ref : int = -1):
	t.flag = false
	t.set_button_icon(o_icon)
	t.reveal = true
	t.ref.append(ref)

func flagx(t : Tile, i : int):
	if(not t.flag and t.reveal):
		return
	if(t.flag):
		return

	directions_ortho_extended(i, func(x): flago_reference(self.tiles[x], x, i))
	t.flag = true
	t.set_button_icon(x_icon)
	t.ref.append(i)

	emit_signal("symbol_flagged")
	check_spots()

func clear_dereferenced():
	for t in self.tiles:
		if(len(t.ref) == 0):
			t.flag = false
			t.set_button_icon(empty_icon)
			t.reveal = false

func clear(t : Tile, i : int):
	var was_x : bool = t.flag
	if(not was_x and t.ref.find(-1) == -1):
		return
	if(was_x):
		directions_ortho_extended(i, func(x): self.tiles[x].ref.erase(i))
		clear_dereferenced()
	t.flag = false
	t.set_button_icon(empty_icon)
	t.reveal = false
	t.ref.clear()

	if(was_x):
		emit_signal("symbol_flagged")
