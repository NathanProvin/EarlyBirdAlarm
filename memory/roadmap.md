# Early Bird Alarm — Roadmap

Iterative: each step ends with something that runs on a real Android device and is validated by the user. Rules and choices: `decisions.md`. Store answers: `store-listing.md`.

## Status — 2026-11-13
- **Live:** 1.0.0+3 in **closed testing** on Google Play (14 active installs; reads the frozen GitHub Pages catalog).
- **1.1.0+4 validated by the user on the S22 (2026-11-13)**, pushed to GitHub (`main`), signed bundle built: `app/build/app/outputs/bundle/release/app-release.aab`. Next: upload to the closed track (tutorial given 2026-11-13), then Production.
- **1.1 contents:** cloud backup + accounts (anonymous, Google, email), profile (@name, avatar, hall of fame, stats), friends, invite links + welcome card, bonus codes (`OGBetaTester`), **remote trades** (face-to-face trading removed), card variants + Shiny, achievements in 5 tiers + Voices series, song comparison after a wrong guess, bird group icons, catalog on R2 (1,292 species), lock-screen fix and tester feedback (1.0.1, never shipped alone).
- **Order:** 1.1.0 closed test → Production → **1.2 Australia / NZ + heatmap** → later (iOS, marketplace, region UI, more of the globe).

## Release 1.1.0 → Production
Updates during the closed test don't reset its clock. Testers' emails stay in the Play Console, never in the repo.
- [x] Version **1.1.0+4**, signed release bundle (no DEV_TOOLS), README rewritten (2026-11-13)
- [ ] **User:** banned-words review in `app/lib/names.dart` (`bannedNames`)
- [ ] Upload to **internal testing** first, install from Play: Google sign-in (Play signing SHA-1), invite link → referrer → welcome card, a test purchase (license tester set), in-app review prompt
- [ ] Then the same bundle to the **closed testing** track, release notes in 4 languages
- [ ] Play Console: store listing (trading bullet changed: "Trade cards with your friends, wherever they are", 4 languages, `store-listing.md`); Data safety for accounts + data deletion URL `https://cdn.earlybirdalarm.app/delete-account.html` (done 2026-11-13 per the user, check); Bluetooth / precise-location declarations gone; **full-screen intent** declaration (alarm clock); product `twitch_plus` titled "Early Bird Plus"
- [ ] Upgrade check: a real S22 1.0.0+3 prefs export in `upgrade_test.dart` (needs the user's OK for adb); the user's collection exported before switching the S22 to the Play build (different signature = another app; the cloud backup now covers it after a Google sign-in)
- [ ] Alarm video for the media-playback foreground-service declaration (S22, locked, rings, guess; unlisted YouTube)
- [ ] S22: the backup alarm (rooster at 3 min, rings with the app killed); a tester's Android 14+ phone: lock-screen quiz and the onboarding's Fix buttons
- [ ] **14 consecutive days with ≥ 12 opted-in testers**, then **Apply for production**; staged rollout 20 % → 100 %
- [ ] README: drop "in closed testing" once public; `svc power stayon usb` off on the S22

## Phase 1.2 — Australia and New Zealand
- [ ] Free-recording sweep on AU / NZ species (xeno-canto free + iNaturalist) before committing
- [ ] Zone in `CELL_AREAS` (same 2° cells, southern seasons need nothing), region names, `PLANNED` update; offline birds for an "oc" continent
- [ ] **Bird group icons for the new families** (the family test fails until each has a group; new groups via `pipeline/family_icons.py`); a "Flightless" series (emu, kiwi, penguins)
- [ ] Overnight build, publish, phone check; store listing mentions Australia / NZ
- [ ] **Missing-species heatmap** (tester request): a toggle on the region picker tints each cell by the species not collected yet; one pipeline file of each cell's species as card numbers (~0.1 MB gzip); tap a cell → "42 species missing here"
- [ ] Catalog clips with `-movflags +faststart` (streaming starts one request sooner) at this full build

## Later
- **Challenges between friends** (the "coming soon" button on a friend's profile).
- **Region UI:** rework the picker, names and collection views (the 2° grid stays).
- **iOS:** AlarmKit (iOS 26+; check custom sounds), Sign in with Apple, StoreKit products; remote trades and backup already cross-platform. $99 / year, cloud Mac builds, a real iPhone.
- **Marketplace** (~1,000+ daily players): server-signed pre-rolled cards (Blaze + Cloud Functions); first a bank (sell duplicates, buy a chosen card), then player listings with a fee; the currency never bought with or turned into money.
- **More of the globe** (each: free-recording sweep, zone, offline birds, languages): Mexico + Central America, South Africa, Japan, India, Brazil.

## Backlog
- [ ] Optional: the app picks up a moderated (removed) @name
- [ ] Cards of species dropped from the catalog are hidden: show them "retired" instead
- [ ] `species.json` re-fetched only when changed (ETag)
- [ ] TalkBack + maximum font size pass on the phone (alarm quiz included); app icon and notification icon check
- [ ] Hand-pick widespread dropped species in `pipeline/overrides.csv`; `series.md` names against the catalog
- [ ] Very big collections (10,000 cards ≈ 0.8 s per answer): cards in their own file
- [ ] Open checks from 2026-11-11: an alarm on mobile data with a Shiny-capable bird, the 5-minute backup timer, Medium / Expert drop simulations, a unit test for the pile
- [ ] Play Store polish: localized screenshots, a promo video
- **Working notes:** read the S22's prefs before and after each phone session (`adb shell run-as com.nathanprovin.earlybird cat shared_prefs/FlutterSharedPreferences.xml`) and restore them after tests that change the collection; throwaway Firebase test accounts are driven from the PC (scratchpad scripts) and deleted after. Screen recordings + `.tools/ffmpeg` contact sheets check animations.

---
# History — done
- **0–2 (2026-10-27):** Flutter project, the `alarm` package ringing locked / killed on the S22, multiple alarms, fade-in, snooze, streak, EN / FR.
- **3a–3c (2026-10-27 → 30):** the pipeline (GBIF, Wikidata, Commons, xeno-canto, AVONET), the card collection (rarities, stats, reveal, sharing), 2° regions + bioregions, the catalog on GitHub Pages, bundled offline birds.
- **4a (2026-10-28 → 11-01):** package name, signing, themes (birds), Twitch Zone boosters, card flip and sparkles, series, frosted bottom bar, world-map picker, DE / ES, deck rotation fixes, odds as exponential decay, onboarding, accessibility tests, reviewer polish (rarity stars, Expert, Wikipedia), README, first signed bundle, 7-night reliability test passed.
- **4b (2026-11-01 → 10):** Play developer account, internal then closed testing of 1.0.0+3 (14 installs), payments profile + 5 products.
- **Tips branch (2026-11-03 → 04):** NC-free catalog (iNaturalist fallback), tips and Twitch Plus, eBird rarity, permanent card numbers, gyroscope tilt, shared cards carry the Play link.
- **1.0.1 (2026-11-10):** lock-screen quiz fix, alarm permissions on the onboarding, gentler ring, tester feedback (Training, Collection views, region picker).
- **Infra (2026-11-10 → 12):** domain `earlybirdalarm.app`, catalog on Cloudflare R2, Firebase project, rules, anonymous sign-in, API key restriction, privacy and delete-account pages.
- **1.1 (2026-11-11 → 13):** backup and accounts; variants and Shiny; odds fitted to play time, the pile, photos downloaded once, phases A–D; codes and referrals; achievements and series rework; song comparison after a wrong guess; profile page and friends; remote trades (face-to-face removed, tag `face-to-face-trade`); trade texts, card header fix, Collection default, bird group icons; validated 2026-11-13.
