# Early Bird Alarm — Roadmap

Iterative: each step ends with something that runs on a real Android device. Placeholders first, real content later. See `decisions.md` for rules and choices ("Scaling — decided 2026-11-10" for the plan below).

## Status — 2026-11-10
- **Live:** 1.0.0+3 in **closed testing** on Google Play, **14 active installs**, lots of constructive tester feedback. Catalog (1,292 species, 0 NC recordings, 1,212 regions) and privacy pages on GitHub Pages (`gh-pages`, ~506 MB: audio 410 MB, photos 63 MB, regions 34 MB).
- **Plan rewritten 2026-11-10** around one bottleneck: **no accounts and no server** caps what the app can do (backup, codes, referrals, market, iOS sync). Order (revised 2026-11-10): **1.0.1 (lock-screen fix, tester feedback) → Infra (domain, R2, Firebase) → 1.1 (backup, codes, shiny, variants) → Production → 1.2 (Australia / NZ, heatmap) → later (iOS, marketplace, region UI)**.
- **1.0.1 done on `lock` (2026-11-10), not deployed:** the infrastructure migration and Phase 1.1 come first; production ships with them. Next: **Infra → 1.1 → Production**.
- **Working branch:** `main` (`lock` merged 2026-11-10).

## Scaling vision and infrastructure
Three layers, each with one job:

| Layer | What it holds | Why | Cost |
|---|---|---|---|
| **Own domain** (e.g. `earlybird.app`, to buy) | Nothing: an address | `baseUrl` is compiled into the app (`app/lib/content.dart`). Pointing it at our domain means the host behind it can change **without an app update**. Must ship before Production | ~€10–15 / year |
| **Cloudflare R2** behind the domain | The **catalog**: audio, photos, region lists, `species.json`, `series.json`. Same for everyone, read-only, big (0.5 GB now, several GB with regions + photo variants) | GitHub Pages: 1 GB cap, ~100 GB/month soft bandwidth, an 800 MB force-push per publish. R2: **no egress fees**, 10 GB free then ~€0.015 / GB-month, sync of changed files only | ~€0 at our scale |
| **Firebase** (Auth + Firestore) | **Per-player data**: accounts, the collection, code redemptions, referrals; later wallets and the market. Private, writable, small (KB per player) | Nothing per player exists off the phone today. Firebase Storage/Hosting bills downloads (~€0.12 / GB), so the catalog stays on R2 | Spark (free): Auth free to 50k MAU, 50k reads / 20k writes a day. Blaze (pay as you go) only when Cloud Functions are needed (marketplace) |

Rules that follow from it:
- **Offline alarms stay sacred:** an alarm must ring and give a card with no network. Firebase is a mirror, never on the alarm's path; the catalog deck is prefetched as today.
- **Cards stay rolled on the phone until the marketplace.** Then: cards pre-rolled and signed by the server when the deck is downloaded (online anyway), revealed offline. Older cards become "pre-season" (or admitted once after a plausibility check, as barter does).
- **Saved data only grows:** new card / prefs fields are optional with defaults, keys are never renamed; a test loads a real 1.0.0+3 preferences file at every release.
- **Accounts bring obligations:** Data safety ("account ID, collection"), privacy policy rewrite (EN/FR/DE/ES), **account deletion in the app and from a web page** (Play requirement); Sign in with Apple once on iOS.
- **Card numbers stay permanent** (`pipeline/numbers.json`): new zones and species get the next numbers.

## Phase 1.0.1 — Lock-screen quiz and tester feedback — DONE 2026-11-10 (branch `lock`, not deployed)
Open ends moved: the domain to Infra; the full-screen declaration, the tester-phone check and the release bundle to Production.
The alarm must show the quiz over the lock screen, screen off, on every tester's phone. Core loop first.
- [x] (reproduced on the S22 by denying the permission, 2026-11-10; the S22's Play install had it granted) **Cause:** confirm on testers' phones (models, Android versions). Likely: Android 14+ turns the full-screen-intent permission off unless Play grants it (alarm-app declaration), plus vendor switches (Samsung sleeping apps, Xiaomi "Show on lock screen" / "Pop-up windows")
- [x] **Alarm permissions on the onboarding's region page** (2026-11-10, user's choice, replacing a separate "Wake-up check" page, its Settings entry and its test ring): under the region pill, "Alarm permissions" lists notifications, quiz over the lock screen (Android 14+, `canUseFullScreenIntent`) and, only on brands that kill apps (Xiaomi, Huawei, Honor, Oppo, Vivo, Realme, OnePlus) while restricted, battery unrestricted (elsewhere alarm-clock alarms get through battery optimisation: hidden), each with ✓ or a Fix button that opens the right system screen (`app/lib/ui/wake.dart`); Skip on the welcome page leads there. Seen on the S22
- [x] **Gentler ring** (testers found it harsh, 2026-11-10): the bird starts silent and rises linearly to full volume over 60 s (`ringFade`; first try 5 % over 40 s was still too harsh for the user), the phone vibrates from 40 s (`ringVibrate`) (500 ms on / off; the plugin's own vibration is off because it can only start at once). Checked on the S22: no vibration at 5 / 20 / 35 s, vibrating at 45 s; the volume ramp itself can't be read with adb, to listen to. Limit: the vibration comes from the quiz screen, so it needs the quiz to show (the permission above)
- [x] **Tester feedback fixes** (list from the user 2026-11-10, coded the same day; seen on the S22: Alarms header, Training page with a full pile, Collection header):
  - Header shared by Alarms and Training: coffee (tips) left, gear right; Alarms: "Streak: N" pill (text, flame, bird on the right) in the middle; add-alarm button = alarm + plus icon
  - **Training** replaces Twitch / Cocheur everywhere (tab, title; the subtitle removed); the paid option is now **Early Bird Plus** (product id `twitch_plus` unchanged: rename its title in the Console), a labeled button offered even on a full pile; empty pile → countdown centered with an hourglass, else countdown at the bottom, raised
  - Support: a card at the top of Settings; a one-time line on the card reveal from 30 cards; Google's in-app review asked once when a reveal is closed from 15 cards (`in_app_review` 2.0.12; never shows on sideloaded builds: check with an internal-test install)
  - Collection: opens on the region; view pill (region, Collected, Species, other regions, all birds of the world); sort (number / rarity / name) and rarity filter in one sheet; Trade and Series as icons; duplicates drawn as a pile in the Species view. Checked: the region view only lists the region's species (France · Nord: ~350 of 1,292 species, the all-year list), not the catalog
  - Region picker: grid and green square hidden, red outline of the covered area ("Red: covered area"), a pin (tap or GPS; tapping outside: "Not covered yet"), a plain Confirm button, back cancels, search only moves the map; cell names kept (place names later)
  - Later rounds the same day: "World" view; Trade / Series in round outlines, the medal in the accent; one fixed-width button opens a sheet (view as a drop-down that closes it, sort, rarity as six circles); heard birds get a glass play button (small tiles and the full card, under "Try next time"); no cell name under the pin; a smaller support card ("Free, no ads, no trackers"); Plus pulses its colour and glow only; the streak pill also heads Training, Training answers count in it, no bird at 0; "Perfect week" and "Iron streak" count alarm answers only (`alarmStreak`, seeded from the 1.0.0+3 streak); Series opens on achievements, a tap shows an achievement's goal; coffee icon in the accent
- [x] S22 check of all the feedback screens (Collection bar and sheet, heard tiles, region picker, Training header, Settings): **validated by the user (2026-11-10)**
- [x] (2026-11-10, `app/test/upgrade_test.dart`, written from the 1.0.0+3 format; swap in a real S22 export when the phone is connected) Test: a 1.0.0+3 preferences file (cards, given, alarms, streak) loads in the new version

## Production (Google Play)
Updates during the closed test don't reset the clock. Testers' emails go into the Play Console only, never into the repo.
- [x] Upload 1.0.0+3 to internal testing
- [x] Closed test track, testers' email list, opt-in link sent; testers installed from the Play Store (14 active installs on 2026-11-10)
- [ ] **14 consecutive days with ≥ 12 opted-in testers**
- [x] Payments profile and the 5 one-time products created in the Play Console (2026-11-10): `tip_espresso` 0.99, `tip_cappuccino` 1.99, `tip_breakfast` 4.99, `tip_binoculars` 19.99 €, `twitch_plus` 1.99 € titled "Early Bird Plus" (English titles and descriptions; no icons yet)
- [ ] (license tester set in the Play Console, 2026-11-10) Test purchase from a Play install, with the next bundle (tips page shows the 4 prices, "Thank you!"; Plus on the Training page)
- [ ] Play Console: **full-screen intent declaration** (alarm clock) so Play grants the permission on install
- [ ] (S22, Android 16, 2026-11-10: **bug reproduced** with the full-screen permission denied by adb — screen stays off, only a notification; Fix opens "Alertes en plein écran", the row turns ✓ on return; with it on, the screen wakes and the quiz shows over the lock screen; the test answer saves no card and shows "Ça marche !" 3 s over the lock screen, then the phone stays locked and the screen goes off. Battery row made advice only: the S22 passed 7 nights with battery optimised. Left: a tester's phone) **Then on a tester's Android 14+ phone:** the onboarding page, each Fix button (full-screen screen, app info → Battery), the test ring with the screen locked (answering gives no card, snooze just stops it)
- [ ] Release bundle: version bump, signed bundle, upload (the first release after Infra and 1.1)
- [ ] S22 check of the backup alarm (rooster at 3 min, strong vibration, volume locked, guess and snooze stop it, rings with the app killed)
- [ ] Store listing (`memory/store-listing.md`, `store/`: icon, feature graphic, 5 screenshots, `store/listing-translations.txt`) and declarations: Data safety, content rating, target audience, no ads, **full-screen intent**, exact alarms
- [ ] Alarm video for the media-playback foreground-service declaration (S22, locked screen, alarm rings, guess), unlisted YouTube
- [ ] Export the user's collection (adb) before switching the S22 to the Play build (different signature = another app)
- [ ] After 14 days: **Apply for production** (Dashboard), Google review up to ~7 days; production with the Infra + 1.1 release, staged rollout 20 % → 100 %
- [ ] README: fill `PLAY_STORE_URL`

## Phase Infra — domain, R2, Firebase (no visible app change)
- [x] (2026-11-10) **Domain** `earlybirdalarm.app` (Cloudflare Registrar); `baseUrl` = `https://cdn.earlybirdalarm.app/v1/` (the GitHub Pages step skipped: straight to R2)
- [x] (2026-11-10) **Catalog on Cloudflare R2**: bucket `earlybird-catalog` (EU jurisdiction, `.eu.` S3 endpoint), custom domain `cdn.earlybirdalarm.app`, r2.dev off; `publish` mirrors it with rclone (winget), keys in `keys/r2.txt`; first sync 493 MB / 5,604 files in 2.5 min, an unchanged re-run 0 B in 20 s. `gh-pages` frozen as is for 1.0.0+3 phones (`publish gh-pages` pushes it again if ever needed)
- [x] S22 check (2026-11-10): a profile build with the region list made stale re-downloaded `species.json`, `regions.json`, `series.json` and `regions/N48E002.json` from R2 (same MD5 as the bucket), prefs unchanged
- [x] (2026-11-10) Privacy pages at `https://cdn.earlybirdalarm.app/privacy.html` (text names Cloudflare); URL changed in the Play Console, README and `memory/store-listing.md`
- [ ] `species.json` re-fetched only when changed (ETag / Last-Modified); split by continent when the globe grows
- [ ] **Firebase project** (`earlybird`, EU region): Auth (anonymous + Google), Firestore with security rules (a player reads and writes only their own documents), FlutterFire config for Android; plan details to discuss with the user
- [ ] Account deletion: in Settings + a web page on the domain
- [ ] Privacy policy (4 languages) and Data safety rewritten for accounts

## Phase 1.1 — Accounts and collection features
- [ ] **1 · Cloud backup:** a silent anonymous account at first launch; the collection (cards, given, heard, series, streak) mirrored to Firestore after each change (one document per player; shortcut: 1 MB ≈ 4,000 cards, split per card when someone gets near); Settings → "Sign in with Google to keep your collection"; signing in on a new phone restores it (merge: union of cards by key). Android Auto Backup stays as a second net
- [ ] **3 · Referrals & Codes** (Settings → "Referrals & Codes"):
  - Codes are words like `RedRobin`, `FavouriteGull`, `NiceTit`, case-insensitive, stored in Firestore (added or disabled from the console, optional end date / use cap); **once per account**, enforced by a create-only redemption document (security rules, no Cloud Functions → stays on the free plan)
  - Each player gets their own invite code + Share; shared cards' Play link carries `&referrer=<code>`, read on first launch with the Play Install Referrer API (Firebase Dynamic Links is shut down; iOS will type the code)
  - Rewards **to decide** (proposal: tester code = 1 guaranteed Rare from the region; newcomer = 1 Rare; inviter = 1 Rare per friend whose first alarm guess is right, cap 10, an Epic at 3 friends)
- [ ] **4 · Shiny tier** (6th tier above Legendary, **card only**, never a bird tier): 1 / 1000 per card, only for species with a real aberrant photo; card says "Leucistic" or "Melanistic", holographic frame, own reveal. Sources (queried 2026-11-10, CC0 / BY / BY-SA only): iNaturalist projects "Albino & Leucistic birds", "Leucistic Birds", "Albino, Leucistic & Melanistic Animals", "Bird Aberrations" → **145 catalog species** (crows, Dark-eyed Junco, Canada Goose, House Sparrow, Blackbird, Jackdaw, Rock Dove, American Robin, Mallard…); "melanistic" search → **29** (Pheasant, Mallard…); Commons "Leucism in birds" (~20 species, overlapping). Only ~15 % of these observations are free-licensed. Pipeline makes a contact sheet per species, **the user picks** (being in a project doesn't prove the aberration). Barter: older app versions refuse a shiny card (harmless)
- [ ] **5 · Card variants:** up to 5 photos per species from Commons Quality / Featured / Valued images (same licence filter, credit per photo), variant 1 = Common … 5 = Legendary, Featured ones to the top tiers, today's photo when there are none. Sample of 25 catalog species (2026-11-10): 40 % have ≥ 5, 12 % 3–4, 24 % 1–2, 24 % none. Each card saves its variant (new optional field) so its image never changes. Size: photos ~50 KB → +≤ 250 MB on R2; the deck downloads all variants of its ~14 birds (~3.5 MB)
- [ ] One full catalog rebuild for 4 + 5, published to R2

## Phase 1.2 — Australia and New Zealand (after the move to R2)
- [ ] Free-recording sweep on AU / NZ species (xeno-canto free + iNaturalist) before committing
- [ ] Zone in `CELL_AREAS` (same 2° cells; southern seasons need no change; the offline map already covers it), region names, `PLANNED` update
- [ ] Offline birds for an "oc" continent (`continentOf()`, `build_fallback()`: 10 bundled birds, ~2 MB)
- [ ] Overnight build (~1.5–2× today), publish, phone check
- [ ] Store listing: mention Australia / NZ
- [ ] **Missing-species heatmap** (tester request 2026-11-10; ~1.5–2 days): a bottom-left toggle on the region picker tints each covered cell by the share of its species not collected yet (or the count: to decide; the count always favours species-rich areas). Data: one pipeline file, each cell's species as card numbers (measured 2026-11-10: 1,159 cells, 260,761 pairs, 1.1 MB raw, ~0.1 MB gzip), downloaded once and refreshed with the catalog; per-region files would be ~34 MB. Tap a cell → "42 species missing here". Same file later for "where to find this bird" on a missing card

## Later
### Region UI (cells unchanged, decided 2026-11-10)
- [ ] Rework the region experience until the user is happy (picker, names, collection views); the 2° grid stays

### iOS (Iteration 5)
- [ ] AlarmKit (iOS 26+): Apple's alarm screen with a system Stop button, so the guess happens after opening the app — check custom-sound support first
- [ ] Sign in with Apple (required next to Google), StoreKit products, cross-platform collections through Firebase
- [ ] **QR-code trading** (Android ↔ iPhone; Nearby is Android-only): phones scan each other's screen for offer, counter-offer, confirmation; `qr_flutter` + `mobile_scanner`, same `TradeSession` messages, ~3–4 days
- [ ] $99 / year, a Mac or a cloud Mac build (Codemagic), a real iPhone for alarm tests

### Marketplace (when ~1,000+ daily players)
- [ ] Server-signed pre-rolled cards (see rules above); Blaze plan + Cloud Functions; per-account issuance limits
- [ ] Step 1, **the bank:** sell duplicates at a fixed price per rarity, buy a chosen card or a booster — currency gets value without liquidity
- [ ] Step 2, **player listings:** fixed-price listings, a fee as the currency sink, daily caps per account, no free text
- [ ] Currency never bought with nor turned into real money (else loot-box and virtual-currency rules)

### More of the globe (after AU / NZ)
Markets, in order (birders × willingness to pay × free-recording coverage × language cost):
2. **Mexico + Central America (Costa Rica…)**: big Android market, birding tourism, Spanish already done, Mexico already "coming soon". Many Neotropical xeno-canto recordings are NC: fewer birds.
3. **South Africa**: birding scene, English, good data.
4. **Japan** (+ Korea, Taiwan): big birding culture, paying users; needs a new language (app strings, Wikidata names, listing, privacy page).
5. **India**: huge Android base, very active eBird; English; low tips (growth / word of mouth more than revenue).
6. **Brazil**: huge market, ~1,900 species; Portuguese; the biggest catalog.
- Each market: free-recording sweep first; zone in `CELL_AREAS`; offline birds per continent; new languages through `LANGS`, `app_xx.arb`, listing, privacy page; build time grows ~linearly with regions (overnight).

## Backlog (open items carried over from the history below)
- [ ] User check on the phone: app icon (home screen, themed icon) and white-bird notification icon
- [ ] TalkBack + maximum font size pass on the phone (alarm quiz screen included)
- [ ] Check on the S22: the full region list, a fresh region download, the deck filling (14 songs) and rotating
- [ ] Hand-pick widespread dropped species in `pipeline/overrides.csv` (`xc=…` / `commons=File:…`) and the 88 "no EN/FR name" species
- [ ] `series.md` names against the current catalog (`py pipeline/build.py series` lists the missing ones)
- [ ] Cards of species dropped from the catalog are hidden: show them with a "retired" badge instead (players read hidden cards as lost)
- [ ] Play Store polish: localized screenshots, a promo video
- [ ] 7-night reliability run with the backup alarm, on 2 phones
- **Working notes:** Gradle heap is capped at 3 GB (`app/android/gradle.properties`) and Gradle is stopped after each build so the pipeline keeps enough memory. Before and after each phone session, read the saved settings (`adb shell run-as com.nathanprovin.earlybird cat shared_prefs/FlutterSharedPreferences.xml`): the user also uses the phone, and automated taps can land on the wrong screen. Screen recordings (`adb shell screenrecord`) + `.tools/ffmpeg` contact sheets are the way to check animations.

---
# History — done, and earlier plans as written
Unchecked items below are either tracked above (Production, Backlog) or superseded by the plan above.

## Next steps to release (decided 2026-10-30)
The fastest path: finish **A** today; create the Play developer account **now, in parallel** (identity check and the 14-day closed test are the long, unavoidable waits); meanwhile **B** and **C**.

### A — Finish the content (when the catalog run ends)
- [x] Full run done 2026-10-30 13:21 (first attempt stopped at the NC self-check: "FRANCE" in a photographer's name; check fixed, rerun from cache in ~1 min): **1,629 species, 1,212 regions, 4,723 recordings** (2,021 song, 2,252 call, 450 alarm), 253 species dropped
- [x] Review `pipeline/report.md`. Findings: drops are 110 "no free recording", 88 "no EN/FR name", 55 "no free photo" — some very widespread birds among them (Sandhill Crane, Ruby-crowned Kinglet, Double-crested Cormorant, American White Pelican, Cooper's Hawk…): fixable later with `pipeline/overrides.csv` (`commons=File:…` / `xc=…`). 895 species use NC recordings (fine for a free app). Stats: only 499 species have all 4; wingspan missing for 825, length for 572 (298 estimated) — those cards show fewer stat rows. 42 regions have < 50 birds; median 267
- [x] `py pipeline/build.py fallback`: 15 EU + 15 NA bundled birds re-picked, with `continent` (6.3 MB)
- [x] Series from the full catalog (`series.json`, 17 KB): only names missing are Clanga clanga / pomarina (both spotted eagles were dropped: no free photo / recording) and Gymnogyps californianus (not in the regions) — no spelling fix needed
- [x] Series reviewed by the user and reworked (2026-10-31): habitats page, renamed themes, Leaf warblers, White knights, 6 new achievements, rewards collected on the page (see decisions.md)
- [x] Published 2026-10-30 (full catalog + `series.json` online, live ~2 min after the push)
- [x] **Rescue of dropped birds (2026-10-30):** two automatic fallbacks in the pipeline — xeno-canto lookup by exact English name (its taxonomy differs from GBIF's: Antigone vs Grus canadensis) and a Commons search when the Wikidata photos aren't free (skipping paintings, maps, eggs…). **1,710 species kept (+81), 171 dropped** (88 no EN/FR name, 82 no usable free recording — mostly seabirds and Mediterranean specialists, e.g. American White Pelican —, 1 no free photo: Cooper's Hawk). Eagles series fixed (Aquila clanga / pomarina). Fallback birds re-picked (Ruby-crowned Kinglet in). Published again
- [ ] Optional: hand-pick the remaining widespread drops in `pipeline/overrides.csv` (`xc=…` / `commons=File:…`), and the 88 "no EN/FR name" species
- [x] Region naming: cells kept (local lists), named after their country + compass part; Collection groups views by name; placeholder countries listed greyed
- [x] Region picker as a world map (tap a cell, search bar, my position), merged 2026-10-31
- [x] German and Spanish (app, catalog names, privacy pages), 2026-10-31; German screens checked on the S22 (no overflow; theme names shrink to fit)
- [x] **Deck rotation bug fixed** (2026-10-31): the deck froze on ~24 species; played songs now leave it, refill weighted; simulated 1,000 cards per difficulty: diversity as the ideal draw (see decisions.md)
- [x] Settings polish (2026-10-31): language drop-down at half width; region and language as accent-filled pills like the chosen difficulty
- [x] **Barter (face-to-face trades)**: validated on two phones 2026-11-01 (after the Location-switch fix)
- [ ] Check on the S22: the full region list, a fresh region download, the deck filling (14 songs) and rotating

### B — Close the 4a leftovers
- [x] **Merge `barter` into `main`** — done 2026-11-01
- [ ] User check on the phone: app icon (home screen, themed icon) and the white-bird notification icon
- [x] Accessibility pass (2026-11-01): `app/test/a11y_test.dart` checks 8 screens (Settings, Collection, Series, Credits, Twitch Zone, onboarding, alarm editor, card reveal) against Flutter's guidelines (48 dp touch targets, labelled tap targets, text contrast) and at 200 % font size. Fixed: the Collection's round buttons and the alarm editor's weekday buttons now have 48 dp touch targets (same 40 dp look), and the Trade / Series labels shrink to fit instead of overflowing. Not automated: the alarm quiz screen (needs the alarm plugin) and a real TalkBack run — worth one manual try on the phone
- [x] **7-night reliability test** (Iteration 1 exit, never formally done): locked, killed, after a reboot, Do Not Disturb, battery saver; ideally also on a second phone of another brand (Xiaomi, Huawei, OnePlus… kill background apps aggressively) — **passed (user, 2026-11-01)**
- [x] **Native proofreading of German and Spanish**: `app/lib/l10n/app_de.arb` / `app_es.arb`, `site-static/privacy-de.html` / `privacy-es.html` (legal text), the DE/ES store listings in `memory/store-listing.md` — **verified by the user (2026-11-01)**
- [x] Public contact email: set `CONTACT_EMAIL` in `pipeline/build.py` (privacy policy) and in `memory/store-listing.md`, then `publish` — **nanodev009@gmail.com (2026-11-01)**

- [x] **Onboarding** (2026-11-01): 5 swipeable pages shown once on first launch (and from Settings → See the introduction again): welcome, region (the Settings pill → map), game options (the Settings difficulty / season controls), collection features (Twitch Zone, series rewards, trading), and a live Epic demo card to hold and tilt; Skip / Next / Let's go; the notification permission is asked after it
- [x] **GitHub README** (2026-11-01): features, how the catalog is built, repository layout, app and pipeline build commands, data licences, privacy, contact; placeholders to fill: logo (`docs/logo.png`), Play Store link (`PLAY_STORE_URL`), screenshots (`docs/screenshots/`), and the code licence (no LICENSE file yet — the user's choice)

- [x] **Late reviewer's 7 comments** (2026-11-01, see decisions.md "Reviewer polish"): navigation-bar overlap, Trade / Series text buttons, pager alignment and copy pill, Bird rarity stars, Wikipedia / Merlin buttons, Expert difficulty (name search by word start), bold Settings headers; sound effects tried and removed at the user's request. Catalog republished with the `"r"` levels; checked on the S22, 3-button navigation checked by the user. Store screenshots: **three only** (quiz, collection, Legendary card), retaken in English 2026-11-01, also in the README

### C — Release build
- [x] **Signed release bundle built 2026-11-01** (1.0.0+1, 62.5 MB, `app/build/app/outputs/bundle/release/app-release.aab`, signed CN=Nathan Provin): `flutter build appbundle --release`, signed with the upload key (`keys/upload.jks` + `app/android/key.properties`, git-ignored — **back them up**: password manager + USB stick)
- [ ] Move the user's collection before switching from the test build: the Play build is signed differently, so Android sees another install. Export the prefs file with adb (as for the package rename, scratchpad copies) or rely on Android Auto Backup (verified in 4a); otherwise cards and streak stay on the test build

### D — Google Play (= 4b; needs the user)
- [x] Create the Play developer account ($25, identity verification: can take days) — created 2026-11-01; app being created in the Console 2026-11-03 (package `com.nathanprovin.earlybird`)
- [ ] **Closed test: at least 12 testers for 14 consecutive days** (required for new personal accounts before production) — recruit early: friends, family, birding groups
- [ ] Store listing: texts rewritten for conversion 2026-11-03 (store title "Early Bird: Bird Song Alarm", launcher label stays "Early Bird") and graphics ready (`store/`: icon, feature graphic, 3 screenshots), all in `memory/store-listing.md`; paste into the Console
- [ ] Declarations (answers drafted in `memory/store-listing.md`): Data safety (no data collected), full-screen intent and exact alarms (core alarm-clock features), media-playback foreground service (Play may ask for a short video), content rating (Everyone), target audience, no ads
- [x] (done 2026-11-04, d7b7fbe: shared cards carry the Play link; README `PLAY_STORE_URL` still to fill → Production) **Share link (virality, before the next release build):** a shared card is only a PNG (`app/lib/ui/collection.dart` `_share`); add a localized `text` to `ShareParams` with the store link `https://play.google.com/store/apps/details?id=com.nathanprovin.earlybird` (known from the package name, live once published), so every shared card is an invite. Also fill `PLAY_STORE_URL` in the README
- [ ] Record the alarm video for the media-playback foreground-service declaration (S22, locked screen, alarm rings, dismiss; unlisted YouTube)
- [ ] Internal test → closed test (14 days) → production — closed test running (14 active installs on 2026-11-10) → see "Production"

### Optional — not blocking a free Android release
- [ ] iOS (Iteration 5)
- [ ] Accounts, card trading, market (see "Future")
- [ ] **Support the developer (recover development costs)** — idea 2026-11-03, not decided. Two options, simplest first:
  1. **Tips** ("Buy me a coffee": e.g. 1 €, 3 €, 5 €) in Settings / Credits, a thank-you message, no gameplay effect. Google Play Billing consumable products (`in_app_purchase` package; Play requires its billing for in-app tips, no external payment link), a payments profile in the Console. Smallest and policy-safe.
  2. **Paid booster** (small microtransaction, e.g. 0.99 € for one booster now instead of waiting for the Twitch timer). Heavier: random cards bought with money = **loot box** rules — Play requires the card odds shown before purchase, the content rating changes to "In-game purchases (includes random items)", paid loot boxes are restricted in Belgium (and contested in the Netherlands: exclude those countries or skip), and it weakens "Free" in the listing. A non-random paid item (e.g. a chosen rarity) avoids the loot-box part.
  - Both first need: the **NC-licensed recordings replaced or removed** (line below: any monetization breaks the NC licence). Measured 2026-11-03: **961 species have only NC recordings** (3,134 of 4,936 recordings, 783 recordists; photos: none NC). These species are local (84 regions on average vs 299). Plan: (a) ask the top recordists for commercial permission on xeno-canto: 5 recordists cover 438 species, 20 cover 637, 50 cover 773; record each grant in `pipeline/overrides.csv`; (b) add iNaturalist sounds as a pipeline fallback — swept 2026-11-03 (research-grade observations with a CC0 / CC BY / CC BY-SA sound): **552 of the 961 NC species have ≥ 1 free sound** (369 have ≥ 3; 71 % of NC species-regions), and 19 of the 79 recording-dropped species come back (Subalpine and Orphean Warbler, Siberian Chiffchaff, Spotted Owl…); 141 have no iNat sound at all (sea ducks, skuas: rarely recorded, not a naming problem). iNat first, then asking only the recordists of what is left: top 5 → 707 of 961, top 20 → 795, top 50 → 871. iNat caveats: phone-quality, often short, no song/call label (default to "call", so Easy stays on xeno-canto songs); same ≥ 10 s and loudness checks as xeno-canto; (c) the user's own recordings; (d) drop whatever is left, the "Contains in-app purchases" label, Data safety review (Google processes the payment; nothing collected by the app), store listing and privacy policy updated.
- [x] (merged into main 2026-11-04, 5e0cbf6 → 5f69344; final catalog 1,292 species, 0 NC, live) **Branch `adding-tips` (started 2026-11-03):** pipeline done: recordings = free xeno-canto → free iNaturalist (`inat_recordings`: research grade, CC0 / BY / BY-SA, ≥ 10 s measured with ffprobe, one per recordist, local first, all tagged "call"; clips named `{id}-n{i}.m4a` so no old NC clip is reused) → NC xeno-canto only if `ALLOW_NC` (False on this branch). Listening sample: 17 of 20 species got a ≥ 10 s clip (Common Goldeneye, Great Egret, Greater Scaup… NC species are not all local). Sample **listened to and quality validated by the user (2026-11-03)**. Full catalog run started 2026-11-03 (`pipeline/cache/run-2026-11-03-inat.log`). **Tips and Twitch Plus coded 2026-11-03** (decisions.md "Tips and Twitch Plus"; privacy pages updated, not yet published; tests and a11y pass; not yet tried on the phone). **Full NC-free catalog built 2026-11-03 (third run: iNaturalist taxon resolved by exact name, 5 s minimum): 1,298 species (was 1,713), 0 NC; 752 on free xeno-canto, 546 on iNaturalist only (530 former NC species, 16 formerly dropped); 586 dropped (497 no free recording, 88 no EN/FR name, 1 no photo); 431 former NC species lost (Rough-legged Buzzard, Surf Scoter, Lesser Scaup, Glaucous Gull, Snowy Owl…); region median 251 birds (was 267), 53 regions < 50. First run had 1,210: a name check threw out renamed species and subspecies. Lost from series: Wallcreeper, Snowy Owl, Gyrfalcon, Ivory Gull, Mandarin Duck, Great Bustard, Ruff, Montagu's Harrier, Brown Pelican… Offline birds re-picked (0 NC). Rarity odds lowered (decisions.md).** Not published yet (publish with the tips release). **Card numbers made permanent** (`pipeline/numbers.json` = the live catalog's 1,713 numbers; kept species keep theirs, new ones get 1714+, no renumbering at publish) and **xeno-canto minimum 5 s** for species with nothing ≥ 10 s (+~13: Ruff, Pacific Diver, Hawk Owl, Broad-billed Sandpiper, Cinereous Vulture…; ~1,311 species expected), 2026-11-03. **Final species build on hold until the user's go** (then the eBird build, then offline birds re-picked). **Rarity from eBird + stars saved on cards coded 2026-11-03** (decisions.md): needs one more full build (new GBIF eBird counts, several hours once). Next: Play Console: payments profile, the 5 products, license testers, internal-test build to try real purchases; publish the NC-free catalog only with the tips release (the catalog is shared with the live app; cards of dropped species are kept but hidden)
- [x] (done: the live 1,292-species catalog has no NC recording) Replace or remove the NC-licensed recordings (mandatory only before any monetization, ads included)
- [ ] Play Store polish: localized screenshots (FR), a promo video
- [x] (done 2026-11-04, 6a082a1, Settings switch on by default) Phone-tilt parallax (gyroscope) for boosters and cards, if the finger version isn't enough
- [x] Slimmer app: 20 bundled birds instead of 30 (10 EU + 10 NA, 6.4 → 4.3 MB), 2026-10-31
- [x] **German and Spanish** (2026-10-31): `LANGS = en, fr, de, es` in the pipeline; bird names from Wikidata labels / P1843 / GBIF vernacular names, a missing DE/ES name falls back to English (only EN + FR required, no new drops); region, direction and series names hand-written; app: `localName()` lookup, `app_de.arb` / `app_es.arb` (informal du / tú), ordinals, language drop-down, privacy pages DE/ES. Old app versions ignore the new fields (no `v2`)
- [ ] → replaced by the R2 sync in "Infra" — Faster publish: push on top of the online `gh-pages` (only changed files are sent) instead of ~800 MB from scratch
- [ ] **QR-code trading** (after the Nearby barter): phones scan each other's screen 2–3 times (offer, counter-offer, confirmation); works between Android and iPhone, camera permission only, nothing can drop mid-trade; clunkier than the live Nearby window. `qr_flutter` + `mobile_scanner`, same `TradeSession` messages, ~3–4 days
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
