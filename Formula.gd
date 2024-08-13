class_name Formula

enum Type {
	Slash,
	Variable,
	Gte,
	Lte,
	Plus,
	PlusPlus,
	Minus,
	MinusMinus,
	Number,
	False,
	Any,
}
var type : Type
var c1 : Formula
var c2 : Formula
var number : int
var varnum : int
var name : String
var description : String
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

static func make_binary_operator(t : Type, a : Formula, b : Formula) -> Formula:
	var x := Formula.new()
	x.type = t
	x.c1 = a
	x.c2 = b
	x.varnum = -1
	x.variables = a.variables + b.variables
	return x
static func make_plus(a : Formula, b : Formula) -> Formula:
	return make_binary_operator(Type.Plus, a, b)
static func make_plusplus(a : Formula, b : Formula) -> Formula:
	return make_binary_operator(Type.PlusPlus, a, b)
static func make_minus(a : Formula, b : Formula) -> Formula:
	return make_binary_operator(Type.Minus, a, b)
static func make_minusminus(a : Formula, b : Formula) -> Formula:
	return make_binary_operator(Type.MinusMinus, a, b)
static func make_slash(a : Formula, b : Formula) -> Formula:
	return make_binary_operator(Type.Slash, a, b)
static func make_variable(id : int, Name : String = "") -> Formula:
	var x := Formula.new()
	x.type = Type.Variable
	x.varnum = id
	if(Name):
		x.name = Name
	else:
		x.name = "#" + str(id % 10)
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

func assertions(safe : bool = true):
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
		Type.PlusPlus:
			assert(number == 0)
			assert(c1 and c2)
			assert(varnum < 0)
		Type.Minus:
			assert(number == 0)
			assert(c1 and c2)
			assert(varnum < 0)
		Type.MinusMinus:
			assert(number == 0)
			assert(c1 and c2)
			assert(varnum < 0)
		Type.Number:
			assert(varnum < 0)
			if(safe and bounds):
				assert(number in bounds)
		Type.False:
			assert(number == 0)
			assert(varnum < 0)
		Type.Any:
			assert(number == 0)
			assert(varnum < 0)

func remove_mine(safe : bool = true):
	assertions(safe)
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
		Type.PlusPlus:
			c2.remove_mine()
		Type.Minus:
			c1.remove_mine()
		Type.MinusMinus:
			c1.remove_mine()
		Type.Number:
			number -= 1
	cleanup(safe)

func copy(other : Formula, deep : bool = true):
	type = other.type
	varnum = other.varnum
	name = other.name
	number = other.number
	if(other.c1 and deep):
		c1 = Formula.new()
		c1.copy(other.c1)
	else:
		c1 = other.c1
	if(other.c2 and deep):
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
		c1.copy(c1.c1, false)
	elif(c1.type == Type.Gte or c1.type == Type.Lte):
		copy(c1.c1, false)

func cleanup(safe : bool = true):
	assertions(safe)
	match(type):
		Type.Slash:
			if(c1.is_unbounded()):
				copy(c2, false)
				cleanup(safe)
			elif(c2.is_unbounded()):
				copy(c1, false)
				cleanup(safe)
		Type.Gte:
			inequality_cleanup()
		Type.Lte:
			inequality_cleanup()
		Type.Plus:
			c1.cleanup(safe)
			c2.cleanup(safe)
			if(c2.type == Type.Number and c2.number == 0):
				copy(c1, false)
			elif(c2.type == Type.Number and c2.number < 0):
				c2.number = -c2.number
				type = Type.Minus
			elif(c1.type == Type.Plus and c1.c2.type == Type.Number and c2.type == Type.Number):
				c2.number += c1.c2.number
				c1.copy(c1.c1, false)
			elif(c1.type == Type.Number and c2.type == Type.Number):
				copy(Formula.make_number(c1.number + c2.number))
			elif(c1.type == Type.Number):
				var c3 := Formula.new()
				c3.copy(c1, false)
				c1.copy(c2, false)
				c2.copy(c3, false)
			else:
				return
			cleanup(safe)
		Type.Minus:
			c1.cleanup(safe)
			c2.cleanup(safe)
			if(c2.type == Type.Number and c2.number == 0):
				copy(c1, false)
			elif(c2.type == Type.Number and c2.number < 0):
				c2.number = -c2.number
				type = Type.Plus
			elif(c1.type == Type.Plus and c1.c2.type == Type.Number and c2.type == Type.Number):
				c2.number -= c1.c2.number
				c1.copy(c1.c1, false)
			elif(c1.type == Type.Number and c2.type == Type.Number):
				copy(Formula.make_number(c1.number - c2.number))
			else:
				return
			cleanup(safe)

func equal(other : Formula) -> bool:
	if(type != other.type):
		return false
	if(c1 and not c1.equal(other.c1)):
		return false
	if(c2 and not c2.equal(other.c2)):
		return false
	return number == other.number and varnum == other.varnum

func for_each_child(f : Callable):
	match(type):
		Type.Plus:
			f.call(c1)
			f.call(c2)
		Type.PlusPlus:
			f.call(c1)
			f.call(c2)
		Type.Minus:
			f.call(c1)
			f.call(c2)
		Type.MinusMinus:
			f.call(c1)
			f.call(c2)
		Type.Slash:
			f.call(c1)
			f.call(c2)
		Type.Gte:
			f.call(c1)
		Type.Lte:
			f.call(c1)

func replace_variables(vars : Variables):
	assertions(false)
	if(len(variables) == 0):
		return
	for_each_child(func (c): c.replace_variables(vars))
	if(type == Type.Variable and varnum in vars.variables):
		copy(vars.variables[varnum], true)
	cleanup(false)

func solve_plus(other : Formula, vars : Variables):
	var added : bool = false
	if(len(c1.variables) > 0):
		var t1 : Formula = c1.duplicate()
		t1.replace_variables(vars)
		var solution : Variables = t1.solve_equation(Formula.make_minus(other, c2), vars.duplicate())
		if(solution.is_match() and vars.merge_without_conflicts(solution)):
			added = true
	if(len(c2.variables) > 0):
		var t2 : Formula = c2.duplicate()
		t2.replace_variables(vars)
		var solution : Variables = t2.solve_equation(Formula.make_minus(other, c1), vars.duplicate())
		if(solution.is_match() and vars.merge_without_conflicts(solution)):
			added = true
	return added

func solve_minus(other : Formula, vars : Variables) -> bool:
	var added : bool = false
	if(len(c1.variables) > 0):
		var t1 : Formula = c1.duplicate()
		t1.replace_variables(vars)
		var solution : Variables = t1.solve_equation(Formula.make_plus(other, c2), vars.duplicate())
		if(solution.is_match() and vars.merge_without_conflicts(solution)):
			added = true
	if(len(c2.variables) > 0):
		var t2 : Formula = c2.duplicate()
		t2.replace_variables(vars)
		var solution : Variables = t2.solve_equation(Formula.make_minus(c1, other), vars.duplicate())
		if(solution.is_match() and vars.merge_without_conflicts(solution)):
			added = true
	return added

func solve_equation(other : Formula, vars : Variables = Variables.new()) -> Variables:
	cleanup(false)
	other.cleanup(false)
	match(type):
		Type.False: return Variables.new()
		Type.Number:
			if(other.type == Type.Number):
				if(other.number == number):
					return Variables.new_match()
				else:
					return Variables.new()
			return other.solve_equation(self)
		Type.Variable:
			if(name == "?"): # FIXME make more robust
				vars.insert_any_variable(varnum)
			elif(not vars.insert_without_conflicts(varnum, other)):
				return Variables.new()
			else:
				var value : Formula = other.duplicate()
				value.replace_variables(vars)
				value.set_bounds(self.bounds)
				vars.variables[varnum] = value
		Type.Plus:
			if(not solve_plus(other, vars)):
				return Variables.new()
		Type.PlusPlus:
			if(not solve_plus(other, vars)):
				return Variables.new()
		Type.Minus:
			if(not solve_minus(other, vars)):
				return Variables.new()
		Type.MinusMinus:
			if(not solve_minus(other, vars)):
				return Variables.new()
		Type.Slash:
			vars.merge(c1.solve_equation(other))
			vars.merge(c1.solve_equation(other))
		_:
			assert(false)
	return vars

func is_form_operator() -> bool:
	return type != Type.PlusPlus and type != Type.MinusMinus

func generalizes(other : Formula, rewriting : bool = false, found : Variables = Variables.new()) -> bool:
	var form_match : bool = rewriting and is_form_operator()
	if(not form_match and other.type == Type.Number and len(variables) > 0):
		var solution : Variables = solve_equation(other, found)
		if(solution.is_match()):
			found.merge_without_conflicts(solution)
			return true
	match(type):
		Type.False: return false
		Type.Any:
			found.insert_any_variable(varnum)
			return rewriting
		Type.Number:
			if(other.type != Type.Number):
				return false
			return other.number == number
		Type.Variable:
			match(other.type):
				Type.False: return true
				Type.Any:
					found.insert_any_variable(varnum)
					return rewriting
				Type.Number:
					if(varnum not in found.variables):
						found.variables[varnum] = other
						return true
					return found.variables[varnum].number == other.number
				Type.Variable:
					if(not rewriting):
						found.variables[varnum] = other
						return varnum == other.varnum
					if(varnum not in found.variables):
						found.variables[varnum] = other
						return true
					return found.variables[varnum].equal(other)
					
				Type.Plus: return false # XXX
				Type.Minus: return false
				Type.Slash: return false
				_: return false
		Type.Plus:
			if(other.type != Type.Plus):
				return false
			return c1.generalizes(other.c1, rewriting, found) and c2.generalizes(other.c2, rewriting, found)
		Type.PlusPlus:
			var calculated : Formula = self.duplicate()
			calculated.replace_variables(found)
			if(calculated.type == Type.PlusPlus):
				return false
			return calculated.generalizes(other, rewriting, found)
		Type.Minus:
			if(other.type != Type.Minus):
				return false
			return c1.generalizes(other.c1, rewriting, found) and c2.generalizes(other.c2, rewriting, found)
		Type.MinusMinus:
			var calculated : Formula = self.duplicate()
			calculated.replace_variables(found)
			if(calculated.type == Type.MinusMinus):
				return false
			return calculated.generalizes(other, rewriting, found)
		Type.Slash:
			if(other.type != Type.Slash):
				return false
			return c1.generalizes(other.c1, rewriting, found) and c2.generalizes(other.c2, rewriting, found)
		Type.Gte:
			if(other.type == Type.Gte):
				return c1.generalizes(other.c1, rewriting, found)
			if(other.type == Type.Number):
				assert(c1.type == Type.Number)
				return other.number >= c1.number
			return false
		Type.Lte:
			if(other.type == Type.Lte):
				return c1.generalizes(other.c1, rewriting, found)
			if(other.type == Type.Number):
				assert(c1.type == Type.Number)
				return other.number <= c1.number
			return false
		_:
			assert(false)
			return false

func duplicate() -> Formula:
	var x := Formula.new()
	x.copy(self, true)
	return x

func _to_string():
	assertions()
	match(type):
		Type.Number:
			return str(number)
		Type.Variable:
			return name
		Type.False:
			return "!"
		Type.Any:
			return "?"
		Type.Plus:
			return c1._to_string() + " + " + c2._to_string()
		Type.PlusPlus:
			return c1._to_string() + " ++ " + c2._to_string()
		Type.Minus:
			return c1._to_string() + " - (" + c2._to_string() + ")"
		Type.MinusMinus:
			return c1._to_string() + " -- (" + c2._to_string() + ")"
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
	for_each_child(func (c): c.set_bounds(b))
	
func is_unbounded():
	if(type != Type.Number):
		return false
	return number not in bounds

func on_edited(item : TreeItem):
	var p := Parser.new()
	var f = p.parse_string(item.get_text(1))
	copy(f)

func create_menu(parent : TreeItem):
	var tree = parent.get_tree()
	var formula_item = tree.create_item(parent)
	if(description):
		formula_item.set_text(0, description)
	elif(name):
		formula_item.set_text(0, name)
	else:
		formula_item.set_text(0, "Formula")
	formula_item.set_text(1, str(self))
	formula_item.set_metadata(1, self)
	formula_item.set_editable(1, true)
