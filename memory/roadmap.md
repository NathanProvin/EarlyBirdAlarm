# Early Bird Alarm — Roadmap

Iterative: each step ends with something that runs on a real Android device. Placeholders first, real content later. See `decisions.md` for rules and choices.

## Iteration 0 — Setup
- [x] `git init`, Flutter project in `app/`, Dawn theme tokens in `lib/ui/theme.dart`

## Iteration 1 — PoC: the core loop with placeholders
- [x] One alarm (hard-coded time picker) that rings via the `alarm` package with the screen locked or the app killed
- [x] 5 bundled placeholder birds (one clip each, placeholder image, EN name + Latin name)
- [x] Ringing screen: 4 choices → success/failure pop-up → reveal screen
- [ ] **Exit:** (passed once on a Galaxy S22: open / locked / killed — 2026-10-27; 7-night soak pending) rings reliably for 7 nights on 2 devices (locked / killed / reboot / Do Not Disturb / Doze). Permissions: `USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`

## Iteration 2 — Real alarm app
- [x] Multiple alarms (time, repeat days, on/off, snooze length, label), fade-in, snooze replays the same bird
- [x] Streak, recent-bird rotation
- [x] Difficulty setting — done in Iteration 3a
- [x] EN/FR localization (UI strings + bird names). Follows the phone language; FR verified on device 2026-10-27, EN not yet

## Iteration 3a — Real content, one region (northern France, cell N48E002)
- [x] Pipeline v0 (`pipeline/build.py`): GBIF presence + rarity per month, GBIF taxonomy, Wikidata EN/FR names + photo, Commons credits, xeno-canto recordings (CC0/BY/BY-SA only), ffmpeg; `report.md`; your photos in `pipeline/my_photos/`
- [x] Catalog bundled in the app; season + rarity filter; difficulty (wrong answers by order/family)
- [x] Settings screen: difficulty, "All birds", **language picker** (Phone / English / Français — user request 2026-10-27), region shown

## Iteration 3b — Card collection (TCG) — see decisions.md "Card collection"
- [x] Pipeline: 5 rarity tiers (replace the 3), card number, stats (weight, wingspan, length, flight distance) with mean + spread per species; coverage report for stats
- [x] Card widget (5 rarity colors, photo, names, 4 stats, quality %, number) — the reveal screen becomes the card
- [x] Correct guess = new card with Gaussian-rolled stats; wrong guess = "heard" silhouette
- [x] Collection tab (bottom bar: Alarms | Collection): 3-column grid, progress, rarity filter, tap → full card, swipe between cards, ×N duplicates
- [x] Share a card as a PNG via the share sheet (`share_plus`)

## Iteration 3c — Full catalog
### 3c-1 — Pipeline + hosting
- [ ] Regions: 2°×2° cells (GPS) + European countries + bioregions (USA 8, Canada 4, European Russia); presence and rarity per region
- [ ] Species built once for all regions (names, photo, 1–5 varied recordings: song/call/alarm, stats); global card numbers; report per region
- [ ] Site in `pipeline/site/v1/` (species.json, regions.json, regions/, audio/, photos/) on GitHub Pages: `gh-pages` branch of NathanProvin/EarlyBirdAlarm → https://nathanprovin.github.io/EarlyBirdAlarm/v1/ (3-region test catalog live 2026-10-28; full catalog pending)
- [x] ~30 fallback birds bundled in the app (`py pipeline/build.py fallback`; rerun after the full catalog)

### 3c-2 — App (verified on the S22, 2026-10-28, with the 3-region test catalog)
- [x] Region: "Use my location" (coarse GPS → cell) or country/bioregion list; first launch + Settings
- [x] Downloads: region photos + audio deck (~14), topped up at app open and after each guess; offline → fallback birds
- [x] Cards keep the rarity and region they were won in; collection = region birds + cards won elsewhere
- [x] Vocalizations: ring picks a recording by difficulty (Easy songs, Medium + calls, Hard all); reveal shows Song / Call / Alarm

## Iteration 4 — Polish and beta
### 4a — Ready to ship, no Play account needed (started 2026-10-28)
- [x] Package name `com.nathanprovin.earlybird` (permanent once on Play); move the S22's collection to it once
- [ ] App icon (coral half-sun + ink bird on paper, adaptive + themed) and white-bird notification icon
- [x] Release signing (upload key in git-ignored `keys/`), release AAB + APK
- [ ] **Themes** — 3 palettes + Settings → Theme (Follow phone = Dawn by day / Dusk in dark mode | Dawn | Dusk | Forest); cards stay on paper in every theme:

  | Theme | Mood | Background | Text | Accent | Secondary surface |
  |---|---|---|---|---|---|
  | Dawn (light) | Warm paper at sunrise | `#F6F1EA` | `#1C1B1A` | coral `#E86A4F` | `#DDD5CA` |
  | Dusk (dark) | Indigo evening sky, amber last light | `#1A1B2E` | `#ECE8F5` | amber `#F2A541` | `#2C2D45` |
  | Forest (light) | Pale sage, deep pine | `#EDF0E6` | `#1F2A22` | pine `#1E6B66` | `#D6DDCC` |
- [ ] Accessibility: TalkBack labels (play button, stats, region list, alarm switches), large text (cards capped at 1.3×)
- [x] Snooze button redesign (UI round 1: full-width, 64 dp, icon)
- [x] Credits screen (UI round 1)
- [x] Privacy policy (EN/FR) on GitHub Pages + link in Credits; `py pipeline/build.py publish`
- [x] Store listing texts + Data Safety / full-screen intent / exact alarm declarations (`memory/store-listing.md`)
- [x] UI review round 2 (2026-10-29): Settings headings (Birds, Credits); centered round Share/ⓘ buttons; 7 round day toggles on one row; "7/353 · France" counter; quiet "?" tiles in the app theme; "Rings in 7 h 05" + bold alarm label; weight 1.2 kg; app version in Credits; haptics (tap when right, buzz when wrong, heavy on a new card). Not chosen: ✓ on selected options, region list ✓, card flip, grid→card transition
- [x] UI round 3 (2026-10-29, user's comments): collection in 2 columns of full mini-cards; views All (default) | Species (best copy, rarest first) | Region, counts in the view menu ("France (7/353)"), top-left corner freed; Settings: Region first, Seasonal/All under Difficulty with a one-line description; alarm rows: time + days + switch on one row, name below, pulsing 24 h progress bar for active alarms
- [x] UI round 4 (2026-10-29): Region view back to 3 columns; rarity menu colored; "Series" placeholder button; Twitch mode tab (5 quizzes, +1 / 10 min, countdown); bottom bar Twitch | Alarms (main) | Collection
- [ ] Series: concept to come (user)

### 4b — Play Store (needs the Play developer account: $25, identity check)
- [ ] Create the Play Console app, upload the AAB to internal testing, submit the declarations
- [ ] Screenshots and feature graphic

## Future — Social & market (needs accounts; see decisions.md "Accounts")
- [ ] Anonymous-first accounts + Sign in with Google/Apple; upload of the local collection
- [ ] Server-minted cards (stat rolls on the server)
- [ ] Trade cards with friends
- [ ] Market with an in-game currency (no real money)
- [ ] Before any monetization: replace or remove NC-licensed recordings

## Iteration 5 — iOS
- [ ] Evaluate AlarmKit (iOS 26+) vs the `alarm` package's background audio; check custom-sound support
