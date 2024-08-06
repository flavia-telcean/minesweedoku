extends Node2D
class_name LineLabel

var color : Color

func _draw():
	draw_circle(Vector2(0,0), 10, color)

func _init(position : Vector2, text : String, line : Line2D):
	self.set_position(position)
	var label := Label.new()
	label.set_position(Vector2(-5, -12))
	label.set_text(text)
	self.z_index = line.z_index + 1
	if(line.default_color.v > 0.5):
		label.modulate = Color.BLACK
	else:
		label.modulate = Color.WHITE
	self.add_child(label)
	self.color = line.default_color

func set_text(text : String):
	get_child(0).set_text(text)
