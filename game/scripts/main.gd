extends Control
## Holds the player's build and switches between screens.

const Drivetrain = preload("res://scripts/drivetrain.gd")
const TT = preload("res://scripts/tt.gd")

const SCREENS := {
	"title": "res://scripts/title_screen.gd",
	"garage": "res://scripts/garage_screen.gd",
	"race": "res://scripts/race_screen.gd",
	"results": "res://scripts/results_screen.gd",
}

## The player's build. The first try is 1:1 on purpose: it stalls on the hill
## and the game explains why.
var motor_teeth: int = 16
var wheel_teeth: int = 16
var attempts: int = 0
var result: Dictionary = {}

var _current: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	go("title")


func _draw() -> void:
	TT.draw_grid(self, size)


func ratio() -> float:
	return Drivetrain.ratio_of(motor_teeth, wheel_teeth)


func start_race() -> void:
	attempts += 1
	result = Drivetrain.simulate(ratio())
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
