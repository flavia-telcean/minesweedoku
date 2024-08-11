extends Grid
class_name MineGrid

signal flagged(index : int)
signal cell_revealed(index : int)

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
	self.set_name("MineGrid")
	self.set_columns(self.width + 1)

	setup_grid([], [], reveal, auto, flag)
	for t in range(len(tiles)):
		tiles[t].cell = Cell.new(t)
	self.mines = self.width * self.height / 3
	generated = false

	get_parent().symbol_flagged.connect(reveal_symbols)

func place_mines(starti : int):
	generated = true
	var mines_left = self.mines
	while(mines_left > 0):
		var i : int = randi_range(0, self.height * self.width - 1)
		if(i == starti or self.tiles[i].mine):
			continue
		self.tiles[i].mine = true
		var counts : Array[int] = []
		directions(i, func(x) : counts.append(indexize(count, x)))
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
		flagged.emit(i)
	else:
		cell_revealed.emit(i)
	if(self.get_parent().can_autoreveal(t) && number == 0):
		directions(i, func(x): indexize(reveal, x))
	
func flag(t : Tile, i: int):
	if(t.reveal):
		return
	t.flag = not t.flag
	flagged.emit(i)
	if(t.flag):
		t.set_button_icon(flag_icon)
	else:
		t.set_button_icon(null)

func idemflag(t : Tile, i: int):
	if(t.reveal):
		return
	if(not t.flag):
		t.flag = true
		flagged.emit(i)
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

func region_at_cell(t : Tile, i : int) -> Region:
	if(not t.reveal or t.is_known_mine()):
		return
	var remaining : int = count(tiles[i], i) - count_known(tiles[i], i)
	var region := Region.new()
	directions(i, func (x):
		if(tiles[x].is_known_mine() or tiles[x].reveal):
			return
		region.cells.append(tiles[x].cell))
	region.id = i
	region.formula = Formula.make_number(remaining)
	var bounds : Array[int]
	bounds.assign(range(max_neighbours + 1))
	region.formula.set_bounds(bounds)
			
	return region

func special_regions() -> Array[Region]:
	var region_whole := Region.new()
	tiles \
		.filter(func (t): return not t.reveal and not t.is_known_mine()) \
		.map(func (t): region_whole.cells.append(t.cell))
	region_whole.id = randi()
	region_whole.formula = Formula.make_number(mine_count() - flag_count())
	var bounds : Array[int]
	bounds.assign(range(mine_count() + 1))
	region_whole.formula.set_bounds(bounds)
	return [region_whole]

func make_regions() -> Array[Region]:
	var regions : Array[Region] = []
	for i in range(len(tiles)):
		if(tiles[i].reveal and not tiles[i].is_known_mine()):
			var region : Region = region_at_cell(tiles[i], i)
			var bounds : Array[int]
			bounds.assign(range(max_neighbours + 1))
			region.formula.set_bounds(bounds)
			if(len(region.cells)):
				regions.append(region)
	regions += special_regions()
	return regions

var lines : Array[Line2D] = []

func distance(x : Vector2, y : Vector2) -> float:
	return y.distance_to(x)

func find_closest_point_and_erase(points : Array[Vector2], point : Vector2) -> Vector2:
	var distances : Array = points.map(func(x): return point.distance_to(x))
	var p : Vector2 = points[distances.find(distances.min())]
	points.erase(p)
	return p

func mst(points : Array[Vector2]) -> Array[Vector2]:
	if(not points):
		return []
	var orig_points : Array[Vector2] = points.duplicate()
	var center : Vector2 = orig_points.reduce(func(x, y): return x + y)
	var root : Vector2 = find_closest_point_and_erase(orig_points, center)
	
	var mstree_walk : Array[Vector2] = [root]
	
	while(len(orig_points)):
		var last_point : Vector2 = root
		var current_point : Vector2 = find_closest_point_and_erase(orig_points, last_point)
		mstree_walk.append(current_point)
		while(len(orig_points) and current_point != last_point):
			last_point = current_point
			current_point = find_closest_point_and_erase(orig_points, current_point)
			mstree_walk.append(current_point)
		if(not orig_points):
			break
		var backtrack : Array[Vector2] = mstree_walk.duplicate()
		backtrack.reverse()
		mstree_walk += backtrack
	return mstree_walk

func get_tile_position(t : Tile) -> Vector2:
	return t.get_screen_position() - get_parent().get_screen_position()

func get_tile_subposition(t : Tile, s : int) -> Vector2:
	return self.tile_size * Vector2(float(s % 3) / 3, float(s / 3) / 3)

var cell_positions : Dictionary = {}

func get_position_id(i : int, ri : int) -> int:
	return hash(i - ri) + hash(i + ri)

func get_point_position(id : int, region_id : int) -> Vector2:
	var position_id : int = get_position_id(id, region_id)
	if(position_id not in cell_positions):
		tiles[id].cell.next_subposition += 1
		cell_positions[position_id] =  get_tile_position(tiles[id]) + get_tile_subposition(tiles[id], tiles[id].cell.next_subposition)
	return cell_positions[position_id]

func create_line(cells : Array[int], id : int, label : String):
	if(len(cells) > 12):
		return
	var positions : Array[Vector2] = []
	positions.assign(cells.map(func(x): return get_point_position(x, id)))
	var line := Line2D.new()
	line.points = mst(positions)
	line.name = str(id)
	line.width = 5
	line.default_color = Color(.2 + randf(), .1 + randf(), .3 + randf())
	positions.map(func(p : Vector2):
		var a := LineLabel.new(p, label, line)
		line.add_child(a))
	get_parent().add_child(line)
	lines.append(line)

func remove_line(id : int):
	lines = lines.filter(func(line):
		if(line.get_name().to_int() == id):
			get_parent().remove_child(line)
			line.queue_free()
		return line.get_name().to_int() != id)

func remove_point(id : int, region : int, new_label : String = ""):
	if(get_position_id(id, region) not in cell_positions):
		print("Attempt to remove point that doesn't exist: ", id, " of ", region)
		return
	for i in lines:
		tiles[id].cell.next_subposition -= 1
		var point_position : Vector2 = cell_positions[get_position_id(id, region)]
		if(point_position not in i.points):
			continue
		var index : int = i.points.find(point_position)
		if(index < 0):
			return
		if(new_label):
			i.get_children().map(func(x): x.set_text(new_label))
		i.remove_point(index)
		for label in i.get_children():
			if(label.position == point_position):
				label.queue_free()
		cell_positions.erase(point_position)

func _process(delta):
	pass
