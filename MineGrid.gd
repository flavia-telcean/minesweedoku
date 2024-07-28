extends GridContainer
class_name MineGrid

var rows : int
var height : int
var width : int
var mines : int
var tiles : Array[Tile]
var max_neighbours : int = 8
var generated : bool

var flag_icon: Texture2D = load("res://flag.png")
var mine_icon: Texture2D = load("res://mine.png")
var empty_icon := Texture2D.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	self.width = 6
	self.height = 6

	self.set_columns(width)
	for i in range(height):
		for j in range(width):
			var a := Tile.new()
			a.custom_minimum_size = Vector2(35,35)
			a.connect("left_click", func(): indexize(_reveal, i * width + j))
			a.connect("right_click", func(): indexize(_flag, i * width + j))
			a.connect("middle_click", func(): indexize(_auto, i * width + j))
			self.add_child(a)
			self.tiles.append(a)
	self.mines = self.width * self.height / 3
	generated = false

	get_parent().connect("symbol_flagged", reveal_symbols)

func _place_mines(starti : int):
	generated = true
	var mines_left = self.mines
	while(mines_left > 0):
		var i : int = randi_range(0, self.height * self.width - 1)
		if(i == starti or self.tiles[i].mine):
			continue
		self.tiles[i].mine = true
		var counts : Array[int] = []
		_directions(i, func(x) : counts.append(indexize(_count, i)))
		for c in counts:
			if(c > self.max_neighbours):
				self.tiles[c].mine = false
				continue
		mines_left -= 1

func _has_up(i: int) -> bool:
	return i >= self.width
func _has_down(i: int) -> bool:
	return i < self.width * (self.height - 1)
func _has_left(i: int) -> bool:
	return i % self.width > 0
func _has_right(i: int) -> bool:
	return i % self.width < self.width - 1

func _count(t: Tile, i: int) -> int:
	if(t.mine):
		return -1
	var number: Array[int] = [0]
	_directions(i, func(x): number[0] += int(self.tiles[x].mine))
	return number[0]

func _count_known(t: Tile, i: int) -> int:
	var number: Array[int] = [0]
	_directions(i, func(x): number[0] += int(self.tiles[x]._is_known_mine()))
	return number[0]

func _directions(i: int, f: Callable):
	if(i < 0 or i >= self.height * self.width):
		return
	if(_has_up(i)):
		if(_has_left(i)):
			f.call(i - self.width - 1)
		if(_has_right(i)):
			f.call(i - self.width + 1)
		f.call(i - self.width)
	if(_has_left(i)):
		f.call(i - 1)
	if(_has_right(i)):
		f.call(i + 1)
	if(_has_down(i)):
		if(_has_left(i)):
			f.call(i + self.width - 1)
		if(_has_right(i)):
			f.call(i + self.width + 1)
		f.call(i + self.width)

func _calc_mines(t: Tile, i: int):
	if(t.number != 9):
		return
	t.number = _count(t, i)
	if(0 <= t.number && t.number <= 8):
		label_tile(t)

func _reveal(t : Tile, i: int):
	if(not generated):
		_place_mines(i)
	if(t.reveal):
		return
	if(t.flag):
		return
	t.reveal = true
	_calc_mines(t, i)
	var number : int = self.get_parent().get_number(t)
	if(number == -1):
		t.set_button_icon(mine_icon)
	if(self.get_parent().can_autoreveal(t) && number == 0):
		_directions(i, func(x): indexize(_reveal, x))
	
func _flag(t : Tile, i: int):
	if(t.reveal):
		return
	t.flag = not t.flag
	if(t.flag):
		t.set_button_icon(flag_icon)
	else:
		t.set_button_icon(null)

func _idemflag(t : Tile, i: int):
	if(t.reveal):
		return
	t.flag = true
	t.set_button_icon(flag_icon)

func _auto(t : Tile, i: int):
	if(not t.reveal):
		_reveal(t, i)
		return
	var number : int = self.get_parent().get_number(t)
	if(number == 0):
		_directions(i, func(x): indexize(_reveal, x))
		return
	if(not get_parent().can_autoreveal(t)):
		return

	var ct : Array[int] = [0]
	_directions(i, func(x): ct[0] += int(self.tiles[x]._is_candidate()))
	if(ct[0] == number):
		_directions(i, func(x): indexize(_idemflag, x))
	elif(ct[0] > _count_known(t, i)):
		if(_count_known(t, i) == number):
			_directions(i, func(x): indexize(_reveal, x))
		return
	elif(ct[0] < _count_known(t, i)):
		return

func reveal_symbols():
	for t in self.tiles:
		if(not t.reveal or t.mine):
			continue
		label_tile(t)

func label_tile(t : Tile):
	if(get_parent().can_autoreveal(t)):
		var number : int = self.get_parent().get_number(t)
		t.set_text(str(number))
	else:
		t.set_text(get_parent().get_string(t.number))
	

func indexize(f: Callable, i: int):
	f.call(self.tiles[i], i)

func mine_number() -> int:
	return self.mines

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
