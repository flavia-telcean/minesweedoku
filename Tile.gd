extends Button
class_name Tile

signal left_click
signal middle_click
signal right_click

var a : Label;
var number: int;
var mine: bool;
var flag: bool;
var reveal: bool;

var ref : Array;

# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_text_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	self.set_expand_icon(true)
	self.reveal = false
	self.number = 9
	a = Label.new()
	a.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	self.add_child(a)
	self.connect("gui_input", _on_gui_input)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				emit_signal("left_click")
			MOUSE_BUTTON_MIDDLE:
				emit_signal("middle_click")
			MOUSE_BUTTON_RIGHT:
				emit_signal("right_click")

func is_known_mine():
	return (self.mine and self.reveal) or self.flag

func is_candidate():
	return (self.reveal and self.mine) or self.flag or (not self.reveal and not self.flag)
