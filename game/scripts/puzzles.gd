extends RefCounted
## Crate puzzles. Each one teaches a single gear idea and pays out a new gear.
##
## kinds:
##   direction  choose how many idler gears sit between motor and wheel
##   speed      choose the output gear's teeth to get a speed goal
##   ratio      choose the wheel gear's teeth to make a ratio
##   circuit    wire two bulbs (0 series, 1 parallel, 2 open)
##   energy     pick a power source for the weather (0 solar, 1 wind, 2 wait)
##   magnet     turn a magnet so it pulls (0 = N|S, 1 = S|N)
##   balance    weigh a lever: choose the weight or the distance

## "Nothing chosen yet" for a puzzle choice.
const NONE := -999

const MOTOR_DIRECTION := 1  # 1 = clockwise, -1 = counterclockwise

const PUZZLES := [
	{
		"id": "idler_cw", "kind": "direction", "concept": "idler",
		"title": "Turn the wheel forward",
		"goal": "The motor turns clockwise. Make the wheel turn clockwise too.",
		"want_dir": 1, "options": [0, 1, 2], "answer": 1,
		"reward": {"kind": "wheel", "teeth": 32},
		"hint": "Every pair of gears that touch flips the direction. Count the flips from motor to wheel.",
	},
	{
		"id": "faster_3", "kind": "speed", "concept": "speed",
		"title": "Spin faster",
		"goal": "The driver gear has 24 teeth. Make the output spin 3 times faster.",
		"driver": 24, "want_factor": 3.0, "options": [8, 12, 24, 48], "answer": 8,
		"reward": {"kind": "motor", "teeth": 8},
		"hint": "A small gear spins faster than the big gear that turns it. Divide the driver's teeth by 3.",
	},
	{
		"id": "ratio_5", "kind": "ratio", "concept": "ratio",
		"title": "Build a pulling ratio",
		"goal": "The motor gear has 8 teeth. Make a 5 : 1 ratio for climbing.",
		"motor": 8, "want_ratio": 5.0, "options": [24, 32, 40, 48], "answer": 40,
		"reward": {"kind": "wheel", "teeth": 40},
		"hint": "Ratio = wheel teeth ÷ motor teeth. What times 8 makes the wheel gear?",
	},
	{
		"id": "idler_ccw", "kind": "direction", "concept": "idler",
		"title": "Reverse it",
		"goal": "The motor turns clockwise. Make the wheel turn counterclockwise.",
		"want_dir": -1, "options": [1, 2, 3], "answer": 2,
		"reward": {"kind": "motor", "teeth": 12},
		"hint": "With no idler gears the wheel already turns the other way. Which choice gets you back there?",
	},
	{
		"id": "slower_2", "kind": "speed", "concept": "speed",
		"title": "Spin slower",
		"goal": "The driver gear has 16 teeth. Make the output spin 2 times slower.",
		"driver": 16, "want_factor": 0.5, "options": [8, 16, 32, 48], "answer": 32,
		"reward": {"kind": "wheel", "teeth": 48},
		"hint": "A big gear turned by a small gear spins slower. Multiply the driver's teeth by 2.",
	},
	{
		"id": "slower_3", "kind": "speed", "concept": "speed",
		"title": "Much slower",
		"goal": "The driver gear has 12 teeth. Make the output spin 3 times slower.",
		"driver": 12, "want_factor": 1.0 / 3.0, "options": [16, 24, 36, 48], "answer": 36,
		"reward": {"kind": "motor", "teeth": 20},
		"hint": "Three times slower means three times the teeth.",
	},
	{
		"id": "ratio_7", "kind": "ratio", "concept": "ratio",
		"title": "The strongest pull",
		"goal": "The motor gear has 8 teeth. Make a 7 : 1 ratio for the steepest hills.",
		"motor": 8, "want_ratio": 7.0, "options": [40, 48, 56, 64], "answer": 56,
		"reward": {"kind": "wheel", "teeth": 56},
		"hint": "7 times 8 teeth is the wheel gear you need.",
	},
	{
		"id": "solar_wire", "kind": "circuit", "concept": "circuit",
		"title": "Wire the solar panel",
		"goal": "The solar panel powers two lights. Wire them so both shine bright.",
		"options": [0, 1, 2], "answer": 1,
		"reward": {"kind": "part", "id": "solar_panel", "name": "solar panel"},
		"hint": "In a parallel circuit each bulb has its own path to the battery.",
	},
	{
		"id": "wind_night", "kind": "energy", "concept": "sources",
		"title": "Power for a windy night",
		"goal": "It is night and the wind is blowing. Which power source keeps the car moving?",
		"night": true, "wind": true, "options": [0, 1, 2], "answer": 1,
		"reward": {"kind": "part", "id": "wind_blade", "name": "wind blade"},
		"hint": "Solar panels need sunlight. What does the night still have?",
	},
	{
		"id": "magnets", "kind": "magnet", "concept": "magnets",
		"title": "Make magnets pull",
		"goal": "The left magnet points its S pole at you. Turn the right magnet so they pull together.",
		"options": [0, 1], "answer": 0,
		"reward": {"kind": "badge", "id": "magnet_badge", "name": "magnet badge"},
		"hint": "Opposite poles attract. The left magnet's S pole needs an N pole to face it.",
	},
	{
		"id": "wing_balance", "kind": "balance", "concept": "balance",
		"title": "Balance the wings",
		"goal": "Balance the lever. The left weight is 6 kg at 2 steps. Choose the weight to hang at 4 steps on the right.",
		"left": [6, 2], "vary": "weight", "fixed": 4, "options": [2, 3, 4, 6], "answer": 3,
		"reward": {"kind": "part", "id": "wings", "name": "wings"},
		"hint": "Weight times distance must match on both sides. 6 times 2 is 12. What times 4 is 12?",
	},
	{
		"id": "prop_balance", "kind": "balance", "concept": "balance",
		"title": "Balance the propeller",
		"goal": "Balance the lever. The left weight is 4 kg at 3 steps. A 2 kg weight goes on the right. Choose how many steps out.",
		"left": [4, 3], "vary": "distance", "fixed": 2, "options": [2, 4, 6, 8], "answer": 6,
		"reward": {"kind": "part", "id": "propeller", "name": "propeller"},
		"hint": "4 times 3 is 12. A lighter weight has to sit farther out. 2 times what is 12?",
	},
]

const CONCEPTS := {
	"idler": {
		"ngss": "3-PS2-1",
		"title": "Idler gears",
		"body": "Gears that touch turn opposite ways. An extra gear in between, called an idler, flips the direction back.",
		"formula": "each touching pair flips the direction",
	},
	"speed": {
		"ngss": "3-PS2-2, 4-PS3-1",
		"title": "Gear speed",
		"body": "A small gear turned by a big gear spins faster. A big gear turned by a small gear spins slower.",
		"formula": "speed change = driver teeth ÷ output teeth",
	},
	"circuit": {
		"ngss": "4-PS3-2",
		"title": "Series and parallel",
		"body": "In a series circuit the bulbs share one path, so they glow dimly. In a parallel circuit each bulb has its own path, so each glows bright.",
		"formula": "parallel: every bulb gets the full battery",
	},
	"sources": {
		"ngss": "4-ESS3-1",
		"title": "Energy sources",
		"body": "Sunlight powers solar panels. Moving air turns wind blades. Pick the source that matches the weather.",
		"formula": "no sun, no solar power. no wind, no wind power",
	},
	"magnets": {
		"ngss": "3-PS2-3, 3-PS2-4",
		"title": "Magnets",
		"body": "Opposite poles pull together. Matching poles push apart.",
		"formula": "N pulls S. N pushes N",
	},
	"balance": {
		"ngss": "3-PS2-1",
		"title": "Balancing a lever",
		"body": "A lever balances when weight times distance is the same on both sides. A light weight far out can balance a heavy weight close in.",
		"formula": "weight × distance = weight × distance",
	},
	"ratio": {
		"ngss": "3-5-ETS1-2",
		"title": "Gear ratio",
		"body": "Divide the wheel gear's teeth by the motor gear's teeth. A bigger ratio pulls harder but tops out at a lower speed.",
		"formula": "ratio = wheel teeth ÷ motor teeth",
	},
}

## Parts a family needs before its courses open.
const FAMILY_PARTS := {
	"energy": ["solar_panel", "wind_blade"],
	"air": ["wings", "propeller"],
}

## Gears the player starts with, before opening any crate.
const START_MOTOR := [16]
const START_WHEEL := [16, 24]


static func count() -> int:
	return PUZZLES.size()


static func by_id(id: String) -> Dictionary:
	for p in PUZZLES:
		if p["id"] == id:
			return p
	return {}


## What a choice does. Always has dir, factor and ratio (for gear puzzles);
## other kinds add their own fields (brightness, power, attract, torque_l/r).
static func outcome(p: Dictionary, choice: int) -> Dictionary:
	match p["kind"]:
		"direction":
			# 0 idlers = one touching pair = one flip; each idler adds another.
			var flips := choice + 1
			return {"dir": MOTOR_DIRECTION * (1 if flips % 2 == 0 else -1), "factor": 1.0, "ratio": 0.0}
		"speed":
			return {"dir": -MOTOR_DIRECTION, "factor": float(p["driver"]) / float(choice), "ratio": 0.0}
		"ratio":
			return {"dir": -MOTOR_DIRECTION, "factor": float(p["motor"]) / float(choice), "ratio": float(choice) / float(p["motor"])}
		"circuit":
			# series bulbs share the battery, parallel bulbs each get all of it
			return {"brightness": [0.5, 1.0, 0.0][choice]}
		"energy":
			var power := 0.0
			match choice:
				0: power = 0.0 if p.get("night", false) else 1.0
				1: power = 1.0 if p.get("wind", false) else 0.0
			return {"power": power}
		"magnet":
			# the left magnet shows its S pole to the right; unlike poles attract
			return {"attract": choice == 0}
		"balance":
			var tl: int = int(p["left"][0]) * int(p["left"][1])
			var tr: int = choice * int(p["fixed"])
			return {"torque_l": tl, "torque_r": tr}
	return {"dir": 1, "factor": 1.0, "ratio": 0.0}


static func is_correct(p: Dictionary, choice: int) -> bool:
	var o := outcome(p, choice)
	match p["kind"]:
		"direction":
			return o["dir"] == p["want_dir"]
		"speed":
			return is_equal_approx(o["factor"], p["want_factor"])
		"ratio":
			return is_equal_approx(o["ratio"], p["want_ratio"])
		"circuit":
			return o["brightness"] >= 1.0
		"energy":
			return o["power"] >= 1.0
		"magnet":
			return o["attract"]
		"balance":
			return o["torque_l"] == o["torque_r"]
	return false


## Plain-language description of what the player's choice actually did.
static func describe(p: Dictionary, choice: int) -> String:
	var o := outcome(p, choice)
	match p["kind"]:
		"direction":
			var word := "clockwise" if o["dir"] == 1 else "counterclockwise"
			var n: int = choice
			var idlers := "no idler gears" if n == 0 else ("1 idler gear" if n == 1 else "%d idler gears" % n)
			return "With %s, the wheel turns %s." % [idlers, word]
		"speed":
			var f: float = o["factor"]
			if f >= 1.0:
				return "That output spins %s times faster." % _num(f)
			return "That output spins %s times slower." % _num(1.0 / f)
		"ratio":
			return "That makes a %s : 1 ratio." % _num(o["ratio"])
		"circuit":
			if o["brightness"] >= 1.0:
				return "Each bulb has its own path, so both shine bright."
			if o["brightness"] > 0.0:
				return "In a series circuit the bulbs share the battery, so both glow dimly."
			return "There is a gap, so no current flows and the bulbs stay dark."
		"energy":
			if o["power"] >= 1.0:
				return "It works: the car keeps moving."
			if choice == 2:
				return "Waiting makes no power. The car stays still."
			return "No sunlight at night, so the solar panel makes no power."
		"magnet":
			return "The magnets pull together." if o["attract"] else "Matching poles push apart."
		"balance":
			var tl: int = o["torque_l"]
			var tr: int = o["torque_r"]
			if tl == tr:
				return "Both sides are %d, so the lever balances." % tl
			var down := "left" if tl > tr else "right"
			return "The left side is %d and the right side is %d, so the %s side goes down." % [tl, tr, down]
	return ""


static func option_label(p: Dictionary, choice: int) -> String:
	match p["kind"]:
		"direction":
			return "No idler" if choice == 0 else ("1 idler" if choice == 1 else "%d idlers" % choice)
		"circuit":
			return ["Series", "Parallel", "Gap"][choice]
		"energy":
			return ["Solar panel", "Wind blade", "Wait"][choice]
		"magnet":
			return "N | S" if choice == 0 else "S | N"
		"balance":
			return ("%d kg" if p["vary"] == "weight" else "%d steps") % choice
	return "%dT" % choice


## What the player finds, in words: "the 32T wheel gear", "the wings".
static func reward_text(p: Dictionary) -> String:
	var r: Dictionary = p["reward"]
	if r["kind"] == "motor" or r["kind"] == "wheel":
		return "the %dT %s gear" % [r["teeth"], r["kind"]]
	return "the %s" % r["name"]


static func _num(x: float) -> String:
	if is_equal_approx(x, roundf(x)):
		return str(int(x))
	return "%.1f" % x
