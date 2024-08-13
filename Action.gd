extends Object
class_name Action

enum Type {
	None,
	Bomb,
	Clear,
	NewRegion,
	Show,
	Hide,
	Trash,
}

var type : Type
var regionformula : Formula
var regionid : int
var regionhidden : bool = false
var bounds : Array[int]
var name : String

static func from_json(d : Dictionary) -> Action:
	var a := Action.new()
	a.type = Type[d["type"]]
	assert(a.type != null)
	if(a.type == Type.NewRegion):
		a.regionid = d["id"]
		var parser := Parser.new()
		a.regionformula = parser.parse_string(d["formula"])
		if("hidden" in d):
			a.regionhidden = d["hidden"]
	return a


func to_json() -> Dictionary:
	var x = {
		"type": Type.keys()[type],
	}
	if(type == Type.NewRegion):
		x["id"] = regionid
		x["formula"] = str(regionformula)
		if(regionhidden == true):
			x["hidden"] = true
	return x

func apply(solver : Solver, mine_grid : MineGrid, variables : Variables, cells : Array[Cell], applicationid : int, original_region : Region = null):
	match(type):
		Type.None: pass
		Type.Bomb:
			for cell in cells:
				mine_grid.indexize(mine_grid.idemflag, cell.id)
		Type.Clear:
			for cell in cells:
				mine_grid.indexize(mine_grid.reveal, cell.id)
		Type.NewRegion:
			if(len(cells) == 0):
				return
			var found_regions : Array[Region] = solver.regions.filter(func (x): return x.id == hash(applicationid + regionid))
			assert(len(found_regions) <= 1)
			if(len(found_regions) == 1):
				found_regions[0].cells += cells
				solver.update_region(found_regions[0])
				return
			var region := Region.new()
			region.cells = cells.duplicate()
			region.id = hash(applicationid + regionid)
			region.hidden = regionhidden
			region.formula = regionformula.duplicate()
			region.formula.replace_variables(variables)
			solver.new_region(region)
		Type.Show:
			assert(original_region)
			original_region.hidden = false
			original_region.create_line(mine_grid)
		Type.Hide:
			assert(original_region)
			original_region.hidden = true
			original_region.remove_line(mine_grid)
		Type.Trash:
			assert(original_region)
			assert(!"TODO")

func set_bounds(b : Array[int]):
	self.bounds = b
	if(self.regionformula):
		self.regionformula.set_bounds(b)

func is_unbounded(variables : Variables) -> bool:
	if(not regionformula):
		return false
	for v in variables.variables:
		if(v in regionformula.variables and variables.variables[v].number not in bounds):
			return true
	return false

func change_type(t : Type):
	if(type != Type.NewRegion and t == Type.NewRegion):
		regionformula = Formula.make_false()
		regionhidden = false
		regionid = 0
	else:
		regionformula = null
		regionhidden = false
		regionid = 0
	type = t

func on_edited(item : TreeItem):
	if(item.get_text(0) == "ID"):
		regionid = item.get_text(1).to_int()
	if(item.get_text(0) == "Hidden"):
		regionhidden = item.get_range(1)
	else:
		change_type(int(item.get_range(1)))
		create_menu(item)

func create_option_button(item : TreeItem):
	item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	item.set_text(1, ",".join(Type.keys()))
	item.set_range(1, type)
	item.set_metadata(1, self)
	item.set_editable(1, true)

func create_menu(parent : TreeItem):
	var tree = parent.get_tree()
	var menu = tree.create_item(parent)
	menu.get_children().map(func(x): menu.remove_child(x))
	create_option_button(menu)
	menu.set_text(0, name)
	if(type == Action.Type.NewRegion):
		var id_item = tree.create_item(menu)
		id_item.set_text(0, "ID")
		id_item.set_text(1, str(regionid))
		id_item.set_editable(1, true)
		var hidden_item = tree.create_item(menu)
		hidden_item.set_text(0, "Hidden")
		hidden_item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
		hidden_item.set_checked(1, regionhidden)
		hidden_item.set_metadata(1, self)
		hidden_item.set_editable(1, true)
		regionformula.create_menu(menu)
