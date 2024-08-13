extends Rule
class_name Rule2

var region1_formula : Formula
var region1_size_formula : Formula
var region1_action : Action = Action.new()

var region2_formula : Formula
var region2_size_formula : Formula
var region2_action : Action = Action.new()

var region1x2_size_formula : Formula
var region1x2_action : Action = Action.new()

static func from_json(d : Dictionary) -> Rule2:
	var rule := Rule2.new()
	if("name" in d):
		rule.name = d["name"]
	var parser := Parser.new()
	rule.region1_formula = parser.parse_string(d["region1_formula"])
	rule.region2_formula = parser.parse_string(d["region2_formula"])
	
	rule.region1_size_formula = parser.parse_string(d["region1_size_formula"])
	rule.region1x2_size_formula = parser.parse_string(d["region1x2_size_formula"])
	rule.region2_size_formula = parser.parse_string(d["region2_size_formula"])
	
	if("region1_action" in d):
		rule.region1_action = Action.from_json(d["region1_action"])
	else:
		rule.region1_action = Action.new()
	if("region1x2_action" in d):
		rule.region1x2_action = Action.from_json(d["region1x2_action"])
	else:
		rule.region1x2_action = Action.new()
	if("region2_action" in d):
		rule.region2_action = Action.from_json(d["region2_action"])
	else:
		rule.region2_action = Action.new()
	rule.set_names()
	return rule

func set_names():
	region1_formula.description = "Region 1"
	region1_size_formula.description = "Region 1 size"
	region1_action.name = "Region 1 action"
	region2_formula.description = "Region 2"
	region2_size_formula.description = "Region 2 size"
	region2_action.name = "Region 2 action"
	region1x2_size_formula.description = "Region 1x2 size"
	region1x2_action.name = "Region 1x2 action"

func set_bounds(bounds : Array[int]):
	region1_formula.set_bounds(bounds)
	region1_action.set_bounds(bounds)
	region2_formula.set_bounds(bounds)
	region2_action.set_bounds(bounds)
	region1x2_action.set_bounds(bounds)

func applies_to_subregion(f : Formula, cells : int, found : Variables):
	return f.generalizes(Formula.make_number(cells), false, found)

func applies(r1 : Region, r2 : Region) -> Variables:
	var found := Variables.new()
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
	if(r1g and r1s and r2g and r2s and r1x2s):
		if(found.is_match()):
			return found
		return Variables.new_match()
	return Variables.new()

func apply(solver : Solver, mine_grid : MineGrid, r1 : Region, r2 : Region):
	var variables : Variables = applies(r1, r2)
	if(region1_action.is_unbounded(variables) or region2_action.is_unbounded(variables) or region1x2_action.is_unbounded(variables)):
		return
	if(not variables.is_match()):
		return
	var applicationid : int = randi()
	region1_action.apply(solver, mine_grid, variables, r1.cells.filter(func (x) : return x not in r2.cells), applicationid, r1)
	region2_action.apply(solver, mine_grid, variables, r2.cells.filter(func (x) : return x not in r1.cells), applicationid, r2)
	region1x2_action.apply(solver, mine_grid, variables, r1.cells.filter(func (x) : return x in r2.cells), applicationid)

func _get_formulas() -> Dictionary:
	return {
		"region1_formula": region1_formula,
		"region2_formula": region2_formula
	}

func _get_size_formulas() -> Dictionary:
	return {
		"region1_size_formula": region1_size_formula,
		"region2_size_formula": region2_size_formula,
		"region1x2_size_formula": region1x2_size_formula
	}

func _get_actions() -> Dictionary:
	return {
		"region1_action": region1_action,
		"region2_action": region2_action,
		"region1x2_action": region1x2_action
	}

func _init():
	self.get_formulas = _get_formulas
	self.get_size_formulas = _get_size_formulas
	self.get_actions = _get_actions
	self.number_of_regions = 2
