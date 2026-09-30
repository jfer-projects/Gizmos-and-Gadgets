extends Control
## The walkable workshop. Walk to a crate to open its puzzle, carry what you
## find to the drop-off door, and snooze the pest if it grabs something.
##
## Controls: arrow keys or WASD, the on-screen stick, or tap where to go.
## Everything here is also reachable from the list view.

const TT = preload("res://scripts/tt.gd")
const Rooms = preload("res://scripts/rooms.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

const SPEED := 175.0
const PLAYER_R := 15.0
const CRATE_SIZE := Vector2(62, 50)
const REACH := 64.0
const PEST_SPEED := 62.0
const PEST_FLEE_SPEED := 105.0
const PEST_HOLD_SECONDS := 12.0
const SNOOZE_SECONDS := 4.0
const SNOOZE_RANGE := 170.0
const STICK_R := 60.0

var main
var room: int = 0
var _floor := Rect2()
var _crate_cache: Array = []
var _crate_floor := Rect2()
var _player := Vector2.ZERO
var _target = null              # Vector2 to walk to, or null
var _target_crate: String = ""  # puzzle id to open on arrival
var _stick_center := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _stick_on := false
var _pests: Array = []
var _rng := RandomNumberGenerator.new()
var _toast := ""
var _toast_left := 0.0
var _whistle_cooldown := 0.0
var _t := 0.0
var _open_button: Button
var _whistle_button: Button
var _carry_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # let taps reach _unhandled_input
	_rng.randomize()
	room = main.room_index
	_layout()
	if main.player_pos.x < 0.0:
		_player = _floor.position + Vector2(_floor.size.x * 0.06, _floor.size.y * 0.5)
	else:
		_player = _floor.position + main.player_pos * _floor.size
	if main.save.settings["pests"]:
		_pests.append(_new_pest(Vector2(0.55, 0.5)))
	_build_hud()
	_layout()
	resized.connect(_layout)


func _layout() -> void:
	_floor = Rect2(20, 74, size.x - 40, size.y - 74 - 16)
	_stick_center = Vector2(88, size.y - 88)
	if _open_button != null:
		_open_button.position = Vector2(size.x - 170 - 24, size.y - 60 - 20)
	if _whistle_button != null:
		_whistle_button.position = Vector2(size.x - 170 - 24, size.y - 60 - 20 - 56)


func _build_hud() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 20
	bar.offset_right = -20
	bar.offset_top = 10
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)
	var back := TT.button("<")
	back.pressed.connect(_leave)
	bar.add_child(back)
	for i in Rooms.ROOMS.size():
		var b := TT.button(Rooms.ROOMS[i]["name"], "primary" if i == room else "plain", 16)
		b.pressed.connect(func(): _go_room(i))
		bar.add_child(b)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_carry_label = TT.label("", 16, TT.INK, true)
	_carry_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_carry_label)
	var list := TT.button("List", "ghost", 16)
	list.pressed.connect(func(): main.go("shelf"))
	bar.add_child(list)

	_open_button = TT.button("Open crate", "primary", 20)
	_open_button.custom_minimum_size = Vector2(170, 60)
	_open_button.visible = false
	_open_button.pressed.connect(_open_nearest)
	add_child(_open_button)

	if main.save.settings["pests"]:
		_whistle_button = TT.button("Snooze pest", "energy", 16)
		_whistle_button.custom_minimum_size = Vector2(170, 48)
		_whistle_button.pressed.connect(_snooze)
		add_child(_whistle_button)
	_update_carry_label()


func _update_carry_label() -> void:
	_carry_label.text = "Carrying %d / %d" % [main.carried.size(), Rooms.MAX_CARRY]


func _go_room(i: int) -> void:
	main.room_index = i
	main.player_pos = Vector2(-1, -1)
	main.go("workshop")


func _leave() -> void:
	main.deliver_carried()  # never lose finds by walking away
	main.player_pos = Vector2(-1, -1)
	main.go("map")


# --- world -------------------------------------------------------------------

## The room's crates, rebuilt only when the floor changes size.
func _crates() -> Array:
	if _crate_cache.is_empty() or _crate_floor != _floor:
		_crate_cache = _build_crates()
		_crate_floor = _floor
	return _crate_cache


func _build_crates() -> Array:
	var out: Array = []
	var ids := Rooms.puzzles_in(room)
	var spots: Array = Rooms.ROOMS[room]["spots"]
	for i in ids.size():
		var c: Vector2 = _floor.position + spots[i] * _floor.size
		out.append({"id": ids[i], "rect": Rect2(c - CRATE_SIZE * 0.5, CRATE_SIZE)})
	return out


func _drop_rect() -> Rect2:
	var d := Rooms.DROP_ZONE
	return Rect2(_floor.position + d.position * _floor.size, d.size * _floor.size)


func _blocked(p: Vector2) -> bool:
	if not _floor.grow(-PLAYER_R).has_point(p):
		return true
	for c in _crates():
		if (c["rect"] as Rect2).grow(PLAYER_R).has_point(p):
			return true
	return false


func _new_pest(frac: Vector2) -> Dictionary:
	return {"pos": _floor.position + frac * _floor.size, "goal": Vector2.ZERO, "wait": 0.0, "state": "wander", "timer": 0.0, "held": ""}


func _nearest_crate() -> Dictionary:
	var best: Dictionary = {}
	var best_d := REACH
	for c in _crates():
		var d := ((c["rect"] as Rect2).get_center()).distance_to(_player)
		if d < best_d:
			best_d = d
			best = c
	return best


func _open_nearest() -> void:
	var c := _nearest_crate()
	if not c.is_empty():
		_open(c["id"])


func _open(id: String) -> void:
	if main.carried.size() >= Rooms.MAX_CARRY and not main.save.is_solved(id) and not main.carried.has(id):
		_say("Your hands are full. Drop off at the door first.")
		return
	main.player_pos = (_player - _floor.position) / _floor.size
	main.puzzle_id = id
	main.workshop_mode = "walk"
	main.go("puzzle")


func _say(text: String) -> void:
	_toast = text
	_toast_left = 2.6
	main.say(text)


# --- input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _open_button.visible:
		_open_nearest()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_leave()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_down(event.position)
		else:
			_stick_on = false
			_stick_vec = Vector2.ZERO
	elif event is InputEventMouseMotion and _stick_on:
		_stick_vec = ((event.position - _stick_center) / STICK_R).limit_length(1.0)


func _pointer_down(pos: Vector2) -> void:
	if pos.distance_to(_stick_center) < STICK_R * 1.4:
		_stick_on = true
		_stick_vec = ((pos - _stick_center) / STICK_R).limit_length(1.0)
		_target = null
		_target_crate = ""
		return
	for c in _crates():
		if (c["rect"] as Rect2).grow(10).has_point(pos):
			_target_crate = c["id"]
			_target = (c["rect"] as Rect2).get_center()
			return
	if _floor.has_point(pos):
		_target = pos
		_target_crate = ""


func _keyboard_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		d.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		d.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		d.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		d.y += 1
	return d.normalized()


# --- update ------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	_whistle_cooldown = maxf(0.0, _whistle_cooldown - delta)
	_toast_left = maxf(0.0, _toast_left - delta)
	_move_player(delta)
	for pest in _pests:
		_update_pest(pest, delta)
	var near := _nearest_crate()
	_open_button.visible = not near.is_empty()
	if not near.is_empty():
		var label := "Open crate" if not (main.save.is_solved(near["id"]) or main.carried.has(near["id"])) else "Look again"
		if _open_button.text != label:
			_open_button.text = label
	if _whistle_button != null:
		_whistle_button.disabled = _whistle_cooldown > 0.0
	if _drop_rect().grow(6).has_point(_player) and not main.carried.is_empty():
		var names: Array = []
		for id in main.carried:
			names.append(Puzzles.reward_text(Puzzles.by_id(id)))
		main.deliver_carried()
		main.audio.sfx("collect")
		_say("Dropped off: %s" % ", ".join(names))
		_update_carry_label()
	queue_redraw()


func _move_player(delta: float) -> void:
	var v := _keyboard_dir()
	if _stick_on:
		v = _stick_vec
	elif v == Vector2.ZERO and _target != null:
		var to: Vector2 = _target - _player
		if _target_crate != "":
			if (_target as Vector2).distance_to(_player) < REACH - 4.0:
				var id := _target_crate
				_target = null
				_target_crate = ""
				_open(id)
				return
		if to.length() < 6.0:
			_target = null
		else:
			v = to.normalized()
	elif v != Vector2.ZERO:
		_target = null
		_target_crate = ""
	if v == Vector2.ZERO:
		return
	var step := v * SPEED * delta
	# move on each axis separately so the player slides along walls and crates
	if not _blocked(_player + Vector2(step.x, 0)):
		_player.x += step.x
	if not _blocked(_player + Vector2(0, step.y)):
		_player.y += step.y


func _update_pest(pest: Dictionary, delta: float) -> void:
	pest["timer"] = float(pest["timer"]) - delta
	match pest["state"]:
		"asleep":
			if pest["timer"] <= 0.0:
				pest["state"] = "wander"
		"flee":
			var away: Vector2 = (pest["pos"] - _player).normalized()
			_pest_step(pest, away * PEST_FLEE_SPEED * delta)
			if pest["timer"] <= 0.0:
				# it gives the item back on its own, so nothing is ever lost
				main.carried.append(pest["held"])
				pest["held"] = ""
				pest["state"] = "wander"
				_say("The pest gave it back.")
				_update_carry_label()
		_:
			pest["wait"] = float(pest["wait"]) - delta
			if pest["wait"] <= 0.0 or (pest["pos"] as Vector2).distance_to(pest["goal"]) < 6.0:
				pest["goal"] = _floor.position + Vector2(_rng.randf(), _rng.randf()) * _floor.size
				pest["wait"] = _rng.randf_range(1.5, 3.5)
			var dir: Vector2 = ((pest["goal"] as Vector2) - (pest["pos"] as Vector2)).normalized()
			_pest_step(pest, dir * PEST_SPEED * delta)
			if not main.carried.is_empty() and (pest["pos"] as Vector2).distance_to(_player) < PLAYER_R + 16.0:
				pest["held"] = main.carried.pop_front()
				pest["state"] = "flee"
				pest["timer"] = PEST_HOLD_SECONDS
				main.audio.sfx("pest")
				_say("The pest grabbed %s! Snooze it." % Puzzles.reward_text(Puzzles.by_id(pest["held"])))
				_update_carry_label()


func _pest_step(pest: Dictionary, step: Vector2) -> void:
	var p: Vector2 = pest["pos"]
	var nx := p + Vector2(step.x, 0)
	if _floor.grow(-14).has_point(nx) and not _in_crate(nx):
		p = nx
	var ny := p + Vector2(0, step.y)
	if _floor.grow(-14).has_point(ny) and not _in_crate(ny):
		p = ny
	pest["pos"] = p


func _in_crate(p: Vector2) -> bool:
	for c in _crates():
		if (c["rect"] as Rect2).grow(12).has_point(p):
			return true
	return false


func _snooze() -> void:
	if _whistle_cooldown > 0.0:
		return
	_whistle_cooldown = 2.0
	main.audio.sfx("whistle")
	for pest in _pests:
		if (pest["pos"] as Vector2).distance_to(_player) <= SNOOZE_RANGE:
			pest["state"] = "asleep"
			pest["timer"] = SNOOZE_SECONDS
			if pest["held"] != "":
				main.carried.append(pest["held"])
				pest["held"] = ""
				_say("You got it back!")
				_update_carry_label()


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	TT.draw_grid(self, size)
	# floor and walls
	draw_rect(_floor, TT.SUNKEN)
	draw_rect(_floor, TT.INK, false, 3.0)
	var shelf_y := _floor.position.y - 10
	for k in 5:
		draw_rect(Rect2(_floor.position.x + 40 + k * (_floor.size.x - 120) / 4.0, shelf_y - 4, 90, 8), TT.BORDER)
	# drop-off door
	var drop := _drop_rect()
	draw_rect(drop, TT.BRAND_TINT)
	for k in 12:
		var a := drop.position + Vector2(0, drop.size.y * k / 12.0)
		draw_line(a, a + Vector2(0, drop.size.y / 24.0), TT.INK, 3.0)
	draw_rect(drop, TT.INK, false, 3.0)
	var f := TT.bold_font()
	draw_string(f, drop.position + Vector2(8, drop.size.y * 0.5 - 4), "DROP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, TT.INK)
	draw_string(f, drop.position + Vector2(8, drop.size.y * 0.5 + 14), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, TT.INK)
	# crates
	for c in _crates():
		_draw_crate(c)
	# pests, then the player on top
	for pest in _pests:
		_draw_pest(pest)
	_draw_player()
	_draw_stick()
	if _toast_left > 0.0:
		var w := f.get_string_size(_toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 32.0
		var r := Rect2((size.x - w) * 0.5, size.y - 64, w, 40)
		draw_style_box(TT.box(TT.RAISED, TT.INK, 20, 2, true), r)
		draw_string(f, r.position + Vector2(16, 27), _toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, TT.INK)


func _crate_colour() -> Color:
	return TT.family_colors(Rooms.ROOMS[room]["family"])["fill"]


func _draw_crate(c: Dictionary) -> void:
	var r: Rect2 = c["rect"]
	var id: String = c["id"]
	var solved: bool = main.save.is_solved(id)
	var carried: bool = main.carried.has(id)
	var fill := TT.SUNKEN if solved else _crate_colour()
	draw_rect(Rect2(r.position + Vector2(0, 4), r.size), TT.SHADOW)
	draw_rect(r, fill)
	draw_rect(r, TT.INK, false, 3.0)
	draw_line(r.position + Vector2(0, r.size.y * 0.5), r.position + Vector2(r.size.x, r.size.y * 0.5), TT.INK, 2.0)
	var mid := r.get_center()
	if solved or carried:
		draw_arc(mid, 14.0, 0.0, TAU, 20, TT.TEAL, 4.0, true)
		draw_polyline(PackedVector2Array([mid + Vector2(-6, 0), mid + Vector2(-1, 6), mid + Vector2(8, -6)]), TT.TEAL, 4.0, true)
	else:
		# a padlock
		draw_rect(Rect2(mid + Vector2(-8, -2), Vector2(16, 12)), TT.INK)
		draw_arc(mid + Vector2(0, -3), 6.0, PI, TAU, 10, TT.INK, 3.0)
	var font := TT.bold_font()
	var title: String = Puzzles.by_id(id)["title"]
	var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(mid.x - w * 0.5, r.end.y + 15), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TT.INK)


func _draw_pest(pest: Dictionary) -> void:
	var p: Vector2 = pest["pos"]
	var asleep: bool = pest["state"] == "asleep"
	var bob := 0.0 if asleep or not TT.motion else sin(_t * 8.0) * 2.0
	p.y += bob
	draw_circle(p + Vector2(0, 16), 16.0, Color(0, 0, 0, 0.12))
	draw_circle(p, 18.0, TT.DANGER)
	draw_arc(p, 18.0, 0.0, TAU, 20, TT.INK, 2.5, true)
	draw_line(p + Vector2(-9, -16), p + Vector2(-13, -26), TT.INK, 2.5)
	draw_line(p + Vector2(9, -16), p + Vector2(13, -26), TT.INK, 2.5)
	if asleep:
		draw_line(p + Vector2(-9, -3), p + Vector2(-3, -3), TT.INK, 2.5)
		draw_line(p + Vector2(3, -3), p + Vector2(9, -3), TT.INK, 2.5)
		draw_string(TT.bold_font(), p + Vector2(14, -22), "Zzz", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TT.INK)
	else:
		draw_circle(p + Vector2(-6, -3), 5.0, TT.RAISED)
		draw_circle(p + Vector2(6, -3), 5.0, TT.RAISED)
		draw_circle(p + Vector2(-5, -3), 2.0, TT.INK)
		draw_circle(p + Vector2(7, -3), 2.0, TT.INK)
	if pest["held"] != "":
		draw_rect(Rect2(p + Vector2(-8, -42), Vector2(16, 14)), TT.BRAND)
		draw_rect(Rect2(p + Vector2(-8, -42), Vector2(16, 14)), TT.INK, false, 2.0)


func _draw_player() -> void:
	var p := _player
	draw_circle(p + Vector2(0, 14), 14.0, Color(0, 0, 0, 0.12))
	draw_rect(Rect2(p + Vector2(-11, -4), Vector2(22, 20)), TT.BLUE)
	draw_rect(Rect2(p + Vector2(-11, -4), Vector2(22, 20)), TT.INK, false, 2.5)
	draw_circle(p + Vector2(0, -10), 11.0, TT.RAISED)
	draw_arc(p + Vector2(0, -10), 11.0, 0.0, TAU, 16, TT.INK, 2.5, true)
	draw_arc(p + Vector2(0, -12), 12.0, PI, TAU, 12, TT.INK, 2.5, true)
	draw_rect(Rect2(p + Vector2(-12, -14), Vector2(24, 5)), TT.BRAND)
	draw_circle(p + Vector2(-4, -8), 1.8, TT.INK)
	draw_circle(p + Vector2(4, -8), 1.8, TT.INK)
	# what you are carrying floats above your head
	for i in main.carried.size():
		var pos := p + Vector2(-16.0 * (main.carried.size() - 1) * 0.5 + 16.0 * i, -36)
		var reward: Dictionary = Puzzles.by_id(main.carried[i])["reward"]
		if reward["kind"] == "motor" or reward["kind"] == "wheel":
			TT.draw_gear(self, pos, 8.0, 8, _t * 2.0, TT.TEAL if reward["kind"] == "motor" else TT.BRAND)
		else:
			draw_rect(Rect2(pos + Vector2(-7, -7), Vector2(14, 14)), TT.BLUE)
			draw_rect(Rect2(pos + Vector2(-7, -7), Vector2(14, 14)), TT.INK, false, 2.0)


func _draw_stick() -> void:
	draw_circle(_stick_center, STICK_R, Color(TT.RAISED, 0.55))
	draw_arc(_stick_center, STICK_R, 0.0, TAU, 32, TT.BORDER, 2.5, true)
	var knob := _stick_center + _stick_vec * STICK_R * 0.6
	draw_circle(knob, 24.0, TT.BRAND)
	draw_arc(knob, 24.0, 0.0, TAU, 20, TT.INK, 2.5, true)
