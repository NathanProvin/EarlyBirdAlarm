# Early Bird Alarm — Roadmap

Iterative: each step ends with something that runs on a real Android device. Placeholders first, real content later. See `decisions.md` for rules and choices.

## Iteration 0 — Setup
- [ ] `git init`, Flutter project in `app/`, Dawn theme tokens in `lib/ui/theme.dart`

## Iteration 1 — PoC: the core loop with placeholders
- [ ] One alarm (hard-coded time picker) that rings via the `alarm` package with the screen locked or the app killed
- [ ] 5 bundled placeholder birds (one clip each, placeholder image, EN name + Latin name)
- [ ] Ringing screen: 4 choices → success/failure pop-up → reveal screen
- [ ] **Exit:** rings reliably for 7 nights on 2 devices (locked / killed / reboot / Do Not Disturb / Doze). Permissions: `USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`

## Iteration 2 — Real alarm app
- [ ] Multiple alarms (time, repeat days, on/off, snooze length, label), fade-in, snooze replays the same bird
- [ ] Streak, recent-bird rotation, difficulty setting
- [ ] EN/FR localization

## Iteration 3 — Real content
- [ ] Pipeline v0: one region cell end to end (license whitelist assert, coverage report)
- [ ] ~30 fallback birds bundled
- [ ] Full Europe + North America catalog on a static CDN; prefetch of the next 7 days; coarse location / manual region; seasonal toggle

## Iteration 4 — Polish and beta
- [ ] Animations, haptics, dark mode, TalkBack, large text
- [ ] Credits/licenses screen, privacy policy, Play Data Safety form, declarations for full-screen intent and exact alarms
- [ ] Play Store internal testing

## Iteration 5 — iOS
- [ ] Evaluate AlarmKit (iOS 26+) vs the `alarm` package's background audio; check custom-sound support
