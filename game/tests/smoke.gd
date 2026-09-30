extends SceneTree
## Opens every screen in every theme and checks nothing throws. Run headless:
##   godot --headless --path . --script res://tests/smoke.gd
## Script errors are printed by the engine; run_all.sh fails on any of them.

const SAVE := "user://smoke_save.json"

var failures := 0


func _init() -> void:
	_go.call_deferred()


func _wait(frames: int = 3) -> void:
	for i in frames:
		await process_frame


func _go() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var main: Control = load("res://scenes/main.tscn").instantiate()
	main.save_path = SAVE
	root.add_child(main)
	await _wait()
	var screens := ["title", "map", "workshop", "garage", "settings", "gate", "parent", "codex"]
	for theme in ["day", "night", "hc"]:
		main.save.settings["theme"] = theme
		main.save.settings["large_text"] = theme == "night"
		main.apply_settings()
		for s in screens:
			main.go(s)
			await _wait()
			_check(main._current != null and main._current.get_child_count() >= 0, "%s opens in %s" % [s, theme])
		for pid in main_puzzle_ids():
			main.puzzle_id = pid
			main.go("puzzle")
			await _wait()
			var scr: Control = main._current
			for o in scr.puzzle["options"]:
				scr._pick(o)
				await _wait(1)
			_check(true, "puzzle %s opens in %s" % [pid, theme])
		for ci in range(load("res://scripts/drivetrain.gd").course_count()):
			main.course = ci
			main.motor_teeth = 8
			main.wheel_teeth = 32
			main.start_race()
			await _wait(4)
			main.go("results")
			await _wait(3)
			_check(true, "course %d race and results open in %s" % [ci, theme])
	print("")
	print("Smoke test: %s" % ("passed" if failures == 0 else "FAILED"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	quit(1 if failures > 0 else 0)


func main_puzzle_ids() -> Array:
	var out: Array = []
	for p in load("res://scripts/puzzles.gd").PUZZLES:
		out.append(p["id"])
	return out


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("  FAIL ", msg)
