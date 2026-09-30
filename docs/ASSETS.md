# Asset ledger

Every non-code asset in the game, and where it comes from. Update this before adding anything.

| Asset | Where | Source | Licence |
|---|---|---|---|
| All game art (gears, vehicles, crates, pest, player, scenery) | Drawn in code by `game/scripts/tt.gd` and the screen scripts | Original, made for this project | Owned by the project owner |
| App icon and Android layers | `game/icon.png`, `icon_foreground.png`, `icon_background.png` | Made by `game/tools/make_icon.gd` from the game's own gear drawing | Owned by the project owner |
| Sound effects and music | Made at start-up by `game/scripts/audio.gd` | Original, synthesised in code, no audio files | Owned by the project owner |
| Text font | Godot's built-in default font (Open Sans) | Bundled inside the Godot engine | Apache 2.0, comes with Godot |
| Bold text | The same font, emboldened in code | | |
| Engine | Godot 4.4.1 | godotengine.org | MIT |
| Design-system fonts (not yet bundled) | Bricolage Grotesque, Atkinson Hyperlegible, JetBrains Mono | Google Fonts | SIL Open Font Licence 1.1. Add the licence file when bundling. |

## Rules

- No file, code, screenshot or data from any earlier commercial game may be used, traced or copied, and no earlier game's names, characters or level layouts may appear.
- Generated art (from an image tool) must be logged here with the tool, the prompt and the licence terms, and checked for resemblance to existing characters.
- Every new font, image or sound gets a row here in the same change that adds it.
