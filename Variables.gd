class_name Variables

var any_variables : Dictionary
var variables : Dictionary
var exact_match : bool = false

static func new_match() -> Variables:
	var v := Variables.new()
	v.exact_match = true
	return v

func merge_without_conflicts(other : Variables) -> bool:
	for i in other.variables:
		if(i in variables and not other.variables[i].equal(variables[i])):
			return false
	variables.merge(other.variables)
	any_variables.merge(other.any_variables)
	return true

func merge(other : Variables):
	variables.merge(other.variables)
	any_variables.merge(other.any_variables)

func insert_without_conflicts(varnum : int, value : Formula) -> bool:
	if(varnum in variables and not value.equal(variables[varnum])):
		return false
	variables[varnum] = value
	return true

func duplicate() -> Variables:
	var v := Variables.new()
	v.variables = variables.duplicate()
	v.any_variables = any_variables.duplicate()
	v.exact_match = exact_match
	return v

func is_match() -> bool:
	return len(variables) or len(any_variables) or exact_match

func insert_any_variable(varnum : int):
	any_variables[varnum] = Formula.make_number(randi())
