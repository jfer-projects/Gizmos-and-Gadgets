# Screen specifications

Phones in landscape for play; menus support portrait. Safe-area insets are respected on every screen. Side gutter `space-4`, touch targets at least 48px.

## 1. Title
`display-xl` name, animated gears, one `tt-btn--lg` primary "Play", secondary "Parent zone" (behind the parent gate). No ads, no external links.

## 2. Map / Zone select
A blueprint-style map with three vehicle-family regions in family colors. Each zone is a card with name, stars earned (out of 3 per race) and a lock icon if not reached. Bottom bar: Codex, Garage, Settings.

## 3. Explore (workshop)
Top-left: back and part count (carried / max) as `numeral-md`. Top-right: hint and Codex. Left thumb: joystick or tap-to-move. Crates show a gear-lock icon; tapping opens the puzzle. The pest is a slow silly creature; contact makes the player drop one part.

## 4. Puzzle
Full-screen work area on `surface` with a light blueprint grid. Goal card top-center in one sentence with a read-aloud button. Draggable pieces in a tray at the bottom (`tt-part`). Hint ladder: nudge, highlight, show. "Try it" primary button runs the simulation. Success opens a Concept Card; failure shows a gentle settle and, on the second miss, a hint.

## 5. Garage
Left 60%: vehicle on a workbench with snap points shown as dashed circles. Right 40%: part tray by category tabs. Bottom-right: Gear Readout (ratio, torque, speed) updating live. A validation strip lists problems in plain words ("No power source connected"). Primary "Start race".

## 6. Race
Side view, the course fills the screen. HUD: position pill, elapsed time in `numeral-md`, and a slim progress track with the rival marker. No steering. Optional single boost or brake button, 64px, bottom right. Pause is top-left.

## 7. Results and Loss Replay
Win: `display-xl` headline, `Stars`, part unlocked, Next. Loss: "0.8 s behind" in `display-lg`, then a replay strip with 2 to 3 annotated moments (`Loss Callout`) on the timeline. Primary action "Tweak and retry" returns to the Garage with the build preserved. The suggested change is offered, never applied automatically.

## 8. Concept Codex
Grid of concept cards (`tt-concept`), locked ones shown as dashed outlines. Tapping opens the card with a short replayable demo.

## 9. Parent zone
Behind `Parent Gate`. Sections: concepts learned, time played, difficulty, reminders, purchase and restore, privacy statement. Plain, calm; no game art beyond the header.

## Motion and sound cues
| Event | Motion | Sound |
|---|---|---|
| Part picked up | Lifts 4px, shadow grows to `toy-shadow-lg` | Soft click |
| Part snaps | 80ms settle, tiny bounce | Chunky snap |
| Gear engages | Gears start turning | Ratchet whir |
| Puzzle solved | Spring pop on the crate, confetti of small gears (max 12) | Rising spring |
| Race lost | Vehicle coasts to a stop, screen holds still | Friendly "hmm" |
| Reduced motion | No ambient rotation or confetti; state changes are instant | Unchanged |
