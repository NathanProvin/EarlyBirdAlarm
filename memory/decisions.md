# Early Bird Alarm — Decisions & Rules

State at **1.1.0+4** (validated by the user 2026-11-13). Current rules first; superseded choices are kept as one-line history at the end. Roadmap: `roadmap.md`. How a card is drafted, in depth: `drafting-design.md`. Store answers: `store-listing.md`.

## Guiding rules (apply to every task)
- **Minimalistic: less is more.** Every screen, setting and element must earn its place. When in doubt, leave it out.
- **Simple: no overengineering.** The smallest solution that works; platform and package features before custom code; nothing "for later".
- **Iterative.** PoC with placeholders first, proven on a real device, then content and polish one step at a time. Every UI change is seen on the S22 and validated by the user.
- **Offline alarms are sacred:** an alarm rings and gives a card with no network. Servers are mirrors, never on the alarm's path.
- **Saved data only grows:** new fields optional with defaults, keys never renamed; a test loads a 1.0.0+3 preferences file (`app/test/upgrade_test.dart`).
- Commit / push only when the user asks. The user's email stays private. The user also uses the S22: read the prefs before and after phone sessions, ask before using boosters or touching the collection.

## Concept and core loop
- An alarm clock (Android first, iOS later). Each ring plays a **real recording of a local bird, in season** (region + current month; "All birds" ignores both). The player guesses the bird (1 of 4 photos; Expert types the name) to stop it.
- **Wake flow:** the song rises from silence to full volume over 60 s (`ringFade`), vibration from 40 s (`ringVibrate`); snooze replays the same bird; the quiz shows over the lock screen (full-screen intent; the onboarding's "Alarm permissions" rows check notifications, full-screen and, on aggressive brands, battery). A backup alarm (rooster at 3 min) covers failures.
- **Right guess** → the card flips face up with sparkles that grow with the rarity. **Wrong guess** → the quiz's 2×2 board stays: tap any photo to hear its bird (from the phone if there, else streamed, never saved), the other photos greyed; **Next** (card icon, arrow and credit line in the accent, outlined in the accent) opens the blurred "heard" card. No time limit. No fact text.
- **Difficulty:** Easy (Common / Uncommon birds, songs), Medium (+ Rare birds, + calls), Hard (all birds, all vocalizations), **Expert** (Hard + typed name: word-start matching in the app's language, English or Latin; blurred photo background; frosted field). Decides card odds, recording kinds and wrong choices (another order / same order / same family).
- **Streak:** consecutive right answers (alarms and Training); snooze neutral; a pill with the theme's animated bird in the header. `alarmStreak` counts alarm answers only (Wake-up streak achievement).
- **Training** (code name `twitch*`): up to 5 boosters, +1 every 15 min (1 min with Early Bird Plus), derived from one timestamp; a tap tears one open and starts the quiz; back forfeits it; never touches alarms.

## Catalog and content
- **1,292 species**, Europe + North America, 2° × 2° GBIF cells named after their country / bioregion + compass part; 20 "coming soon" countries greyed. Region picker = offline world map (Natural Earth): pin + Confirm, red outline of the covered area, search, my position. Cells stay 2° (finer cells: sparse data); the region UI gets reworked later.
- **Licences:** recordings CC0 / BY / BY-SA only (xeno-canto, then iNaturalist research grade; `ALLOW_NC = False` since money is in the app); photos CC0 / PD / BY / BY-SA (Commons, iNaturalist); stats AVONET + Wikidata; group icons PhyloPic CC0 / PDM. Credits on each card (ⓘ) and in Settings → Credits.
- **Vocalizations:** up to 5 recordings per species (song → call → alarm, distinct recordists), ≥ 5 s; difficulty decides the kinds that ring.
- **Rarity per region** from the share of GBIF records in the bird's best month, from eBird checklists when the region-month has ≥ 5,000 eBird records (one survey database no longer makes a rare bird look common). **Bird rarity stars** 0.5–5 (10 levels) on cards, saved on the card when won.
- **Card numbers are permanent** (`pipeline/numbers.json`); new species get the next numbers.
- **Hosting:** catalog on **Cloudflare R2** behind `cdn.earlybirdalarm.app` (own domain: the host can change without an app update); `publish` mirrors changed files with rclone. 1.0.0+3 phones still read the frozen `gh-pages`. `series.json` refreshed daily, the rest weekly.
- **Languages:** EN, FR, DE, ES (`LANGS` in the pipeline, `app_<lang>.arb`); French "vous", German "du", Spanish "tú"; a missing DE / ES bird name falls back to English. 20 bundled offline birds (10 EU + 10 NA, never NC).

## Drafting: the pile, the odds, the photos
Details and reasoning: `drafting-design.md`.
- **The pile:** 14 fresh songs; each ring draws the **top** card, the freed slot gets a bird drawn by rarity weight (16 / 9 / 6 / 3 / 2 from Common to Legendary, limited by difficulty), put **under** the pile. Each scheduled alarm holds its own card; pile cards are never cleaned up; a played song rests for the last 200 plays (or half the playable songs if fewer). Each pile card's quiz (4 choices) is prepared when it joins.
- **Card rarity** (on a right answer): exponential decay per difficulty (`rarityScale` in `birds.dart`), leaning toward the bird's own tier; a species already owned as Legendary has half the Legendary odds. Fitted to **16 cards a day** (1 alarm + 3 Training sessions): Hard an Epic every ~3 days and a Legendary every ~2 weeks; Expert ~2 days / ~1 week; Medium ~1 week / ~3–4 months; Easy ~5 months / ~13 months. Odds differ by region (kept). **Drop rates kept as they are** (2026-11-12); achievement tier cards come on top.
- **Shiny:** 6th tier above Legendary, card only, **1 / 1250** per card of a species with a hand-picked aberrant photo (172 photos, 171 species, `pipeline/shiny.csv`). Two looks (`ui/shiny.dart`): leucistic = diamond / ivory, melanistic = obsidian with magma veins; 4.2 s firework reveal.
- **Stats:** weight, wingspan, length, flight distance, rolled once around the species mean with a fat upward tail; quality % = average percentile. Duplicates kept.
- **Photos:** each card gets one of the bird's photos (catalog or up to 5 Commons Quality / Featured / Valued variants) at random, picked at the draw, fetched during the quiz, kept for good; syncs delete photos neither in the region's catalog nor owned. All photos within 1200 × 900 at high quality. On mobile data no bulk region download.
- **Big collections:** cards decoded once and kept in memory (10,000 cards: draw 1.8 ms, answer bookkeeping ~0.8 s). Next step if needed: cards in their own file.

## Cards and collection
- **Card design:** portrait 5:7, frame in the rarity's material (cardboard, leather, metal, foil, gold; Shiny diamond / obsidian), textured card stock per rarity, photo, name + Latin, bird rarity stars, 4 stat bars, number `#042`, rarity label centred in the header with the quality % at the right edge, the won recording's play button printed in the frame's material. Cards are always paper / ink whatever the theme (obsidian for melanistic Shiny).
- **Bird group icon** (2026-11-13): top left of the photo, a 40 dp glass circle tinted with the rarity colour (35 %), white silhouette. 113 families in **29 groups** (`familyGroups` in `ui/family_icon.dart`); silhouettes from **PhyloPic, public domain only**, picked for distinctness, mirrored to face left, parrot and kingfisher cropped to the head (`pipeline/family_icons.py` → `family_paths.dart`; Merlin's icons are Cornell's and were not used). A test fails if a catalog family has no group: add AU / NZ families in 1.2.
- **Full-screen cards** tilt toward a held finger (and the gyroscope, Settings switch); Epic and up are glossy; Wikipedia (in the app's language), Share (PNG + Play link), Info.
- **Collection:** opens on **Collected, sorted by rarity** (2026-11-13); views: Collected, Species (best copy, piles for duplicates), the current region, other regions won in, World; sort number / rarity / name; rarity filter; search (any language, accents ignored). Heard birds: blurred tile with a glass play button.
- **Achievements and series** (screen: Achievements | Series segmented switch, accent / ink thumb): **18 achievements × 5 tiers** (I–V; tier n gives a card of the n-th rarity; goals in `achievementGoals`, `series.dart`) on 3 pages + a "To be added" page. Series: families, habitats, **Voices** (Virtuosos, Mimics, Night voices, Dawn chorus, Long flight, Pelagic), themes, Birders' legends; shown with ≥ 3 birds in the region; completing one gives a card of its guaranteed rarity, collected with a tap on the glowing badge. Source `pipeline/series.md`.

## Accounts, profile and friends (1.1)
- **Firebase** project `earlybird-alarm` (Spark, free plan, no Cloud Functions → no push notifications): Auth (anonymous at first launch, never awaited; Google or email + password, link keeps the uid, an existing account merges both collections) and Firestore (`europe-west1`), security rules only (`app/firestore.rules`, live check `py -I app/firestore_rules_check.py`, which must print "rules ok"). Rules must be query-provable (`||` of comparisons, not `in`), and reads by id where a missing document must be readable.
- **API key** restricted to the Android app: package + 4 SHA-1 (upload, 2 Play signing, debug). A missing fingerprint shows as "Something went wrong" on Firestore calls.
- **Backup:** the collection only (cards, given, heard, series, streaks, bonus boosters, profile cache); `players/{uid}` + cards in chunks of 1,000 (`players/{uid}/cards/{n}`); batched writes (≤ every 5 min, and when the app goes to the background). Alarms and settings: Android Auto Backup. Delete account in the app and at `cdn.earlybirdalarm.app/delete-account.html`; the cards stay on the phone.
- **Profile** (the Account page, person icon in the headers): avatar cropped round from one of the player's cards, unique **@name** (automatic bird name + 4 digits, 3–20 letters / digits / `_`, renamed once a week, banned-words list in `names.dart`), email small, hall of fame of 3 cards (fan), stats, Friends, Bonus codes, Account management (sign-in, forgot password, delete) kept whole.
- **Friends:** add by @name → request → accept (`friendRequests/{to}_{from}`, `friends/{uid}/list/{friend}`); first 3 shown + See all; a friend's profile: Trade, Challenge "coming soon", Remove, Block, Report (mailto). `profiles/{uid}` holds only the name and catalog content.
- **Codes:** word codes, case-insensitive, once per account (create-only `redemptions/{uid}_{CODE}`), made in the console. **`OGBetaTester`** until 2026-12-31: 1 Shiny from the region, else a Legendary.
- **Referrals:** a share message whose Play link carries the inviter's uid (`&referrer=`, read by the Play Install Referrer at first launch); the friend writes `referrals/{friendUid}` at install and gets a **welcome card** (Rare 50 / Epic 40 / Legendary 10 %) after the onboarding; the inviter sees "N friends joined" and the Influencer achievement.
- **Remote trades** (2026-11-13; replaced face-to-face trading, tag `face-to-face-trade`): between friends only, iPhone ↔ Android. One trade per pair (`trades/{a}_{b}`, uids sorted). Ways in: the Collection's ⇄ (friend picker) and Trade on a friend's profile. Each side offers ≤ 10 cards (**both must offer**), agrees to the hash of both offers; a change invalidates; once both agreed the same hash the offers freeze and each phone applies the swap once (`tradesApplied`), the last deletes the trade. Cancel before; **7-day expiry**; offered cards locked out of other trades; a dot on the profile icon when a trade waits. Received cards pass `checkCard`. Trade screen text cut to the minimum: Give / Receive / Agree / Waiting validation.
- **Trust:** cards are still rolled on the phone. Before any marketplace: server-signed pre-rolled cards (Blaze + Cloud Functions), older cards "pre-season".

## Money
- **Everything through Google Play Billing** (`in_app_purchase`): tips `tip_espresso` 0.99, `tip_cappuccino` 1.99, `tip_breakfast` 4.99, `tip_binoculars` 19.99 € (pure thanks) and **Early Bird Plus** (`twitch_plus`, 1.99 € once: a booster every minute). Prices always from Play. Trusted on the device (restored at launch).
- **Nothing random is ever sold** (no loot boxes). Support visibility: a card at the top of Settings, one line on the reveal from 30 cards, Google's in-app review once from 15 cards.

## Design — "Dawn"
- Flat solid colours, one corner radius, one typeface, lots of space. Exceptions for the game's treasures only: boosters (foil), badges, reveals, shiny looks, frosted-glass bars and badges.
- **Themes = birds:** Blackbird (dark, accent `#E8A33D`), Serin (dark green, yellow accent), Blue Tit (light, cobalt), Gull (light, brick red); Phone = Blue Tit by day, Blackbird at night. Rarity colours: Common stone `#8C857B`, Uncommon fern `#4F8F5B`, Rare sky `#3B7DB8`, Epic plum `#8A4FB0`, Legendary gold `#D9A21B`, Shiny diamond / obsidian.
- Bottom bar: Training | **Alarms** (accent circle) | Collection, on frosted glass. Buttons clear of the 3-button navigation bar; 48 dp touch targets (`a11y_test.dart`). No sound effects (tried, removed).
- App ID `com.nathanprovin.earlybird`; store title "Early Bird: Bird Song Alarm", launcher "Early Bird".

## Tech
- Flutter; native Kotlin only where needed (`MainActivity.kt` channels: version, network metered, referrer). State: `ChangeNotifier` (`store`). Packages: `alarm`, `just_audio`, `geolocator` (coarse), `shared_preferences`, `share_plus`, `url_launcher`, `permission_handler`, `in_app_purchase`, `in_app_review`, Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`), `installreferrer` (Gradle). No package for animations or SVG: plain Flutter painters.
- Developer tools only with `--dart-define=DEV_TOOLS=true` (reveal previews, 1000-card draw, 1-min Training); every normal build has none (tested).
- Tools in `.tools/` (Flutter, JDK, Android SDK, ffmpeg, gh): put `.tools/flutter/bin` and `.tools/android-sdk/platform-tools` on PATH, `PUB_CACHE=.tools/pub-cache`, `JAVA_HOME=.tools/jdk`. Python: `py`. Gradle heap capped at 3 GB.
- Pipeline (`pipeline/build.py`, Python stdlib + ffmpeg, offline): GBIF + eBird presence and rarity, GBIF taxonomy, Wikidata names, Commons photos, xeno-canto / iNaturalist recordings (−16 LUFS, AAC 48 kbps), AVONET stats, series, publish to R2.

## History (superseded, for context)
- 2026-10-27 → 31: the TCG design, 5 tiers then exponential odds with a lean toward the bird's tier; card stock, 3D cards, Twitch Zone (renamed Training 2026-11-10); themes from Dawn / Dusk / Forest to birds; world-map region picker; DE / ES.
- 2026-10-31 → 11-13: **face-to-face trading** over Google Nearby (Bluetooth, precise location; Android only) — removed for remote trades; QR trading dropped with it.
- 2026-11-03: the NC-free catalog (1,713 → 1,292 species) so that tips are possible; eBird rarity; permanent numbers.
- 2026-11-10: tester feedback round (Training, gentler ring, region picker, Collection views); scaling plan (domain → R2 → Firebase).
- 2026-11-11: accounts and backup, Shiny, variants, odds fitted to play time, the pile, photos downloaded once, phases A–D (`drafting-design.md`).
- 2026-11-12: codes and referrals (referral = link, no code), achievements rework, song comparison after a wrong guess, API key restriction.
- 2026-11-13: profile page, remote trades, trade texts cut, card header fix, Collection default, bird group icons, 1.1.0 validated.
