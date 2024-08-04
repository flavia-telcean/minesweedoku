class_name Region

var cells : Array[Cell]
var formula : Formula
var id : int

func remove_mine(mine_grid : MineGrid, old_id : int):
	cells = cells.filter(func(x): return x.id != old_id)
	formula.remove_mine()
	mine_grid.remove_point(old_id, self.id, str(formula))

func clear_cell(mine_grid : MineGrid, old_id : int):
	mine_grid.remove_point(old_id, self.id, str(formula))
	cells = cells.filter(func(x): return x.id != old_id)

func add_cell(new_id : int, tile : Tile):
	var cell := Cell.new(new_id)
	cells.append(cell)

func has_cell(id : int) -> bool:
	for i in cells:
		if(i.id == id):
			return true
	return false

func count_cells_not_in(other : Region) -> int:
	var count : int = 0
	for i in cells:
		if(i not in other.cells):
			count += 1
	return count
	
func count_cells_in(other : Region) -> int:
	var count : int = 0
	for i in cells:
		if(i in other.cells):
			count += 1
	return count

func count_cells() -> int:
	return len(cells)

func cell_ids() -> Array[int]:
	var ids : Array[int] = []
	for cell in cells:
		ids.append(cell.id)
	return ids

func create_line(mine_grid : MineGrid):
	mine_grid.create_line(cell_ids(), id, str(formula.number))
