extends SceneTree
## A bot plays the whole game from a fresh save, using only what a child could
## do: open crates in the shelf order, take the best build from the gears it
## owns, and race. It proves the game can be finished and shows how many crates
## each course needs. Run headless:
##   godot --headless --path . --script res://tests/playthrough.gd

const Drivetrain = preload("res://scripts/drivetrain.gd")
const Puzzles = preload("res://scripts/puzzles.gd")
const SaveData = preload("res://scripts/save.gd")
const Analysis = preload("res://scripts/analysis.gd")

var failures := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


## The best build among the gears the save owns: [ratio, motor, wheel, time].
func _best_owned(save: RefCounted, ci: int) -> Array:
	var best: Array = []
	for m in save.owned("motor"):
		for w in save.owned("wheel"):
			var r := Drivetrain.simulate(ci, Drivetrain.ratio_of(m, w))
			if r["finished"] and (best.is_empty() or r["time"] < best[3]):
				best = [Drivetrain.ratio_of(m, w), m, w, r["time"]]
	return best


func _wins(ci: int, best: Array) -> bool:
	return not best.is_empty() and best[3] <= Drivetrain.rival_result(ci)["time"]


func _init() -> void:
	var save := SaveData.new()
	save.path = "user://playthrough_save.json"
	var order: Array = []
	for p in Puzzles.PUZZLES:
		order.append(p["id"])
	print("Course                Crates opened so far   Build       Time    Stars")
	var total_stars := 0
	for ci in Drivetrain.course_count():
		var c: Dictionary = Drivetrain.COURSES[ci]
		# open crates until the course is open and a winning build exists
		var guard := 0
		while guard < 20:
			guard += 1
			var open: bool = save.course_unlocked(Drivetrain.COURSES, ci) or (ci > 0 and save.missing_parts(c["family"]).is_empty() == false)
			var best := _best_owned(save, ci)
			var parts_ok: bool = save.missing_parts(c["family"]).is_empty()
			if parts_ok and _wins(ci, best):
				break
			# open the next crate that helps: family parts first when they are missing
			var next := ""
			if not parts_ok:
				for pid in order:
					if not save.is_solved(pid) and Puzzles.by_id(pid)["reward"].get("id", "") in save.missing_parts(c["family"]):
						next = pid
						break
			if next == "":
				for pid in order:
					if not save.is_solved(pid):
						next = pid
						break
			if next == "":
				break
			# a child solves it: the right answer is always available
			check(Puzzles.is_correct(Puzzles.by_id(next), Puzzles.by_id(next)["answer"]), "crate %s can be solved" % next)
			save.solved.append(next)
		var best_now := _best_owned(save, ci)
		check(save.missing_parts(c["family"]).is_empty(), "%s: the family's parts have been found" % c["name"])
		check(_wins(ci, best_now), "%s: a winning build exists with the gears owned" % c["name"])
		if best_now.is_empty():
			continue
		# race it the way the game does
		var res := Drivetrain.simulate(ci, best_now[0])
		var stars := Drivetrain.stars_for(ci, res["time"], res["finished"])
		save.stars[c["id"]] = maxi(stars, save.stars_for(c["id"]))
		total_stars += stars
		print("%-22s %-22d %2dT/%2dT=%.2f  %5.2f s  %d" % [c["name"], save.solved.size(), best_now[1], best_now[2], best_now[0], res["time"], stars])
		check(stars >= 1, "%s: the bot wins" % c["name"])
	check(save.solved.size() <= Puzzles.count(), "no crate is needed twice")
	var all_won := true
	for c in Drivetrain.COURSES:
		if save.stars_for(c["id"]) == 0:
			all_won = false
	check(all_won, "all 15 courses can be won in one playthrough")
	print("  crates opened to win everything: %d of %d, stars %d of %d" % [save.solved.size(), Puzzles.count(), total_stars, Drivetrain.course_count() * 3])

	# the first win must take some effort but not too much
	var fresh := SaveData.new()
	check(_best_owned(fresh, 0).is_empty(), "with no crates opened the first hill cannot be finished")
	fresh.solved.append("idler_cw")
	check(not _wins(0, _best_owned(fresh, 0)), "one crate is not enough to win the first course")
	fresh.solved.append("faster_3")
	check(_wins(0, _best_owned(fresh, 0)), "two crates are enough to win the first course")

	# with every gear, three stars are possible on every course
	var full := SaveData.new()
	for id in order:
		full.solved.append(id)
	for ci in Drivetrain.course_count():
		var b := _best_owned(full, ci)
		check(Drivetrain.stars_for(ci, b[3], true) == 3, "%s: three stars are possible" % Drivetrain.COURSES[ci]["name"])

	print("")
	print("Playthrough: %s" % ("passed" if failures == 0 else "FAILED"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save.path))
	quit(1 if failures > 0 else 0)
