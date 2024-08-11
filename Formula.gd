class_name Formula

enum Type {
	Slash,
	Variable,
	Gte,
	Lte,
	Plus,
	Minus,
	Number,
	False,
	Any,
}
var type : Type
var c1 : Formula
var c2 : Formula
var number : int
var varnum : int
var variables : Array[int]
var bounds : Array[int]

static func make_false() -> Formula:
	var x := Formula.new()
	x.type = Type.False
	x.varnum = -1
	return x
static func make_any() -> Formula:
	var x := Formula.new()
	x.type = Type.Any
	x.varnum = -1
	return x

static func make_plus(a : Formula, b : Formula) -> Formula:
	var x := Formula.new()
	x.type = Type.Plus
	x.c1 = a
	x.c2 = b
	x.varnum = -1
	x.variables = a.variables + b.variables
	return x
static func make_minus(a : Formula, b : Formula) -> Formula:
	var x := Formula.new()
	x.type = Type.Minus
	x.c1 = a
	x.c2 = b
	x.varnum = -1
	x.variables = a.variables + b.variables
	return x
static func make_variable(id : int) -> Formula:
	var x := Formula.new()
	x.type = Type.Variable
	x.varnum = id
	x.variables = [id]
	x.number = 0
	return x
static func make_number(i : int) -> Formula:
	var x := Formula.new()
	x.type = Type.Number
	x.variables = []
	x.number = i
	x.varnum = -1
	return x
static func make_unary_operator(f : Formula, o : Type) -> Formula:
	var x := Formula.new()
	x.type = o
	x.variables = f.variables.duplicate()
	x.c1 = f.duplicate()
	x.number = 0
	x.varnum = -1
	return x
static func make_gte(f : Formula) -> Formula:
	return make_unary_operator(f, Type.Gte)
static func make_lte(f : Formula) -> Formula:
	return make_unary_operator(f, Type.Lte)

func assertions():
	match(type):
		Type.Variable:
			assert(varnum >= 0)
			assert(number == 0)
		Type.Slash:
			assert(number == 0)
			assert(c1 and c2)
			assert(varnum < 0)
		Type.Gte:
			assert(number == 0)
			assert(c1)
			assert(varnum < 0)
		Type.Lte:
			assert(number == 0)
			assert(c1)
			assert(varnum < 0)
		Type.Plus:
			assert(number == 0)
			assert(c1 and c2)
			assert(varnum < 0)
		Type.Number:
			assert(varnum < 0)
			if(bounds):
				assert(number in bounds)
		Type.False:
			assert(number == 0)
			assert(varnum < 0)
		Type.Any:
			assert(number == 0)
			assert(varnum < 0)

func remove_mine(safe : bool = true):
	if(safe):
		assertions()
	match(type):
		Type.Variable:
			var new := Formula.make_minus(Formula.make_variable(varnum), Formula.make_number(1))
			copy(new)
		Type.Slash:
			c1.remove_mine(false)
			c2.remove_mine(false)
		Type.Gte:
			c1.remove_mine()
		Type.Lte:
			c1.remove_mine()
		Type.Plus:
			c2.remove_mine()
		Type.Number:
			number -= 1
	if(safe):
		cleanup()
func copy(other : Formula):
	type = other.type
	varnum = other.varnum
	number = other.number
	if(other.c1):
		c1 = Formula.new()
		c1.copy(other.c1)
	else:
		c1 = other.c1
	if(other.c2):
		c2 = Formula.new()
		c2.copy(other.c2)
	else:
		c2 = other.c2
	if(other.bounds):
		bounds = other.bounds
	variables = other.variables.duplicate()
func inequality_cleanup():
	assert(type == Type.Lte or type == Type.Gte)
	assert(c1)
	assert(varnum < 0)
	c1.cleanup()
	
	if(c1.type == type):
		c1.copy(c1.c1)
	elif(c1.type == Type.Gte or c1.type == Type.Lte):
		copy(c1.c1)

func cleanup():
	assertions()
	match(type):
		Type.Slash:
			c1.cleanup()
			c2.cleanup()
		Type.Gte:
			inequality_cleanup()
		Type.Lte:
			inequality_cleanup()
		Type.Plus:
			c1.cleanup()
			c2.cleanup()
			if(c2.type == Type.Number and c2.number == 0):
				copy(c1)
			elif(c2.type == Type.Number and c2.number < 0):
				c2.number = -c2.number
				type = Type.Minus
			elif(c1.type == Type.Plus and c1.c2.type == Type.Number and c2.type == Type.Number):
				c2.number += c1.c2.number
				c1.copy(c1.c1)
			elif(c1.type == Type.Number and c2.type == Type.Number):
				copy(Formula.make_number(c1.number + c2.number))
			elif(c1.type == Type.Number):
				var c3 := Formula.new()
				c3.copy(c1)
				c1.copy(c2)
				c2.copy(c3)
			else:
				return
			cleanup()
		Type.Minus:
			c1.cleanup()
			c2.cleanup()
			if(c2.type == Type.Number and c2.number == 0):
				copy(c1)
			elif(c2.type == Type.Number and c2.number < 0):
				c2.number = -c2.number
				type = Type.Plus
			elif(c1.type == Type.Plus and c1.c2.type == Type.Number and c2.type == Type.Number):
				c2.number -= c1.c2.number
				c1.copy(c1.c1)
			elif(c1.type == Type.Number and c2.type == Type.Number):
				copy(Formula.make_number(c1.number - c2.number))
			else:
				return
			cleanup()

func try_solving_for_variable(varid : int) -> Formula:
	return Formula.new()
	#match(type):
	#	Type.False: return {}
	#	Type.Number:
	#	Type.Variable:
	#	Type.Plus:
	#	Type.Minus:
	#	Type.Slash:
	#	_:
	#		print("TODO :211")

func equal(other : Formula) -> bool:
	if(type != other.type):
		return false
	if(c1 and not c1.equal(other.c1)):
		return false
	if(c2 and not c2.equal(other.c2)):
		return false
	return number == other.number and varnum == other.varnum

func replace_variables(dict : Dictionary):
	assertions()
	if(len(variables) == 0):
		return
	match(type):
		Type.Variable:
			if(varnum in dict):
				copy(dict[varnum])
		Type.Plus:
			c1.replace_variables(dict)
			c2.replace_variables(dict)
		Type.Minus:
			c1.replace_variables(dict)
			c2.replace_variables(dict)
		Type.Slash:
			c1.replace_variables(dict)
			c2.replace_variables(dict)
		Type.Gte:
			c1.replace_variables(dict)
		Type.Lte:
			c1.replace_variables(dict)
	cleanup()

func solve_equation(other : Formula, dict : Dictionary = {}) -> Dictionary:
	cleanup()
	other.cleanup()
	match(type):
		Type.False: return {}
		Type.Number:
			if(other.type == Type.Number):
				if(other.number == number):
					return {-1: Formula.make_false()}
				else:
					return {}
			return other.solve_equation(self)
		Type.Variable:
			if(not merge_without_conflicts(dict, {varnum: other})):
				return {}
			else:
				other.replace_variables(dict)
				dict[varnum] = other
		Type.Plus:
			var added : bool = false
			if(len(c1.variables) > 0):
				var solution : Dictionary = c1.solve_equation(Formula.make_minus(other, c2), dict.duplicate())
				if(solution and merge_without_conflicts(dict, solution)):
					added = true
			if(len(c2.variables) > 0):
				var solution : Dictionary = c2.solve_equation(Formula.make_minus(other, c1), dict.duplicate())
				if(solution and merge_without_conflicts(dict, solution)):
					added = true
			if(not added):
				return {}
		Type.Minus:
			var added : bool = false
			if(len(c1.variables) > 0):
				var solution : Dictionary = c1.solve_equation(Formula.make_plus(other, c2), dict.duplicate())
				if(solution and merge_without_conflicts(dict, solution)):
					added = true
			if(len(c2.variables) > 0):
				var solution : Dictionary = c2.solve_equation(Formula.make_minus(c1, other), dict.duplicate())
				if(solution and merge_without_conflicts(dict, solution)):
					added = true
			if(not added):
				return {}
		Type.Slash:
			dict.merge(c1.solve_equation(other))
			dict.merge(c1.solve_equation(other))
		_:
			assert(false)
	return dict

func is_solution(vars : Dictionary, other : Formula) -> bool:
	match(type):
		Type.False: return false
		Type.Any: return true
		Type.Number:
			if(other.type == Type.Number):
				return other.number == number
			else:
				return other.is_solution(vars, self)
		Type.Variable: return other.is_solution(vars, vars[varnum])
		Type.Plus:
			var result : bool = false
			var is_c1_constant : bool = len(c1.variables) == 0
			var is_c2_constant : bool = len(c2.variables) == 0
			if(not is_c1_constant):
				result = result or c1.is_solution(vars, Formula.make_minus(other, c2))
			if(not is_c2_constant):
				result = result or c2.is_solution(vars, Formula.make_minus(other, c1))
			if(is_c1_constant and is_c2_constant):
				assert(false)
			return result
		Type.Minus:
			var result : bool = false
			var is_c1_constant : bool = len(c1.variables) == 0
			var is_c2_constant : bool = len(c2.variables) == 0
			if(not is_c1_constant):
				result = result or c1.is_solution(vars, Formula.make_plus(other, c2))
			if(not is_c2_constant):
				result = result or c2.is_solution(vars, Formula.make_minus(c1, other))
			return result
		Type.Slash:
			return is_solution(vars, c1) or is_solution(vars, c2)
		Type.Gte:
			assert(other.type == Type.Number)
			match(c1.type):
				Type.Number: return number >= other.number
				Type.Plus:
					var result : bool = false
					var is_c1_constant : bool = len(c1.c1.variables) == 0
					var is_c2_constant : bool = len(c1.c2variables) == 0
					if(not is_c1_constant):
						result = result or c1.c1.is_solution(vars, Formula.make_minus(other, c1.c2))
					if(not is_c1_constant):
						result = result or c1.c2.is_solution(vars, Formula.make_minus(other, c1.c1))
					if(is_c1_constant and is_c2_constant):
						assert(false)
					return result
				_:
					assert(false)
		_:
			assert(false)
	return false

func merge_without_conflicts(d1 : Dictionary, d2 : Dictionary) -> bool:
	for i in d2:
		if(i in d1 and not d2[i].equal(d1[i])):
			return false
	d1.merge(d2)
	return true

func generalizes(other : Formula, rewriting : bool = false, found : Dictionary = {}) -> bool:
	assertions()
	other.assertions()
	if(other.type == Type.Number):
		var solution : Dictionary = solve_equation(other, found)
		if(len(solution) > 0):
			merge_without_conflicts(found, solution)
			return true
	if(type != Type.Variable and type != other.type):
		return false
	match(type):
		Type.False: return false
		Type.Any:
			found[varnum] = randi()
			return rewriting
		Type.Number:
			return other.number == number
		Type.Variable:
			match(other.type):
				Type.False: return true
				Type.Any:
					found[varnum] = randi()
					return rewriting
				Type.Number:
					if(varnum not in found):
						found[varnum] = other.number
						return true
					return false
				Type.Variable:
					if(not rewriting):
						found[varnum] = other.varnum
						return varnum == other.varnum
					if(varnum not in found):
						found[varnum] = other.varnum
						return true
					return found[varnum] == other.varnum
					
				Type.Plus: return false # XXX
				Type.Minus: return false
				Type.Slash: return false
				_: return false
		Type.Plus:
			return c1.generalizes(other.c1, rewriting, found) and c2.generalizes(other.c2, rewriting, found)
		Type.Minus:
			return c1.generalizes(other.c1, rewriting, found) and c2.generalizes(other.c2, rewriting, found)
		Type.Slash:
			return c1.generalizes(other.c1, rewriting, found) and c2.generalizes(other.c2, rewriting, found)
		_:
			assert(false)
			return false

func values_in(other : Formula) -> Dictionary:
	assert(generalizes(other, false))
	match(type):
		Type.Any: return {}
		Type.Number: return {}
		Type.Variable:
			match(other.type):
				Type.Number:
					return {varnum: other.number}
				Type.Plus: assert(false) # XXX
				Type.Minus: assert(false)
				Type.Slash: assert(false)
				_: return {}
		Type.Plus:
			var dict : Dictionary = c1.values_in(other.c1)
			dict.merge(c2.values_in(other.c2))
			return dict
		Type.Minus:
			var dict : Dictionary = c1.values_in(other.c1)
			dict.merge(c2.values_in(other.c2))
			return dict
		Type.Slash:
			var dict : Dictionary = c1.values_in(other.c1)
			dict.merge(c2.values_in(other.c2))
			return dict
	assert(false)
	return {}

func duplicate() -> Formula:
	var x := Formula.new()
	x.copy(self)
	return x

func _to_string():
	assertions()
	match(type):
		Type.Number:
			return str(number)
		Type.Variable:
			return "#" + str(varnum % 10)
		Type.False:
			return "!"
		Type.Any:
			return "?"
		Type.Plus:
			return c1._to_string() + " + " + c2._to_string()
		Type.Minus:
			return c1._to_string() + " - (" + c2._to_string() + ")"
		Type.Slash:
			if(c1.type == Type.Number and c2.type == Type.Number):
				return c1._to_string() + " / " + c2._to_string()
			return "(" + c1._to_string() + ") / (" + c2._to_string() + ")"
		Type.Gte:
			if(c1.type == Type.Number):
				return c1._to_string() + "+"
			return "(" + c1._to_string() + ")+"
		Type.Lte:
			if(c1.type == Type.Number):
				return c1._to_string() + "-"
			return "(" + c1._to_string() + ")-"

func set_bounds(b : Array[int]):
	self.bounds = b
	if(c1):
		c1.set_bounds(b)
	if(c2):
		c1.set_bounds(b)
	
func is_unbounded():
	if(type != Type.Number):
		return false
	return number not in bounds
