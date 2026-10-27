# Early Bird Alarm — Decisions & Rules

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
| Audio | xeno-canto, **CC BY / CC BY-SA / CC0 only** (keeps monetizing possible). Credit shown on the reveal screen |
| Delivery | Hybrid: ~30 bundled fallback birds + a static CDN catalog; the next 7 days' birds are prefetched. No server |
| Languages | English + French UI and common names; scientific name always shown |
| Wake flow | Volume fades up over ~60s → snooze (same bird) → pick 1 of 4 → success/failure pop-up → reveal (photo, names, Latin name, credits). **No fact text** |
| Gamification | Streak = consecutive correct guesses; a wrong guess resets it; snooze doesn't affect it |
| Difficulty | User setting Easy / Medium / Hard. Decides which rarity tiers can ring (weighted, rarer = less often) and the wrong choices (another order / the same order / the same family) |
| Alarms | Multiple alarms: time, repeat days, on/off, snooze length, label |
| Rotation | New bird per ring, avoiding birds heard recently |
| Collection | Trading-card collection of the birds you identified (see "Card collection") |
| Business | Free MVP; monetization decided later. No billing, no account, no tracking |
| Privacy | Coarse location only, processed on the device; manual region picker as the alternative |

## Card collection (TCG) — decided 2026-10-27
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
  - Sources: weight from AVONET (CC BY 4.0, credited); wingspan and length from Wikidata (CC0), missing values estimated from AVONET wing length and mass by a fit on species that have both; flight distance = distance between the species' January and June GBIF occurrence centroids (≈0 for sedentary birds).
  - Each card rolls each stat from a **Gaussian around the species mean** (spread: real AVONET spread where available, otherwise a fixed coefficient of variation per stat), clamped to ±2σ. Rolled once when the card is earned; never changes.
  - **Quality %** = average percentile of the 4 rolls. Duplicates are kept (×N); the collection shows the best copy.
- **Card design:** portrait 5:7, flat solid frame in the rarity color (Legendary: thicker frame), photo, name in the app language + Latin, rarity label, 4 stats with a small bar, quality %, number `#042 / 272`. No gradients, no shadows, one radius (Dawn rules still apply). The reveal screen *is* the card.
- **Collection tab:** bottom bar Alarms | Collection. 3-column grid sorted by number, progress "42 / 272", rarity filter chips, undiscovered birds of the region as "?" placeholders, tap → full card, swipe between cards.
- **Sharing (moved into v1):** a share button turns the card into a PNG for the phone's share sheet (`share_plus`). No account, no server.
- **Not in v1:** trading between players (needs accounts + a server), packs, any paid item.

## Design — "Dawn"
- Flat solid colors only: no gradients, no shadows. One corner radius. Lots of whitespace. One typeface.
- Light: bg `#F6F1EA` · text `#1C1B1A` · accent `#E86A4F` · success `#3E8E6A` · fail `#C9503C`
- Dark: bg `#141312`, other tokens mirrored.
- Coral on paper is about 3:1 contrast, so use it only for large or graphic elements. Body text is always ink.
- Pop-up: a solid circle scales in (moss ✓ / brick ✕), with haptics and the streak count ticking up or resetting.

## Tech choices
- Flutter packages: `alarm`, `geolocator` (coarse), `workmanager`, `http`, `path_provider`, `shared_preferences`, `flutter_localizations` (ARB en/fr). State: built-in `ChangeNotifier`.
- Content pipeline (`pipeline/build.py`, Python stdlib + ffmpeg, run offline): GBIF occurrences per 2°×2° cell × month (presence + rarity) and GBIF taxonomy (order/family) + Wikidata EN/FR names and photo (GBIF vernacular names as fallback; replaces the IOC spreadsheet, decided 2026-10-27) + Wikimedia Commons photos (CC0/PD/BY/BY-SA; GFDL rejected) + xeno-canto v3 (API key in git-ignored `pipeline/xc_key.txt`; CC0/BY/BY-SA only, quality A/B, 30s clips normalized to −16 LUFS, AAC 48 kbps .m4a). Your own photos: `pipeline/my_photos/<Latin_name>.jpg` (+ optional `credits.csv`); manual picks: `pipeline/overrides.csv`.
- Each ring gets its bird when scheduled (the `alarm` package needs a local file). If the file is missing, a bundled fallback bird plays, so the alarm always rings.

## Out of scope for v1
Monetization, accounts, fact text, card trading. (The card collection replaces the "life list"; card sharing moved into v1 on 2026-10-27.)
