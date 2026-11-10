import 'package:flutter/material.dart';

import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'bird_icon.dart';
import 'booster.dart';
import 'card.dart';
import 'settings.dart';
import 'theme.dart';
import 'wake.dart';

/// The introduction, shown once on first launch (and from Settings): what the app is,
/// the region, the game options, the collection features, a card to hold and tilt, and
/// the Wake-up check. Skip jumps to the Wake-up check; finishing marks it seen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = 7;
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
                          dimension: 150,
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
                          size: 96,
                          color: scheme.primary,
                        ),
                        title: l.introRegionTitle,
                        body: [
                          Text(l.introRegion),
                          const SizedBox(height: 24),
                          const RegionPill(),
                        ],
                      ),
                      _Page(
                        top: Icon(Icons.tune, size: 96, color: scheme.primary),
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
                          size: 96,
                          color: scheme.primary,
                        ),
                        title: l.introCollectionTitle,
                        body: [
                          for (final (icon, text) in [
                            (Icons.music_note, l.introTwitch),
                            (
                              Icons.collections_bookmark_outlined,
                              l.introSeries,
                            ),
                            (Icons.swap_horiz, l.introTrade),
                          ])
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(icon, color: scheme.primary),
                              title: Text(text),
                            ),
                        ],
                      ),
                      _Page(
                        // The five rarities, in their colours.
                        top: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 6,
                          children: [
                            for (final t in tiers)
                              Text(
                                rarityName(l, t),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: rarityColor[t],
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                          ],
                        ),
                        title: l.introRarityTitle,
                        body: [Text(l.introRarity)],
                      ),
                      _Page(
                        top: _demo == null
                            ? null
                            : SizedBox(
                                width: 220,
                                child: AspectRatio(
                                  aspectRatio: 0.68,
                                  child: CardTilt(
                                    shine: true,
                                    child: BirdCardView(
                                      bird: birdById(_demo.birdId)!,
                                      card: _demo,
                                    ),
                                  ),
                                ),
                              ),
                        title: l.introExamineTitle,
                        body: [Text(l.introExamine)],
                      ),
                      // Last, and where Skip leads: an alarm that can't show the quiz
                      // over the lock screen breaks the whole app.
                      _Page(
                        top: Icon(
                          Icons.alarm_on,
                          size: 96,
                          color: scheme.primary,
                        ),
                        title: l.wakeTitle,
                        body: const [WakeCheck()],
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
                          onPressed: () => _pager.jumpToPage(_pages - 1),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: [
        if (top != null) Center(child: top),
        const SizedBox(height: 24),
        Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        DefaultTextStyle.merge(
          style: text.bodyLarge,
          textAlign: TextAlign.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: body,
          ),
        ),
      ],
    );
  }
}
