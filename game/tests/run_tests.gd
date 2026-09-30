extends SceneTree
## Headless tests. Run from the game folder:
##   godot --headless --path . --script res://tests/run_tests.gd

const Drivetrain = preload("res://scripts/drivetrain.gd")
const Analysis = preload("res://scripts/analysis.gd")
const Puzzles = preload("res://scripts/puzzles.gd")
const SaveData = preload("res://scripts/save.gd")

var failures := 0


func _init() -> void:
	_test_determinism()
	_test_hill_course()
	_test_every_course()
	_test_courses_want_different_gears()
	_test_analysis_stall()
	_test_analysis_topped_out()
	_test_close_loss_explained()
	_test_no_notes_for_best()
	_test_mud_and_ramp_notes()
	_test_stars()
	_test_gear_snap()
	_test_puzzles_have_one_answer()
	_test_puzzle_rewards_cover_all_gears()
	_test_puzzle_outcomes()
	_test_save_round_trip()
	_test_unlocking()
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
	for ci in Drivetrain.course_count():
		var a := Drivetrain.simulate(ci, 3.0)
		var b := Drivetrain.simulate(ci, 3.0)
		check(a["time"] == b["time"] and a["xs"] == b["xs"], "course %d: same build gives the identical race" % ci)


func _test_hill_course() -> void:
	var r := Drivetrain.simulate(0, 1.0)
	check(not r["finished"] and r["seg_enter"].size() == 2, "hill: 1:1 stalls on the hill")
	var gap: float = Drivetrain.simulate(0, 3.0)["time"] - Drivetrain.rival_result(0)["time"]
	check(gap > 0.3 and gap < 1.5, "hill: 3:1 loses by under 1.5 s (%.2f)" % gap)


func _test_every_course() -> void:
	for ci in Drivetrain.course_count():
		var name: String = Drivetrain.COURSES[ci]["name"]
		var best := Drivetrain.best_build(ci)
		var rival := Drivetrain.rival_result(ci)
		var margin: float = rival["time"] - best["result"]["time"]
		print("  ", name, ": best ", best["motor"], "T/", best["wheel"], "T = ", "%.2f" % best["ratio"], " in ", "%.2f" % best["result"]["time"], " s; rival ", "%.2f" % rival["time"], " s")
		check(rival["finished"], "%s: the rival finishes" % name)
		check(margin > 0.3 and margin < 1.3, "%s: the best build beats the rival by a fair margin (%.2f s)" % [name, margin])
		var ratios := {}
		for m in Drivetrain.MOTOR_GEARS:
			for w in Drivetrain.WHEEL_GEARS:
				ratios[Drivetrain.ratio_of(m, w)] = true
		var winners := 0
		for r in ratios:
			var sim := Drivetrain.simulate(ci, r)
			if sim["finished"] and sim["time"] <= rival["time"]:
				winners += 1
		check(winners >= 2 and winners <= 8, "%s: a few gear choices win, not all of them (%d)" % [name, winners])


func _test_courses_want_different_gears() -> void:
	var sprint: float = Drivetrain.best_build(1)["ratio"]
	var hill: float = Drivetrain.best_build(0)["ratio"]
	var pass_ratio: float = Drivetrain.best_build(4)["ratio"]
	check(sprint < hill, "the straight wants a smaller ratio than the hill (%.2f < %.2f)" % [sprint, hill])
	check(pass_ratio > hill, "the mountain pass wants a bigger ratio than the hill (%.2f > %.2f)" % [pass_ratio, hill])


func _test_analysis_stall() -> void:
	var notes := Analysis.explain(Drivetrain.simulate(0, 1.0))
	check(notes.size() == 1 and notes[0]["title"] == "Stalled on the hill", "1:1 on the hill: one note, stalled")
	if notes.size() > 0:
		check(notes[0]["suggested_ratio"] == 2.0, "after a stall the hint doubles the ratio")
		check(Drivetrain.simulate(0, notes[0]["suggested_ratio"])["finished"], "the hinted build finishes the race")


func _test_analysis_topped_out() -> void:
	var notes := Analysis.explain(Drivetrain.simulate(1, 7.0))
	check(notes.size() > 0 and notes[0]["direction"] == "speed", "7:1 on the straight: advice is to add speed")
	if notes.size() > 0:
		check(notes[0]["suggested_ratio"] < 7.0, "suggested ratio is smaller")


func _test_close_loss_explained() -> void:
	var r := Drivetrain.simulate(0, 3.0)
	var notes := Analysis.explain(r)
	check(notes.size() > 0, "a 0.7 s loss at 3:1 is still explained")
	if notes.size() > 0:
		check(Drivetrain.simulate(0, notes[0]["suggested_ratio"])["time"] < r["time"], "the hint for 3:1 makes the car faster")


func _test_no_notes_for_best() -> void:
	for ci in Drivetrain.course_count():
		check(Analysis.explain(Drivetrain.best_build(ci)["result"]).size() == 0, "course %d: the best build has nothing to explain" % ci)


func _test_mud_and_ramp_notes() -> void:
	var mud := Analysis.explain(Drivetrain.simulate(3, 2.0))
	check(mud.size() > 0 and mud[0]["place"] == "in the mud", "2:1 in the mud is blamed on the mud")
	var ramp := Analysis.explain(Drivetrain.simulate(2, 1.0))
	check(ramp.size() == 1 and ramp[0]["title"] == "Stalled on the hill", "1:1 stalls on the ramp")
	var pass_notes := Analysis.explain(Drivetrain.simulate(4, 3.0))
	check(pass_notes.size() > 0, "3:1 in the pass gets an explanation")
	for n in pass_notes + mud + ramp:
		print("  note: ", "%.0f" % n["time"], " s ", n["place"], " | ", n["title"], " | ", n["body"])


func _test_stars() -> void:
	for ci in Drivetrain.course_count():
		var best: Dictionary = Drivetrain.best_build(ci)["result"]
		check(Drivetrain.stars_for(ci, best["time"], true) == 3, "course %d: best build earns 3 stars" % ci)
		check(Drivetrain.stars_for(ci, 99.0, false) == 0, "course %d: did not finish earns no stars" % ci)


func _test_gear_snap() -> void:
	var pair := Analysis.nearest_gears(4.0)
	check(Drivetrain.ratio_of(pair[0], pair[1]) == 4.0, "nearest gears to 4.0 make exactly 4:1")
	var owned := Analysis.nearest_gears(4.0, [16], [16, 24])
	check(owned == [16, 24], "with only owned gears, the nearest pair is 16T/24T")


func _test_puzzles_have_one_answer() -> void:
	for p in Puzzles.PUZZLES:
		var right := 0
		for o in p["options"]:
			if Puzzles.is_correct(p, o):
				right += 1
		check(right == 1 and Puzzles.is_correct(p, p["answer"]), "%s: exactly one correct option" % p["id"])
		check(Puzzles.CONCEPTS.has(p["concept"]), "%s: has a concept card" % p["id"])
		for o in p["options"]:
			if not Puzzles.is_correct(p, o):
				check(Puzzles.describe(p, o).length() > 10, "%s: wrong choice %d gets an explanation" % [p["id"], o])


func _test_puzzle_rewards_cover_all_gears() -> void:
	var save := SaveData.new()
	save.path = "user://test_cover.json"
	for p in Puzzles.PUZZLES:
		save.solved.append(p["id"])
	check(save.owned("motor") == Drivetrain.MOTOR_GEARS, "solving every crate finds every motor gear")
	check(save.owned("wheel") == Drivetrain.WHEEL_GEARS, "solving every crate finds every wheel gear")
	var fresh := SaveData.new()
	check(fresh.owned("motor") == [16] and fresh.owned("wheel") == [16, 24], "a new player starts with 16T motor and 16T/24T wheel")
	var start_best := INF
	for m in fresh.owned("motor"):
		for w in fresh.owned("wheel"):
			var r := Drivetrain.simulate(0, Drivetrain.ratio_of(m, w))
			if r["finished"]:
				start_best = minf(start_best, r["time"])
	check(start_best == INF, "with the starting gears the hill cannot be finished yet")


func _test_puzzle_outcomes() -> void:
	var idler := Puzzles.by_id("idler_cw")
	check(Puzzles.outcome(idler, 0)["dir"] == -1 and Puzzles.outcome(idler, 1)["dir"] == 1, "one idler makes the wheel turn the same way as the motor")
	var speed := Puzzles.by_id("faster_3")
	check(is_equal_approx(Puzzles.outcome(speed, 8)["factor"], 3.0), "24T driving 8T spins 3 times faster")


func _test_save_round_trip() -> void:
	var a := SaveData.new()
	a.path = "user://test_roundtrip.json"
	a.mark_solved("idler_cw")
	a.record_stars("hill", 2)
	a.record_stars("hill", 1)
	a.last_wheel = 32
	a.write()
	var b := SaveData.new()
	b.path = a.path
	b.load_from_disk()
	check(b.is_solved("idler_cw") and not b.is_solved("faster_3"), "solved crates survive a save")
	check(b.stars_for("hill") == 2, "stars keep the best result")
	check(b.last_wheel == 32, "the last build is remembered when the gear is owned")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(a.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_cover.json"))
	var bad := SaveData.new()
	bad.path = "user://test_bad.json"
	var f := FileAccess.open(bad.path, FileAccess.WRITE)
	f.store_string("not json {{")
	f.close()
	bad.load_from_disk()
	check(bad.solved.is_empty(), "a damaged save file is ignored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bad.path))


func _test_unlocking() -> void:
	var s := SaveData.new()
	s.path = "user://test_unlock.json"
	check(s.course_unlocked(Drivetrain.COURSES, 0) and not s.course_unlocked(Drivetrain.COURSES, 1), "only the first course starts open")
	s.stars["hill"] = 1
	check(s.course_unlocked(Drivetrain.COURSES, 1) and not s.course_unlocked(Drivetrain.COURSES, 2), "winning a course opens the next one")
