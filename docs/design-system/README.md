Tinker Track is a mobile STEM puzzle-racing game for ages 9 to 11. Players earn parts by solving small physics puzzles, choose gears to build a vehicle, then race a rival. Losing is part of the fun and always explains itself. Use this system for every screen, asset brief and store graphic.

## Content fundamentals

- Write at a grade 4 reading level. One idea per sentence. Explanations are two sentences at most.
- Talk to the player as "you". Address a parent as "grown-ups" only in the Parent Zone and the parent gate.
- Curious and encouraging, never babyish, never sarcastic. Say "Not yet" and "Try 3 : 1", never "Wrong" or "You lose".
- Sentence case everywhere. Labels on chips, gauges and tabs are set uppercase by the `label` style, not typed in capitals.
- Numbers are part of the fun at this age. Show teeth counts and ratios as `24T` and `3 : 1` in `numeral-*` styles. Explain a number the first time it appears.
- No emoji in UI. No exclamation marks except on the win screen.
- Losses are described by cause and cure: "Stalled on the hill. A bigger ratio gives more pull." Never blame the player.
- Real examples: "Nice, that gear turns the wheel." "Your wheels spin fast but the hill is steep." "0.8 s behind. One tooth changes that."

## Visual foundations

**Idea:** a blueprint workshop with toy-like parts. The ground is pale grid paper (Day) or a deep navy drafting table (Night Shift). Parts are chunky, outlined in `ink`, and cast a hard offset shadow so they look like physical toys you can pick up.

- **Color.** Ground `surface`; raised things `surface-raised`; wells `surface-sunken`. Text is `ink`, secondary text `ink-muted`. Four identity colors: `brand` (Gear Yellow, primary action and Ground vehicles), `teal` (Circuit Teal, success, energy, speed), `blue` (Bolt Blue, hints, air, torque), `danger` (Rally Orange, stalls and losses). Each has an `on-` token for text on its fill and a `-tint` ground for calm callouts.
- **Vehicle families.** Ground = `brand`, Green Energy = `teal`, Air = `blue`. Use the family color for chips, zone headers and race banners; never as the only cue, always with the family name or icon.
- **Type.** Bricolage Grotesque for display and titles (`display-*`, `title`). Atkinson Hyperlegible for all reading text (`body`, `body-sm`, `label`, `caption`); it is designed for legibility and helps readers with dyslexia. JetBrains Mono for every number that students compare (`numeral-*`). Keep `body` at 18px on phones; nothing is smaller than 14px.
- **Spacing.** 4px base: `space-1` to `space-8`. Screen side gutter is `space-4`. Touch targets are at least 48px (`space-7`).
- **Radius.** `radius-sm` inputs and chips, `radius-md` buttons and part tiles, `radius-lg` cards and dialogs, `radius-pill` status pills.
- **Outlines and shadows.** Every pickable object has a 2px `ink` outline and `toy-shadow`. Pressing removes the shadow and moves the object down 4px. Dialogs and the dragged part use `toy-shadow-lg`. No blurred shadows, no gradients.
- **Grid.** Backgrounds may carry a `grid-line` blueprint grid at 24px pitch. It is decoration only, never behind text smaller than `body`.
- **Motion.** Snap and press feedback under 120ms. Gears turning is the one continuous ambient motion, and it stops entirely in reduced-motion mode. Success is a short spring; a loss is a gentle settle, never a shake.
- **Focus.** A solid 3px `focus-ring` with a 2px offset on every focusable element.
- **Themes.** Day is the default. Night Shift follows the device. High Contrast is an added theme with every text pair at 7:1 or better, black borders and no tinted grounds.

## Iconography

Icons are chunky outline glyphs, 24px grid, 3px stroke, round caps and joins, drawn in `ink` (or an `on-` color on a fill). Never emoji. A status is never color alone: success = check, hint = question mark, loss = exclamation, each in a filled circle. Icons needed for launch are listed in `art-direction.md`.

## Do not

- Do not put `brand` yellow text on any light ground, or white text on it. Use `on-brand`.
- Do not use red, or red beside green, to signal win and loss. Teal and Rally Orange differ in lightness and always carry an icon and a word.
- Do not use gradients, drop shadows with blur, or glossy highlights.
- Do not use the names, characters, art style or layouts of any earlier commercial game.
