extends Control
## The Codex: every idea the crates teach. Unlearned cards stay hidden.

const TT = preload("res://scripts/tt.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

var main


func _ready() -> void:
	var root := TT.screen_column(self, 20, 12, 20, 12)
	root.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var back := TT.button("<")
	back.pressed.connect(func(): main.go(main.back_target()))
	head.add_child(back)
	var title := TT.label("Codex", 28, TT.INK, true)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for id in Puzzles.CONCEPTS:
		grid.add_child(_card(id))


func _card(id: String) -> Control:
	var c: Dictionary = Puzzles.CONCEPTS[id]
	var known: bool = main.save.learned_concepts().has(id)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", TT.box(TT.TEAL_TINT if known else TT.SUNKEN, TT.INK if known else TT.BORDER, 20, 2, known))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(TT.label(c["title"] if known else "? ? ?", 22, TT.INK if known else TT.MUTED, true))
	var body := TT.label(c["body"] if known else "Solve a crate to learn this.", 16, TT.INK if known else TT.MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	if known:
		v.add_child(TT.label(c["formula"], 15, TT.TEAL, true))
		var listen := TT.button("Listen", "ghost", 15)
		listen.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		listen.pressed.connect(func(): main.audio.speak("%s. %s" % [c["title"], c["body"]]))
		v.add_child(listen)
	return p
