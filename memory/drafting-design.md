# Card drafting — how a bird and its card are chosen (state on 2026-11-11)

From the tap on a booster to the card in the collection, told as a card table: the **dealer** is the app, the **box** holds every card that exists, and in front of the player sits a face-down **pile**. Decisions behind each choice are in `decisions.md` (2026-11-11 entries).

## The table before the tap

1. **The box: the catalog.** 1,292 species (`species.json`).
2. **The cards allowed at this table: region and season.** France · Nord lists 260 species (`regions/N48E002.json`), each with how common it is **this month**: Common, Uncommon, Rare, Epic or Legendary. That is the *bird's* tier, not the card's.
   - **Difficulty removes cards:** Easy keeps Common- and Uncommon-tier birds, Medium adds Rare, Hard and Expert keep all (`pool()` in `birds.dart`).
   - **Raffle tickets per allowed species:** Common 16, Uncommon 9, Rare 6, Epic 3, Legendary 2 (a common bird is dealt 8× more often than a Legendary one).
3. **The pile: the deck.** **14 face-down cards** (`deckPile()` in `content.dart`). Each card is **one bird with one recording already downloaded**, so an alarm rings offline. The top card is the one that has waited longest; the order comes from the file's download date.
   - **The rarity is not printed on the pile's cards.** The pile holds birds and songs; the card's rarity is stamped only when it is won.
4. **The discard tray: resting songs.** A song that has rung goes into the "played" list and can't come back into the pile while there: for the **last 200 songs played**, or **half of the songs that can ring at this difficulty** if fewer (Easy has ~110 songs in France · Nord).
5. **Cards put aside: alarms.** Each scheduled alarm **holds its own card** from the pile (`_held` in `store.dart`): two alarms, or an alarm and a booster, never share one.

## Step 1 — the booster tap

`_open()` in `ui/twitch.dart` → `store.pickNext()`:
1. **The dealer flips the top card** of the pile, skipping cards held by alarms. No raffle here: it happened when the card went into the pile.
2. **The card's picture is decided now** (`drawPhoto()` in `cards.dart`): the catalog photo or one of up to 5 variants, equally likely. Saved in `drawnPhotos` (preferences) and **downloaded at once**, while the song plays.
3. **One booster is used** (`useTwitch()`): series bonus boosters first, else the countdown timestamp moves on.

**Empty pile** (offline too long): any song already on the phone, by raffle tickets, then the bundled birds. Songs can repeat: the safety net that guarantees an alarm always rings.

## Step 2 — the quiz

`ui/ring.dart` loops the card's song and shows **4 photos**: the right bird and 3 wrong ones (`choicesFor()`; on Hard from the same family, else the same order). The card's photo finishes downloading meanwhile (~0.4 s measured; the quiz lasts several seconds).

## Step 3 — the answer

The answer stays on screen **2 s**, during which `store.answered()`:
1. **Puts the song in the discard tray** (played list) and updates the streak.
2. **Takes one song out of the tray** (its rest is over) and slips it **under the pile** (its file is re-dated: `toBottom()`).
3. **Wrong answer:** no card; the bird joins "heard" (grey card).
4. **Right answer: the dealer stamps the rarity** (`drawRarity()` in `birds.dart`):
   - **Base odds by difficulty**, each rarity rarer than the one below. Hard: 72 / 20.6 / 6 / 1.1 / 0.25 % (`rarityScale`, fitted to 16 cards a day).
   - **Lean toward the bird:** each step between a rarity and the bird's tier divides that rarity's odds (by 3 on Hard): common birds almost always give Common cards, Legendary-tier birds give far more rare cards.
   - **No Legendary hoarding:** a species already owned as Legendary has half the Legendary odds.
5. **The card is printed** (`rollCard()` in `cards.dart`):
   - **Stats** rolled around the species' real averages, with occasional "fine specimens"; their average percentile is the quality %.
   - **Shiny check:** if the species has a Shiny photo, **1 in 1,250** makes it Shiny whatever the stamped rarity, with the leucistic / melanistic photo.
   - **Otherwise** the photo decided at the draw.
6. **The card joins the collection** (`cards` in the preferences).
7. **Its photo, if not on the phone yet:** wait for the download already under way, **4 s at most** (measured **0 ms** on 141 reveals, Wi-Fi and 4G). Offline: the catalog photo shows until the next sync fetches it.

## Step 4 — the dealer tidies up (background)

`store.sync()` → `syncRegion()` in `content.dart`, without making the player wait:
1. **Refills the pile** (`topUpDeck()`): a raffle among allowed species, leaving out species already in the pile (one card per species), the 10 birds heard last, and resting songs. The winning song is downloaded and placed **under** the pile.
2. **Photos:** the region's catalog photos still missing, then each owned card's photo.
3. **Cleans the table:** songs that have rung, the oldest beyond 60 (never pile or held cards); photos other than the region's catalog and the owned cards'.
4. **Cloud copy:** the backup sees the collection change and writes it to Firestore.

## Step 5 — the reveal, then the collection

The reveal flips the card with effects growing with rarity (Shiny: 4.2 s of fireworks in its look's colours). The Collection reads the same data: the card is in Collected, best copies, series and achievements.

## Compromises and workarounds

| Choice | Why | Cost |
|---|---|---|
| A pile of 14 downloaded songs | Alarms ring offline | Data and space for 14 songs; after 14 cards offline the safety net repeats songs |
| Rarity stamped at the win, not printed in the pile | Bird and card are two separate draws (a Blackbird can be Legendary, rarely) | No rarity "waits" in the pile |
| Raffle tickets 16/9/6/3/2 + lean | Common birds ring often, scarce birds give rare cards | With rare Legendaries, a Legendary-tier bird gives Common 30 % of the time on Hard |
| One card per species in the pile, last 10 birds excluded | Variety | The pile never holds the same bird twice |
| Rest tray sized to the pool | No song repeats too soon | On Easy (small pool) birds ring by number of songs more than by tickets: more Uncommon cards (31 % vs 26 %) |
| Pile order = file download date | No separate list to maintain | A song back from rest needs its file re-dated to go under |
| Pile filtered when dealt | Season / difficulty changes take effect at once | Cards that no longer fit are skipped until cleaned |
| Photo picked at the draw, downloaded during the quiz | No wait at the reveal (0 ms measured) | Shiny photos still download at the reveal (~0.5 s, every ~6 months) |
| Photos downloaded once, owned ones kept | ~5 MB a day instead of ~15 | Space grows with the collection: ~400 MB realistic after years, 850 MB ceiling |
| Odds fitted on France · Nord at 16 cards a day | Hard: an Epic every ~3 days, a Legendary every ~2 weeks | Other regions differ (California: a Legendary every ~5 days); accepted, no per-region scaling |
| Easy's tiny Legendary chance | Easy only deals Common / Uncommon birds and the lean is strong | Base odds look high (2.3 %) to land at ~1 card in 6,000 |
| Cards rolled on the phone | No server before the marketplace | Rolls can't be trusted (server-signed cards planned) |
| Dev draw pauses 2 s per card | Realistic photo timing in simulations | Simulations are slower |

## Known risks (review of 2026-11-11) — the optimization round

Ranked by priority; **to fix**: 1–7 and 10 (8 and 9 left aside by the user).

1. **Cloud backup stops after ~3,250 cards** (one 1 MB Firestore document, 322 bytes a card measured; ~7 months at 16 cards a day): writes then fail silently.
2. **Alarm photos deleted after prefetch:** the sync's photo cleanup doesn't keep pending draws' photos; an alarm's photo, picked at scheduling, is deleted by the next sync (and a sync finishing during a quiz deletes the one being prefetched).
3. **Firestore free quota ~1,000 active players:** one write per collection change (~16+ a day each, the whole document each time) against 20,000 writes a day on the Spark plan.
4. **~70–90 MB of catalog photos on mobile data without asking** (first sync, region change).
5. **Collection decoded from JSON at each `cards` read** and rewritten whole at each card: stutters at ~10,000 cards.
6. **Hundreds of file checks on the main thread** at each draw / sync / answer (pile building).
7. **Startup race:** the cards held by alarms are filled by `healAlarms()`, after the sync: a booster opened right at launch can take an alarm's card.
8. *(left aside)* Manual region choice lets players farm Legendary-rich regions.
9. *(left aside)* Small regions on Easy can empty the pile (last-10 exclusion on a ~10–15-species pool).
10. **Shiny won offline shows the normal catalog photo** under "Shiny · Leucistic" until the next sync.
11. Low: a Legendary-tier bird gives 30 % Common on Hard; clock changes refill boosters; forged cards through a self-written cloud document (server-signed cards planned); Easy leans to Uncommon; pile order depends on file dates; tiny leftovers (`_fetching`, stale `drawnPhotos`).

Not tested yet: Medium and Expert simulations, weak networks, a real alarm ringing with the pile (where risk 2 shows), a unit test for the pile.
