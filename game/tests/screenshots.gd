extends Node
## Renders each screen and saves a PNG. Needs a display (xvfb on a server):
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/screenshots.tscn -- out_dir
## Not part of the game.

const OUT_DEFAULT := "/tmp/tinker_shots"

var _main: Control
var _out := OUT_DEFAULT


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	get_window().size = Vector2i(844, 390)
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_run.call_deferred()


func _shot(name: String) -> void:
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [_out, name])
	print("saved ", name)


func _run() -> void:
	await _shot("1_title")
	_main.go("garage")
	await _shot("2_garage_1to1")
	_main.motor_teeth = 8
	_main.wheel_teeth = 32
	_main.go("garage")
	await _shot("3_garage_4to1")
	_main.motor_teeth = 16
	_main.wheel_teeth = 16
	_main.start_race()
	await get_tree().create_timer(6.0).timeout
	await _shot("4_race_1to1")
	_main.go("results")
	await _shot("5_results_stall")
	_main.motor_teeth = 8
	_main.wheel_teeth = 24
	_main.start_race()
	await get_tree().create_timer(20.0).timeout
	await _shot("6_race_3to1")
	_main.go("results")
	await _shot("7_results_close_loss")
	_main.motor_teeth = 8
	_main.wheel_teeth = 32
	_main.start_race()
	await get_tree().create_timer(2.0).timeout
	_main.go("results")
	await _shot("8_results_win")
	get_tree().quit()
