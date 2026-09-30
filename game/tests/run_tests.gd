extends SceneTree
## Headless tests. Run from the game folder:
##   godot --headless --path . --script res://tests/run_tests.gd

const Drivetrain = preload("res://scripts/drivetrain.gd")
const Analysis = preload("res://scripts/analysis.gd")

var failures := 0


func _init() -> void:
	_test_determinism()
	_test_ratio_one_stalls()
	_test_best_build_beats_rival()
	_test_three_to_one_loses_narrowly()
	_test_more_ratio_is_slower_than_best()
	_test_analysis_stall()
	_test_analysis_topped_out()
	_test_close_loss_explained()
	_test_no_notes_for_best()
	_test_stars()
	_test_gear_snap()
	print("")
	if failures == 0:
		print("All tests passed.")
	else:
		print("%d test(s) FAILED." % failures)
	quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func _test_determinism() -> void:
	var a := Drivetrain.simulate(3.0)
	var b := Drivetrain.simulate(3.0)
	check(a["time"] == b["time"] and a["xs"] == b["xs"], "same build gives the identical race")


func _test_ratio_one_stalls() -> void:
	var r := Drivetrain.simulate(1.0)
	check(not r["finished"], "1:1 never finishes (stalls on the hill)")
	check(r["seg_enter"].size() == 2, "1:1 gets as far as the hill")


func _test_best_build_beats_rival() -> void:
	var best := Drivetrain.best_build()
	var rival := Drivetrain.rival_result()
	print("  best build: ", best["motor"], "T / ", best["wheel"], "T = ", best["ratio"], "  time ", best["result"]["time"], "   rival time ", rival["time"])
	check(best["result"]["time"] < rival["time"], "the best build beats the rival")
	check(rival["time"] > 31.5 and rival["time"] < 33.0, "rival finishes near 32 s")


func _test_three_to_one_loses_narrowly() -> void:
	var r := Drivetrain.simulate(3.0)
	var gap: float = r["time"] - Drivetrain.rival_result()["time"]
	print("  3:1 finishes in ", r["time"], " (", gap, " s behind)")
	check(r["finished"] and gap > 0.3 and gap < 1.5, "3:1 loses by under 1.5 s")


func _test_more_ratio_is_slower_than_best() -> void:
	var r := Drivetrain.simulate(7.0)
	check(r["finished"] and r["time"] > Drivetrain.best_build()["result"]["time"] + 2.0, "7:1 finishes but is much slower than the best")


func _test_analysis_stall() -> void:
	var notes := Analysis.explain(Drivetrain.simulate(1.0))
	check(notes.size() > 0, "1:1 gets an explanation")
	if notes.size() > 0:
		var hill: Dictionary = notes[0]
		print("  note: ", hill["title"], " | ", hill["body"], " | suggest ", hill["suggested_ratio"])
		check(hill["title"] == "Stalled on the hill", "the biggest note is the stall on the hill")
		check(hill["direction"] == "pull", "advice is to add pull")
		check(hill["suggested_ratio"] == 2.0, "after a stall the hint doubles the ratio")
		check(Drivetrain.simulate(hill["suggested_ratio"])["finished"], "the hinted build finishes the race")


func _test_analysis_topped_out() -> void:
	var notes := Analysis.explain(Drivetrain.simulate(8.0))
	check(notes.size() > 0, "8:1 gets an explanation")
	if notes.size() > 0:
		check(notes[0]["direction"] == "speed", "advice for 8:1 is to add speed")
		check(notes[0]["suggested_ratio"] < 8.0, "suggested ratio is smaller than 8")


func _test_close_loss_explained() -> void:
	var r := Drivetrain.simulate(3.0)
	var notes := Analysis.explain(r)
	for n in notes:
		print("  note: ", n["time"], " ", n["place"], " | ", n["title"], " | suggest ", n["suggested_ratio"])
	check(notes.size() > 0, "a 0.7 s loss at 3:1 is still explained")
	if notes.size() > 0:
		check(Drivetrain.simulate(notes[0]["suggested_ratio"])["time"] < r["time"], "the hint for 3:1 makes the car faster")


func _test_no_notes_for_best() -> void:
	var best := Drivetrain.best_build()
	check(Analysis.explain(best["result"]).size() == 0, "the best build has nothing to explain")


func _test_stars() -> void:
	var best: Dictionary = Drivetrain.best_build()["result"]
	check(Drivetrain.stars_for(best["time"], true) == 3, "best build earns 3 stars")
	check(Drivetrain.stars_for(Drivetrain.simulate(3.0)["time"], true) == 0, "3:1 earns no stars")
	check(Drivetrain.stars_for(99.0, false) == 0, "did not finish earns no stars")


func _test_gear_snap() -> void:
	var pair := Analysis.nearest_gears(4.0)
	check(Drivetrain.ratio_of(pair[0], pair[1]) == 4.0, "nearest gears to 4.0 make exactly 4:1")
