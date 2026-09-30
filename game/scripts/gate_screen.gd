extends Control
## The grown-ups gate. It asks for three digits written as words. It never
## asks a child's age and never shows a default answer.

const TT = preload("res://scripts/tt.gd")

const WORDS := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]

var main
var _digits: Array = []
var _typed := ""
var _display: Label
var _message: Label


func _ready() -> void:
	_new_code()
	var column := TT.screen_column(self, 24, 16, 24, 16)
	var root := HBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 24)
	column.add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	root.add_child(left)
	left.add_child(TT.label("Grown-ups only", 32, TT.INK, true))
	var ask := TT.label("Type these numbers to continue.", 18, TT.MUTED)
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(ask)
	var words := PanelContainer.new()
	words.add_theme_stylebox_override("panel", TT.box(TT.SUNKEN, TT.BORDER, 12, 2))
	var wl := TT.label(" · ".join(_words()), 26, TT.INK, true)
	wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(wl)
	left.add_child(words)
	_display = TT.label("_ _ _", 40, TT.INK, true)
	_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_display)
	_message = TT.label("", 16, TT.DANGER, true)
	left.add_child(_message)
	var cancel := TT.button("Cancel", "ghost")
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cancel.pressed.connect(func(): main.go("title"))
	left.add_child(cancel)

	var pad := GridContainer.new()
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", 8)
	pad.add_theme_constant_override("v_separation", 8)
	root.add_child(pad)
	for d in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
		pad.add_child(_key(str(d)))
	var del := TT.button("Del", "plain", 20)
	del.custom_minimum_size = Vector2(72, 64)
	del.pressed.connect(func():
		_typed = _typed.substr(0, _typed.length() - 1)
		_update())
	pad.add_child(del)
	pad.add_child(_key("0"))
	var ok := TT.button("Go", "primary", 20)
	ok.custom_minimum_size = Vector2(72, 64)
	ok.pressed.connect(_check)
	pad.add_child(ok)


func _key(digit: String) -> Button:
	var b := TT.button(digit, "plain", 24)
	b.custom_minimum_size = Vector2(72, 64)
	b.pressed.connect(func():
		if _typed.length() < 3:
			_typed += digit
			_update())
	return b


func _new_code() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_digits = []
	while _digits.size() < 3:
		var d := rng.randi_range(0, 9)
		if not _digits.has(d):
			_digits.append(d)


func _words() -> Array:
	var out: Array = []
	for d in _digits:
		out.append(WORDS[d])
	return out


func _update() -> void:
	var shown: Array = []
	for i in 3:
		shown.append(_typed[i] if i < _typed.length() else "_")
	_display.text = " ".join(shown)
	_message.text = ""


func expected() -> String:
	var s := ""
	for d in _digits:
		s += str(d)
	return s


func _check() -> void:
	if _typed == expected():
		main.go("parent")
	else:
		_typed = ""
		_new_code()
		main.go("gate")
