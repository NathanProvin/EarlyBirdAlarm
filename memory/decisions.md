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
| Difficulty | User setting Easy / Medium / Hard (wrong choices from other families, the same order, or the same family/genus) |
| Alarms | Multiple alarms: time, repeat days, on/off, snooze length, label |
| Rotation | New bird per ring, avoiding birds heard recently |
| Business | Free MVP; monetization decided later. No billing, no account, no tracking |
| Privacy | Coarse location only, processed on the device; manual region picker as the alternative |

## Design — "Dawn"
- Flat solid colors only: no gradients, no shadows. One corner radius. Lots of whitespace. One typeface.
- Light: bg `#F6F1EA` · text `#1C1B1A` · accent `#E86A4F` · success `#3E8E6A` · fail `#C9503C`
- Dark: bg `#141312`, other tokens mirrored.
- Coral on paper is about 3:1 contrast, so use it only for large or graphic elements. Body text is always ink.
- Pop-up: a solid circle scales in (moss ✓ / brick ✕), with haptics and the streak count ticking up or resetting.

## Tech choices
- Flutter packages: `alarm`, `geolocator` (coarse), `workmanager`, `http`, `path_provider`, `shared_preferences`, `flutter_localizations` (ARB en/fr). State: built-in `ChangeNotifier`.
- Content pipeline (Python, run offline): IOC taxonomy (EN/FR names) + GBIF occurrences per 2°×2° cell × month + xeno-canto v3 (license whitelist, quality A/B, 30s clips normalized to −16 LUFS, AAC .m4a) + Wikimedia Commons photos (free licenses).
- Each ring gets its bird when scheduled (the `alarm` package needs a local file). If the file is missing, a bundled fallback bird plays, so the alarm always rings.

## Out of scope for v1
Life list and stats, sharing, monetization, accounts, fact text.
