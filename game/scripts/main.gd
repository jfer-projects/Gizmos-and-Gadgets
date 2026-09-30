extends Control
## Holds the player's progress and build, and switches between screens.

const Drivetrain = preload("res://scripts/drivetrain.gd")
const SaveData = preload("res://scripts/save.gd")
const TT = preload("res://scripts/tt.gd")

const SCREENS := {
	"title": "res://scripts/title_screen.gd",
	"map": "res://scripts/map_screen.gd",
	"workshop": "res://scripts/workshop_screen.gd",
	"puzzle": "res://scripts/puzzle_screen.gd",
	"garage": "res://scripts/garage_screen.gd",
	"race": "res://scripts/race_screen.gd",
	"results": "res://scripts/results_screen.gd",
}

## Where to save. Tests point this somewhere harmless before the first screen.
var save_path: String = SaveData.DEFAULT_PATH
var save: RefCounted
var course: int = 0
var puzzle_id: String = ""
var motor_teeth: int = 16
var wheel_teeth: int = 16
var result: Dictionary = {}

var _current: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	save = SaveData.new()
	save.path = save_path
	save.load_from_disk()
	# The first build is 1:1 on purpose: it stalls on the first hill and the
	# game explains why.
	motor_teeth = save.last_motor
	wheel_teeth = save.last_wheel
	go("title")


func _draw() -> void:
	TT.draw_grid(self, size)


func ratio() -> float:
	return Drivetrain.ratio_of(motor_teeth, wheel_teeth)


func start_race() -> void:
	save.last_motor = motor_teeth
	save.last_wheel = wheel_teeth
	result = Drivetrain.simulate(course, ratio())
	go("race")


func go(screen: String) -> void:
	if _current != null:
		_current.queue_free()
	var node := Control.new()
	node.set_script(load(SCREENS[screen]))
	node.set("main", self)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(node)
	_current = node
