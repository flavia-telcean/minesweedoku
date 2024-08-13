extends Node
class_name Solver

var gm : BoardsFlow.GameMode
var regions : Array[Region]
var bounds : Array[int]

var mine_grid : MineGrid

var parser := Parser.new()
var rules : Array = []

var tree : RulesTree
var root

func _ready():
	tree = get_node("/root/Control/").find_child("Rules")
	root = tree.create_item()
	bounds.assign(range(mine_grid.max_neighbours + 1))
	load_rules()
	special_regions()
	get_node("/root/Control").find_child("SolveButton").pressed.connect(_on_activate)
	get_node("/root/Control").find_child("RemoveButton").pressed.connect(remove_regions)
	get_node("/root/Control").find_child("SpecialButton").pressed.connect(special_regions)
	get_node("/root/Control").find_child("SaveButton").pressed.connect(save_rules)


func add_rule(rule):
	rule.set_bounds(mine_grid.get_bounds())
	rules.append(rule)
	rule.create_menu(root)

func load_rules():
	var json := JSON.new()
	var rules_file := FileAccess.open("rules.json", FileAccess.READ)
	var error = json.parse(rules_file.get_as_text())
	rules_file.close()
	if error != OK:
		print("JSON Parse Error: ", json.get_error_message(), " in rules.json at line ", json.get_error_line())
	for i in json.data:
		add_rule(Rule.from_json(i))

func save_rules():
	var json := JSON.new()
	var rules_file := FileAccess.open("rules.json", FileAccess.WRITE)
	rules_file.store_string(json.stringify(rules.map(func (r): return r.to_json()), "\t"))
	rules_file.close()

func special_regions():
	mine_grid.special_regions().map(new_region)

func new_region(region : Region):
	regions.append(region)
	region.create_line(mine_grid)

func update_region(region : Region):
	region.create_line(mine_grid)

func new_region_at_cell(i : int):
	var region : Region = mine_grid.indexize(mine_grid.region_at_cell, i)
	if(region):
		new_region(region)
	for r in regions:
		if(r.has_cell(i)):
			r.clear_cell(mine_grid, i)

func _cell_revealed(i : int):
	new_region_at_cell(i)

func _remove_mine(i : int):
	if(not mine_grid.tiles[i].is_known_mine()): #FIXME
		return
	for r in regions:
		if(r.has_cell(i)):
			r.remove_mine(mine_grid, i)

func remove_empty_regions():
	regions = regions.filter(func(r):
		if(not len(r.cells)):
			r.remove_line(mine_grid)
		return len(r.cells) > 0)

func remove_duplicate_regions():
	var to_be_removed : Array[int] = []
	for i in range(len(regions)):
		for j in range(i + 1, len(regions)):
			if(regions[i].equal(regions[j])):
				regions[j].remove_line(mine_grid)
				to_be_removed.append(regions[j].id)
	regions.assign(regions.filter(func(r): return r.id not in to_be_removed))

func step():
	var old_regions : Array[Region] = regions.duplicate()
	
	for r in range(len(old_regions)):
		for rule in rules:
			if(rule.number_of_regions != 1):
				continue
			rule.apply(self, mine_grid, old_regions[r])
	
	for r1 in range(len(old_regions)):
		for r2 in range(len(old_regions)):
			if(r1 == r2):
				continue
			for rule in rules:
				if(rule.number_of_regions != 2):
					continue
				rule.apply(self, mine_grid, old_regions[r1], old_regions[r2])

func remove_regions():
	remove_empty_regions()
	remove_duplicate_regions()

func _on_activate():
	step()
	remove_regions()
