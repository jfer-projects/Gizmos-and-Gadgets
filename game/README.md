# Tinker Track prototype (Godot 4.4)

A playable slice of the game: pick a motor gear and a wheel gear, race a rival over a flat, a steep hill and a flat, and if you lose, see why.

## Play it

1. Install [Godot 4.4](https://godotengine.org/download) (the standard build, not .NET).
2. Open this `game/` folder as a project and press Play (F5). The window is 844 x 390 (a phone in landscape).

## What is in it

| Screen | What it does |
|---|---|
| Title | Play |
| Courses | Five courses. Each opens when you win the one before. Stars show your best result. |
| Workshop | Seven crates. Each holds a small gear puzzle and, when solved, a new gear. You start with only a 16T motor gear and 16T and 24T wheel gears, so you cannot finish the first hill yet. |
| Crate puzzle | Read the goal, pick a part, press Try it. The gears turn so you can see direction and speed. A miss says exactly what your choice did, and a hint appears after the second miss. A solve shows a Concept card and lets you collect the gear. |
| Garage | Choose from the gears you have found. Ratio, torque and speed update live. The gears turn and mesh so you can see the ratio. |
| Race | Plays back the race. You do not steer: your gears decide it. Fast and Skip buttons. |
| Results | Win with stars, or "Why did I lose?": a speed-over-time replay with the problem moments marked, a plain-language cause for each, and a hint button that loads a suggested build from gears you own (or sends you to the Workshop if you need to find more). |

Progress (solved crates, stars, last build) is saved on the device in `user://tinker_track_save.json`.

### The courses

| # | Course | What it asks of your gears | Best build |
|---|---|---|---|
| 1 | Hill Climb | Flat, a steep hill, flat | 4 : 1 |
| 2 | Windy Straight | Almost no air drag, long and fast: top speed wins | about 2.5 : 1 |
| 3 | Ramp Yard | A short very steep ramp, then a long downhill | 4 : 1 |
| 4 | Mud Flats | Thick mud drags on the wheels | about 4.7 : 1 |
| 5 | Mountain Pass | Two climbs, the second steeper | 5 : 1 |

### The crates

| Crate | Puzzle | Concept | Gear found |
|---|---|---|---|
| 1 | Add an idler so the wheel turns the same way as the motor | Idler gears | 32T wheel |
| 2 | 24T driver, make the output 3 times faster | Gear speed | 8T motor |
| 3 | 8T motor, build a 5 : 1 ratio | Gear ratio | 40T wheel |
| 4 | Reverse the wheel with idlers | Idler gears | 12T motor |
| 5 | 16T driver, make the output 2 times slower | Gear speed | 48T wheel |
| 6 | 12T driver, make the output 3 times slower | Gear speed | 20T motor |
| 7 | 8T motor, build a 7 : 1 ratio | Gear ratio | 56T wheel |

The first build is 1:1 on purpose. It stalls on the hill and the game explains why. Ratios around 4:1 win on the first course. You have to find that out yourself.

## How the race works

`scripts/drivetrain.gd` simulates the race at a fixed 60 steps a second, so the same gears always give the same result.

- A DC motor loses torque as it spins faster.
- Ratio = wheel teeth / motor teeth. Wheel force = ratio x motor torque / wheel radius.
- Gravity on the hill, rolling resistance and air drag push back.
- A big ratio pulls harder but tops out at a lower speed. A small ratio is faster on the flat but stalls on the hill.

Each course has a rival with a fixed ratio, tuned to finish about 0.7 s behind the best build, so a good build wins and a near miss loses narrowly. Courses differ in slope, mud (rolling resistance) and air drag. Course data lives in `scripts/drivetrain.gd`.

`scripts/analysis.gd` compares your time in each part of the course to the best build and writes the "why did I lose?" notes. Its hints move your ratio in the right direction without giving away the best answer.

## Tests

```
godot --headless --path game --script res://tests/run_tests.gd
```

Checks that every course is deterministic, the rival is beatable but not by every build, the courses want different gears, the loss explanations and hints make sense, every crate has exactly one right answer, solving every crate finds every gear, and saves and unlocking work.

Screenshots (needs a display, for example `xvfb-run` on a server):

```
xvfb-run -a godot --path game --rendering-driver opengl3 res://tests/screenshots.tscn -- /tmp/shots
```

## Not done yet

- No walkable workshop or pest yet: crates are a shelf you tap.
- Only the Ground family. Green Energy and Air vehicles are not built.
- Only gear puzzles (direction, speed, ratio). No levers, circuits, magnets or forces, and no two-stage gear trains.
- Placeholder shapes and the default font. Final art and fonts come from the design system in `docs/design-system/`.
- No sound, no read-aloud, no reduced-motion or high-contrast option.
- Day theme only. Colours live in `scripts/tt.gd`.
- Mobile export needs the Godot export templates and Android or Xcode tooling, which are not set up here.
