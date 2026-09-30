# Tinker Track

A mobile STEM puzzle-racing game for ages 9 to 11, built in Godot 4.4 (GDScript). Players earn gears and parts by solving small physics puzzles in crates, build a drivetrain by choosing gears, and race a rival. A loss always explains itself.

It is an original game inspired by the mechanics of 1990s edutainment vehicle-building games. It uses no code, art, audio, names or characters from any earlier game. Keep it that way (see `docs/PRD.md` section 9).

## Layout

- `game/` the Godot project. `game/README.md` explains the screens, courses and crates.
- `game/scripts/drivetrain.gd` the deterministic race simulation and all 15 course definitions. Start here.
- `game/scripts/analysis.gd` the "Why did I lose?" notes and hints.
- `game/scripts/puzzles.gd` the 12 crate puzzles, their concepts and rewards.
- `game/scripts/tt.gd` the look (three themes) and drawing helpers.
- `game/scripts/*_screen.gd` one file per screen. Screens build their UI in code.
- `game/tests/` headless tests. `game/tools/` the course tuning report and icon maker.
- `docs/` product docs: PRD, status, roadmap, privacy policy, store listing, release checklist, test plan, asset ledger, design system copies.

## Commands

Godot 4.4.1 is needed (not the .NET build).

```
game/tests/run_all.sh /path/to/godot        # every headless test; must print ALL GREEN
godot --headless --path game --script res://tools/tune.gd   # course tuning report
xvfb-run -a godot --path game --rendering-driver opengl3 res://tests/screenshots.tscn -- /tmp/shots
```

Run `godot --headless --path game --import` once after adding a script so Godot writes its `.uid` file, and commit the `.uid` files.

## Rules for changes

- The race must stay deterministic: fixed time step, no randomness in `drivetrain.gd`.
- After changing any course or motor number, run `tune.gd` and keep each rival about 0.7 s behind the best build. `run_tests.gd` checks this.
- Loss text is cause and cure, never blame. Loss sounds are soft, never buzzers.
- Never rely on colour alone. Every status also has a word or an icon. `run_tests.gd` checks contrast in all three themes.
- Kids-store rules: no ads, no third-party SDKs or analytics, no accounts, no chat, no links out, no network permission. Anything that leaves the device or costs money must sit behind the parent gate and needs a documented decision first.
- Screens must survive large text. Build menu screens with `TT.screen_column`.
- Godot GDScript gotcha: `:=` cannot infer a type from a Dictionary or Array element. Write the type out.
