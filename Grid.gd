extends GridContainer
class_name Grid

var width : int
var height : int
var tiles : Array[Tile]

func setup_grid(vertical : Array[String], horizontal : Array[String], left : Callable, middle : Callable, right : Callable):
	self.set_columns(self.width + 1)
	var label := Label.new()
	self.add_child(label)
	for i in range(width):
		label = Label.new()
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		if(len(horizontal)):
			label.set_text(horizontal[i])
		self.add_child(label)
	for i in range(width):
		label = Label.new()
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		if(len(horizontal)):
			label.set_text(vertical[i])
		self.add_child(label)
		for j in range(width):
			var a := Tile.new()
			a.custom_minimum_size = Vector2(35,35)
			a.connect("left_click", func(): indexize(left, i * width + j))
			a.connect("middle_click", func(): indexize(middle, i * width + j))
			a.connect("right_click", func(): indexize(right, i * width + j))
			self.add_child(a)
			self.tiles.append(a)

func indexize(f: Callable, i: int):
	f.call(self.tiles[i], i)

func has_up(i: int) -> bool:
	return i >= self.width
func has_down(i: int) -> bool:
	return i < self.width * (self.height - 1)
func has_left(i: int) -> bool:
	return i % self.width > 0
func has_right(i: int) -> bool:
	return i % self.width < self.width - 1

func directions(i: int, f: Callable):
	if(i < 0 or i >= self.height * self.width):
		return
	if(has_up(i)):
		if(has_left(i)):
			f.call(i - self.width - 1)
		if(has_right(i)):
			f.call(i - self.width + 1)
		f.call(i - self.width)
	if(has_left(i)):
		f.call(i - 1)
	if(has_right(i)):
		f.call(i + 1)
	if(has_down(i)):
		if(has_left(i)):
			f.call(i + self.width - 1)
		if(has_right(i)):
			f.call(i + self.width + 1)
		f.call(i + self.width)

func directions_ortho_extended(i : int, f : Callable):
	if(i < 0 or i >= self.height * self.width):
		return
	var t : int = i
	while(has_up(t)):
		t -= self.width
		f.call(t)
	t = i
	while(has_left(t)):
		t -= 1
		f.call(t)
	t = i
	while(has_right(t)):
		t += 1
		f.call(t)
	t = i
	while(has_down(t)):
		t += self.width
		f.call(t)

