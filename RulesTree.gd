extends Tree
class_name RulesTree

func _ready():
	hide_root = true
	item_edited.connect(_on_edited)

func _on_edited():
	var item = get_edited()
	if(item.get_metadata(1)):
		item.get_metadata(1).on_edited(item)
