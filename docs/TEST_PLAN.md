# Test plan

## Automated (run on every push by `.github/workflows/tests.yml`)

Run locally: `game/tests/run_all.sh /path/to/godot`. It fails on any failed check and on any engine script error.

| Suite | What it proves |
|---|---|
| `tests/run_tests.gd` | Race simulation is deterministic. Every course has a beatable rival, and only a few gear choices win. Courses want different gears. Hills, mud, clouds, wind and take-off behave as described. Loss notes and hints are right and improve the time. Every crate has exactly one right answer and an explanation for every wrong one. Solving every crate finds every gear and part. Family and course unlocking. Saves round-trip, survive a broken file and keep settings. Every sound is audible and not clipping, and the miss sound is softer than the win sound. Text and border contrast in all three themes. |
| `tests/smoke.gd` | Every screen, every puzzle option and a race and result on every course open without an error in all three themes and with large text. |
| `tests/workshop_test.gd` | Walking, crate collision, opening a crate, carrying, the pest stealing, snoozing, the pest giving items back, dropping off, full hands, no-pest and list modes. |
| `tools/tune.gd` | Not a test. A report used when changing courses. |

## Manual, on a real phone and tablet (not done yet)

Do these on one small Android phone (about 5 inch), one large phone, one iPhone, and one tablet.

**Touch and controls**
- [ ] Every button can be hit with a thumb. Nothing is under a notch or the system bars.
- [ ] The on-screen stick moves the player smoothly. Tap-to-walk works. A tap on a crate walks to it and opens it.
- [ ] Drag scrolling works on the Parent zone, Codex and any screen that scrolls, without pressing buttons by accident.
- [ ] Rotating the device does not crash. (The game is landscape only.)
- [ ] Switching apps during a race and coming back keeps the game running or paused sensibly.

**Performance**
- [ ] Steady frame rate in a race on the oldest target device. Cold start under 4 seconds.
- [ ] Battery use over 20 minutes of play is reasonable. The device does not get hot.

**Sound and feel**
- [ ] Sound is not too loud on a phone speaker. Music can be turned off. The mute switch is respected.
- [ ] Vibration is short and can be turned off.
- [ ] Read aloud works with the device voice, stops when a new line starts, and fails quietly when there is no voice.

**Accessibility**
- [ ] Large text does not hide any button (scrolling reaches everything).
- [ ] High Contrast is readable in bright sunlight.
- [ ] Every puzzle can be solved with taps only. The whole game can be played with the walk-around switched off.
- [ ] Try it with a child who has dyslexia and with a child who uses a switch or a controller, if possible.

**Kids and safety**
- [ ] The Parent gate cannot be passed by a nine-year-old who has not been told how.
- [ ] Confirm the installed app requests no permissions and makes no network calls (check with the device's privacy report or a network monitor).

## Playtest with children (see `ROADMAP.md`)

Sessions of 15 minutes, 3 to 5 children per round. Do not explain. Record: where they stop reading, where they get stuck, what they say when they lose, whether they can explain the gear ratio afterwards, whether they want to play again.
