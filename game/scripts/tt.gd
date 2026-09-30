extends RefCounted
## Tinker Track look: colours from the design system (Day theme) plus
## small helpers for styled controls and for drawing gears and the car.
## Keep in step with docs/design-system/tokens.json.

const SURFACE := Color("#EAF1EF")
const RAISED := Color("#FFFFFF")
const SUNKEN := Color("#DCE7E3")
const GRID := Color("#C6D6D0")
const INK := Color("#10243E")
const MUTED := Color("#45586F")
const BORDER := Color("#5F7389")
const BRAND := Color("#F5B700")
const ON_BRAND := Color("#10243E")
const TEAL := Color("#096A70")
const ON_TEAL := Color("#FFFFFF")
const BLUE := Color("#2B62C9")
const ON_BLUE := Color("#FFFFFF")
const DANGER := Color("#A83208")
const ON_DANGER := Color("#FFFFFF")
const BRAND_TINT := Color("#FFF1C2")
const TEAL_TINT := Color("#D2EFEF")
const BLUE_TINT := Color("#DCE7FB")
const DANGER_TINT := Color("#FBDCCB")

static var _bold: FontVariation


static func bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	return _bold


static func box(fill: Color, border: Color = INK, radius: int = 12, border_w: int = 2, shadow: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if shadow:
		sb.shadow_color = border
		sb.shadow_offset = Vector2(0, 4)
		sb.shadow_size = 1
	return sb


static func label(text: String, size: int = 18, color: Color = INK, is_bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if is_bold:
		l.add_theme_font_override("font", bold_font())
	return l


## kind: plain, primary, energy, info, ghost
static func button(text: String, kind: String = "plain", size: int = 18) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(48, 48)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_font_override("font", bold_font())
	var fill := RAISED
	var fg := INK
	match kind:
		"primary":
			fill = BRAND
			fg = ON_BRAND
		"energy":
			fill = TEAL
			fg = ON_TEAL
		"info":
			fill = BLUE
			fg = ON_BLUE
		"ghost":
			fill = SURFACE
			fg = INK
	var normal := box(fill, BORDER if kind == "ghost" else INK, 12, 2, kind != "ghost")
	var pressed := box(fill.darkened(0.08), INK, 12, 2, false)
	pressed.content_margin_top = 12
	pressed.content_margin_bottom = 4
	var disabled := box(fill.lerp(SUNKEN, 0.6), BORDER, 12, 2, false)
	for state in ["normal", "hover", "focus"]:
		b.add_theme_stylebox_override(state, normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_color_override("font_disabled_color", MUTED)
	return b


static func draw_grid(ci: CanvasItem, size: Vector2, pitch: float = 24.0) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), SURFACE)
	var x := 0.0
	while x <= size.x:
		ci.draw_line(Vector2(x, 0), Vector2(x, size.y), GRID, 1.0)
		x += pitch
	var y := 0.0
	while y <= size.y:
		ci.draw_line(Vector2(0, y), Vector2(size.x, y), GRID, 1.0)
		y += pitch


## A real gear: filled body with `teeth` teeth, outlined in ink.
static func draw_gear(ci: CanvasItem, center: Vector2, radius: float, teeth: int, angle: float, fill: Color, label_text: String = "") -> void:
	var pts := PackedVector2Array()
	var step := TAU / float(teeth)
	var r_in := radius * 0.84
	for i in teeth:
		var a0 := angle + step * i
		pts.append(center + Vector2.from_angle(a0) * r_in)
		pts.append(center + Vector2.from_angle(a0 + step * 0.2) * radius)
		pts.append(center + Vector2.from_angle(a0 + step * 0.45) * radius)
		pts.append(center + Vector2.from_angle(a0 + step * 0.65) * r_in)
	ci.draw_colored_polygon(pts, fill)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, INK, 2.5, true)
	ci.draw_circle(center, radius * 0.2, RAISED)
	ci.draw_arc(center, radius * 0.2, 0.0, TAU, 20, INK, 2.5, true)
	if label_text != "":
		var f := bold_font()
		var fs := int(clampf(radius * 0.42, 12.0, 26.0))
		var w := f.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(f, center + Vector2(-w * 0.5, radius * 0.62 + fs * 0.3), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


## The car, drawn around `origin` (ground contact between the wheels),
## facing right, tilted by `tilt` radians. `unit` is pixels per design unit.
static func draw_car(ci: CanvasItem, origin: Vector2, unit: float, tilt: float, body: Color, wheel_angle: float, motor_teeth: int = 12, wheel_teeth: int = 24) -> void:
	ci.draw_set_transform(origin, tilt, Vector2(unit, unit))
	var cabin := PackedVector2Array([Vector2(-22, -38), Vector2(-12, -58), Vector2(20, -58), Vector2(32, -38)])
	ci.draw_colored_polygon(cabin, BLUE_TINT)
	var cab_line := cabin.duplicate()
	cab_line.append(cabin[0])
	ci.draw_polyline(cab_line, INK, 2.5 / unit, true)
	ci.draw_style_box(box(body, INK, int(10), maxi(1, int(round(2.5 / unit))), false), Rect2(-52, -40, 104, 26))
	# the two wheels, each ringed with gear teeth
	draw_gear(ci, Vector2(-30, -14), 20.0, 14, wheel_angle, RAISED)
	draw_gear(ci, Vector2(30, -14), 20.0, 14, wheel_angle, RAISED)
	# the drivetrain gears you chose, tucked inside the body
	draw_gear(ci, Vector2(-8, -27), clampf(float(motor_teeth) * 0.6, 7.0, 12.0), motor_teeth, -wheel_angle * float(wheel_teeth) / float(motor_teeth), TEAL)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
