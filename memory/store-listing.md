# Early Bird Alarm — Google Play listing & declarations

Ready to paste into Play Console (Iteration 4b). Keep in sync with the app.

## Basics
- **App name:** Early Bird Alarm (≤ 30 chars)
- **Package:** `com.nathanprovin.earlybird`
- **Category:** Lifestyle (alternative: Education)
- **Contact email:** CONTACT_EMAIL (to set)
- **Privacy policy URL:** https://nathanprovin.github.io/EarlyBirdAlarm/privacy.html
- **Price:** free; no ads, no in-app purchases (v1)

## Short description (≤ 80 chars)
- **EN:** Wake up to a real bird song, guess the bird, and collect its card.
- **FR:** Réveillez-vous au chant d'un vrai oiseau, devinez-le et gagnez sa carte.

## Full description
### EN
Early Bird Alarm wakes you up with a real bird song from your region and season.

Guess which bird is singing among 4 photos to stop the alarm. Right answer? You win its card: a trading card with its own rarity, photo, recording and stats (weight, wingspan, length, flight distance). Wrong? It's "heard" — catch it next time.

• Real recordings from xeno-canto and photos from Wikimedia Commons
• Birds of your region and season, from Europe to North America
• Easy, Medium and Hard: songs only, then calls and alarm calls
• 5 rarities, from Common to Legendary — rare birds ring rarely
• A card collection to complete, with your best copies and streaks
• Twitch Zone: open a free booster every 10 minutes to train your ear and win more cards
• Series to complete — gulls, owls, birds of prey, birders' legends… — each one earns a bonus booster
• Four bird themes: Blackbird, Serin, Blue Tit and Gull
• Share your cards with friends
• Multiple alarms, repeat days, snooze, gentle fade-in
• Works offline once your region is downloaded
• No account, no ads, no tracking. Location (optional) never leaves your phone.

### FR
Early Bird Alarm vous réveille avec le chant d'un vrai oiseau de votre région, de saison.

Devinez quel oiseau chante parmi 4 photos pour arrêter l'alarme. Bonne réponse ? Vous gagnez sa carte : une carte à collectionner avec sa rareté, sa photo, son enregistrement et ses statistiques (poids, envergure, longueur, distance de vol). Raté ? Il est « entendu » — ce sera pour la prochaine fois.

• De vrais enregistrements de xeno-canto et des photos de Wikimedia Commons
• Les oiseaux de votre région et de la saison, de l'Europe à l'Amérique du Nord
• Facile, Moyen, Difficile : chants seuls, puis cris et cris d'alarme
• 5 raretés, de Commune à Légendaire — les oiseaux rares sonnent rarement
• Une collection de cartes à compléter, vos meilleurs exemplaires et vos séries
• Zone Cocheur : ouvrez un booster gratuit toutes les 10 minutes pour entraîner votre oreille et gagner d'autres cartes
• Des séries à compléter — goélands, chouettes, rapaces, légendes des cocheurs… — chacune rapporte un booster bonus
• Quatre thèmes d'oiseaux : Merle, Serin, Mésange bleue et Goéland
• Partagez vos cartes avec vos amis
• Plusieurs alarmes, jours de répétition, répétition, montée progressive du volume
• Fonctionne hors ligne une fois votre région téléchargée
• Pas de compte, pas de publicité, pas de pistage. La position (facultative) ne quitte jamais votre téléphone.

## Data safety form
- **Does the app collect or share user data?** No.
  - Approximate location: used only on the device to pick the region, never transmitted → not "collected" under Play's definition (processed ephemerally on device).
  - No personal info, no identifiers, no analytics, no crash reporting.
- **Is data encrypted in transit?** Yes (HTTPS downloads from GitHub Pages).
- **Can users request deletion?** No data is collected; uninstalling removes everything. Android Auto Backup is handled by Google in the user's own account.

## Permission declarations
### Full-screen intent (`USE_FULL_SCREEN_INTENT`)
Core functionality: **alarm clock**. When an alarm the user set goes off, the app shows a full-screen quiz (identify the bird) that the user must answer to stop the alarm, including on the lock screen.

### Exact alarms (`USE_EXACT_ALARM`)
The app's core function is an **alarm clock**: users set alarms that must ring at the exact time they chose. `USE_EXACT_ALARM` is permitted for alarm clock apps.

### Foreground service (media playback)
Plays the alarm's bird recording while the alarm rings, until the user answers or snoozes.

### Location (`ACCESS_COARSE_LOCATION`)
Optional, only when the user taps "Use my location": approximate position to choose the bird region, processed on the device only.

## Content rating (IARC questionnaire)
No violence, sexual content, profanity, gambling, user-generated content, or user-to-user communication. Card sharing is an image sent via the system share sheet. Expected rating: Everyone / PEGI 3.

## Licenses to mention (also in the app's Credits)
GBIF.org (occurrences), Wikidata (CC0), Wikimedia Commons photos (per-photo licenses, credited on each card), xeno-canto recordings (CC0 / BY / BY-SA; a few BY-NC / BY-NC-SA, **to replace before any monetization**), AVONET (Tobias et al. 2022, CC BY 4.0), Wikipedia.

## Screenshots to take (phone, 1080×2340)
1. Quiz screen: 4 photos with names, Snooze.
2. Answer animation (green frame on the right bird).
3. "New Rare card!" reveal.
4. Collection grid, Collected view.
5. A Legendary card full screen.
6. Alarms list.
7. Region choice ("Use my location").
8. Blackbird (dark) theme, one screen.
9. Twitch Zone: the floating booster pile with its countdown.
10. Series: a page of badges with one foil (completed) ring.

Feature graphic (1024×500): the app icon's sun and bird + "Wake up to birdsong".
