extends Control

var label := Label.new()

func _ready():
        label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
        self.find_child("Boards").connect("flagged", set_progress_text)
        set_progress_text()
        self.add_child(label)

func set_progress_text():
        label.set_text(self.find_child("Boards").get_progress_string())


func _process(delta):
        pass
