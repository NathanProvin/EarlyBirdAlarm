import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import 'card.dart';
import 'collection.dart';
import 'theme.dart';

/// The Play Store page; the referrer shows shared-card installs in the Play Console
/// (Acquisition reports, utm_source=share).
const playLink =
    'https://play.google.com/store/apps/details?id=com.nathanprovin.earlybird'
    '&referrer=utm_source%3Dshare%26utm_medium%3Dcard';

const _w = 1080.0,
    _h = 1350.0,
    _cardH = 960.0; // 4:5, the size chats and feeds show whole

/// Shares the card in [boundary] as a 4:5 post: rarity backdrop and headline, the card,
/// and the app's name with "Free on Google Play" (apps like Instagram drop the text, so
/// the picture itself says where to get the app), plus a text with the store link.
/// The text is also copied: Messenger and others keep only the picture, so the player can
/// paste the link.
Future<void> shareCard(
  BuildContext context,
  RenderRepaintBoundary boundary,
  Bird bird,
  CardData card,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final rarity = cardRarity(card);
  final tier = rarityName(l, rarity);
  final frame = rarityColor[rarity]!;
  final cardImage = await boundary.toImage(
    pixelRatio: _cardH / boundary.size.height,
  );
  // The launcher icon, generated with it by pipeline/store_assets.py.
  final icon = (await (await ui.instantiateImageCodec(
    (await rootBundle.load('assets/icon.png')).buffer.asUint8List(),
  )).getNextFrame()).image;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const page = Rect.fromLTWH(0, 0, _w, _h);
  canvas
    ..drawRect(
      page,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, _h), [
          Color.lerp(frame, ink, 0.25)!,
          Color.lerp(frame, ink, 0.8)!,
        ]),
    )
    // A glow behind the card.
    ..drawCircle(
      const Offset(_w / 2, 650),
      560,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(_w / 2, 650), 560, [
          frame.withValues(alpha: 0.7),
          frame.withValues(alpha: 0),
        ]),
    );

  void text(
    String s,
    double size,
    double y, {
    FontWeight? weight,
    double alpha = 1,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: paper.withValues(alpha: alpha),
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: _w - 80);
    p.paint(canvas, Offset((_w - p.width) / 2, y));
  }

  text(l.shareTitle(tier), 64, 40, weight: FontWeight.bold);

  final cardW = cardImage.width.toDouble(), cardH = cardImage.height.toDouble();
  final dst = Rect.fromLTWH((_w - cardW) / 2, 150, cardW, cardH);
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(
        dst.shift(const Offset(0, 16)),
        const Radius.circular(36),
      ),
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    )
    ..drawImage(cardImage, dst.topLeft, Paint());

  // The app's bird and name, centered as a group under the card.
  final name = TextPainter(
    text: const TextSpan(
      text: 'Early Bird',
      style: TextStyle(color: paper, fontSize: 52, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  const logo = 84.0;
  final left = (_w - logo - 16 - name.width) / 2;
  final logoRect = Rect.fromLTWH(left, 1130, logo, logo);
  canvas
    ..save()
    ..clipRRect(RRect.fromRectAndRadius(logoRect, const Radius.circular(20)))
    ..drawImageRect(
      icon,
      Offset.zero & Size(icon.width.toDouble(), icon.height.toDouble()),
      logoRect,
      Paint()..filterQuality = FilterQuality.medium,
    )
    ..restore();
  name.paint(canvas, Offset(left + logo + 16, 1140));
  text(l.shareTagline, 34, 1235, alpha: 0.8);

  final picture = recorder.endRecording();
  final image = await picture.toImage(_w.toInt(), _h.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  cardImage.dispose();
  icon.dispose();
  image.dispose();

  final message = l.shareText(bird.nameIn(l.localeName), tier, playLink);
  await Clipboard.setData(ClipboardData(text: message));
  messenger?.showSnackBar(SnackBar(content: Text(l.shareCopied)));
  await SharePlus.instance.share(
    ShareParams(
      text: message,
      files: [XFile.fromData(png!.buffer.asUint8List(), mimeType: 'image/png')],
      fileNameOverrides: ['${bird.id}.png'],
    ),
  );
}
