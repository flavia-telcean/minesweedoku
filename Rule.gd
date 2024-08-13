extends Object
class_name Rule

var name : String

var get_formulas : Callable
var get_size_formulas : Callable
var get_actions : Callable

var number_of_regions : int

static func from_json(d : Dictionary):
	match(int(d["size"])):
		1: return Rule1.from_json(d)
		2: return Rule2.from_json(d)

func to_json() -> Dictionary:
	var formulas : Dictionary = get_all_formulas()
	var actions : Dictionary = get_actions.call()
	var x : Dictionary = {
		"size": number_of_regions,
		"name": name,
	}
	for i in formulas:
		x[i] = str(formulas[i])
	for i in actions:
		x[i] = actions[i].to_json()
	return x

func get_all_formulas() -> Dictionary:
	var x : Dictionary = {}
	x.merge(get_formulas.call())
	x.merge(get_size_formulas.call())
	return x

func create_menu(parent : TreeItem):
	var tree : RulesTree = parent.get_tree()
	var rule_item = tree.create_item(parent)
	rule_item.set_text(0, name)
	rule_item.set_expand_right(0, true)
	var formulas : Dictionary = get_all_formulas()
	var actions : Dictionary = get_actions.call()
	for i in formulas:
		formulas[i].create_menu(rule_item)
	for i in actions:
		actions[i].create_menu(rule_item)
	rule_item.set_collapsed(true)
