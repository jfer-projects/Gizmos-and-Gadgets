# Product Requirements Document — "Tinker Track" (working title)

*A mobile STEM puzzle-and-racing game inspired by the mechanics of 1990s edutainment "build a vehicle from puzzle-earned parts" games. All names, art, audio, code, characters and levels are original.*

| | |
|---|---|
| Status | v0.3 — playable build exists. See `docs/STATUS.md` for what is built, changed or missing against this PRD |
| Platforms | iOS + Android phones and tablets (Godot 4 recommended) |
| Audience | Children 9–11 (primary; Apple Kids age band 9–11, NGSS grades 4–5), parents/caregivers and teachers (secondary), nostalgic adults (tertiary) |
| Date | 2026-09-29 |

---

## 1. Context and research summary

### 1.1 The inspiration (what we can learn from, not copy)
Research on *Super Solvers: Gizmos & Gadgets!* (The Learning Company, 1993) shows:
- Educational science game for ages 7–12 covering simple machines, magnets, basic electronics, forms of energy; topics include balance, electricity, energy, force, gears, magnetics, machines.
- Structure: the player explores warehouses collecting vehicle parts, unlocking doors and boxes by solving physics puzzles, then builds vehicles and races a rival. 15 races across three categories (automotive, alternative energy, aircraft), 5 each.
- A thief-style obstacle steals collected parts; a non-lethal tool defeats it and recovers them.
- Reviews at the time praised graphics, music and replay value, unusual for edutainment then.

**Takeaway:** the durable, non-protectable ideas are: (a) *earn parts by solving small science puzzles*, (b) *assemble a vehicle from those parts*, (c) *race to test your build*, (d) *three vehicle families*, (e) *a light obstacle that risks your loot*. Everything else (fiction, characters, names, layouts, art, sound, text, the specific puzzles) must be original. See §9.

### 1.2 Market and competitive scan
| Product | What it proves | Gap we can fill |
|---|---|---|
| Bad Piggies (Rovio) | Build-a-vehicle-and-run is a proven mobile loop; criticised for freemium wrapper (paid "scrap"/ads) | Same loop, no predatory monetization, real science explanation |
| Poly Bridge series | Engineering sandbox puzzles retain adults and older kids | Too hard/unguided for 7–12; no learning scaffolding |
| The Incredible Machine | Grandfather of contraption puzzlers | Dated; no mobile-native touch design |
| Kids learning subscriptions (Prodigy, Lingokids, Sago Mini) | Parents pay for ad-free, research-backed kids apps | Mostly math/literacy/toddler; few *physics/engineering* titles for 7–12 |

Market signals (directional only — sourced from vendor market reports, not audited): educational games are the fastest-growing education-app category; subscriptions dominate revenue; iOS skews to higher ARPU; parents increasingly prefer ad-free. **Open item:** validate with a real source (Sensor Tower / Appfigures) before any funding or pricing decision.

### 1.3 Standards alignment (for teacher/parent credibility)
Map content to NGSS grades 3–5: **3-PS2-1** (balanced/unbalanced forces), **3-PS2-2** (motion patterns), **3-PS2-3/-4** (electric/magnetic interactions, magnet design problem), **4-PS3-1/-2** (speed and energy, energy transfer), **3-5-ETS1** (engineering design: define, test, improve). Every puzzle and part should carry a tag to one of these.

### 1.4 Platform and legal constraints (research)
- **COPPA (US):** Amended rule effective June 21, 2025: separate parental consent for disclosing children's data to third parties for targeted advertising, stricter retention/security, neutral age screens (no defaulting an age or nudging falsification).
- **Apple Kids Category:** one age band (5&under / 6–8 / 9–11); **parental gate required** for purchases and external links; no PII or device info to third parties without parental consent; ads must be human-reviewed; no links out without a gate.
- **Google Play Families policy:** must comply with COPPA/GDPR; child-directed apps may use only Families-certified ad SDKs and no personalized ads.
- **Implication:** the safest and simplest path is *no ads, no third-party analytics SDKs, no accounts, no chat, on-device saves*.

---

## 1.5 Owner decisions (v0.2)
1. **Publish eventually** → all P1 items (kids-store compliance, parent zone, accessibility) are in scope, not optional.
2. **Core fun = choosing the right gears to win, and learning from losses.** Gear ratios are the central build decision; a loss must always explain *why* (see FR-22a/22b).
3. **Target ages 9–11** → numbers (teeth counts, ratios) are shown by default, not hidden; reading level ~grade 4; tone avoids being babyish.

## 2. Vision, goals, non-goals

**Vision:** "Learn how things work by making them work." A kid earns parts by cracking bite-size physics puzzles, builds a vehicle, and races to see if their understanding holds up.

**Goals**
1. G1 — Ship a fun, complete single-player game (45 levels, 3 vehicle families) playable offline.
2. G2 — Each puzzle teaches one concept and gives a "why it worked" explanation in ≤ 2 sentences.
3. G3 — Legally clean and store-compliant for kids (no ads/trackers/accounts).
4. G4 — Personal-use build first (Milestone M1), commercial release optional.

**Non-goals (v1):** multiplayer, user-generated level sharing, chat, accounts/cloud save, ads, loot boxes, web build, AR.

**Success metrics (if released):** D1 ≥ 40%, D7 ≥ 15% retention; ≥ 60% of players finish the first race; median session 8–15 min; crash-free sessions ≥ 99.5%; parent rating ≥ 4.5★. Metrics collected on-device/aggregated via store-provided consoles only (no third-party SDKs).

---

## 3. Personas

| Persona | Needs | Design implication |
|---|---|---|
| **Maya, 9** — plays on family tablet | Quick wins, cool vehicles, no reading walls | Icons + short text + optional voiceover; visible progress |
| **Leo, 7** — early reader | Not to be blocked by text | Read-aloud on every prompt; forgiving hints |
| **Dana, parent** | Trust, no ads/purchases, evidence of learning | Parent zone behind gate; skill summary; one-time price |
| **Mr. Ortiz, 4th-grade teacher** | Standards alignment, short sessions | NGSS tags, 10-minute play blocks, printable concept sheet |
| **Sam, 38 — nostalgic adult (and the product owner)** | Same spirit as the 90s game | Optional retro-styled theme; harder "Expert" tier |

---

## 4. Core loop

```
Enter Workshop zone → find crates → solve a science puzzle to open a crate →
collect Part (with concept card) → avoid/handle the Pilfering Pest (loses carried parts) →
reach garage → assemble vehicle → race rival → earn stars/new zone
```

Session target: one zone + one race in ≈ 10 minutes.

---

## 5. Functional requirements

Priority: **P0** = must for M1 (personal playable), **P1** = must for public release, **P2** = later.

### 5.1 World / exploration
- FR-1 (P0) Top-down or side-view workshop zone the player walks through by touch (virtual joystick or tap-to-move; user-selectable).
- FR-2 (P0) Each zone has a "front" open area and locked "back rooms"; doors/crates open by solving puzzles.
- FR-3 (P0) Parts are categorized as Frame, Wheels/Propulsion, Power, Control, Special.
- FR-4 (P0) Player carries a limited number of parts (default 6) to a Garage drop-off.
- FR-5 (P1) 3 themed zones per vehicle family (9 zones) with distinct art and puzzle emphasis.

### 5.2 Obstacle ("Pilfering Pest" — original creature, placeholder)
- FR-6 (P0) 1–3 wandering pests per zone; contact makes the player drop one carried part to the pest.
- FR-7 (P0) Player can stun a pest with a non-violent tool (e.g., sticky-note launcher, "snooze whistle") and recover the part.
- FR-8 (P1) Difficulty setting adjusts pest count/speed; "No pests" accessibility option.

### 5.3 Puzzles
- FR-9 (P0) Puzzle types (each teaches one concept):
  1. **Balance** — place weights on a lever/scale to balance (torque).
  2. **Gears** — connect gears so an output turns the desired direction/speed.
  3. **Circuits** — complete a circuit with battery/bulb/switch; series vs. parallel.
  4. **Magnets** — orient/place magnets to attract/repel to move an object.
  5. **Levers/pulleys/inclined planes** — choose the simple machine to lift a load.
  6. **Energy** — route energy (sun, wind, spring, battery) to the right device.
  7. **Forces** — set force/angle to move an object to a target.
- FR-10 (P0) Each puzzle has 3 difficulty tiers generated from parameterized templates (≥ 15 templates, ≥ 3 variants each ⇒ replayability).
- FR-11 (P0) Immediate feedback: success animation, then a ≤ 2-sentence "Why it worked" card; failure animation with a hint on second failure and a solution walkthrough after the third.
- FR-12 (P0) No time pressure in puzzles; no penalty beyond needing another attempt.
- FR-13 (P1) Every puzzle tagged with NGSS code and concept ID for the parent report.

### 5.4 Garage and build
- FR-14 (P0) Drag-and-snap vehicle editor with visible attachment points; invalid connections highlighted with reason.
- FR-15 (P0) Vehicle families: **Ground**, **Green Energy** (solar/wind/spring/pedal), **Air**. 5 races each = 15 main races.
- FR-16 (P0) Each race defines required part slots (e.g., needs frame + 2 wheels + power) and optional performance parts.
- FR-17 (P0) Build validation before race with plain-language issue list ("No power source connected").
- FR-18 (P1) Part stats (mass, torque, efficiency) shown as simple bars; "Show me the science" toggle for numbers.
- FR-19 (P1) Vehicle naming, color/decal customization (cosmetic, all unlockable via play).

### 5.5 Racing
- FR-20 (P0) 2D side-view physics race against an AI rival on a course with hills, gaps, wind, or mud depending on family.
- FR-21 (P0) Race is deterministic given the same build (fair, learnable); no player steering required except optional boost/brake or single-button control depending on vehicle.
- FR-20a (P0) **Gear-ratio drivetrain is the central build decision.** Player picks gears (teeth counts) for the drivetrain; ratio trades torque vs. top speed. Courses reward different ratios (steep hills → high torque; long flats → high speed; mixed → multi-gear/transmission in later races).
- FR-20b (P0) Live "gear ratio" readout in the Garage (e.g., 24:8 = 3:1) with a simple torque/speed bar; numbers visible by default for ages 9–11.
- FR-22 (P0) Results screen: placement, stars (1–3), and a "what helped / what slowed you" explanation tied to parts.
- FR-22a (P0) **"Why did I lose?" replay:** after a loss, a short replay with annotated moments (e.g., "stalled on the hill: ratio too low for the slope", "topped out at 40 km/h on the flat"), naming the exact part/setting responsible.
- FR-22b (P0) Loss framing: no failure jingle or shaming; close losses shown as "0.8 s behind"; a suggested tweak is offered but the player chooses.
- FR-23 (P0) One-tap "Tweak & retry" returns to Garage with build preserved.
- FR-24 (P1) Rubber-banding is disabled; rival strength scales by race number.

### 5.6 Progression
- FR-25 (P0) Zones and races unlock linearly; replaying earns higher star ratings for cosmetic rewards.
- FR-26 (P0) Autosave after every puzzle and race; local storage only.
- FR-27 (P1) Multiple local profiles (up to 4) with avatar; no personal data required.
- FR-28 (P2) Free Build sandbox with all collected parts.

### 5.7 Learning support
- FR-29 (P1) Concept Codex: collectible cards for each concept learned, replayable mini-demos.
- FR-30 (P1) Parent Zone (behind an adult-level gate): concepts encountered, puzzles attempted vs. solved, time played, difficulty controls, play-time reminder.
- FR-31 (P2) Teacher printable: one-page concept sheets aligned to NGSS.

### 5.8 Settings and safety
- FR-32 (P0) Sound, music, haptics toggles; language selection (EN v1).
- FR-33 (P1) Parental gate for any external link, store rating prompt, and any purchase.
- FR-34 (P1) No ads, no third-party analytics/attribution SDKs, no account, no chat, no push notifications.

### 5.9 Monetization (options; recommendation below)
| Option | Pros | Cons |
|---|---|---|
| **Premium one-time ($4.99–$6.99) — recommended** | Cleanest with kids' policies; simple; parent trust | Lower reach; needs marketing |
| Free with 1st zone + one-time unlock | Try-before-buy, still no ads | Requires IAP gate + Ask to Buy handling |
| Subscription | Highest revenue in category | Needs ongoing content; heavy for one developer |

Recommended for v1: free demo (first zone + 2 races) + single full-game unlock, no consumables, no ads.

---

## 6. Non-functional requirements
- NFR-1 Offline-first; full game works without network.
- NFR-2 60 fps on devices from ~2019 mid-range; cold start < 4 s; install size < 300 MB.
- NFR-3 Portrait-supported menus, landscape gameplay; tablet layouts.
- NFR-4 Accessibility: colorblind-safe palette; puzzle solutions never rely on color alone; text scaling; read-aloud; one-handed controls; reduced-motion mode; dyslexia-friendly font option.
- NFR-5 Privacy: no collection of personal information; compliant with COPPA (amended 2025), GDPR-K, Apple Kids Category, Google Play Families.
- NFR-6 Content rating: target ESRB Everyone / PEGI 3; Apple 9–11 or 6–8 band.
- NFR-7 Localization-ready (all strings externalized).
- NFR-8 Determinism: physics stepped at fixed timestep for repeatable races.

---

## 7. Use cases

| ID | Actor | Scenario | Success criteria |
|---|---|---|---|
| UC-1 | Child | Opens crate, solves a gear puzzle on second try using hint | Crate opens, part added, concept card shown |
| UC-2 | Child | Pest steals a part; child stuns pest and recovers it | Part returns to inventory |
| UC-3 | Child | Builds a wind-powered car, loses race, sees "no gearing for hills" feedback, tweaks, wins | Retry ≤ 3 taps; win recorded |
| UC-4 | Child | Returns after a week and resumes | Autosave restores zone, inventory, build |
| UC-5 | Parent | Opens Parent Zone through gate, reviews concepts mastered, sets 30-min reminder | Gate blocks child-level tasks; data shown |
| UC-6 | Parent | Tries to buy full game | Gate → platform purchase flow → unlock persists, restorable |
| UC-7 | Teacher | Uses tablet in class for 10 minutes | No login needed; sessions start ≤ 15 s; profile switch |
| UC-8 | Child with reading difficulty | Uses read-aloud and icon hints | Completes zone without reading unaided |
| UC-9 | Adult | Plays on Expert difficulty | Puzzles with numeric parameters; no hints |

---

## 8. Design considerations

**Game feel:** bright, tactile, toy-like. Satisfying snap sounds, chunky parts, readable silhouettes at phone size. Music: upbeat, looping, per-family palette.

**Touch UX:** 48 dp minimum tap targets, drag tolerance for small hands, undo on every builder action, no gestures that need two fingers except optional zoom.

**Teaching principles:** learn-by-doing; one concept per puzzle; predict-then-test; explanations after action, not before; misconceptions addressed in failure feedback.

**Difficulty:** tier curve within each family; hint ladder (nudge → highlight → solution); never dead-end the player (always a path forward).

**Tone:** encouraging, curious, not condescending; no violence; pests are "silly" not scary.

**Art direction options** (pick one in design phase): (A) flat vector cartoon, (B) pixel-art homage with modern polish, (C) clay/paper-craft look. Recommend A for cost and scalability.

**Tech recommendation:** Godot 4 (GDScript or C#), Box2D-style 2D physics via Godot Physics 2D or Rapier; data-driven puzzle templates in JSON/Resources; deterministic fixed-step race simulation; save file as local JSON.

---

## 9. IP and clean-room policy (binding for this project)
1. No original game files, screenshots, code, audio, or extracted data are used in the repo or as tracing reference.
2. No original names: title, characters (rival, thief, hero), zone names, dialogue, or logo. Avoid names of the original cast in code, comments, and asset filenames.
3. Levels, puzzle layouts, and vehicle designs are authored fresh; do not recreate the original's specific puzzle instances from memory.
4. Use only original, licensed (record licenses), or clearly public-domain/CC0 assets. Keep an `ASSETS.md` ledger.
5. Search USPTO/EUIPO trademarks for the final title before publishing; secure domain and store names.
6. Mechanics, genre, and educational subject matter are used freely.
7. Consult an IP attorney before commercial release. This document is not legal advice.

---

## 10. Milestones

| Milestone | Scope | Outcome |
|---|---|---|
| **M0 Prototype** (2–3 wks) | Drag-and-snap builder + one race + 2 puzzle types | Feel test of core loop |
| **M1 Personal playable** (6–8 wks) | 1 vehicle family, 5 races, 7 puzzle types, pests, saves | You can play it |
| **M2 Full content** (8–12 wks) | 3 families, 15 races, 9 zones, codex | Feature complete |
| **M3 Polish + compliance** (4–6 wks) | Accessibility, parent zone, gates, store assets, playtests with kids | Store-ready |
| **M4 Launch** | Soft launch (one country) → global | Monitor crashes and reviews |

---

## 11. Risks and mitigations
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Derivative-work claim | Low if §9 followed | High | Strict clean-room, original fiction |
| Physics builder too hard for kids | Med | High | Guided templates, snap points, playtests every milestone |
| Content volume (art, levels) too large for one dev | High | High | Parameterized puzzles, modular parts, reuse kit-bash art, consider AI-assisted concepting with licensing review |
| Kids-store rejection | Med | Med | No SDKs/ads/links; gates; pre-review checklist |
| Discoverability of a premium kids app | High | Med | Lean on teacher/parent channels, press kit, free demo |
| Physics nondeterminism across devices | Med | Med | Fixed timestep, deterministic solver, test on low-end devices |

---

## 12. Open questions for the owner
1. ~~Personal-only or publish?~~ **Decided: publish eventually.** (Changes how much of §5.7–5.9 and §6 we build.)
2. Preferred **engine/stack** (Godot recommended) and your coding comfort.
3. Preferred **art style** (A/B/C) and budget for art/audio.
4. ~~Target age band~~ **Decided: 9–11.** Still open: **school/classroom** ambitions.
5. ~~Which parts did you love most?~~ **Answered:** working out the right gears to win the race, and the (productive) frustration of losing. (Your memory of the *feel* guides mechanics; it does not need to be copied.)
6. Monetization preference (premium recommended).

## 13. Sources
- [Gizmos & Gadgets! overview (Wikipedia, via search summary)](https://en.wikipedia.org/wiki/Gizmos_&_Gadgets!) — wiki content was read through a search summary because direct fetch was blocked.
- [Apple Kids Category guidance](https://developer.apple.com/app-store/kids-apps/)
- [Google Play Families policies](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
- [FTC COPPA rule amendments 2025 (Federal Register)](https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule)
- [Loeb & Loeb summary of amended COPPA](https://www.loeb.com/en/insights/publications/2025/05/childrens-online-privacy-in-2025-the-amended-coppa-rule)
- [NGSS 3-PS2 Forces and Interactions](https://www.nextgenscience.org/dci-arrangement/3-ps2-motion-and-stability-forces-and-interactions)
- [Best physics puzzle games for Android (TheGamer)](https://www.thegamer.com/best-physics-puzzle-games-android-mobile-phones/)
- [Education apps market report (Dataintelo)](https://dataintelo.com/report/education-apps-market) — vendor estimate, low confidence
