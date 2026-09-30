extends RefCounted
## Crate puzzles. Each one teaches a single gear idea and pays out a new gear.
##
## kinds:
##   direction  choose how many idler gears sit between motor and wheel
##   speed      choose the output gear's teeth to get a speed goal
##   ratio      choose the wheel gear's teeth to make a ratio

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
]

const CONCEPTS := {
	"idler": {
		"title": "Idler gears",
		"body": "Gears that touch turn opposite ways. An extra gear in between, called an idler, flips the direction back.",
		"formula": "each touching pair flips the direction",
	},
	"speed": {
		"title": "Gear speed",
		"body": "A small gear turned by a big gear spins faster. A big gear turned by a small gear spins slower.",
		"formula": "speed change = driver teeth ÷ output teeth",
	},
	"ratio": {
		"title": "Gear ratio",
		"body": "Divide the wheel gear's teeth by the motor gear's teeth. A bigger ratio pulls harder but tops out at a lower speed.",
		"formula": "ratio = wheel teeth ÷ motor teeth",
	},
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


## What a choice does. Returns dir (1 or -1, of the last gear), factor (output
## speed as a multiple of the driver's) and ratio (for ratio puzzles, else 0).
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
	return ""


static func option_label(p: Dictionary, choice: int) -> String:
	if p["kind"] == "direction":
		return "No idler" if choice == 0 else ("1 idler" if choice == 1 else "%d idlers" % choice)
	return "%dT" % choice


static func _num(x: float) -> String:
	if is_equal_approx(x, roundf(x)):
		return str(int(x))
	return "%.1f" % x
