# Early Bird Alarm — Roadmap

Iterative: each step ends with something that runs on a real Android device. Placeholders first, real content later. See `decisions.md` for rules and choices.

## Status — end of session 2026-10-29
- **App:** Iteration 4a polish done (UI rounds 2–4, Twitch Zone with boosters, card flip reveal with rarity sparkles, Series with achievements, glass bottom bar, 4 bird themes). Everything committed and pushed; the S22 runs a **profile** build of the latest commit (`flutter build apk --profile`, installed with `adb install --no-streaming -r`; same debug signature, data kept).
- **Not yet seen on the phone** (installed, phone was locked): Settings → Theme swatches and the 4 bird themes, the 3 new achievements + back button on the Series screen, the rarity-scaled sparkles (Epic/Legendary especially), the countdown/bottom-bar tweaks.
- **Pipeline:** the full catalog run (`py pipeline/build.py`, WORKERS=2) was still at step 5/6 (card stats) at the end of the session, log in `pipeline/cache/run.log`. It now also writes `series.json` at the end.
- **Next session, in order:**
  1. Check the run finished (`pipeline/cache/run.log`, `pipeline/report.md`); then `py pipeline/build.py fallback` and `py pipeline/build.py publish` (publishes `series.json` too); tick 3c-1.
  2. `py pipeline/build.py series` output: fix the Latin names "not in the catalog" in `pipeline/series.md` (GBIF spelling), review the hand-picked lists with the user.
  3. Look at the unverified items above on the S22 (unlock the phone; it locks itself when the USB link drops).
  4. Open questions for the user: "Flight 0.0 km" on resident birds (show "—" or "Resident"?); Legendary hunter is 0/66 in France (keep, or make it "5 Legendary cards"?); badge photos of narrow pictures show side bands (fill the circle?).
  5. Then 4a leftovers (icon/notification icon check, accessibility pass), and 4b when the Play account exists.
- **Working notes:** Gradle heap is capped at 3 GB (`app/android/gradle.properties`) and Gradle is stopped after each build so the pipeline keeps enough memory. Before and after each phone session, read the saved settings (`adb shell run-as com.nathanprovin.earlybird cat shared_prefs/FlutterSharedPreferences.xml`): the user also uses the phone, and automated taps can land on the wrong screen. Screen recordings (`adb shell screenrecord`) + `.tools/ffmpeg` contact sheets are the way to check animations.

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
- [x] Collection tab (bottom bar: Alarms | Collection): 3-column grid, progress, rarity filter, tap → full card, swipe between cards, ×N duplicates (reworked in 4a UI rounds 3–4)
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
- [ ] App icon (coral half-sun + ink bird on paper, adaptive + themed) and white-bird notification icon — built 2026-10-28, user check on the phone pending
- [x] Release signing (upload key in git-ignored `keys/`), release AAB + APK
- [x] **Themes** — first 3 palettes (Dawn/Dusk/Forest, 2026-10-28), **replaced on 2026-10-29 by 4 bird themes** (see below and decisions.md "Themes — birds")
- [ ] Accessibility: TalkBack labels (play button, stats, region list, alarm switches, day toggles with full day names, bottom bar, booster pile "Open a booster", badges "name, 4/9"), large text (cards capped at 1.3×) — labels added as features were built; a full TalkBack + max-font pass on the phone is still to do
- [x] Snooze button redesign (UI round 1: full-width, 64 dp, icon)
- [x] Credits screen (UI round 1) + app version (round 2)
- [x] Privacy policy (EN/FR) on GitHub Pages + link in Credits; `py pipeline/build.py publish`
- [x] Store listing texts + Data Safety / full-screen intent / exact alarm declarations (`memory/store-listing.md`)

#### UI rounds (2026-10-29, all verified on the S22 unless noted)
- [x] **Fix:** cards always use the paper/ink theme (text was invisible in dark mode); Gradle heap 8 → 3 GB.
- [x] **Round 2 (my review, user picked):** Settings headings; centered round Share/ⓘ; 7 round day toggles on one row (44 dp targets, TalkBack reads full day names); region-explicit counter; quiet "?" tiles in the app theme; "Rings in …" (later replaced by the bar); bold alarm label; weight with one decimal under 10 kg (1.2 kg); app version in Credits (Android channel `early_bird/version`, no package); haptics (tap right, buzz wrong). Not chosen: ✓ on selected options, region list ✓, grid→card transition.
- [x] **Round 3 (user):** collection 2 columns of full mini-cards (real card scaled with FittedBox); views **All** (default) | **Species** (best copy, rarest first) | **Region**; counts inside the view menu ("France (7/353)"), top-left corner freed; Settings: Region first, Seasonal/All under Difficulty + one-line description; alarm rows: time + days + switch on one row, name below, **pulsing 24 h progress bar** (fills over the last 24 h; TalkBack reads "Rings in …").
- [x] **Round 4 (user):** Region view back to 3 compact columns; rarity menu items in rarity colors; menus shrink with "…" so the top row never overflows; **Series** button; **Twitch mode** tab; bottom bar Twitch | Alarms (main) | Collection.

#### Twitch Zone ("Cocheur") — boosters
- [x] Rules: up to 5 quizzes, +1 every 10 min (one timestamp, no background job), starting one uses it, leaving forfeits it, wins cards like alarms, never touches the streak; tests for the maths.
- [x] Page: "Twitch Zone / Train and earn cards" at the top, a **floating pile of foil boosters** (1–5, slightly askew, own float rhythm, leans to the finger with parallax), large accent-colored countdown under it (hidden when full), faint outline when empty.
- [x] Booster: silver→accent foil, logo (drawn from the icon's shapes) + "Early Bird", thin dark edge, crimped seals, foil grain, tilt-following shadow and shine (the only gradient/shadow exceptions to the Dawn rules).
- [x] Opening: **single tap** → the zig-zag top strip lifts and flies off (0.3 s) while the quiz fades in; the quiz = the alarm's 4 photos, song on loop in the app, "Listen again" instead of Snooze, back allowed.
- [x] History: swipe-to-tear first (2026-10-29), replaced by tap at the user's request; the first reveal (rise out of the booster, 1.9 s) was simplified to the flip below.

#### Card reveal (alarms and Twitch)
- [x] The card **flips face up in place** on the final screen (no layout jump), starting once the screen has slid in; each face is cached (RepaintBoundary) for smooth frames; heavy haptic when it turns. "New Common card!" title removed.
- [x] **Sparkles scale with rarity:** Common = small burst behind the card (1.1 s) · Uncommon + twinkling 4-point stars around the edge · Rare denser · Epic + 2 glints orbiting the edge · Legendary 48 particles, 20 stars, 3 glints + a sheen across the card (2.5 s). Not seen on the phone yet.

#### Series (Collection → Series)
- [x] Pages of 2×3 round badges (swipe, page dots, small back button bottom right): photo of the signature bird (greyed until one is won), accent progress arc, **foil ring when complete**; tap → the series' birds 3 per row → full cards.
- [x] Kinds: **families** (Gulls, Owls, Woodpeckers, Ducks & geese, Birds of prey, Herons & egrets, Waders, Crows & jays, Tits, Finches, Swallows & swifts, Thrushes), **themes** (Birds in black, Garden songbirds, Rainbow birds, Night singers, Eagles), **Birders' legends**, **achievements** (Legendary hunter, Perfect week, Full set, Collector 100 cards, Local expert 50 species, Rare finds 5 Rare+).
- [x] Data: `pipeline/series.md` (editable) → `py pipeline/build.py series` → `series.json` (~9 KB, bundled + published; refreshed weekly with the catalog). A series shows when ≥ 3 of its birds live in the region.
- [x] Reward: each completion (once per region) = **+1 bonus booster**, on top of the 5 and used first; granted silently after an answer (no text on the reveal, user's choice).
- [ ] Check `series.md` names against the full catalog (`py pipeline/build.py series` lists the missing ones), user review of the hand-picked lists.

#### Bottom bar & themes
- [x] Bottom bar: **frosted glass** (blur + translucent surface) over the pages, Twitch (music note + count badge) | Alarms (52 dp accent circle, ring when open) | Collection; pages scroll under it. History: plain → shaped "bump" background → glass (user).
- [x] **4 bird themes + Phone**, picked with round swatches in Settings: Blackbird (dark), Serin (dark), Blue Tit (light), Gull (light); Phone = Blue Tit by day, Blackbird in dark mode; old saved themes fall back to Phone. Not seen on the phone yet.

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
