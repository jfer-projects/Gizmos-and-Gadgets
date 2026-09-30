extends SceneTree
## Plays the walking workshop through code: walk to a crate, carry, get robbed
## by the pest, snooze it, deliver at the door. Run headless:
##   godot --headless --path . --script res://tests/workshop_test.gd

const SAVE := "user://workshop_test_save.json"

var failures := 0


func _init() -> void:
	_go.call_deferred()


func _wait(frames: int = 2) -> void:
	for i in frames:
		await process_frame


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func _go() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var main: Control = load("res://scenes/main.tscn").instantiate()
	main.save_path = SAVE
	root.add_child(main)
	await _wait()
	main.go("workshop")
	await _wait()
	var ws: Control = main._current
	check(ws.get_script().resource_path.ends_with("workshop_screen.gd"), "the walking workshop opens")
	check(ws._crates().size() == 7, "the gear shop holds 7 crates")

	# a wall stops the player, crates are solid
	ws._player = ws._floor.position + Vector2(2, 2)
	check(ws._blocked(ws._player), "the wall blocks a player standing on it")
	var crate: Dictionary = ws._crates()[0]
	check(ws._blocked((crate["rect"] as Rect2).get_center()), "a crate is solid")

	# walk up to a crate: the open button appears and opens its puzzle
	ws._player = (crate["rect"] as Rect2).get_center() + Vector2(0, 50)
	ws._process(0.016)
	check(ws._open_button.visible, "the open button shows next to a crate")
	ws._open_nearest()
	await _wait()
	check(main.puzzle_id == crate["id"] and main.workshop_mode == "walk", "opening the crate starts its puzzle")

	# solving in walk mode carries the find; it is not saved until dropped off
	var pid: String = main.puzzle_id
	main.collect(pid)
	check(main.carried == [pid] and not main.save.is_solved(pid), "a solved crate is carried, not banked")
	main.go("workshop")
	await _wait()
	ws = main._current
	check(ws._carry_label.text == "Carrying 1 / 3", "the carrying count shows")

	# the pest robs you
	ws._pests.clear()
	var pest: Dictionary = ws._new_pest(Vector2(0.5, 0.5))
	ws._pests.append(pest)
	ws._player = Vector2(400, 200)
	pest["pos"] = ws._player + Vector2(5, 0)
	ws._process(0.016)
	check(pest["state"] == "flee" and pest["held"] == pid and main.carried.is_empty(), "the pest grabs what you carry")
	check(not main.save.is_solved(pid), "a stolen find is not lost or banked")

	# snooze returns it
	pest["pos"] = ws._player + Vector2(60, 0)
	ws._snooze()
	check(pest["state"] == "asleep" and main.carried == [pid], "snoozing the pest returns the find")
	check(ws._whistle_cooldown > 0.0, "the whistle has a short cooldown")

	# the pest gives it back on its own if never snoozed
	main.carried.clear()
	pest["state"] = "flee"
	pest["held"] = pid
	pest["timer"] = 0.01
	ws._update_pest(pest, 0.1)
	check(main.carried == [pid] and pest["state"] == "wander", "a pest that is not snoozed gives the find back")

	# a sleeping pest cannot rob you
	pest["state"] = "asleep"
	pest["timer"] = 3.0
	pest["pos"] = ws._player
	ws._update_pest(pest, 0.1)
	check(main.carried == [pid], "a sleeping pest steals nothing")

	# delivery at the door banks the find
	ws._pests.clear()
	ws._player = ws._drop_rect().get_center()
	ws._process(0.016)
	check(main.save.is_solved(pid) and main.carried.is_empty(), "the drop-off door banks what you carry")

	# a full pair of hands blocks new crates
	main.carried = ["idler_cw", "faster_3", "ratio_5"]
	main.puzzle_id = ""
	var before: Control = main._current
	ws._open("idler_ccw")
	await _wait()
	check(main._current == before and main.puzzle_id == "", "with full hands a new crate will not open")

	# leaving the workshop banks everything
	main.carried = ["slower_2"]
	ws._leave()
	await _wait()
	check(main.save.is_solved("slower_2") and main.carried.is_empty(), "walking away banks what you carry")

	# no-pest setting: nothing to fear
	main.save.settings["pests"] = false
	main.go("workshop")
	await _wait()
	check(main._current._pests.is_empty(), "no pests appear when they are switched off")

	# list mode banks straight away
	main.save.settings["walk"] = false
	main.workshop_mode = "list"
	main.collect("slower_3")
	check(main.save.is_solved("slower_3"), "in list mode a find is banked at once")
	main.go("workshop")
	await _wait()
	check(main._current.get_script().resource_path.ends_with("shelf_screen.gd"), "with walking off, the workshop is a list")

	print("")
	print("Workshop test: %s" % ("passed" if failures == 0 else "FAILED"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	quit(1 if failures > 0 else 0)
