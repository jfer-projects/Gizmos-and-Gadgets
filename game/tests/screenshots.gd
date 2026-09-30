extends Node
## Renders the main screens and saves a PNG of each. Needs a display (xvfb on
## a server):
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/screenshots.tscn -- out_dir
## Not part of the game. Uses its own throwaway save file.

const SAVE := "user://screenshots_save.json"

var _main: Control
var _out := "/tmp/tinker_shots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	get_window().size = Vector2i(844, 390)
	_main = load("res://scenes/main.tscn").instantiate()
	_main.save_path = SAVE
	add_child(_main)
	_run.call_deferred()


func _shot(shot_name: String, wait: float = 0.4) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
	print("saved ", shot_name)


func _screen() -> Control:
	return _main._current


func _run() -> void:
	await _shot("01_title")
	_main.go("map")
	await _shot("02_map_new")
	_main.go("workshop")
	await _shot("03_workshop_new")
	_main.puzzle_id = "idler_cw"
	_main.go("puzzle")
	await _shot("04_puzzle_direction")
	_screen()._pick(0)
	_screen()._try()
	await _shot("05_puzzle_miss", 2.0)
	_main.go("puzzle")
	_screen()._pick(1)
	_screen()._try()
	await _shot("06_puzzle_success", 2.0)
	_main.puzzle_id = "faster_3"
	_main.go("puzzle")
	_screen()._pick(12)
	_screen()._try()
	await _shot("07_puzzle_speed_miss", 2.0)
	_main.puzzle_id = "ratio_5"
	_main.go("puzzle")
	_screen()._pick(40)
	await _shot("08_puzzle_ratio")
	# a player who has found everything
	var puzzles = load("res://scripts/puzzles.gd")
	for p in puzzles.PUZZLES:
		_main.save.solved.append(p["id"])
	_main.save.stars["hill"] = 3
	_main.save.stars["sprint"] = 2
	_main.go("map")
	await _shot("09_map_progress")
	_main.course = 3
	_main.motor_teeth = 8
	_main.wheel_teeth = 16
	_main.go("garage")
	await _shot("10_garage_mud")
	_main.start_race()
	await get_tree().create_timer(9.0).timeout
	await _shot("11_race_mud")
	_main.go("results")
	await _shot("12_results_mud")
	_main.course = 1
	_main.motor_teeth = 16
	_main.wheel_teeth = 40
	_main.start_race()
	await get_tree().create_timer(12.0).timeout
	await _shot("13_race_sprint")
	_main.course = 2
	_main.motor_teeth = 8
	_main.wheel_teeth = 32
	_main.start_race()
	await get_tree().create_timer(24.0).timeout
	await _shot("14_race_ramp_down")
	_main.go("results")
	await _shot("15_results_win")
	get_tree().quit()
