<p align="center">
  <img src="docs/logo.png" alt="Early Bird Alarm logo" width="128" height="128">
</p>

<h1 align="center">Early Bird Alarm</h1>

<p align="center">
  <b>Wake up to a real bird song. Guess the bird, win its card, learn its song.</b>
</p>

<!-- TODO: replace PLAY_STORE_URL with the store page once the app is published -->
<p align="center">
  <a href="PLAY_STORE_URL">Get it on Google Play</a>
</p>

---

Early Bird Alarm is an Android alarm clock that plays a **real recording of a bird that lives
around you, in season**. To stop the alarm, you guess which bird is singing. Guess right and
you win its trading card; guess wrong and the bird is "heard", for next time. Little by
little, you learn the songs of your region.

Free, no account, no ads, no tracking. English, French, German and Spanish.

## Screenshots

<p align="center">
  <img src="store/screenshots/1-quiz.png" alt="The alarm quiz: four photos, guess the bird" width="250">
  <img src="store/screenshots/2-collection.png" alt="The collection" width="250">
  <img src="store/screenshots/3-legendary.png" alt="A Legendary card, full screen" width="250">
</p>

## Features

- **Local, seasonal birds**: 1,713 species across Europe and North America, with recordings
  from xeno-canto. Pick your region on a world map, or use your position (it never leaves the
  phone).
- **Four difficulties**: songs of common birds only, then calls, then every vocalization of
  rarer birds; and **Expert**, where you type the bird's name instead of choosing among four
  photos. A "Seasonal / All birds" switch.
- **Trading cards** with five rarities, from Common to Legendary, and real statistics of the
  species (weight, wingspan, length, migration distance). Each card is a unique specimen; aim
  for a 100 % bird. A **Bird rarity** row rates how rare the species is in your region, from
  half a star to five glinting stars.
- **Twitch Zone**: a free booster every 15 minutes to train your ear between alarms.
- **Series and achievements**: families, habitats and themed series, plus game achievements.
  Completing one gives a card of guaranteed rarity.
- **Face-to-face trading**: two phones side by side swap cards over Bluetooth / Wi-Fi
  (Google Nearby Connections), with no server and no account.
- Bird-themed colour themes, card sharing, the species' Wikipedia article in your language,
  collection search, works offline once your region is downloaded.

## Repository layout

| Path | What |
|---|---|
| `app/` | The Flutter app (Android) |
| `pipeline/build.py` | Builds the catalog: regions, species, photos, recordings, stats, series |
| `pipeline/series.md` | The series (editable): families, habitats, themes, and their rewards |
| `pipeline/world_map.py` | Builds the offline world map of the region picker (Natural Earth) |
| `pipeline/store_assets.py` | Draws the store icon and feature graphic from the app's icon |
| `site-static/` | Privacy policy pages (4 languages), published with the catalog |
| `store/` | Play Store graphics and screenshots |
| `memory/` | Design decisions, roadmap and store listing |

## Data and licences

| Content | Source | Licence |
|---|---|---|
| Presence, seasons, rarity | GBIF.org occurrence data (only monthly counts are used) | CC0, CC BY or CC BY-NC, per dataset |
| Names | Wikidata | CC0 |
| Photos | Wikimedia Commons | CC0, public domain, CC BY, CC BY-SA (author and licence on each card) |
| Recordings | xeno-canto | CC0, CC BY, CC BY-SA; CC BY-NC(-SA) for a few species without a free recording (author and licence on each card) |
| Card statistics | AVONET (Tobias et al. 2022, *Ecology Letters*), Wikipedia, Wikidata | CC BY 4.0, CC BY-SA, CC0 |
| World map | Natural Earth | Public domain |

The app shows each photo's and recording's author and licence on its card (ⓘ) and in
Settings → Credits.

## Privacy

No account, no analytics, no ads. Your alarms, settings and cards stay on your phone; the
position (optional) is only used on the phone to pick a region. See the
[privacy policy](https://nathanprovin.github.io/EarlyBirdAlarm/privacy.html).

## Contact

Questions and feedback: [nanodev009@gmail.com](mailto:nanodev009@gmail.com), or open an
[issue](https://github.com/NathanProvin/EarlyBirdAlarm/issues).

## License

<!-- TODO: choose a licence for the code (e.g. MIT, Apache-2.0, GPL-3.0) and add a LICENSE file -->
The code's licence is not chosen yet. Bird data, photos and recordings keep their own
licences (see above).
