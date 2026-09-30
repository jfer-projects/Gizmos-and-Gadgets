# Tinker Track (Godot 4.4)

A gear-ratio puzzle-racing game for ages 9 to 11. Solve crate puzzles to find gears and parts, choose a motor gear and a wheel gear, and race a rival over 15 courses. When you lose, the game shows you why.

## Play it

1. Install [Godot 4.4](https://godotengine.org/download) (the standard build, not .NET).
2. Open this `game/` folder as a project and press Play (F5). The window is 844 x 390, a phone in landscape.

Ready-made unsigned builds for Windows, macOS, Linux and the web come from `.github/workflows/export.yml` (run it from the Actions tab) or from `godot --headless --path game --export-release "<preset>" <output>`. Mobile builds need signing keys: see `docs/RELEASE_CHECKLIST.md`.

## What is in it

| Screen | What it does |
|---|---|
| Title | Play, Settings, Parent zone |
| Courses | 15 courses in three tabs: Cars, Green, Planes. A course opens when the one before it is won. Green and Planes also need their parts. |
| Workshop | Walk around three rooms (Gear Shop, Green Shed, Hangar). Open crates, carry what you find to the drop-off door, and snooze the pest if it grabs something. A list view is the alternative. |
| Crate puzzle | Read the goal, pick a part, press Try it. The picture shows what your choice does. A miss says exactly what happened. A hint appears after the second miss. A solve shows a Concept card and gives you the gear or part. |
| Garage | Choose from the gears you have found. Ratio, torque and speed update live and the gears turn and mesh. |
| Race | Plays back the race. You do not steer: your gears decide it. Fast and Skip buttons. |
| Results | Win with stars, or "Why did I lose?": a speed-over-time replay with the problem moments marked, the cause in plain words, and a hint button. |
| Codex | Every idea the crates teach. |
| Parent zone | Behind a gate that asks for three digits written as words. Shows time played, courses, stars, what was learned with standards codes, and a privacy note. |
| Settings | Day, Night Shift and High Contrast themes; sound, music, vibration; read aloud; large text; reduced motion; pests on or off; walk or list workshop; erase progress. |

Progress and settings are saved on the device in `user://tinker_track_save.json`. The game uses no network, no ads and no accounts, and asks for no permission except vibration on Android.

## The courses

| Family | Courses | What changes |
|---|---|---|
| Cars | Hill Climb, Windy Straight, Ramp Yard, Mud Flats, Mountain Pass | Slope, air drag, mud |
| Green energy | Solar Roof, Windy Lane, Spring Hill, Cloudy Ridge, Eco Grand Prix | Motor power that fades in clouds or as a spring winds down; headwinds and tailwinds |
| Planes | Runway Dash, Short Field, Headwind Hop, Canyon Run, Grand Air Race | Reach take-off speed before the runway ends, then cruise; too slow or too topped-out and you crash |

## The crates

| Kind | Puzzle | Concept | Finds |
|---|---|---|---|
| Idler | Make the wheel turn the same way as the motor (1 crate), or the opposite way (1 crate) | Idler gears | 32T wheel gear, 12T motor gear |
| Speed | Pick an output gear to spin 3 times faster, 2 times slower or 3 times slower (3 crates) | Gear speed | 8T motor, 48T wheel, 20T motor |
| Ratio | Build a 5 : 1 and a 7 : 1 ratio (2 crates) | Gear ratio | 40T wheel, 56T wheel |
| Circuit | Wire two bulbs so both shine bright | Series and parallel | Solar panel |
| Energy | Pick a power source for a windy night | Energy sources | Wind blade |
| Magnet | Turn a magnet so the pair pulls | Magnets | Magnet badge |
| Lever | Balance a lever by choosing a weight, and by choosing a distance (2 crates) | Balancing | Wings, propeller |

The solar panel and wind blade open the Green courses. The wings and propeller open the Planes.

## How the race works

`scripts/drivetrain.gd` simulates every race at a fixed 60 steps a second, so the same gears always give the same result.

- A DC motor loses torque as it spins faster.
- Ratio = wheel teeth / motor teeth. Wheel force = ratio x motor torque / wheel radius.
- Gravity on hills, rolling resistance (high in mud), air drag, wind, and power changes push and pull.
- A big ratio pulls harder but tops out at a lower speed. A small ratio is faster on the flat but stalls on hills.
- On a runway the plane must reach take-off speed by the end, or it crashes. In the air it must stay above stall speed.

Every course has a rival at a fixed ratio, tuned to finish about 0.7 s behind the best build. `scripts/analysis.gd` compares your time in each part of the course with the best build and writes the "why did I lose?" notes. Its hints move your ratio the right way without giving away the best answer.

To retune a course, edit it in `drivetrain.gd` and run `godot --headless --path game --script res://tools/tune.gd`. It prints the best builds and the rival ratios to try.

## Tests

```
game/tests/run_all.sh /path/to/godot
```

Runs four headless suites: the rules (`run_tests.gd`), every screen in every theme (`smoke.gd`), the walking workshop (`workshop_test.gd`), and a bot that plays the whole game from a fresh save (`playthrough.gd`). It ends with `ALL GREEN` or `TESTS FAILED`. `.github/workflows/tests.yml` runs it on every push.

Screenshots (needs a display, for example `xvfb-run` on a server):

```
xvfb-run -a godot --path game --rendering-driver opengl3 res://tests/screenshots.tscn -- /tmp/shots
```

## Not done yet

See `docs/STATUS.md` (what is built against the PRD) and `docs/ROADMAP.md`. The main gaps: playtests with children, testing on real phones, final art and fonts, screen-reader support, and a drag-and-snap builder.
