# Status against the PRD

As of the autonomous build session. "Built" means it works in the game and is covered by a test or checked in a screenshot. Nothing has been tested on a physical phone yet.

## Summary

| | |
|---|---|
| Vehicle families | 3 (cars, green energy, planes) |
| Courses | 15, five per family, each with a tuned rival |
| Gears | 10 (4 motor, 6 wheel) |
| Crate puzzles | 12, in 7 kinds (idler, speed, ratio, circuit, energy, magnet, lever) |
| Concept cards | 7, each mapped to a standards code |
| Screens | 12 |
| Automated checks | about 340, run by `game/tests/run_all.sh` (rules, every screen in every theme, the walking workshop, and a bot that plays the whole game) |
| Themes | Day, Night Shift, High Contrast, all contrast-tested |
| Sound | 9 effects and 2 tunes, made in code |

## Requirements

**P0 = needed to play, P1 = needed to publish, P2 = later.**

| ID | What | State | Note |
|---|---|---|---|
| FR-1 | Walkable workshop with joystick or tap | Built | Keyboard, on-screen stick and tap-to-go. A list view is the alternative. |
| FR-2 | Locked back rooms | Partly | Three rooms instead of a front and back. Crates are locked until their puzzle is solved. |
| FR-3 | Part categories | Changed | Gears and family parts (solar panel, wind blade, wings, propeller). A full frame and wheels model was dropped to keep the gear choice central. |
| FR-4 | Carry parts to a drop-off | Built | Carry 3, drop at the door. |
| FR-5 | Nine themed zones | Partly | Three rooms and 15 courses, but the art is placeholder shapes. |
| FR-6, FR-7 | Pest and non-violent stun | Built | One pest per room. The snooze whistle returns what it took. It gives it back on its own after 12 s. |
| FR-8 | Pest difficulty and off switch | Partly | Off switch built. No speed or count setting. |
| FR-9 | Seven puzzle types | Partly | Idler, speed, ratio, circuit, energy sources, magnets and lever are built. Pulleys and forces are not. |
| FR-10 | Three tiers of parameterised puzzles | Not built | 12 fixed puzzles. |
| FR-11, FR-12 | Feedback, no time pressure | Built | A miss says exactly what the choice did. A hint appears after the second miss. |
| FR-13 | Standards codes | Built | Shown in the Parent zone. |
| FR-14 | Drag-and-snap vehicle editor | Changed | The build is a motor gear and a wheel gear chosen with steppers. A drag editor is on the roadmap. |
| FR-15 | Three vehicle families, 15 races | Built | |
| FR-16, FR-17 | Required slots and build validation | Changed | Not needed with a two-gear build. Family parts gate the families instead. |
| FR-18 | Stat bars and numbers | Built | Torque and speed bars with numbers. |
| FR-19 | Naming and customisation | Not built | |
| FR-20 to FR-21 | Side-view race, deterministic | Built | |
| FR-20a, FR-20b | Gear ratio is the central decision, live readout | Built | |
| FR-22, FR-22a, FR-22b | Results, "Why did I lose?", gentle loss framing | Built | |
| FR-23 | Tweak and retry | Built | |
| FR-24 | Rival scaling | Changed | Each rival is tuned to finish about 0.7 s behind the best build on its course. |
| FR-25, FR-26 | Linear unlock, autosave | Built | Families also need their parts. |
| FR-27 | Local profiles | Not built | One profile per device. |
| FR-28 | Free build | Not built | |
| FR-29 | Codex | Built | Read-aloud on each card. |
| FR-30 | Parent zone | Built | Time played, courses, stars, concepts, standards, privacy note. |
| FR-31 | Teacher printable | Not built | |
| FR-32 | Sound, music, haptics, language | Partly | Sound, music and vibration built. English only. |
| FR-33 | Parent gate | Built | Three digits written as words, on-screen keypad. Guards the Parent zone. There are no purchases or links to guard yet. |
| FR-34 | No ads, SDKs, accounts, chat, notifications | Built | The Android preset also switches off the internet permission. |
| NFR-1 | Offline | Built | |
| NFR-2 | Performance and size | Unmeasured | Web build 44 MB, Windows 98 MB. No device profiling yet. |
| NFR-3 | Portrait menus, tablets | Not built | Landscape only. Layouts stretch but are untested on tablets. |
| NFR-4 | Accessibility | Partly | Three themes, large text, reduced motion, read-aloud through the device voice, non-drag puzzles, nothing depends on colour alone. Screen-reader support is missing (see roadmap). |
| NFR-5 | Privacy law | Designed for | Needs a legal review before release. |
| NFR-6 | Content rating | Drafted | See `docs/STORE_LISTING.md`. |
| NFR-7 | Localisation | Not built | Text is written in the code. |
| NFR-8 | Determinism | Built | Fixed step, tested. |

## What the playthrough bot found

The bot opens crates in shelf order and always builds the best winning drivetrain from the gears it owns.

- Two crates (a 32T wheel gear and an 8T motor gear) are enough to win the first course, and a 4 : 1 build wins the first five. Three stars on Windy Straight needs a smaller ratio, so the child has to go back and find more gears. That is the pull to explore.
- Green Energy opens after the solar panel and wind blade crates, Planes after the wings and propeller.
- Winning all 15 courses takes 9 of the 12 crates. Three stars everywhere is possible with the right gears.
- Later courses reward finding more gears less than the early ones. A reason to keep collecting (for example bigger star totals unlocking cosmetic rewards) is on the roadmap.

## Known problems and risks

- Not tested on a real phone: touch feel, frame rate, battery, the on-screen stick, the device voice, vibration.
- No screen-reader support. Godot 4.4 has none; it arrives in a later Godot release.
- The best gear ratio sits between 2.5 and 6 on every course. A flat motor curve keeps the sweet spot wide. Courses differ mostly in what fails, not in the winner.
- All art is shapes drawn in code. It is consistent but not final.
- The default font is used. The design system's fonts are not bundled.
- The best-build search uses all ten gears, but the hints only suggest gears the child owns. A child with few gears may need a hint to visit the Workshop, which the button does.
- Exported builds are unsigned.
