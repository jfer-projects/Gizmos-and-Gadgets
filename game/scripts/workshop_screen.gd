extends Control
## The crate shelf. Solve a crate's puzzle to find a new gear.

const TT = preload("res://scripts/tt.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

var main


func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_top = 14
	root.offset_right = -20
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var back := TT.button("<")
	back.pressed.connect(func(): main.go("map"))
	head.add_child(back)
	var title := TT.label("Workshop", 28, TT.INK, true)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)

	var owned_m: Array = main.save.owned("motor")
	var owned_w: Array = main.save.owned("wheel")
	var inv := TT.label("Your gears   Motor: %s   Wheel: %s" % [_teeth_list(owned_m), _teeth_list(owned_w)], 16, TT.MUTED, true)
	root.add_child(inv)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	var focused := false
	for i in Puzzles.count():
		var p: Dictionary = Puzzles.PUZZLES[i]
		var done: bool = main.save.is_solved(p["id"])
		var b := TT.button("", "energy" if done else "primary", 16)
		b.custom_minimum_size = Vector2(0, 76)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var reward: Dictionary = p["reward"]
		b.text = "%s\n%s" % [p["title"], ("Found %s" % Puzzles.reward_text(p)) if done else "Crate %d: tap to open" % (i + 1)]
		b.pressed.connect(func():
			main.puzzle_id = p["id"]
			main.go("puzzle"))
		grid.add_child(b)
		if not done and not focused:
			b.grab_focus()
			focused = true
	var note := TT.label("Every crate hides a gear. New gears show up in the Garage.", 16, TT.MUTED)
	root.add_child(note)


func _teeth_list(list: Array) -> String:
	var parts: PackedStringArray = []
	for t in list:
		parts.append("%dT" % t)
	return "  ".join(parts)
