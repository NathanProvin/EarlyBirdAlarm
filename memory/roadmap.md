# Early Bird Alarm — Roadmap

Iterative: each step ends with something that runs on a real Android device. Placeholders first, real content later. See `decisions.md` for rules and choices.

## Status — 2026-10-30
- **App:** feature-complete for a first free Android release; Iteration 4a polish done (see below). Everything committed and pushed; the S22 runs a **profile** build of the latest commit (`flutter build apk --profile`, installed with `adb install --no-streaming -r`; same debug signature, data kept). Test builds have a dev-only "preview a card reveal" row at the bottom of Credits.
- **Pipeline / catalog:** full catalog built and published 2026-10-30: **1,710 species, 1,212 regions** (1,159 GPS cells named "France · North"…, 40 countries, 13 bioregions) + 20 "coming soon" placeholder countries. A publish force-pushes ~800 MB in one go (`gh-pages` is rebuilt from scratch): needs a stable connection (one Wi-Fi cut cost two retries).
- **Phone:** the user's card collection was wiped 2026-10-30 to start fresh (backups in the session scratchpad); streak, alarms and settings kept.
- **Next:** see "Next steps to release" below, starting with A.

## Next steps to release (decided 2026-10-30)
The fastest path: finish **A** today; create the Play developer account **now, in parallel** (identity check and the 14-day closed test are the long, unavoidable waits); meanwhile **B** and **C**.

### A — Finish the content (when the catalog run ends)
- [x] Full run done 2026-10-30 13:21 (first attempt stopped at the NC self-check: "FRANCE" in a photographer's name; check fixed, rerun from cache in ~1 min): **1,629 species, 1,212 regions, 4,723 recordings** (2,021 song, 2,252 call, 450 alarm), 253 species dropped
- [x] Review `pipeline/report.md`. Findings: drops are 110 "no free recording", 88 "no EN/FR name", 55 "no free photo" — some very widespread birds among them (Sandhill Crane, Ruby-crowned Kinglet, Double-crested Cormorant, American White Pelican, Cooper's Hawk…): fixable later with `pipeline/overrides.csv` (`commons=File:…` / `xc=…`). 895 species use NC recordings (fine for a free app). Stats: only 499 species have all 4; wingspan missing for 825, length for 572 (298 estimated) — those cards show fewer stat rows. 42 regions have < 50 birds; median 267
- [x] `py pipeline/build.py fallback`: 15 EU + 15 NA bundled birds re-picked, with `continent` (6.3 MB)
- [x] Series from the full catalog (`series.json`, 17 KB): only names missing are Clanga clanga / pomarina (both spotted eagles were dropped: no free photo / recording) and Gymnogyps californianus (not in the regions) — no spelling fix needed
- [ ] User review of the hand-picked series lists (Birds in black, Garden songbirds, Rainbow birds, Night singers, Eagles, Birders' legends) in `pipeline/series.md`
- [x] Published 2026-10-30 (full catalog + `series.json` online, live ~2 min after the push)
- [x] **Rescue of dropped birds (2026-10-30):** two automatic fallbacks in the pipeline — xeno-canto lookup by exact English name (its taxonomy differs from GBIF's: Antigone vs Grus canadensis) and a Commons search when the Wikidata photos aren't free (skipping paintings, maps, eggs…). **1,710 species kept (+81), 171 dropped** (88 no EN/FR name, 82 no usable free recording — mostly seabirds and Mediterranean specialists, e.g. American White Pelican —, 1 no free photo: Cooper's Hawk). Eagles series fixed (Aquila clanga / pomarina). Fallback birds re-picked (Ruby-crowned Kinglet in). Published again
- [ ] Optional: hand-pick the remaining widespread drops in `pipeline/overrides.csv` (`xc=…` / `commons=File:…`), and the 88 "no EN/FR name" species
- [x] Region naming: cells kept (local lists), named after their country + compass part; Collection groups views by name; placeholder countries listed greyed
- [x] Region picker as a world map (tap a cell, search bar, my position), merged 2026-10-31
- [ ] Check on the S22: the full region list, a fresh region download, the deck filling (14 songs) and rotating

### B — Close the 4a leftovers
- [ ] User check on the phone: app icon (home screen, themed icon) and the white-bird notification icon
- [ ] Accessibility pass: TalkBack on every screen, largest font size
- [ ] **7-night reliability test** (Iteration 1 exit, never formally done): locked, killed, after a reboot, Do Not Disturb, battery saver; ideally also on a second phone of another brand (Xiaomi, Huawei, OnePlus… kill background apps aggressively)
- [ ] Public contact email: set `CONTACT_EMAIL` in `pipeline/build.py` (privacy policy) and in `memory/store-listing.md`, then `publish`

### C — Release build
- [ ] `flutter build appbundle --release`, signed with the upload key (`keys/upload.jks` + `app/android/key.properties`, git-ignored — **back them up**: password manager + USB stick)
- [ ] Move the user's collection before switching from the test build: the Play build is signed differently, so Android sees another install. Export the prefs file with adb (as for the package rename, scratchpad copies) or rely on Android Auto Backup (verified in 4a); otherwise cards and streak stay on the test build

### D — Google Play (= 4b; needs the user)
- [ ] Create the Play developer account ($25, identity verification: can take days)
- [ ] **Closed test: at least 12 testers for 14 consecutive days** (required for new personal accounts before production) — recruit early: friends, family, birding groups
- [ ] Store listing: texts ready in `memory/store-listing.md`; still to make: 512 × 512 icon (export from the vector), 1024 × 500 feature graphic, phone screenshots (list in the file)
- [ ] Declarations (answers drafted in `memory/store-listing.md`): Data safety (no data collected), full-screen intent and exact alarms (core alarm-clock features), media-playback foreground service (Play may ask for a short video), content rating (Everyone), target audience, no ads
- [ ] Internal test → closed test (14 days) → production

### Optional — not blocking a free Android release
- [ ] iOS (Iteration 5)
- [ ] Accounts, card trading, market (see "Future")
- [ ] Replace or remove the NC-licensed recordings (mandatory only before any monetization, ads included)
- [ ] Play Store polish: localized screenshots (FR), a promo video
- [ ] Phone-tilt parallax (gyroscope) for boosters and cards, if the finger version isn't enough
- [x] Slimmer app: 20 bundled birds instead of 30 (10 EU + 10 NA, 6.4 → 4.3 MB), 2026-10-31
- [ ] **German and Spanish** (~1 day; plan from 2026-10-30): one language list `en, fr, de, es` in the pipeline (the app's comes from the ARB files); 1) generalize with EN/FR only — a `name(json, locale)` helper replaces the 6 `startsWith('fr')` checks, Wikidata query / region / series names loop over the list; 2) add `app_de.arb` / `app_es.arb` (83 strings, native proofreading), bird names from Wikidata `de`/`es` labels (**missing ones fall back to English; only EN + FR stay mandatory**, so no new drops), country names from Wikidata by ISO code (only the 13 bioregions, 9 compass words and 18 series names hand-written), German/Spanish ordinals, privacy policy pages DE/ES (legal text), language setting as a dropdown; 3) rerun the pipeline (new Wikidata name queries only); 4) layout check on the phone in German (long words). New names are extra fields next to `en`/`fr` in the catalog, so older app versions keep working (no `v2`). Optional: Play listing DE/ES. First, one query to count the 1,710 birds missing a German / Spanish name
- [ ] Faster publish: push on top of the online `gh-pages` (only changed files are sent) instead of ~800 MB from scratch
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
- [x] Regions: 2°×2° cells (GPS) + European countries + bioregions (USA 8, Canada 4, European Russia); presence and rarity per region
- [x] Species built once for all regions (names, photo, 1–5 varied recordings: song/call/alarm, stats); global card numbers; report per region
- [x] Site in `pipeline/site/v1/` (species.json, regions.json, regions/, audio/, photos/) on GitHub Pages: `gh-pages` branch of NathanProvin/EarlyBirdAlarm → https://nathanprovin.github.io/EarlyBirdAlarm/v1/ (full catalog live 2026-10-30: 1,710 species, 1,212 regions)
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
- [x] **4 bird themes + Phone**: Blackbird (dark), Serin (dark, renamed from Greenfinch, mossier green), Blue Tit (light), Gull / FR Mouette (light, the Black-headed Gull); Phone = Blue Tit by day, Blackbird in dark mode; old saved themes fall back to Phone. Picker = a row of drawn birds in each theme's plumage with palette dots (2026-10-30). Selected Settings options filled with the theme accent, others neutral.

#### 2026-10-30 (all on the S22; details in decisions.md)
- [x] Streak pill top left: the theme's animated bird (asleep / bobbing / hopping with a flame / flapping) + the count
- [x] "Resident" instead of "0.0 km" flight distance
- [x] **Pick = bird first, then card rarity:** bird drafted as before (scarce species a little more often: 16/9/6/3/2), then the card's rarity from the difficulty's odds (Easy 60/32/7/1/0, Medium 45/32/16/6/1, Hard 25/34/27/13/3), tilted toward the bird's scarcity (×½ per tier of distance). Rarest copy = best copy; Legendary hunter = 5 Legendary cards
- [x] **Deck rotation:** only downloaded, not-just-heard songs count, so each answer brings a new species; bundled birds only as a fallback (they had filled the deck: nothing had ever been downloaded); ≤ 60 songs kept; offline first launch keeps the user's continent's bundled birds
- [x] **Stats with a fat upward tail** (shared "specimen" factor, Student-t): quality ≥ 80 % for ~8.5 % of cards (was 1.7 %)
- [x] **Card stock per rarity**, all faint: guilloche (Common, Uncommon), wide lattice (Rare), foliage shadow (Epic), golden camouflage (Legendary)
- [x] **Cards in 3D:** full-screen cards tilt toward a held finger (no sway); glossy plastic shine on Epic and Legendary sliding with the tilt
- [x] Reveal: fireworks from the card's border + aura, scaled by rarity; discreet haptics on booster opening and on each reveal step
- [x] Dev-only reveal preview per rarity (Credits, test builds only; nothing saved)

### 4b — Play Store
See "Next steps to release", D.

## Future — Social & market (needs accounts; see decisions.md "Accounts")
- [ ] Anonymous-first accounts + Sign in with Google/Apple; upload of the local collection
- [ ] Server-minted cards (stat rolls on the server)
- [ ] Trade cards with friends
- [ ] Market with an in-game currency (no real money)
- [ ] Before any monetization: replace or remove NC-licensed recordings

## Iteration 5 — iOS
- [ ] Evaluate AlarmKit (iOS 26+) vs the `alarm` package's background audio; check custom-sound support
