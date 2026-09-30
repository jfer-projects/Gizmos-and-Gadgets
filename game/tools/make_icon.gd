extends Node
## Draws the app icon and its Android layers. Needs a display (xvfb on a server):
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/make_icon.tscn
## Writes icon.png (1024, opaque), icon_foreground.png (transparent) and
## icon_background.png. Everything is drawn from the game's own palette.

const TT = preload("res://scripts/tt.gd")

var _mode := "full"  # full, foreground, background


class IconArt extends Control:
	var mode := "full"

	func _draw() -> void:
		var TT = preload("res://scripts/tt.gd")
		var s := size.x
		if mode != "foreground":
			# deep navy drafting table with a faint blueprint grid
			draw_rect(Rect2(Vector2.ZERO, size), Color("#10243E"))
			var pitch := s / 16.0
			for k in range(1, 16):
				draw_line(Vector2(k * pitch, 0), Vector2(k * pitch, s), Color("#1B3557"), 3.0)
				draw_line(Vector2(0, k * pitch), Vector2(s, k * pitch), Color("#1B3557"), 3.0)
		if mode == "background":
			return
		# design coordinates are for a 1024 canvas; the safe zone for Android
		# adaptive icons is the middle two thirds, so keep the art inside it
		var k := s / 1024.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
		# a big yellow gear meshing with a small teal gear, centred in the safe zone
		var big := Vector2(440, 560)
		var small := big + Vector2.from_angle(deg_to_rad(-38.0)) * 300.0
		TT.draw_gear(self, big, 210.0, 14, 0.12, Color("#F5B700"))
		TT.draw_gear(self, small, 100.0, 7, 0.55, Color("#3CC7CC"))
		draw_set_transform_matrix(Transform2D.IDENTITY)


func _ready() -> void:
	TT.apply_theme("day")
	var jobs := [["full", "res://icon.png", false], ["foreground", "res://icon_foreground.png", true], ["background", "res://icon_background.png", false]]
	for job in jobs:
		var vp := SubViewport.new()
		vp.size = Vector2i(1024, 1024)
		vp.transparent_bg = job[2]
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var art := IconArt.new()
		art.mode = job[0]
		art.size = Vector2(1024, 1024)
		vp.add_child(art)
		add_child(vp)
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(job[1])
		print("wrote ", job[1])
		vp.queue_free()
	get_tree().quit()
