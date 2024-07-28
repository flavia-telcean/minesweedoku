extends HFlowContainer
class_name BoardsFlow

enum GameMode {
    Normal,
    Encrypted,
}

@export_range(5, 20) var board_size : int

signal symbol_flagged
signal flagged

@export var gm : GameMode
var symbol_board : SymbolGrid
var mine_board : MineGrid

func setup_symbol_board():
        assert(board_size <= 9)

        symbol_board = SymbolGrid.new()
        symbol_board.set_name("SymbolGrid")
        symbol_board.set_n_symbols(board_size)

        symbol_board.connect("symbol_flagged", func(): emit_signal("symbol_flagged"))
        self.add_child(symbol_board)

func setup_mine_board():
        mine_board = MineGrid.new()
        mine_board.set_name("MineGrid")
        mine_board.set_board_size(board_size, board_size)
        if(gm == GameMode.Encrypted):
                mine_board.max_neighbours = board_size - 1

        mine_board.connect("flagged", func(): emit_signal("flagged"))
        self.add_child(mine_board)

func _ready():
        setup_mine_board()
        if(gm == GameMode.Encrypted):
                setup_symbol_board()

func can_autoreveal(t : Tile) -> bool:
        match(gm):
                GameMode.Encrypted: return symbol_board.can_autoreveal(t)
        return true

func get_number(t : Tile) -> int:
        match(gm):
                GameMode.Encrypted: return symbol_board.get_number(t)
        return t.number

func get_string(i: int) -> String:
        return symbol_board.get_symbol(i)

func get_progress_string() -> String:
        return str(mine_board.flag_count()) + " / " + str(mine_board.mine_count())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
        pass
