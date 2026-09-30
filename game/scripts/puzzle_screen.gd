extends Control
## One crate puzzle: read the goal, choose a part, press Try it.

const TT = preload("res://scripts/tt.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

const NONE := -999

var main
var puzzle: Dictionary
var choice: int = NONE
var tries: int = 0
var _diagram: Control
var _option_buttons: Array = []
var _try_button: Button
var _overlay: Control
var _mid: HBoxContainer
var _busy := false


func _ready() -> void:
	puzzle = Puzzles.by_id(main.puzzle_id)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 12
	root.offset_right = -16
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	var back := TT.button("<")
	back.pressed.connect(func(): main.go("workshop" if main.workshop_mode == "walk" and main.save.settings["walk"] else "shelf"))
	top.add_child(back)
	var goal_card := PanelContainer.new()
	goal_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_card.add_theme_stylebox_override("panel", TT.box(TT.RAISED, TT.INK, 12, 2))
	var goal := TT.label("Goal: " + puzzle["goal"], 18, TT.INK, true)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_card.add_child(goal)
	top.add_child(goal_card)
	var listen := TT.button("Listen", "info", 16)
	listen.pressed.connect(func(): main.audio.speak(puzzle["goal"]))
	top.add_child(listen)
	main.say(puzzle["goal"])

	_diagram = Control.new()
	_diagram.set_script(load("res://scripts/puzzle_diagram.gd"))
	_diagram.puzzle = puzzle
	_diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mid = HBoxContainer.new()
	_mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mid.add_theme_constant_override("separation", 10)
	root.add_child(_mid)
	_mid.add_child(_diagram)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	root.add_child(bottom)
	var pick := TT.label("Pick one", 14, TT.MUTED, true)
	pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(pick)
	for o in puzzle["options"]:
		var b := TT.button(Puzzles.option_label(puzzle, o), "plain", 20)
		b.custom_minimum_size = Vector2(96, 56)
		b.pressed.connect(func(): _pick(o))
		bottom.add_child(b)
		_option_buttons.append([o, b])
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)
	_try_button = TT.button("Try it", "energy", 22)
	_try_button.custom_minimum_size = Vector2(150, 56)
	_try_button.disabled = true
	_try_button.pressed.connect(_try)
	bottom.add_child(_try_button)
	_option_buttons[0][1].grab_focus()


func _pick(o: int) -> void:
	if _busy:
		return
	choice = o
	_diagram.choice = o
	_diagram.reveal = false
	_try_button.disabled = false
	for pair in _option_buttons:
		var picked: bool = pair[0] == o
		pair[1].add_theme_stylebox_override("normal", TT.box(TT.BRAND_TINT if picked else TT.RAISED, TT.INK, 12, 4 if picked else 2, not picked))
		pair[1].add_theme_stylebox_override("hover", TT.box(TT.BRAND_TINT if picked else TT.RAISED, TT.INK, 12, 4 if picked else 2, not picked))


func _try() -> void:
	if _busy or choice == NONE:
		return
	_busy = true
	tries += 1
	_diagram.reveal = true
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	if Puzzles.is_correct(puzzle, choice):
		_show_success()
	else:
		_show_miss()


## The answer panel opens beside the picture so the picture stays visible.
func _overlay_shell(fill: Color, border: Color) -> VBoxContainer:
	_clear_overlay()
	_overlay = PanelContainer.new()
	_overlay.custom_minimum_size = Vector2(330, 0)
	_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_overlay.add_theme_stylebox_override("panel", TT.box(fill, border, 20, 3, true))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_overlay.add_child(v)
	_mid.add_child(_overlay)
	return v


func _clear_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


func _show_success() -> void:
	main.audio.sfx("success")
	var concept: Dictionary = Puzzles.CONCEPTS[puzzle["concept"]]
	var reward: Dictionary = puzzle["reward"]
	var already: bool = main.save.is_solved(puzzle["id"])
	var v := _overlay_shell(TT.TEAL_TINT, TT.INK)
	v.add_child(TT.label("It works!", 26, TT.TEAL, true))
	v.add_child(TT.label(concept["title"], 20, TT.INK, true))
	var body := TT.label(concept["body"], 15, TT.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	var formula := TT.label(concept["formula"], 14, TT.TEAL, true)
	formula.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(formula)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fill)
	var row := HBoxContainer.new()
	v.add_child(row)
	var label := "Back to the shelf" if already else "Collect %s" % Puzzles.reward_text(puzzle)
	var collect := TT.button(label, "primary", 20)
	collect.custom_minimum_size = Vector2(0, 52)
	collect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collect.pressed.connect(func():
		main.audio.sfx("collect")
		main.collect(puzzle["id"])
		main.go("workshop" if main.workshop_mode == "walk" and main.save.settings["walk"] else "shelf"))
	row.add_child(collect)
	collect.grab_focus()


func _show_miss() -> void:
	main.audio.sfx("miss")
	main.say(Puzzles.describe(puzzle, choice))
	var v := _overlay_shell(TT.DANGER_TINT, TT.DANGER)
	v.add_child(TT.label("Not yet", 26, TT.INK, true))
	var what := TT.label(Puzzles.describe(puzzle, choice), 17, TT.INK)
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(what)
	if tries >= 2:
		var hint := TT.label("Hint: " + puzzle["hint"], 15, TT.MUTED, true)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(hint)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fill)
	var row := HBoxContainer.new()
	v.add_child(row)
	var again := TT.button("Try again", "info", 20)
	again.custom_minimum_size = Vector2(0, 52)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func():
		_clear_overlay()
		_busy = false
		_diagram.reveal = false)
	row.add_child(again)
	again.grab_focus()
