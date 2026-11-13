import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'family_paths.dart';

/// Bird group icons (2026-11-13): each catalog family belongs to one group, drawn as a
/// public-domain PhyloPic silhouette (pipeline/family_icons.py) on a 24×24 grid. Shown
/// in a glass circle tinted with the rarity, at the top left of the card's photo.

const familyGroups = <String, List<String>>{
  'duck': ['Anatidae'],
  'gamebird': [
    'Phasianidae', 'Odontophoridae', 'Numididae', 'Cracidae', 'Tinamidae', //
    'Turnicidae', 'Otididae',
  ],
  'diver': ['Gaviidae', 'Podicipedidae'],
  'pigeon': ['Columbidae', 'Pteroclididae'],
  'cuckoo': ['Cuculidae'],
  'nightjar': ['Caprimulgidae', 'Nyctibiidae'],
  'swift': ['Apodidae', 'Hirundinidae'],
  'hummingbird': ['Trochilidae'],
  'rail': ['Rallidae'],
  'heron': [
    'Ardeidae', 'Ciconiidae', 'Threskiornithidae', 'Phoenicopteridae', //
    'Gruidae', 'Aramidae',
  ],
  'shorebird': [
    'Scolopacidae', 'Charadriidae', 'Haematopodidae', 'Recurvirostridae', //
    'Burhinidae', 'Glareolidae',
  ],
  'gull': ['Laridae', 'Stercorariidae'],
  'auk': ['Alcidae'],
  'seabird': [
    'Procellariidae', 'Diomedeidae', 'Hydrobatidae', 'Phaethontidae', //
    'Fregatidae', 'Sulidae',
  ],
  'cormorant': ['Phalacrocoracidae', 'Anhingidae', 'Pelecanidae'],
  'raptor': ['Accipitridae', 'Cathartidae', 'Pandionidae'],
  'falcon': ['Falconidae'],
  'owl': ['Strigidae', 'Tytonidae'],
  'kingfisher': [
    'Alcedinidae', 'Coraciidae', 'Meropidae', 'Momotidae', 'Upupidae', //
    'Trogonidae', 'Ramphastidae',
  ],
  'woodpecker': ['Picidae', 'Certhiidae', 'Furnariidae'],
  'parrot': ['Psittacidae'],
  'crow': ['Corvidae'],
  'flycatcher': [
    'Tyrannidae', 'Cotingidae', 'Thamnophilidae', 'Bombycillidae', //
    'Ptilogonatidae',
  ],
  'shrike': [
    'Laniidae',
    'Malaconotidae',
    'Prionopidae',
    'Vireonidae',
    'Campephagidae',
  ],
  'tit': [
    'Paridae', 'Aegithalidae', 'Remizidae', 'Panuridae', 'Troglodytidae', //
    'Sittidae', 'Cinclidae',
  ],
  'warbler': [
    'Parulidae', 'Phylloscopidae', 'Sylviidae', 'Acrocephalidae', //
    'Locustellidae', 'Cettiidae', 'Cisticolidae', 'Regulidae', 'Polioptilidae',
    'Scotocercidae', 'Peucedramidae', 'Zosteropidae', 'Leiothrichidae',
    'Pycnonotidae', 'Nectariniidae',
  ],
  'thrush': [
    'Turdidae', 'Muscicapidae', 'Mimidae', 'Sturnidae', 'Icteridae', //
    'Oriolidae',
  ],
  'finch': [
    'Fringillidae', 'Passerellidae', 'Passeridae', 'Emberizidae', //
    'Calcariidae', 'Cardinalidae', 'Thraupidae', 'Estrildidae', 'Ploceidae',
    'Viduidae', 'Rhodinocichlidae', 'Prunellidae',
  ],
  'lark': ['Alaudidae', 'Motacillidae'],
};

final _groupOf = {
  for (final e in familyGroups.entries)
    for (final f in e.value) f: e.key,
};

String? familyGroup(String family) => _groupOf[family];

/// An SVG-like path in absolute M L C Z commands, each glued to its first number.
Path parseIconPath(String d) {
  final p = Path();
  final v = <double>[];
  String? cmd;
  void flush() {
    switch (cmd) {
      case 'M':
        p.moveTo(v[0], v[1]);
      case 'L':
        p.lineTo(v[0], v[1]);
      case 'C':
        p.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]);
    }
    v.clear();
  }

  for (final w in d.split(' ')) {
    if (w.isEmpty) continue;
    if ('MLCZ'.contains(w[0])) {
      flush();
      cmd = w[0];
      if (cmd == 'Z') p.close();
      if (w.length > 1) v.add(double.parse(w.substring(1)));
    } else {
      v.add(double.parse(w));
    }
  }
  flush();
  return p;
}

final _paths = <String, Path>{};

/// The group's silhouette on the 24×24 grid.
Path groupPath(String group) =>
    _paths.putIfAbsent(group, () => parseIconPath(familyPaths[group]!));

class _GroupPainter extends CustomPainter {
  const _GroupPainter(this.group, this.color);
  final String group;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.clipRect(
      const Rect.fromLTWH(0, 0, 24, 24),
    ); // a head profile is cropped
    canvas.drawPath(groupPath(group), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GroupPainter old) =>
      old.group != group || old.color != color;
}

/// The bird's group in a glass circle tinted with [color], the size of the card's play
/// button (nothing for a family not mapped yet).
class FamilyBadge extends StatelessWidget {
  const FamilyBadge(this.family, {required this.color, super.key});
  final String family;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final group = familyGroup(family);
    if (group == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.35),
              border: Border.all(
                color: Color.lerp(
                  color,
                  Colors.white,
                  0.45,
                )!.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: CustomPaint(painter: _GroupPainter(group, Colors.white)),
          ),
        ),
      ),
    );
  }
}
