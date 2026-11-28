import 'package:flutter/material.dart';

import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'account.dart';
import 'bird_icon.dart';
import 'booster.dart';
import 'card.dart';
import 'profile.dart' show Avatar;
import 'ranking.dart' show podiumColors;
import 'settings.dart';
import 'theme.dart';
import 'twitch.dart' show PlusSheet;
import 'wake.dart';

/// The introduction, shown once on first launch (and from Settings): what the app is,
/// the region and the alarm permissions, the game options, the collection features, an
/// the profile, friends and rankings (1.4.1), an account for the backup, Early Bird Plus,
/// and a card to hold and tilt under the rarities. Skip on the welcome page leads to the region and permissions
/// (an alarm that can't show the quiz breaks the app); later, skip or finish marks it seen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = 8;
  final _pager = PageController();
  int _page = 0;

  // A sample Epic card (glossy) of a bird of the region, to try tilting; never saved.
  late final CardData? _demo = birds.isEmpty
      ? null
      : rollCard(
          birds.firstWhere(
            (b) => b.id == 'erithacus_rubecula',
            orElse: () => birds.first,
          ),
          store.region,
          rarity: 'epic',
        );

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  /// The feature lines of a page: an accent icon, then the text.
  /// Centred as one block, the lines aligned on their icons (user, 2026-11-28).
  Widget _rows(ColorScheme scheme, List<(IconData, String)> rows) => Center(
    child: IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, text) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: scheme.primary),
                  const SizedBox(width: 16),
                  Flexible(child: Text(text, textAlign: TextAlign.start)),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  void _finish() {
    store.onboarded = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store, // the region and game options change from here
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final scheme = Theme.of(context).colorScheme;
      final last = _page == _pages - 1;
      return PopScope(
        canPop: false, // finish or skip: both mark it seen
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _finish();
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pager,
                    onPageChanged: (p) => setState(() => _page = p),
                    children: [
                      _Page(
                        top: SizedBox.square(
                          dimension: 120,
                          child: CustomPaint(
                            painter: BirdPainter.of(
                              store.theme == 'system' ? 'bluetit' : store.theme,
                            ),
                          ),
                        ),
                        title: 'Early Bird',
                        body: [Text(l.introWelcome)],
                      ),
                      _Page(
                        top: Icon(
                          Icons.public,
                          size: 72,
                          color: scheme.primary,
                        ),
                        title: l.introRegionTitle,
                        body: [
                          Text(l.introRegion),
                          const SizedBox(height: 24),
                          const RegionPill(),
                          const SizedBox(height: 32),
                          const AlarmPermissions(),
                        ],
                      ),
                      _Page(
                        top: Icon(Icons.tune, size: 72, color: scheme.primary),
                        title: l.introGameTitle,
                        body: [
                          Text(l.introLater),
                          const SizedBox(height: 24),
                          const GameOptions(),
                        ],
                      ),
                      _Page(
                        top: Icon(
                          Icons.collections_bookmark_outlined,
                          size: 72,
                          color: scheme.primary,
                        ),
                        title: l.introCollectionTitle,
                        body: [
                          _rows(scheme, [
                            (Icons.music_note, l.introTwitch),
                            (
                              Icons.collections_bookmark_outlined,
                              l.introSeries,
                            ),
                          ]),
                        ],
                      ),
                      // 1.4.1 (user, 2026-11-28): the profile, friends and rankings.
                      _Page(
                        top: const _Podium(),
                        title: l.introSocialTitle,
                        body: [
                          _rows(scheme, [
                            (Icons.account_circle_outlined, l.introProfile),
                            (Icons.group_add, l.introFriends),
                            (Icons.swap_horiz, l.introTrade),
                            (Icons.leaderboard, l.introRankings),
                          ]),
                        ],
                      ),
                      _Page(
                        top: Icon(
                          Icons.cloud_done_outlined,
                          size: 72,
                          color: scheme.primary,
                        ),
                        title: l.introAccountTitle,
                        body: [
                          Text(l.introAccount),
                          const SizedBox(height: 16),
                          const AccountPanel(),
                        ],
                      ),
                      // Plus, gently: Next stays the main button.
                      _Page(
                        top: Icon(Icons.bolt, size: 72, color: scheme.primary),
                        title: l.twitchPlus,
                        body: [
                          _rows(scheme, [
                            (Icons.bolt, l.introPlusBoosters),
                            (Icons.radar, l.introPlusRadar),
                            (Icons.hardware, l.introPlusForge),
                            (Icons.campaign, l.introPlusLure),
                          ]),
                          const SizedBox(height: 16),
                          if (store.twitchPlus)
                            Text(l.introPlusOwned)
                          else ...[
                            Text(l.introPlusOnce),
                            const SizedBox(height: 12),
                            Center(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(160, 48),
                                ),
                                icon: const Icon(Icons.bolt),
                                label: Text(l.introPlusSee),
                                onPressed: () => showModalBottomSheet<void>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (_) => const PlusSheet(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // The card to tilt, under the five rarities in their colours
                      // (the rarity page merged in, 1.4.1).
                      _Page(
                        top: Column(
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 14,
                              runSpacing: 6,
                              children: [
                                for (final t in tiers)
                                  Text(
                                    rarityName(l, t),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: rarityColor[t],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                              ],
                            ),
                            if (_demo case final demo?) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 220,
                                child: AspectRatio(
                                  aspectRatio: 0.68,
                                  child: CardTilt(
                                    shine: true,
                                    child: BirdCardView(
                                      bird: birdById(demo.birdId)!,
                                      card: demo,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        title: l.introExamineTitle,
                        body: [
                          Text(l.introExamine),
                          const SizedBox(height: 12),
                          Text(l.introRarity),
                        ],
                      ),
                    ],
                  ),
                ),
                // Page dots, then Skip and Next / Start (the dots on their own line: a
                // large Next button covered the last one).
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _page
                                ? scheme.primary
                                : scheme.onSurface.withValues(alpha: 0.25),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      if (!last)
                        TextButton(
                          onPressed: _page == 0
                              ? () => _pager.jumpToPage(1)
                              : _finish,
                          child: Text(l.skip),
                        ),
                      const Spacer(),
                      FilledButton(
                        // The theme's buttons are full width (Size.fromHeight): not here.
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(132, 56),
                        ),
                        onPressed: last
                            ? _finish
                            : () => _pager.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              ),
                        child: Text(last ? l.start : l.next),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// One page of the introduction: a picture, a title, and its content, scrollable.
class _Page extends StatelessWidget {
  const _Page({required this.top, required this.title, required this.body});
  final Widget? top;
  final String title;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Centred in the screen's height (user, 2026-11-28); scrolls only if it overflows.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (top != null) Center(child: top),
              const SizedBox(height: 16),
              Text(
                title,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              DefaultTextStyle.merge(
                style: text.bodyLarge,
                textAlign: TextAlign.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three faceless players on a podium (2nd, 1st, 3rd), the steps in the ranking's medal
/// colours: no real player shown.
class _Podium extends StatelessWidget {
  const _Podium();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 6,
      children: [
        for (final (place, height) in [(2, 44.0), (1, 64.0), (3, 30.0)])
          Column(
            spacing: 6,
            children: [
              Avatar(null, size: place == 1 ? 64 : 52),
              Container(
                width: 72,
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: podiumColors[place - 1],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Text(
                  '$place',
                  style: text.titleLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
