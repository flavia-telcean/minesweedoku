class_name Parser

enum Tokens {
	Plus,
	Minus,
	Variable,
	Number,
	Slash,
	Left_parenthesis,
	Right_parenthesis,
	None,
	Bomb,
	Clear,
	Region,
	End,
}
class Token:
	var type : Tokens
	var varnum : int
	var number : int
	func assertions():
		if(type == Tokens.Variable):
			assert(varnum >= 0)
			assert(number == 0)
		elif(type == Tokens.Number):
			assert(varnum < 0)
		else:
			assert(varnum < 0)
			assert(number == 0)
var stream : String
var position : int = 0
var variables : Dictionary = {}
var current_token : Token
var variable_id : int = 1
var next_char : String
var tokens : Array[Token]
static var whitespace : Array[String] = [" ", "	", "\n", "\r"]
static var letters : Array = range(26).map(func (x): return char("a".unicode_at(0)+x)) + ["?"]
static var digits : Array = range(10).map(func (x): return char("0".unicode_at(0)+x))
static var level : Dictionary = {
	Tokens.Slash: [15, 15],
	Tokens.Plus: [10, 10],
	Tokens.Minus: [10, 5],
}

func get_char() -> String:
	if(position >= len(stream)):
		return char(26)
	position += 1
	return stream[position-1].to_lower()

func lex_next_token() -> Token:
	while(next_char in whitespace):
		next_char = get_char()
	if(next_char == char(26)):
		return create_end_token()
	if(next_char == "+"):
		return create_plus_token()
	if(next_char == "-"):
		return create_minus_token()
	if(next_char == "/"):
		return create_slash_token()
	if(next_char == "(" or next_char == ")"):
		return create_parenthesis_token()
	if(next_char in letters):
		return create_variable_token()
	if(next_char in digits):
		return create_number_token()
	assert(false)
	return Token.new()

func create_plus_token() -> Token:
	assert(next_char == "+")
	next_char = get_char()
	var t := Token.new()
	t.type = Tokens.Plus
	t.varnum = -1
	return t

func create_minus_token() -> Token:
	assert(next_char == "-")
	next_char = get_char()
	var t := Token.new()
	t.type = Tokens.Minus
	t.varnum = -1
	return t

func create_slash_token() -> Token:
	assert(next_char == "/")
	next_char = get_char()
	var t := Token.new()
	t.type = Tokens.Slash
	t.varnum = -1
	return t

func create_parenthesis_token() -> Token:
	var t := Token.new()
	if(next_char == "("):
		t.type = Tokens.Left_parenthesis
	elif(next_char == ")"):
		t.type = Tokens.Right_parenthesis
	else: assert(false)
	t.varnum = -1
	next_char = get_char()
	return t

func create_variable_token() -> Token:
	assert(next_char in letters)
	var s : String = ""
	while(next_char in letters):
		s += next_char
		next_char = get_char()
	var t := Token.new()
	match(s):
		"none":
			t.type = Tokens.None
		"bomb":
			t.type = Tokens.Bomb
		"clear":
			t.type = Tokens.Clear
		"region":
			t.type = Tokens.Region
		"?":
			t.type = Tokens.Variable
			variables[s] = randi()
			t.varnum = variables[s]
		_:
			t.type = Tokens.Variable
			if(s not in variables):
				variables[s] = hash(s)
			t.varnum = variables[s]
	return t
	
func create_number_token() -> Token:
	assert(next_char in digits)
	var s : String = ""
	while(next_char in digits):
		s += next_char
		next_char = get_char()
	var t := Token.new()
	t.type = Tokens.Number
	t.varnum = -1
	t.number = s.to_int()
	return t
	
func create_end_token() -> Token:
	assert(next_char == char(26))
	var t := Token.new()
	t.type = Tokens.End
	t.varnum = -1
	return t

func tokenize():
	position = 0
	next_char = get_char()
	var t : Token = lex_next_token()
	while(t.type != Tokens.End):
		tokens.append(t)
		t = lex_next_token()

var token_position : int = 0
var next_token : Token

func get_next_token() -> Token:
	if(token_position >= len(tokens)):
		return create_end_token()
	token_position += 1
	return tokens[token_position - 1]

func parse_parenthesis() -> Array:
	assert(next_token.type == Tokens.Left_parenthesis)
	var units : Array = []
	next_token = get_next_token()
	while(next_token.type != Tokens.Right_parenthesis):
		assert(next_token.type != Tokens.End)
		if(next_token.type == Tokens.Left_parenthesis):
			units.append(parse_parenthesis())
		else:
			units.append(next_token)
		next_token = get_next_token()
	return units

func make_tree() -> Array:
	var units : Array = []
	next_token = get_next_token()
	while(next_token.type != Tokens.End):
		if(next_token.type == Tokens.Left_parenthesis):
			units.append(parse_parenthesis())
		else:
			units.append(next_token)
		next_token = get_next_token()
	return units

func parse(tree : Array) -> Formula:
	assert(len(tree))
	if(len(tree) == 1):
		var element = tree[0];
		if(typeof(element) == TYPE_ARRAY):
			return parse(element)
		else:
			element.assertions()
			match(element.type):
				Tokens.Variable: return Formula.make_variable(element.varnum)
				Tokens.Number: return Formula.make_number(element.number)
				_: assert(false);
	for i in level:
		var tokens_of_this_level : Array = tree.filter(func (x): return (not typeof(x) == TYPE_ARRAY) and x.type == i)
		if(len(tokens_of_this_level) > 0):
			var first_tree : Array = []
			var second_tree : Array = []
			var found : int = 0
			for j in tree:
				if(typeof(j) != TYPE_ARRAY):
					j.assertions()
				if(typeof(j) == TYPE_ARRAY and not found):
					first_tree.append(j)
					continue
				if(typeof(j) == TYPE_ARRAY or found):
					second_tree.append(j)
					continue
				
				if(j.type == i):
					found = true
					continue
				if(j.type in level):
					assert(level[j.type][0] <= level[i][0])
				first_tree.append(j)
			match(i):
				Tokens.Slash:
					return Formula.make_slash(parse(first_tree), parse(second_tree))
				Tokens.Plus:
					if(len(second_tree) == 0):
						return Formula.make_gte(parse(first_tree))
					return Formula.make_plus(parse(first_tree), parse(second_tree))
				Tokens.Minus:
					if(len(second_tree) == 0):
						return Formula.make_lte(parse(first_tree))
					return Formula.make_minus(parse(first_tree), parse(second_tree))
				_: assert(false)
			
	return Formula.make_false()

func make_tree_string(s : String) -> Array:
	stream = s
	next_char = char(26)
	token_position = 0
	tokens = []
	next_token = create_end_token()
	tokenize()
	return make_tree()

func parse_string(s : String):
	return parse(make_tree_string(s))
