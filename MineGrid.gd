extends Grid
class_name MineGrid

signal flagged

var mines : int
var max_neighbours : int = 8
var generated : bool

var flag_icon: Texture2D = load("res://flag.png")
var mine_icon: Texture2D = load("res://mine.png")
var empty_icon := Texture2D.new()

func set_board_size(w : int, h : int):
	self.width = w
	self.height = h

func _ready():
	self.set_columns(self.width + 1)

	setup_grid([], [], reveal, auto, flag)
	self.mines = self.width * self.height / 3
	generated = false

	get_parent().connect("symbol_flagged", reveal_symbols)

func place_mines(starti : int):
	generated = true
	var mines_left = self.mines
	while(mines_left > 0):
		var i : int = randi_range(0, self.height * self.width - 1)
		if(i == starti or self.tiles[i].mine):
			continue
		self.tiles[i].mine = true
		var counts : Array[int] = []
		directions(i, func(x) : counts.append(indexize(count, i)))
		for c in counts:
			if(c > self.max_neighbours):
				self.tiles[c].mine = false
				continue
		mines_left -= 1

func count(t: Tile, i: int) -> int:
	if(t.mine):
		return -1
	var number: Array[int] = [0]
	directions(i, func(x): number[0] += int(self.tiles[x].mine))
	return number[0]

func count_known(t: Tile, i: int) -> int:
	var number: Array[int] = [0]
	directions(i, func(x): number[0] += int(self.tiles[x].is_known_mine()))
	return number[0]

func calc_mines(t: Tile, i: int):
	if(t.number != 9):
		return
	t.number = count(t, i)
	if(0 <= t.number && t.number <= 8):
		label_tile(t)

func reveal(t : Tile, i: int):
	if(not generated):
		place_mines(i)
	if(t.reveal):
		return
	if(t.flag):
		return
	t.reveal = true
	calc_mines(t, i)
	var number : int = self.get_parent().get_number(t)
	if(number == -1):
		t.set_button_icon(mine_icon)
		emit_signal("flagged")
	if(self.get_parent().can_autoreveal(t) && number == 0):
		directions(i, func(x): indexize(reveal, x))
	
func flag(t : Tile, i: int):
	if(t.reveal):
		return
	t.flag = not t.flag
	emit_signal("flagged")
	if(t.flag):
		t.set_button_icon(flag_icon)
	else:
		t.set_button_icon(null)

func idemflag(t : Tile, i: int):
	if(t.reveal):
		return
	if(not t.flag):
		t.flag = true
		emit_signal("flagged")
	t.flag = true
	t.set_button_icon(flag_icon)

func auto(t : Tile, i: int):
	if(not t.reveal):
		reveal(t, i)
		return
	var number : int = self.get_parent().get_number(t)
	if(number == 0):
		directions(i, func(x): indexize(reveal, x))
		return
	if(not get_parent().can_autoreveal(t)):
		return

	var ct : Array[int] = [0]
	directions(i, func(x): ct[0] += int(self.tiles[x].is_candidate()))
	if(ct[0] == number):
		directions(i, func(x): indexize(idemflag, x))
	elif(ct[0] > count_known(t, i)):
		if(count_known(t, i) == number):
			directions(i, func(x): indexize(reveal, x))
		return
	elif(ct[0] < count_known(t, i)):
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
	
func mine_count() -> int:
	return self.mines

func flag_count() -> int:
	var count : int = 0;
	for t in self.tiles:
		if(t.reveal and t.mine):
			count += 1
		if(t.flag):
			count += 1
	return count

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
