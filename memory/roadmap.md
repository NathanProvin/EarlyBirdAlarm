# Early Bird Alarm — Roadmap

Iterative: each step ends with something that runs on a real Android device and is validated by the user. Rules and choices: `decisions.md`. Store answers: `store-listing.md`.

## Status — 2026-11-27
- **1.4.0 planned** (production polish, see Phase 1.4.0): crafting balance and mode, filter sheet, photo sharing, Pouillots, ranking rework, Lure. Challenges stay in Later.

## Status — 2026-11-24
- **1.3.0+8 uploaded to the closed track** (crafting, points, monthly ranking, achievements rework); see Phase 1.3.0 below. The lines under this one are the 2026-11-13 status, kept for history.
- **Live:** 1.0.0+3 in **closed testing** on Google Play (14 active installs; reads the frozen GitHub Pages catalog).
- **1.1.0+4 validated by the user on the S22 (2026-11-13)**, pushed to GitHub (`main`), signed bundle built: `app/build/app/outputs/bundle/release/app-release.aab`. Next: upload to the closed track (tutorial given 2026-11-13), then Production.
- **1.1 contents:** cloud backup + accounts (anonymous, Google, email), profile (@name, avatar, hall of fame, stats), friends, invite links + welcome card, bonus codes (`OGBetaTester`), **remote trades** (face-to-face trading removed), card variants + Shiny, achievements in 5 tiers + Voices series, song comparison after a wrong guess, bird group icons, catalog on R2 (1,292 species), lock-screen fix and tester feedback (1.0.1, never shipped alone).
- **Order:** 1.1.0 closed test → Production → **1.2 Australia / NZ, North Africa / Middle East, Mexico / Central America + heatmap** → later (iOS, marketplace, region UI, more of the globe).

## Release 1.1.0 → Production
Updates during the closed test don't reset its clock. Testers' emails stay in the Play Console, never in the repo.
- [x] Version **1.1.0+4**, signed release bundle (no DEV_TOOLS), README rewritten (2026-11-13)
- [x] **User:** banned-words review in `app/lib/names.dart` (`bannedNames`)
- [x] Upload to **internal testing** first, install from Play: Google sign-in (Play signing SHA-1), invite link → referrer → welcome card, a test purchase (license tester set), in-app review prompt (checked by the user on the S22, 2026-11-13; the S22 now runs the Play build, so a debug `adb install -r` fails on the signature until it's uninstalled)
- [ ] Then the same bundle to the **closed testing** track, release notes in 4 languages
- [ ] Play Console: store listing (trading bullet changed: "Trade cards with your friends, wherever they are", 4 languages, `store-listing.md`); Data safety for accounts + data deletion URL `https://cdn.earlybirdalarm.app/delete-account.html` (done 2026-11-13 per the user, check); Bluetooth / precise-location declarations gone; **full-screen intent** declaration (alarm clock, done per the user 2026-11-24); product `twitch_plus` titled "Early Bird Plus"
- [ ] Upgrade check: a real S22 1.0.0+3 prefs export in `upgrade_test.dart` (needs the user's OK for adb); the user's collection exported before switching the S22 to the Play build (different signature = another app; the cloud backup now covers it after a Google sign-in)
- [x] Alarm video for the media-playback foreground-service declaration (S22, locked, rings, guess; unlisted YouTube)
- [x] S22: the backup alarm (rooster at 3 min, rings with the app killed): done and checked (user, 2026-11-24)
- [ ] A tester's Android 14+ phone: lock-screen quiz and the onboarding's Fix buttons
- [ ] **14 consecutive days with ≥ 12 opted-in testers**, then **Apply for production**; staged rollout 20 % → 100 %
- [ ] README: drop "in closed testing" once public; `svc power stayon usb` off on the S22

## Phase 1.2 — Australia / NZ, North Africa / Middle East, Mexico / Central America + heatmap
- [x] Free-recording sweeps: AU / NZ (`sweep_oc.md`), the four new zones (`sweep_mena_mxca.md`: common + uncommon 91–96 % covered; ~500 new species from Mexico / Central America, ~100 from North Africa / Middle East)
- [x] Pipeline: English-only names, GBIF + Commons sounds, iNaturalist variant photos with a reject list, synonym names, frozen ids (seeded from 1.1), 2 spare clips, faststart clips, `cells_species.json`
- [x] Zones: AU bioregions + NZ, country lists + wide cell boxes for the new zones; continents fixed and `oc` in the app
- [x] Group icons for the new families (ratite, penguin + mappings); series for the new regions
- [x] Missing-species heatmap (Plus) on the region map; the map opens on the phone's continent
- [x] **Full build** (finished: the published catalog has 2,630 species, AVONET habitat / diet on ~2,520, variants on 2,468, no Latin-only English names; checked 2026-11-24). Left, optional, by a quick rebuild: → family-icon test on the real catalog, empty series pruned, Latin-only English names into `names.csv`
- [ ] Optional: `variants.py` → photo review into `photo_rejects.csv` → quick rebuild (it also writes AVONET `habitat` / `diet` into `species.json`: the running build predates them)
- [x] Card badges at the photo's bottom left: group, habitat, diet (AVONET), glass cartridges, a tap slides out "Family · Turdidae" for 3 s
- [x] Expert mistake replay: answer and pick stacked (one per row); haptic tick on the 3 main tabs; Expert pool checked (every tier, as Hard)
- [x] **Art n/6** (user, 2026-11-17; built, hidden for a single photo or a Shiny): "*Art x/n*", x = the card's photo number, n = the species' photo count (catalog + variants); italic, the stat names' font size; top right of the photo, a rounded glass cartridge like the group badge. Duplicates then count by bird + rarity + art; a species page shows "arts found". Check first that a saved card records its photo (older cards: catalog photo = Art 1)
- [x] Collection pass (user, 2026-11-17): Duplicates view (species owned more than once; count = spare cards), Newest and Quality % sorts, a fuller pile (3 rarity-tinted cards), a pile opens into its copies (top card flies, the others are dealt out), no ×N above a full card, grid ×N 20 % smaller with a black outline. Rejected: group / habitat / diet filters, Shiny / new toggles, region won in
- [x] Switch account on the account page (collection saved to the account and required online, then the phone emptied). Trade: full cards with names, a Collected / Duplicates switch for my cards and the friend's, offers open whole on tap
- [x] `firestore.rules` deployed 2026-11-17: friends read each other's card chunks (user OK)
- [x] Phone check with a dev build: Melbourne cell, 1,000 drawn cards, badges, heatmap (validated by the user, 2026-11-20)
- [x] README (1.2 rewrite, new screenshots), store listing and "What's new" (4 languages, 2,630 species, new areas), version **1.2.0+6** (+5 was already used on Play), signed bundle built (2026-11-21). Catalog **published to R2 before 1.2 is live** (user, 2026-11-20): 1.1 reads it fine (same formats and region kinds; strict cell-id parsing; no icon for a new family; an Oceania player's offline fallback is the European birds). R2 uploads now copy and never delete (old cards may point at dropped clips / photos). **New logo** (user, marketing, 2026-11-20): `pipeline/logo.png` → every icon and store image via `store_assets.py` (scaled to Android's 66 dp safe circle), boosters / card backs, a faint blurred logo behind the Alarm list; bundle rebuilt. **The user's own photos** as extra variants (`py build.py myphotos`, first: Stonechat). Next: publish the catalog (the photo), upload the bundle to the closed track with the new icon and feature graphic; the catalog fixes (Latin-only names, out-of-area trim) at the next rebuild

## Phase 1.3.0 — crafting, points, monthly ranking (2026-11-23; named 1.2.1 until 2026-11-24)
All in `main` (pushed: 02a8ee3, 1866473, c1bd81a, fd6b716, ac7d56c, 2b01f8f); details in decisions.md (Crafting, Points, Monthly world ranking, UI pass, Smooth scrolling).
- [x] Crafting (Plus): hammer + Forge pill in the Collection, same species only, recipes in pictures, forge animation
- [x] Points (rarity 1 / 5 / 20 / 60 / 150 / 300, +25 % quality, +25 % arts) on the profile; monthly world ranking (bar chart, top 10 + own row, reward card on the 1st by top percentile)
- [x] Firestore rules for `ranks/{yyyymm}/players/{uid}` **deployed** 2026-11-23 (user OK); `firestore_rules_check.py` covers them (8 cases, "rules ok")
- [x] Profile reworked (avatar 150 dp + @name, 3 stacked count pills + email, score 2/3 + rank 1/3); map: radar above Confirm, search smaller above it
- [x] Smoother scrolling (no live blurs, photos decoded at shown size, profile built once): validated by the user on the S22 ("much smoother")
- [x] Release APK 1.2.1+7 on the S22 (fresh install 2026-11-23: the old 1.2.0 sideload was gone; the user signs in with Google to get the collection back)
- [x] **UI pass 2026-11-24** (pushed: fd6b716, ac7d56c): own profile in a friend's layout with "#12 ›" inside the Points tile (validated); crafting from opened piles in Species and Duplicates, the forge pill kept (full width) on the pile; forge animation centred and bigger; forge gauge (slots filling, "2/3", result popping in); unpaid pill "Combine cards" and the new Plus pitch; `HIDE_PLUS` build flag; unpaid layouts checked by the user
- [x] **Achievements rework + diet / habitat series + Series pages packed 6 per page + ranking reminder ~2 days before month end** (2b01f8f, installed on the S22 2026-11-24)
- [x] Version **1.3.0+8** (user: major features), release notes in 4 languages (`store-listing.md`), 2026-11-24
- [x] Signed bundle 1.3.0+8 → closed track (built and uploaded 2026-11-24)
- [x] Forge with real spares, from opened piles too (user, S22, 2026-11-24)
- [x] Long German / Spanish names (user OK, 2026-11-24)
- [ ] Checks on the S22: large font size, the 1st-of-month reward (kept open, user 2026-11-24) (December 1st: first real claim), ranking with several players: on 2026-11-24 the user saw only themselves, expected (only 1.2.1+ writes rows and 1.2.1 never reached Play; a row also needs an @name, the cloud on and a card won this UTC month): **wait for testers on 1.3.0**, check `ranks/202611/players` in the Firebase console if still alone
- [ ] Open questions: the recipes panel doesn't say "same species" (rainbow card = any rarity); players without an @name never appear in the ranking (ask for one on opening it, or an anonymous label? undecided); ranking scores are self-reported (cheatable until server-signed cards); unclaimed-achievement progress can drop when crafting uses cards

## Phase 1.4.0 — production polish (planned 2026-11-27)
The production release: no risky features. Order below = build order, one release APK on the S22 per step, validated by the user; decisions.md updated as each step is built.
- [x] **Crafting balance:** 3 Common → Uncommon (`craftCost`, `cards.dart`); the booster recipe is now **only 2 Commons of one species → 2 boosters** (any other pair refused, the Legendary goal-2 fallback gone); recipe panel, "+2 boosters" text (4 languages), `craft_test.dart`
- [x] **Crafting mode:** the hammer switches the Collection to **Duplicates** (the previous view comes back on leaving); while active the header view pill becomes an accent-filled "🔨 Forge" pill and a slow accent glow pulses along the screen edges (a painter, no blur)
- [x] **Filter & sort sheet:** dropdown kept; section titles bold in the accent with an icon (👁 View, ⇅ Sort, ★ Rarity), thin dividers; the View dropdown in a filled box with a 2 px accent outline, bigger text, the view's icon
- [x] **Settings → "Share your bird photos"** (subtitle "or send feedback to the developer"), after Theme: a mailto to the contact address with a template (bird, place, date, "I took these photos and allow Early Bird to use them under CC BY 4.0, credited as: ___"); photos attached in the mail app; added like `my_photos` (credited to the sender); 4 languages
- [x] **Pouillots series = whole family** (`family: Phylloscopidae` in `series.md`: 20 catalog species, adds Chiffchaff, Willow, Wood and Canary Islands Chiffchaff; griseolus / maculipennis were not in the catalog); `series.json` rebuilt and published (copy), no app release needed
- [x] **Ranking rework** (`ranking.dart`, `ui/ranking.dart`, rules):
  - Month | All-time switch at the top centre (the Achievements | Series switch, made public), "NOV" (localized short month) by default
  - All-time board: `ranks/all/players/{uid}` = all collection points, written with the month row; no rewards; rules block for `all` (higher cap), checker cases, deleted with the account. **Rules deploy needs the user's OK**
  - Rows: rank, round avatar (added to the row doc, rules `hasOnly` + `avatar`), bar with the @name and points inside (minimum width), reward card icon at the right (month board); top 10 + own row as 11th with its real rank
  - Month rewards by rank: #1 Legendary, #2 Epic, #3 Rare, #4–5 Uncommon, #6–10 Common, **nothing below #10 for now** (percentiles again with more players); collected on the 1st through a popup ("You finished #3 in November!") then the reward card
- [x] **Lure (FR "Repasse")**, Plus only, 3 a day: icon at the bottom left of the Training tab (unpaid → Plus sheet); a search of the species that can be drafted now (region, season, difficulty); the bird's call plays, popup "You played the Blackbird's call. Will it answer?"; the **next card from any source** (Training or alarm) has 50 % chance of being that bird; a miss uses the call up; no network → a normal draw
- [x] **User (console):** code `ami2nathan` → reward `legendary` (codes live in Firestore `codes/{word}`, not in the app)
- [x] **Performance pass** (2026-11-27): grid tiles and forge without live blurs, 35 → 5 ms GPU frames (decisions.md, Smooth scrolling)
- [ ] User review on the S22 (crafting validated; ranking and Lure fixes of 2026-11-27 installed); the two noisy recordings to remove (reject list)
- [x] Version 1.4.0+9, release notes in 4 languages (`store-listing.md`), signed bundle built (2026-11-27)
- [ ] Upload the bundle to the closed track, then production

## Later
- **Challenges between friends** (brainstormed 2026-11-27, not green-lit): async 5-bird duel on a `challenges/{a}_{b}` doc (trade pattern), or a real-time 3-lives duel with wagered cards held in escrow in the duel doc (removed from both collections at the start, so a loser going offline can't keep them; leaving = loss); cheatable while cards are rolled on the phone.
- [x] **Achievements balance** (user, 2026-11-24): done the same day, see decisions.md "Achievements and series".
- **Region UI:** rework the picker, names and collection views (the 2° grid stays).
- **iOS:** AlarmKit (iOS 26+; check custom sounds), Sign in with Apple, StoreKit products; remote trades and backup already cross-platform. $99 / year, cloud Mac builds, a real iPhone.
- **Marketplace** (~1,000+ daily players): server-signed pre-rolled cards (Blaze + Cloud Functions); first a bank (sell duplicates, buy a chosen card), then player listings with a fee; the currency never bought with or turned into money.
- **Duplicates worth something** (ideas 2026-11-22; a crafting variant of (2) + 2 cards → booster built 2026-11-23 for 1.2.1, see decisions.md "Crafting"): (1) a spare card for boosters now (Common 1 … Legendary 5; reuses twitchBonus; recommended first), (2) 5 copies of a rarity combine into 1 card of the next (no Shiny), (3) feed a copy to reroll the best copy's stats, keeping the better, (4) feathers from duplicates buy a heard-but-missed bird (local step toward the Marketplace bank; recommended second), (5) Art sets: all of a species' photos, (6) one-way gifts to friends. Not more than two of 2-4 at once (too many exchange systems); all local, so cheatable until server-side.
- **More of the globe** (each: free-recording sweep, zone, offline birds, languages): South Africa, Japan, India, Brazil.

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
