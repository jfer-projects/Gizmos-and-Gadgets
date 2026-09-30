extends SceneTree
## Course tuning report. For every course: the fastest gear pairs, which pairs
## fail, and the rival ratio that finishes about 0.7 s behind the best build.
##   godot --headless --path . --script res://tools/tune.gd

const Drivetrain = preload("res://scripts/drivetrain.gd")


func _init() -> void:
	var ratios := {}
	for m in Drivetrain.MOTOR_GEARS:
		for w in Drivetrain.WHEEL_GEARS:
			ratios[snappedf(Drivetrain.ratio_of(m, w), 0.0001)] = true
	var list: Array = ratios.keys()
	list.sort()
	for ci in Drivetrain.course_count():
		var c: Dictionary = Drivetrain.COURSES[ci]
		var fin: Array = []
		var fails: Array = []
		for r in list:
			var sim := Drivetrain.simulate(ci, r)
			if sim["finished"]:
				fin.append([sim["time"], r])
			else:
				fails.append("%.2f(%s)" % [r, sim["fail"]])
		fin.sort_custom(func(a, b): return a[0] < b[0])
		var line := "%-2d %-16s" % [ci, c["name"]]
		if fin.is_empty():
			print(line, "  NOBODY FINISHES")
			continue
		var best: Array = fin[0]
		var top: Array = []
		for k in mini(4, fin.size()):
			top.append("%.2f:%.1f" % [fin[k][1], fin[k][0]])
		# rival ratios on each side of the best build that finish ~0.7 s behind
		var target: float = best[0] + 0.7
		var low := 0.0
		var low_gap := INF
		var high := 0.0
		var high_gap := INF
		for k in range(100, 1000, 5):
			var r: float = k / 100.0
			var sim := Drivetrain.simulate(ci, r)
			if not sim["finished"]:
				continue
			var g := absf(sim["time"] - target)
			if r < best[1] and g < low_gap:
				low_gap = g
				low = r
			if r > best[1] and g < high_gap:
				high_gap = g
				high = r
		print(line, " best %.2f %.2fs" % [best[1], best[0]], " top ", top, " rival now ", c["rival"], "  low ", low, " (%.2f)" % low_gap, " high ", high, " (%.2f)" % high_gap, " fails ", fails.size())
	quit()
