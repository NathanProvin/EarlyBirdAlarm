# Early Bird Alarm â€” Decisions & Rules

## Concept
An alarm clock (Android first, iOS later). Each ring plays a different bird song or call. The user guesses the bird (1 of 4) to dismiss the alarm, then sees the answer.

## Guiding rules (apply to every task)
- **Minimalistic: less is more.** Every screen, setting, and element must earn its place. When in doubt, leave it out.
- **Simple: no overengineering or overcomplication.** Use the smallest solution that works. No abstractions, options, or infrastructure "for later". Use platform and package features before custom code.
- **Iterative design.** Build a PoC first with placeholders (a few bundled birds, placeholder images, a rough UI), and prove the core loop on a real device. Then add content and polish one iteration at a time.

## Product decisions
| Topic | Decision |
|---|---|
| Stack | Flutter. Native Kotlin/Swift only where the alarm core needs it |
| Birds | Local to the user + seasonal (region + current month). Settings toggle "All birds" ignores both |
| Launch area | Europe + North America |
| Audio | xeno-canto, **CC BY / CC BY-SA / CC0** (keeps monetizing possible). Credit shown on the reveal screen. **Exception (decided 2026-10-28):** a species with no free recording at all may use **CC BY-NC / BY-NC-SA** recordings (never ND, since clips are trimmed); they are flagged `nc` in species.json and listed in the report, and **must be replaced or removed before any monetization** (ads count as commercial). Needed mainly for North America, where most xeno-canto recordings are NC |
| Vocalizations | Several recordings per species (decided 2026-10-28): **5** if the bird is common in some region, 3 uncommon, 2 rare, 1 epic/legendary. Kinds rotate **song â†’ call â†’ alarm**; each extra pick needs a new recordist (and country when possible), recorded in Europe/North America first. No chick, imitation, uncertain or aberrant recordings. **Difficulty decides the kinds that ring**: Easy songs, Medium songs + calls, Hard all (a species without a song falls back to its best recording). The reveal shows which kind was heard |
| Delivery | Hybrid: ~30 bundled fallback birds + a static catalog on **GitHub Pages** (public repo `early-bird-content`, `/v1/`; decided 2026-10-28). The phone downloads its region's photos and keeps an **audio deck** of ~14 songs that can ring soon (topped up when the app opens and after each guess; no background job, since the app is opened every morning to answer â€” `workmanager` dropped 2026-10-28). No server |
| Region | Either **GPS** â†’ the 2Â°Ã—2Â° cell around you (computed on the phone), or **pick from a list**: European countries; USA, Canada and Russia split into bioregions (decided 2026-10-28). Rarity is computed per region and **frozen on the card** when it's won |
| Languages | English + French UI and common names; scientific name always shown |
| Wake flow | Volume fades up over ~60s â†’ snooze (same bird) â†’ pick 1 of 4 â†’ success/failure pop-up â†’ reveal (photo, names, Latin name, credits). **No fact text** |
| Gamification | Streak = consecutive correct guesses; a wrong guess resets it; snooze doesn't affect it |
| Difficulty | User setting Easy / Medium / Hard. Decides which rarity tiers can ring (weighted, rarer = less often) and the wrong choices (another order / the same order / the same family) |
| Alarms | Multiple alarms: time, repeat days, on/off, snooze length, label |
| Rotation | New bird per ring, avoiding birds heard recently |
| Collection | Trading-card collection of the birds you identified (see "Card collection") |
| Backup | Android Auto Backup of the preferences file only (cards, heard birds, streak, alarms, settings, region; a few KB) to the user's Google account; the downloaded catalog is re-fetched and alarms are rescheduled at app start (decided and verified on the S22, 2026-10-28). No cross-platform sync |
| Accounts | **Not in v1** (decided 2026-10-28). Required as soon as cards can change hands (trading, market) or the collection must sync across devices/platforms. Then: anonymous-first accounts (local collection uploaded silently), "Sign in with Google/Apple" on demand, **cards minted by the server** (rolls can't be trusted on the phone; earlier cards kept as "pre-season"), market in an in-game currency before any real money (payment, gambling/loot-box and store rules) |
| Business | Free MVP; monetization decided later. No billing, no account, no tracking |
| Privacy | Coarse location only, processed on the device; manual region picker as the alternative |

## Card collection (TCG) â€” decided 2026-10-27
Goal: make the game shareable and give a reason to keep waking up with it ("gotta catch 'em all").
- **Earning:** a **correct guess** adds the bird's card to the collection. A wrong guess leaves a grey "heard" silhouette that a later correct guess turns into the card.
- **Rarity, 5 tiers**, one scale used everywhere (card color, which birds ring, weights). Based on the species' share of GBIF bird records in the cell, in its best month (thresholds tuned from the report):

  | Tier | Color | Ring weight | Can ring at |
  |---|---|---|---|
  | Common | stone `#8C857B` | 16 | Easy, Medium, Hard |
  | Uncommon | fern `#4F8F5B` | 8 | Easy, Medium, Hard |
  | Rare | sky `#3B7DB8` | 4 | Medium, Hard |
  | Epic | plum `#8A4FB0` | 2 | Hard |
  | Legendary | gold `#D9A21B` | 1 | Hard |

  The monthly tier still decides *when* a bird can ring (season); the card shows the species' fixed tier.
- **Stats (4):** Weight (g), Wingspan (cm), Length (cm), Flight distance (km).
  - Sources: weight from AVONET (CC BY 4.0, credited); wingspan and length from Wikidata (CC0), missing values estimated from AVONET wing length and mass by a fit on species that have both; flight distance = distance between the species' January and June GBIF occurrence centroids (â‰ˆ0 for sedentary birds).
  - Each card rolls each stat from a **Gaussian around the species mean** (spread: real AVONET spread where available, otherwise a fixed coefficient of variation per stat), clamped to Â±2Ïƒ. Rolled once when the card is earned; never changes.
  - **Quality %** = average percentile of the 4 rolls. Duplicates are kept (Ã—N); the collection shows the best copy.
- **Card design:** portrait 5:7, flat solid frame in the rarity color (Legendary: thicker frame), photo, name in the app language + Latin, rarity label, 4 stats with a small bar, quality %, number `#042 / 272`. No gradients, no shadows, one radius (Dawn rules still apply). Cards are always printed on paper (ink text), whatever the app theme. The reveal screen *is* the card.
- **Collection tab** (UI rounds 3â€“4, 2026-10-29): views **All** (default, every copy) | **Species** (best copy, rarest first) | **Region** (3 compact columns, "?" for undiscovered); counts inside the view menu ("All (15)", "France (9/353)"); All/Species show the full card scaled down, 2 per row; rarity menu items in their rarity colors; "Series" button top right. Tap â†’ full card, swipe between cards.
- **Bottom bar:** Twitch | **Alarms** (accent circle, the main action, ring when open) | Collection (small, muted until selected), on **frosted glass** over the pages (decided 2026-10-29 after a plain bar and a shaped one were rejected).
- **Twitch mode ("Cocheur", decided 2026-10-29):** a training ground that wins cards like alarms do. Up to 5 boosters, +1 every 10 min (derived from one timestamp; nothing runs in the background), countdown under the pile to the second. The **Twitch Zone** shows the boosters as a floating pile (drag = parallax tilt); **a tap opens one** (the top strip tears off) and starts the quiz: the alarm's 4 photos, the song looping in the app, "Listen again", back allowed (forfeits it). Never touches the wake-up streak. Same bird pick as alarms (season, difficulty, recent birds, songs on the phone).
- **Card reveal (decided 2026-10-29):** after a right answer (alarm or Twitch) the card **flips face up in place** (~0.55 s), then sparkles that **grow with the rarity**: Common a small burst behind the card; Uncommon/Rare + twinkling stars round the edge; Epic + orbiting glints; Legendary + a sheen across the card (1.1 s â†’ 2.5 s in all). No "New card!" title. A wrong answer still shows the blurred "heard" card.
- **Series (decided 2026-10-29):** badges in pages of 2Ã—3 (Collection â†’ Series, small back button bottom right). Kinds: families (rules on order/family/genus), hand-picked themes, Birders' legends (iconic twitcher birds), and game achievements (Legendary hunter, Perfect week, Full set, Collector 100 cards, Local expert 50 region species, Rare finds 5 Rare+ â€” in the app's code). Source `pipeline/series.md` â†’ `series.json` (~9 KB, published with the catalog and bundled as fallback; **no per-bird tagging**, the catalog's taxonomy does the work). A series shows only with â‰¥ 3 birds in the player's region; badge = the signature bird's photo (or the region's first). Completing one (once per region; achievements once) turns the ring foil and gives **+1 bonus Twitch booster**, on top of the 5 and used first, granted silently.
- **Sharing (moved into v1):** a share button turns the card into a PNG for the phone's share sheet (`share_plus`). No account, no server.
- **Not in v1:** trading between players (needs accounts + a server), any paid item. (Free boosters exist since 2026-10-29: they are the Twitch quizzes, never sold.)

## Design â€” "Dawn"
- Flat solid colors only: no gradients, no shadows. One corner radius. Lots of whitespace. One typeface.
- **Exceptions (decided 2026-10-29), for the game's "treasure" objects only:** boosters (foil gradient, shine, grain, crimped seals, a shadow that follows the tilt), completed series badges (foil ring), the Legendary reveal sheen, and the frosted-glass bottom bar (blur).
- Light: bg `#F6F1EA` Â· text `#1C1B1A` Â· accent `#E86A4F` Â· success `#3E8E6A` Â· fail `#C9503C`
- **Themes â€” birds** (decided 2026-10-29, replace Dawn/Dusk/Forest; all WCAG AA checked): **Blackbird** (dark: bg `#1E2124`, text `#ECEAE6`, accent beak orange `#E8A33D`, surface `#2F3337`) Â· **Serin** (dark, renamed from Greenfinch on 2026-10-30: bg mossy green `#33501F` (brighter than the first pine `#243020`, 2026-10-30), text `#F2F6E6`, accent yellow `#F5D83C`, surface `#46672F` â€” dark because yellow can't be text on a light background) Â· **Blue Tit** (light: bg `#EEF3F7`, text `#1D2A36`, accent cobalt `#2F6DB5`, surface `#D5E1EA`) Â· **Gull** (light: bg `#FAF7F0`, text `#1A1A1A`, accent brick red `#B5442E`, surface `#E2E3E0`). Settings â†’ Theme: 5 round swatches, Phone (default: Blue Tit by day, Blackbird in dark mode) | the 4 birds; old saved themes fall back to Phone. Success, fail and rarity colors are the same in every theme; cards are always printed on paper (the Dawn ink/paper/coral tokens).
- App ID `com.nathanprovin.earlybird` (decided 2026-10-28, permanent once on Google Play). Icon: coral half-sun on the horizon with an ink bird perched in front, on paper.
- Coral on paper is about 3:1 contrast, so use it only for large or graphic elements. Body text is always ink.
- Pop-up: a solid circle scales in (moss âœ“ / brick âœ•), with haptics and the streak count ticking up or resetting.

## Tech choices
- Flutter packages: `alarm`, `geolocator` (coarse), `http`, `path_provider`, `shared_preferences`, `flutter_localizations` (ARB en/fr), `just_audio` (card â–¶ and the Twitch quiz song), `share_plus`, `url_launcher`, `permission_handler`. State: built-in `ChangeNotifier`. No package for animations, sensors or app info: boosters, flip and sparkles are plain Flutter (Transform, CustomPainter); the app version comes from a tiny Android channel (`early_bird/version` in MainActivity.kt).
- Testing on the S22: `flutter build apk --profile` (near-release speed, same debug signature as debug builds, so data is kept) and `adb install --no-streaming -r` (streamed installs of the 107 MB APK fail on this USB link). Unit/widget tests in `app/test/widget_test.dart` cover the bird pick, cards, stats formats, Twitch maths, series rules, booster tap, the flip.
- Content pipeline (`pipeline/build.py`, Python stdlib + ffmpeg, run offline): GBIF occurrences per 2Â°Ã—2Â° cell Ã— month (presence + rarity) and GBIF taxonomy (order/family) + Wikidata EN/FR names and photo (GBIF vernacular names as fallback; replaces the IOC spreadsheet, decided 2026-10-27) + Wikimedia Commons photos (CC0/PD/BY/BY-SA; GFDL rejected) + xeno-canto v3 (API key in git-ignored `pipeline/xc_key.txt`; CC0/BY/BY-SA only, quality A/B, 30s clips normalized to âˆ’16 LUFS, AAC 48 kbps .m4a). Your own photos: `pipeline/my_photos/<Latin_name>.jpg` (+ optional `credits.csv`); manual picks: `pipeline/overrides.csv`.
- Each ring gets its bird when scheduled (the `alarm` package needs a local file). If the file is missing, a bundled fallback bird plays, so the alarm always rings.

## Out of scope for v1
Monetization, accounts, fact text, card trading. (The card collection replaces the "life list"; card sharing moved into v1 on 2026-10-27.)
