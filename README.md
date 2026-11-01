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
around you, in season**. To stop the alarm, you guess which bird is singing among four photos.
Guess right and you win its trading card; guess wrong and the bird is "heard", for next time.
Little by little, you learn the songs of your region.

Free, no account, no ads, no tracking. English, French, German and Spanish.

## Features

- **Local, seasonal birds**: 1,713 species across Europe and North America. Pick your region
  on a world map, or use your position (it never leaves the phone).
- **Three difficulties**: songs of common birds only, then calls, then every vocalization of
  rarer birds. A "Seasonal / All birds" switch.
- **Trading cards** with five rarities, from Common to Legendary, and real statistics of the
  species (weight, wingspan, length, migration distance). Each card is a unique specimen; aim
  for a 100 % bird.
- **Twitch Zone**: a free booster every 15 minutes to train your ear between alarms.
- **Series and achievements**: families, habitats and themed series, plus game achievements.
  Completing one gives a card of guaranteed rarity.
- **Face-to-face trading**: two phones side by side swap cards over Bluetooth / Wi-Fi
  (Google Nearby Connections), with no server and no account.
- Bird-themed colour themes, card sharing, collection search, works offline once your
  region is downloaded.

## Screenshots

<!-- TODO: add phone screenshots (docs/screenshots/*.png) -->
| Alarm quiz | Card reveal | Collection | Series |
|---|---|---|---|
| *coming soon* | *coming soon* | *coming soon* | *coming soon* |

## How it works

```
GBIF observations ─┐
Wikidata / Commons ├─► pipeline/build.py ─► static catalog ─► GitHub Pages ─► the app
xeno-canto         │   (Python, cached)      species.json        /v1/          downloads its
AVONET + Wikipedia ┘                         regions/*.json                     region's birds
                                             audio/, photos/
```

- **Presence and rarity**: for each region (2° × 2° GPS cells, European countries, US and
  Canadian bioregions, European Russia), monthly bird observation counts from
  [GBIF](https://www.gbif.org) give each species a tier per month, from common to legendary.
- **Names and photos**: [Wikidata](https://www.wikidata.org) and
  [Wikimedia Commons](https://commons.wikimedia.org), freely licensed only. Names come in
  English, French, German and Spanish.
- **Recordings**: [xeno-canto](https://xeno-canto.org), freely licensed recordings, varied
  between song, call and alarm call.
- **Card statistics**: [AVONET](https://doi.org/10.1111/ele.13898), Wikipedia and Wikidata;
  migration distance estimated from GBIF.
- **Catalog**: built once for all regions, published as static files on GitHub Pages. The
  app keeps a small deck of songs on the phone for the next alarms, so rings work offline;
  20 common birds are bundled for the very first launch.

## Repository layout

| Path | What |
|---|---|
| `app/` | The Flutter app (Android) |
| `pipeline/build.py` | Builds the catalog: regions, species, photos, recordings, stats, series |
| `pipeline/series.md` | The series (editable): families, habitats, themes, and their rewards |
| `pipeline/world_map.py` | Builds the offline world map of the region picker (Natural Earth) |
| `site-static/` | Privacy policy pages (4 languages), published with the catalog |
| `memory/` | Design decisions, roadmap and store listing |

## Building

### App

Requirements: Flutter 3.47 (Dart 3.13), JDK 17, the Android SDK.

```sh
cd app
flutter pub get
flutter test
flutter build apk --profile          # a test build to install on a phone
flutter build appbundle --release    # the Play Store bundle (needs your signing key)
```

Developer tools (a card-reveal preview, a 1,000-card draw for statistics, a 1-minute
Twitch Zone) are off in every normal build; add `--dart-define=DEV_TOOLS=true` to turn them on.

Release signing reads `app/android/key.properties` and an upload keystore, both kept out of
the repository.

On Windows, the maintainers keep the toolchain in a git-ignored `.tools/` folder and activate
it with `. .\env.ps1` in PowerShell.

### Catalog

Requirements: Python 3.10+ (developed with 3.12), a [xeno-canto API key](https://xeno-canto.org/explore/api) in
`pipeline/xc_key.txt` (git-ignored).

```sh
py pipeline/build.py              # full build, every region (long; every request is cached)
py pipeline/build.py LU,FR        # a few regions, for testing
py pipeline/build.py series       # rebuild series.json after editing pipeline/series.md
py pipeline/build.py fallback     # refresh the birds bundled in the app
py pipeline/build.py publish      # push the catalog and privacy pages to GitHub Pages
```

The build writes `pipeline/report.md`: kept and dropped species, recordings and regions.

## Data and licences

| Content | Source | Licence |
|---|---|---|
| Presence, seasons | GBIF.org occurrence data (only monthly counts are used) | CC0, CC BY or CC BY-NC, per dataset |
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
