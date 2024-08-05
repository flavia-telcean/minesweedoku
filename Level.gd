extends Control

var label := Label.new()
var boards : BoardsFlow

func _ready():
	label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	boards = self.find_child("Boards")
	boards.flagged.connect(set_progress_text)
	set_progress_text()
	self.add_child(label)

func set_progress_text():
	label.set_text(boards.get_progress_string())
