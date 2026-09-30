# Tinker Track prototype (Godot 4.4)

A playable slice of the game: pick a motor gear and a wheel gear, race a rival over a flat, a steep hill and a flat, and if you lose, see why.

## Play it

1. Install [Godot 4.4](https://godotengine.org/download) (the standard build, not .NET).
2. Open this `game/` folder as a project and press Play (F5). The window is 844 x 390 (a phone in landscape).

## What is in it

| Screen | What it does |
|---|---|
| Title | Play |
| Garage | Choose motor gear (8 to 20 teeth) and wheel gear (16 to 56 teeth). Ratio, torque and speed update live. The gears turn and mesh so you can see the ratio. |
| Race | Plays back the race. You do not steer: your gears decide it. Fast and Skip buttons. |
| Results | Win with stars, or "Why did I lose?": a speed-over-time replay with the problem moments marked, a plain-language cause for each, and a hint button that loads a suggested build. |

The first build is 1:1 on purpose. It stalls on the hill and the game explains why. Ratios around 4:1 win. You have to find that out yourself.

## How the race works

`scripts/drivetrain.gd` simulates the race at a fixed 60 steps a second, so the same gears always give the same result.

- A DC motor loses torque as it spins faster.
- Ratio = wheel teeth / motor teeth. Wheel force = ratio x motor torque / wheel radius.
- Gravity on the hill, rolling resistance and air drag push back.
- A big ratio pulls harder but tops out at a lower speed. A small ratio is faster on the flat but stalls on the hill.

The rival always drives 3.3:1 and finishes in about 32.1 s. The fastest build of the available gears (8T motor, 32T wheel = 4:1) finishes in about 31.3 s.

`scripts/analysis.gd` compares your time in each part of the course to the best build and writes the "why did I lose?" notes. Its hints move your ratio in the right direction without giving away the best answer.

## Tests

```
godot --headless --path game --script res://tests/run_tests.gd
```

Checks determinism, that 1:1 stalls, that 3:1 loses narrowly, that the best build beats the rival, and that the explanations and hints make sense.

Screenshots (needs a display, for example `xvfb-run` on a server):

```
xvfb-run -a godot --path game --rendering-driver opengl3 res://tests/screenshots.tscn -- /tmp/shots
```

## Not done yet

- Only one course, one vehicle family and no puzzles or exploration.
- Placeholder shapes and the default font. Final art and fonts come from the design system in `docs/design-system/`.
- No sound, no saves, no touch-specific tuning or accessibility options beyond large targets.
- Day theme only. Colours live in `scripts/tt.gd`.
- Mobile export needs the Godot export templates and Android or Xcode tooling, which are not set up here.
