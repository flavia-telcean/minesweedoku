extends Node
class_name Solver

var gm : BoardsFlow.GameMode
var regions : Array[Region]

var mine_grid : MineGrid

class Action:
	enum Type {
		None,
		Bomb,
		Clear,
		NewRegion,
	}
	
	var solver : Solver
	
	var type : Type
	var regionformula : Formula
	var regionid : int
	
	static func from_tree(tree : Array) -> Action:
		assert(len(tree))
		var a := Action.new()
		match(tree[0].type):
			Parser.Tokens.None:
				a.type = Type.None
			Parser.Tokens.Bomb:
				a.type = Type.Bomb
			Parser.Tokens.Clear:
				a.type = Type.Clear
			Parser.Tokens.Region:
				a.type = Type.NewRegion
				assert(len(tree) == 3 and tree[1].type == Formula.Type.Number)
				a.regionid = tree[1].number
				var parser := Parser.new()
				a.regionformula = parser.parse(tree[2])
			_:
				assert(false)
		return a
	
	func apply(mine_grid : MineGrid, cells : Array[Cell]):
		match(type):
			Type.None: pass
			Type.Bomb:
				for cell in cells:
					mine_grid.indexize(mine_grid.idemflag, cell.id)
			Type.Clear:
				for cell in cells:
					mine_grid.indexize(mine_grid.reveal, cell.id)
			Type.NewRegion:
				var found_regions : Array[Region] = solver.regions.filter(func (x): return x.id == regionid)
				assert(len(found_regions) <= 1)
				if(len(found_regions) == 1):
					found_regions[0].cells += cells
					return
				var region := Region.new()
				region.cells = cells.duplicate()
				region.id = regionid
				solver.regions.append(region)

class Rule1:
	var region_formula : Formula
	var region_size_formula : Formula
	var region_action : Action
	
	var number_of_regions : int = 1
	
	static func from_string(string : String) -> Rule1:
		var rule := Rule1.new()
		var parser := Parser.new()
		
		var tree : Array = parser.make_tree_string(string)
		assert(len(tree) == 3)
		rule.region_formula = parser.parse(tree[0])
		rule.region_size_formula = parser.parse(tree[1])
		rule.region_action = Action.from_tree(tree[2])
		return rule
	
	func applies_to_subregion(f : Formula, cells : int, found : Dictionary):
		return f.generalizes(Formula.make_number(cells), false, found)
	
	func applies(r : Region):
		var found : Dictionary = {}
		var rg : bool = region_formula.generalizes(r.formula, true, found)
		var rs : bool = applies_to_subregion(region_size_formula, r.count_cells(), found)
		return rg and rs
	
	func apply(mine_grid : MineGrid, r : Region):
		assert(applies(r))
		region_action.apply(mine_grid, r.cells)

class Rule2:
	var region1_formula : Formula
	var region1_size_formula : Formula
	var region1_action : Action = Action.new()
	
	var region2_formula : Formula
	var region2_size_formula : Formula
	var region2_action : Action = Action.new()
	
	var region1x2_size_formula : Formula
	var region1x2_action : Action = Action.new()
	
	var number_of_regions : int = 2
	
	static func from_string(string : String) -> Rule2:
		var rule := Rule2.new()
		var parser := Parser.new()
		
		var tree : Array = parser.make_tree_string(string)
		assert(len(tree) == 8)
		rule.region1_formula = parser.parse(tree[0])
		rule.region2_formula = parser.parse(tree[1])
		
		rule.region1_size_formula = parser.parse(tree[2])
		rule.region1x2_size_formula = parser.parse(tree[3])
		rule.region2_size_formula = parser.parse(tree[4])
		
		rule.region1_action = Action.from_tree(tree[5])
		rule.region1x2_action = Action.from_tree(tree[6])
		rule.region2_action = Action.from_tree(tree[7])
		return rule
	
	func applies_to_subregion(f : Formula, cells : int, found : Dictionary):
		return f.generalizes(Formula.make_number(cells), false, found)
	
	func applies(r1 : Region, r2 : Region):
		var found : Dictionary = {}
		var r1f : Formula = region1_formula.duplicate()
		var r2f : Formula = region2_formula.duplicate()
		var r1sf : Formula = region1_size_formula.duplicate()
		var r2sf : Formula = region2_size_formula.duplicate()
		var r1x2sf : Formula = region1x2_size_formula.duplicate()
		var r1g : bool = r1f.generalizes(r1.formula, true, found)
		var r2g : bool = r2f.generalizes(r2.formula, true, found)
		
		var cells_in_1_not_in_2 : int = r1.count_cells_not_in(r2)
		var cells_in_2_not_in_1 : int = r2.count_cells_not_in(r1)
		var cells_intersection : int = r1.count_cells_in(r2)
		
		var r1s : bool = applies_to_subregion(r1sf, cells_in_1_not_in_2, found)
		var r2s : bool = applies_to_subregion(r2sf, cells_in_2_not_in_1, found)
		var r1x2s : bool = applies_to_subregion(r1x2sf, cells_intersection, found)
		return r1g and r1s and r2g and r2s and r1x2s
	
	func apply(mine_grid : MineGrid, r1 : Region, r2 : Region):
		assert(applies(r1, r2))
		region1_action.apply(mine_grid, r1.cells.filter(func (x) : return x not in r2.cells))
		region2_action.apply(mine_grid, r2.cells.filter(func (x) : return x not in r1.cells))
		region1x2_action.apply(mine_grid, r1.cells.filter(func (x) : return x in r2.cells))

var parser := Parser.new()
var rules : Array = []

func _ready():
	rules.append(Rule2.from_string("(y) (x+y) (?) (?) (x) (clear) (none) (bomb)"))
	#rules.append(Rule2.from_string("(1) (x+1) (?) (?) (x) (clear) (none) (bomb)"))
	rules.append(Rule2.from_string("(x) (x) (0) (?) (?) (none) (none) (clear)"))
	rules.append(Rule1.from_string("(x) (x) (bomb)"))
	rules.append(Rule1.from_string("(0) (x) (clear)"))

func new_region(i : int):
	var region : Region = mine_grid.indexize(mine_grid.region_at_cell, i)
	if(region):
		regions.append(region)
		region.create_line(mine_grid)
	for r in regions:
		if(r.has_cell(i)):
			r.clear_cell(mine_grid, i)

func _cell_revealed(i : int):
	new_region(i)

func _remove_mine(i : int):
	if(not mine_grid.tiles[i].is_known_mine()): #FIXME
		return
	for r in regions:
		if(r.has_cell(i)):
			r.remove_mine(mine_grid, i)

func remove_empty_regions():
	regions = regions.filter(func(r): return len(r.cells) > 0)

func remove_duplicate_regions():
	var to_be_removed : Array[int] = []
	for i in range(len(regions)):
		for j in range(i + 1, len(regions)):
			if(regions[i].equal(regions[j])):
				regions[j].remove_line(mine_grid)
				to_be_removed.append(regions[j].id)
	regions = regions.filter(func(r): return r.id not in to_be_removed)

func _on_activate():
	for r in range(len(regions)):
		for rule in rules:
			if(rule.number_of_regions != 1):
				continue
			if(rule.applies(regions[r])):
				rule.apply(mine_grid, regions[r])
	
	for r1 in range(len(regions)):
		for r2 in range(len(regions)):
			if(r1 == r2):
				continue
			for rule in rules:
				if(rule.number_of_regions != 2):
					continue
				if(rule.applies(regions[r1], regions[r2])):
					rule.apply(mine_grid, regions[r1], regions[r2])

	remove_empty_regions()
	remove_duplicate_regions()
