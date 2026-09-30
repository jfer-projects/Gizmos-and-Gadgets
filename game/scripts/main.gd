extends Control
## Holds the player's progress and build, and switches between screens.

const Drivetrain = preload("res://scripts/drivetrain.gd")
const SaveData = preload("res://scripts/save.gd")
const TT = preload("res://scripts/tt.gd")
const Audio = preload("res://scripts/audio.gd")

const SCREENS := {
	"title": "res://scripts/title_screen.gd",
	"map": "res://scripts/map_screen.gd",
	"workshop": "res://scripts/workshop_screen.gd",
	"puzzle": "res://scripts/puzzle_screen.gd",
	"garage": "res://scripts/garage_screen.gd",
	"race": "res://scripts/race_screen.gd",
	"results": "res://scripts/results_screen.gd",
	"settings": "res://scripts/settings_screen.gd",
	"gate": "res://scripts/gate_screen.gd",
	"parent": "res://scripts/parent_screen.gd",
	"codex": "res://scripts/codex_screen.gd",
}

## Where to save. Tests point this somewhere harmless before the first screen.
var save_path: String = SaveData.DEFAULT_PATH
var save: RefCounted
var course: int = 0
var map_family: String = ""  # which family tab the course map shows
var puzzle_id: String = ""
var motor_teeth: int = 16
var wheel_teeth: int = 16
var result: Dictionary = {}

var audio: Node
var _current: Control
var _back_to: String = "title"  # where Settings and the Codex return to


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	save = SaveData.new()
	save.path = save_path
	save.load_from_disk()
	audio = Audio.new()
	add_child(audio)
	apply_settings()
	# every button gets the same soft click
	get_tree().node_added.connect(func(n: Node):
		if n is Button:
			n.pressed.connect(func(): audio.sfx("click")))
	# The first build is 1:1 on purpose: it stalls on the first hill and the
	# game explains why.
	motor_teeth = save.last_motor
	wheel_teeth = save.last_wheel
	go("title")


## Push the saved settings into the look, the sound and the text size.
func apply_settings() -> void:
	var st: Dictionary = save.settings
	TT.apply_theme(st["theme"])
	TT.text_scale = 1.25 if st["large_text"] else 1.0
	TT.motion = not st["reduced_motion"]
	audio.set_flags(st["sfx"], st["music"])
	queue_redraw()


## Read a line aloud when the player has turned read-aloud on.
func say(text: String) -> void:
	if save.settings["read_aloud"]:
		audio.speak(text)


func _process(delta: float) -> void:
	save.play_seconds += delta


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
	audio.music("race" if screen == "race" else "calm")
	if screen == "title" or screen == "map":
		save.write()
	if _current != null:
		_current.queue_free()
	var node := Control.new()
	node.set_script(load(SCREENS[screen]))
	node.set("main", self)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(node)
	_current = node


## Open a screen that returns to where you came from (Settings, Codex).
func go_with_back(screen: String, back_to: String) -> void:
	_back_to = back_to
	go(screen)


func back_target() -> String:
	return _back_to
