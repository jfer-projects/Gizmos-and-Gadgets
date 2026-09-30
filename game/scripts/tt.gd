extends RefCounted
## Tinker Track look: colours from the design system (Day theme) plus
## small helpers for styled controls and for drawing gears and the car.
## Keep in step with docs/design-system/tokens.json.
##
## Colours are variables so the player can switch between the Day, Night Shift
## and High Contrast themes (see apply_theme). Screens are rebuilt when they
## open, so a theme change shows on the next screen.

static var SURFACE: Color = Color("#EAF1EF")
static var RAISED: Color = Color("#FFFFFF")
static var SUNKEN: Color = Color("#DCE7E3")
static var GRID: Color = Color("#C6D6D0")
static var INK: Color = Color("#10243E")
static var MUTED: Color = Color("#45586F")
static var BORDER: Color = Color("#5F7389")
static var BRAND: Color = Color("#F5B700")
static var ON_BRAND: Color = Color("#10243E")
static var TEAL: Color = Color("#096A70")
static var ON_TEAL: Color = Color("#FFFFFF")
static var BLUE: Color = Color("#2B62C9")
static var ON_BLUE: Color = Color("#FFFFFF")
static var DANGER: Color = Color("#A83208")
static var ON_DANGER: Color = Color("#FFFFFF")
static var BRAND_TINT: Color = Color("#FFF1C2")
static var TEAL_TINT: Color = Color("#D2EFEF")
static var BLUE_TINT: Color = Color("#DCE7FB")
static var DANGER_TINT: Color = Color("#FBDCCB")

static var SHADOW: Color = Color("#10243E")
static var text_scale: float = 1.0
static var motion: bool = true  # false = reduced motion: no idle spinning or confetti
static var theme_name: String = "day"

const THEMES := {
	"day": {
		"SURFACE": "#EAF1EF", "RAISED": "#FFFFFF", "SUNKEN": "#DCE7E3", "GRID": "#C6D6D0",
		"INK": "#10243E", "MUTED": "#45586F", "BORDER": "#5F7389",
		"BRAND": "#F5B700", "ON_BRAND": "#10243E", "TEAL": "#096A70", "ON_TEAL": "#FFFFFF",
		"BLUE": "#2B62C9", "ON_BLUE": "#FFFFFF", "DANGER": "#A83208", "ON_DANGER": "#FFFFFF",
		"BRAND_TINT": "#FFF1C2", "TEAL_TINT": "#D2EFEF", "BLUE_TINT": "#DCE7FB", "DANGER_TINT": "#FBDCCB",
		"SHADOW": "#10243E",
	},
	"night": {
		"SURFACE": "#0E1B2C", "RAISED": "#16283E", "SUNKEN": "#0A1523", "GRID": "#24405E",
		"INK": "#EAF1EF", "MUTED": "#A9BACB", "BORDER": "#7F93A8",
		"BRAND": "#FFC933", "ON_BRAND": "#10243E", "TEAL": "#3CC7CC", "ON_TEAL": "#0E1B2C",
		"BLUE": "#7AA5FF", "ON_BLUE": "#0E1B2C", "DANGER": "#FF8A5B", "ON_DANGER": "#0E1B2C",
		"BRAND_TINT": "#3B3411", "TEAL_TINT": "#113A3E", "BLUE_TINT": "#1B2F55", "DANGER_TINT": "#4A2415",
		"SHADOW": "#050C15",
	},
	"hc": {
		"SURFACE": "#FFFFFF", "RAISED": "#FFFFFF", "SUNKEN": "#F0F0F0", "GRID": "#D8D8D8",
		"INK": "#000000", "MUTED": "#1A1A1A", "BORDER": "#000000",
		"BRAND": "#FFC800", "ON_BRAND": "#000000", "TEAL": "#005A5F", "ON_TEAL": "#FFFFFF",
		"BLUE": "#1A44A0", "ON_BLUE": "#FFFFFF", "DANGER": "#8F2A00", "ON_DANGER": "#FFFFFF",
		"BRAND_TINT": "#FFFFFF", "TEAL_TINT": "#FFFFFF", "BLUE_TINT": "#FFFFFF", "DANGER_TINT": "#FFFFFF",
		"SHADOW": "#000000",
	},
}

static var _bold: FontVariation


## Switch the whole palette. Unknown names fall back to Day.
static func apply_theme(name: String) -> void:
	if not THEMES.has(name):
		name = "day"
	theme_name = name
	var t: Dictionary = THEMES[name]
	SURFACE = Color(t["SURFACE"])
	RAISED = Color(t["RAISED"])
	SUNKEN = Color(t["SUNKEN"])
	GRID = Color(t["GRID"])
	INK = Color(t["INK"])
	MUTED = Color(t["MUTED"])
	BORDER = Color(t["BORDER"])
	BRAND = Color(t["BRAND"])
	ON_BRAND = Color(t["ON_BRAND"])
	TEAL = Color(t["TEAL"])
	ON_TEAL = Color(t["ON_TEAL"])
	BLUE = Color(t["BLUE"])
	ON_BLUE = Color(t["ON_BLUE"])
	DANGER = Color(t["DANGER"])
	ON_DANGER = Color(t["ON_DANGER"])
	BRAND_TINT = Color(t["BRAND_TINT"])
	TEAL_TINT = Color(t["TEAL_TINT"])
	BLUE_TINT = Color(t["BLUE_TINT"])
	DANGER_TINT = Color(t["DANGER_TINT"])
	SHADOW = Color(t["SHADOW"])


## Font size after the player's text-size setting.
static func fs(size: int) -> int:
	return int(round(float(size) * text_scale))


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
	l.add_theme_font_size_override("font_size", fs(size))
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
	b.add_theme_font_size_override("font_size", fs(size))
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


## Draw the vehicle for a family: "ground" is the car, "energy" adds a solar
## panel, "air" is a propeller plane. `lift` raises it off the ground in pixels.
static func draw_vehicle(ci: CanvasItem, family: String, origin: Vector2, unit: float, tilt: float, body: Color, wheel_angle: float, motor_teeth: int = 12, wheel_teeth: int = 24, lift: float = 0.0) -> void:
	var at := origin - Vector2(0, lift)
	if family == "air":
		_draw_plane(ci, at, unit, tilt, body, wheel_angle, motor_teeth, wheel_teeth)
		return
	draw_car(ci, at, unit, tilt, body, wheel_angle, motor_teeth, wheel_teeth)
	if family == "energy":
		ci.draw_set_transform(at, tilt, Vector2(unit, unit))
		ci.draw_line(Vector2(-8, -58), Vector2(-8, -66), INK, 2.5 / unit)
		ci.draw_line(Vector2(14, -58), Vector2(14, -66), INK, 2.5 / unit)
		var panel := Rect2(-26, -74, 60, 8)
		ci.draw_rect(panel, TEAL)
		ci.draw_rect(panel, INK, false, 2.5 / unit)
		for k in range(1, 4):
			ci.draw_line(Vector2(panel.position.x + k * 15.0, panel.position.y), Vector2(panel.position.x + k * 15.0, panel.end.y), ON_TEAL, 1.5 / unit)
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _draw_plane(ci: CanvasItem, origin: Vector2, unit: float, tilt: float, body: Color, spin: float, motor_teeth: int, wheel_teeth: int) -> void:
	ci.draw_set_transform(origin, tilt, Vector2(unit, unit))
	var lw := 2.5 / unit
	var tail := PackedVector2Array([Vector2(-50, -44), Vector2(-66, -68), Vector2(-40, -44)])
	ci.draw_colored_polygon(tail, BLUE)
	ci.draw_polyline(PackedVector2Array([tail[0], tail[1], tail[2]]), INK, lw, true)
	ci.draw_style_box(box(body, INK, 10, 2), Rect2(-52, -46, 104, 26))
	ci.draw_circle(Vector2(20, -36), 6, BLUE_TINT)
	ci.draw_arc(Vector2(20, -36), 6, 0.0, TAU, 12, INK, lw, true)
	var wing := PackedVector2Array([Vector2(-16, -46), Vector2(24, -46), Vector2(10, -66), Vector2(-14, -66)])
	ci.draw_colored_polygon(wing, BLUE)
	ci.draw_polyline(PackedVector2Array([wing[0], wing[1], wing[2], wing[3], wing[0]]), INK, lw, true)
	draw_gear(ci, Vector2(-26, -12), 11.0, 9, spin, RAISED)
	draw_gear(ci, Vector2(26, -12), 11.0, 9, spin, RAISED)
	draw_gear(ci, Vector2(-4, -33), clampf(float(motor_teeth) * 0.5, 6.0, 10.0), motor_teeth, -spin * float(wheel_teeth) / float(motor_teeth), TEAL)
	# propeller blades spin fast enough to blur into a bar
	var hub := Vector2(58, -33)
	var blade := Vector2(0, 20).rotated(spin * 5.0)
	ci.draw_line(hub - blade, hub + blade, INK, 4.0 / unit)
	ci.draw_circle(hub, 4, BRAND)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
