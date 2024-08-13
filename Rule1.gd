extends Rule
class_name Rule1

var region_formula : Formula
var region_size_formula : Formula
var region_action : Action

static func from_json(d : Dictionary) -> Rule1:
	var rule := Rule1.new()
	if("name" in d):
		rule.name = d["name"]
	var parser := Parser.new()
	
	rule.region_formula = parser.parse_string(d["region_formula"])
	rule.region_size_formula = parser.parse_string(d["region_size_formula"])
	if("region_action" in d):
		rule.region_action = Action.from_json(d["region_action"])
	else:
		rule.region_action = Action.new()
	rule.set_names()
	return rule

func set_names():
	region_formula.description = "Region"
	region_size_formula.description = "Region size"
	region_action.name = "Region action"

func set_bounds(bounds : Array[int]):
	region_formula.set_bounds(bounds)
	region_action.set_bounds(bounds)

func applies_to_subregion(f : Formula, cells : int, found : Variables):
	return f.generalizes(Formula.make_number(cells), false, found)

func applies(r : Region) -> Variables:
	var found := Variables.new()
	var rg : bool = region_formula.generalizes(r.formula, true, found)
	var rs : bool = applies_to_subregion(region_size_formula, r.count_cells(), found)
	if(rg and rs):
		if(found.is_match()):
			return found
		return Variables.new_match()
	return Variables.new()

func apply(solver : Solver, mine_grid : MineGrid, r : Region):
	var variables : Variables = applies(r)
	if(region_action.is_unbounded(variables)):
		return
	if(not variables.is_match()):
		return
	region_action.apply(solver, mine_grid, variables, r.cells, randi(), r)

func _get_formulas() -> Dictionary:
	return {
		"region_formula": region_formula
	}

func _get_size_formulas() -> Dictionary:
	return {
		"region_size_formula": region_size_formula
	}

func _get_actions() -> Dictionary:
	return {
		"region_action": region_action
	}

func _init():
	self.get_formulas = _get_formulas
	self.get_size_formulas = _get_size_formulas
	self.get_actions = _get_actions
	self.number_of_regions = 1
