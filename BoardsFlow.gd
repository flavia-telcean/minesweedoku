extends HFlowContainer
class_name BoardsFlow

enum GameMode {
    Normal,
    Encrypted,
}

signal symbol_flagged

var gm : GameMode

func _ready():
        gm = GameMode.Encrypted
        if(gm == GameMode.Encrypted):
                pass
        var mine_count := Label.new()
        mine_count.set_text(str(self.mine_grid.mine_number()))
        self.add_child(mine_count)

        self.symbol_grid.connect("symbol_flagged", func(): emit_signal("symbol_flagged"))

func _get(property: StringName) -> Variant:
        match(property):
                "mine_grid": return find_child("MineGrid")
                "symbol_grid": return find_child("SymbolGrid")
        return null

func can_autoreveal(t : Tile) -> bool:
        match(gm):
                GameMode.Encrypted: return self.symbol_grid.can_autoreveal(t)
        return true

func get_number(t : Tile) -> int:
        match(gm):
                GameMode.Encrypted: return self.symbol_grid.get_number(t)
        return t.number

func get_string(i: int) -> String:
        return self.symbol_grid._get_symbol(i)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
        pass
