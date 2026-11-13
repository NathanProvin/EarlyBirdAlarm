import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Bird group icons (2026-11-13): each catalog family belongs to one group, drawn as an
/// original minimal silhouette on a 24×24 grid, head to the left. Shown in a glass
/// circle at the top left of the card's photo.

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

// Shapes: 'e cx cy rx ry [deg]' an ellipse, 'l x1 y1 x2 y2 w' a stroke, any other an
// SVG-like path (absolute M L Q C Z); a leading '-' cuts the shape out.
const _shapes = <String, List<String>>{
  'duck': [
    'e 13 15 7.5 3.6',
    'e 6.5 9.5 2.6 2.4',
    'M4.8 10.5 L8.4 9.8 L10.5 13 L6.5 13.5 Z',
    'M4.3 9.4 Q2.2 10 1.4 11.2 L4.8 11 Z',
    'M19.5 14 L22.5 11.8 L20.5 16 Z',
  ],
  'gamebird': [
    'e 12.5 14 6.5 4.5 -10',
    'e 6.5 8.5 2 2',
    'M5.2 9.5 L8.2 8.5 L10 12 L6.5 12.5 Z',
    'M4.7 8.2 L3.2 9 L4.8 9.4 Z',
    'M6.4 6.7 Q5.4 4.4 3.8 4.4 Q5.2 5.6 5.4 7 Z',
    'M17.5 12.5 L22 16 L17 16.5 Z',
    'l 11 17.5 10.5 21.5 1',
    'l 14 17.5 14 21.5 1',
  ],
  'diver': [
    'e 14 16 7.5 2.6',
    'M7 15.5 Q6 11 6.6 8 L8.5 8 Q8.6 11.5 11 14.2 Z',
    'e 7.5 7.4 1.8 1.5',
    'M6 7 L2.2 7.7 L6 8.1 Z',
    'M20.5 15 L22.8 14.2 L21.6 16.5 Z',
  ],
  'pigeon': [
    'e 12.5 13.5 6 4 -15',
    'e 6.8 8.2 2 2',
    'M5.8 9 L8.6 8.4 L10.5 12 L7 12.5 Z',
    'M4.9 8 L3.4 8.6 L4.9 8.9 Z',
    'M17 12 L22.5 14.5 L22 16 L16.5 15.5 Z',
    'l 11 17 11 20 1',
    'l 13 17 13.2 20 1',
  ],
  'cuckoo': [
    'e 10 11 5 2.4 15',
    'e 5.2 8.8 2 1.8',
    'M3.4 8.4 Q2.4 8.6 1.4 9.4 L3.5 9.4 Z',
    'M13.5 11.6 L22.5 17.5 L21.6 18.8 L12.8 14 Z',
    'l 9.5 13.2 9 16 0.8',
  ],
  'nightjar': [
    'e 12.5 13.2 7.5 2.4',
    'e 5.6 12 2.8 2.1',
    'M3 11.8 L2 12.4 L3 12.8 Z',
    'M18.5 12.4 L23 12.8 L22.5 14.6 L18.5 14.4 Z',
    'l 1 16.2 23 16.2 1.1',
  ],
  'swift': [
    'M12 10 Q6 8.6 1 13.6 Q7 11.4 11.5 13.2 Z',
    'M12 10 Q18 8.6 23 13.6 Q17 11.4 12.5 13.2 Z',
    'e 12 11.6 1.5 4',
    'M10.9 14.8 L9.2 21 L12 17.2 L14.8 21 L13.1 14.8 Z',
  ],
  'hummingbird': [
    'e 13.2 13.4 4 2.2 -35',
    'e 9.4 9.8 1.9 1.8',
    'M7.8 9.2 L1.6 7.4 L7.7 10.2 Z',
    'M12.5 11.5 Q15.5 4 21.5 2.2 Q18.5 8.5 14.8 12.8 Z',
    'M15.2 14.6 L18.6 19.8 L13.8 16.4 Z',
  ],
  'rail': [
    'e 12.5 12.5 5 3.5 -10',
    'e 7.3 8.5 2 1.9',
    'M5.6 7.8 L3.4 9 L5.6 9.8 Z',
    'M6.8 10 L9 9.2 L10.4 12 L8 12.6 Z',
    'M17 11 L19.6 9.2 L18.6 12.8 Z',
    'l 11.5 15.5 10.5 20.8 0.8',
    'l 13.5 15.5 14 20.8 0.8',
    'l 7.5 21 12.6 21 0.6',
    'l 12 21 17.5 21 0.6',
  ],
  'heron': [
    'e 14.5 10.8 4.5 2.4 -20',
    'M11 10.6 Q8 9.5 8.6 6.4 Q9 4.6 7.6 4.2 L7 5 Q7.8 5.6 7.2 7 Q6.6 10.4 10.4 12.6 Z',
    'e 6.8 4.1 1.5 1.1',
    'M5.6 3.7 L1.4 4.8 L5.6 4.6 Z',
    'M18.4 9 L21 11.6 L17.8 11.4 Z',
    'l 13.8 12.5 12.8 21.5 0.8',
    'l 15.2 12.5 15.8 21.5 0.8',
  ],
  'shorebird': [
    'e 12 12 5 3 -8',
    'e 6.8 9 1.8 1.7',
    'M5.3 9 L1 10.8 L5.5 9.8 Z',
    'M16.5 10.8 L20.8 12.4 L16.5 13.6 Z',
    'l 11.5 14.5 10.5 20.5 0.8',
    'l 13 14.5 13.6 20.5 0.8',
  ],
  'gull': [
    'e 13 12 6 3.2 -5',
    'e 7 8.8 2.2 2',
    'M6 9.8 L8.8 8.8 L10.5 11.5 L7.5 12 Z',
    'M5.2 8.6 L2.4 9.2 Q3.4 9.9 5.2 9.9 Z',
    'M17.5 10.8 L23 13.4 L17.5 14 Z',
    'l 12 15 11.6 20.5 0.9',
    'l 14 15 14.2 20.5 0.9',
  ],
  'auk': [
    'e 12.5 14 4 6 10',
    'e 10.2 7 2.6 2.4',
    'M7.9 5.9 L4.6 7.4 L7.9 8.9 Z',
    'M11 19.5 L8.6 21.4 L13.4 21.4 Z',
  ],
  'seabird': [
    'e 12.5 13 5.5 1.6',
    'e 6.6 12.4 1.7 1.4',
    'M5.1 12 L2.8 12.6 Q2.8 13.3 3.6 13.3 L5.1 13 Z',
    'M10 12.6 L20.5 4.4 L21.4 5 L13.6 13.2 Z',
    'M17.5 12.4 L21.5 12.8 L17.5 14 Z',
  ],
  'cormorant': [
    'e 12 13.2 2.2 5',
    'e 11 6.3 1.4 1.2',
    'M9.8 5.9 L7.4 6.5 Q7.6 7 8 6.9 L9.8 6.9 Z',
    'l 11.4 7 11.8 9.4 1.6',
    'M11 10 L2.6 6.8 Q3.2 11 10.6 14.4 Z',
    'M13 10 L21.4 6.8 Q20.8 11 13.4 14.4 Z',
    'l 12 18 12 21.5 1.4',
  ],
  'raptor': [
    'e 12 12 1.8 4',
    'e 12 7.6 1.4 1.4',
    'M11 10 L1 9 L1.8 10.4 L0.8 11 L2.4 11.8 L1.6 12.6 L11 13.6 Z',
    'M13 10 L23 9 L22.2 10.4 L23.2 11 L21.6 11.8 L22.4 12.6 L13 13.6 Z',
    'M10.8 15.4 L9.6 20 L14.4 20 L13.2 15.4 Z',
  ],
  'falcon': [
    'e 13 12 3.2 5.5 15',
    'e 10.6 6.2 2.2 2.1',
    'M8.5 5.6 L7 6.4 Q7.2 7.5 8.6 7.3 Z',
    'M14.4 16.4 L17.4 22 L15 22.4 L13 17.4 Z',
  ],
  'owl': [
    'e 12 14.5 5 6',
    'e 12 7.8 4.6 3.8',
    'M8 5.4 L7.2 2 L10.2 4.4 Z',
    'M16 5.4 L16.8 2 L13.8 4.4 Z',
    '-e 10.2 7.8 1.3 1.3',
    '-e 13.8 7.8 1.3 1.3',
    'M11.4 9.2 L12.6 9.2 L12 10.6 Z',
  ],
  'kingfisher': [
    'e 13 12 4 3 -20',
    'e 9 8.6 2.8 2.6',
    'M6.8 8 L1.4 9.4 L6.8 10 Z',
    'M16.4 12.6 L19.6 16.6 L16 14.6 Z',
    'l 6 16 22 16 1.1',
  ],
  'woodpecker': [
    'l 19.5 1 19.5 23 2.4',
    'e 15.2 12.5 2.8 5 -15',
    'e 13.6 6.6 2.1 2',
    'M11.7 6.2 L7.8 6.8 L11.7 7.5 Z',
    'M12.8 4.9 Q14.6 3.4 16.2 4.9 Z',
    'M16 16.5 L18.2 21.4 L17.8 16 Z',
  ],
  'parrot': [
    'e 12.5 11.5 3.2 4.6 10',
    'e 11 6.5 2.6 2.4',
    'M8.8 5.8 Q6.6 5.8 7 8.2 Q7.6 9.2 8.9 8.4 Z',
    'M13 15 L15.2 23 L13.6 23.2 L11.8 15.6 Z',
    'l 5 16 19 16 1.1',
  ],
  'crow': [
    'e 13 12.5 6 3.5 -8',
    'e 7 9 2.4 2.2',
    'M5 8.3 L1.6 9.6 L5 10.4 Z',
    'M18 12 L23 13.5 L22.5 15.5 L17.5 15 Z',
    'l 12 15.5 11.5 20.5 1',
    'l 14 15.5 14 20.5 1',
  ],
  'flycatcher': [
    'e 12 12 3.4 4.8 12',
    'e 10 6.5 2.4 2.2',
    'M9.6 4.5 L13.4 4 L11.8 5.8 Z',
    'M7.8 6.2 L5.4 6.8 L7.8 7.4 Z',
    'M13 15.5 L15 21 L13.2 21.3 L11.8 16 Z',
    'l 5 16.6 19 16.6 1',
  ],
  'shrike': [
    'e 12 11.5 4 3 -25',
    'e 8 7.6 2.4 2.2',
    'M5.8 7 L4 7.6 Q4.3 8.5 5.9 8.3 Z',
    'M15 13 L21 19 L19.8 20 L13.8 14.8 Z',
    'l 3 15.6 17 15.6 1',
    'M6.2 15.4 L5.6 12.8 L7 15.4 Z',
  ],
  'tit': [
    'e 12 13 4.5 3.5',
    'e 8.2 10 2.4 2.2',
    'M6 9.8 L4 10.2 L6 10.6 Z',
    'M15.4 11.6 L18.4 5.4 L19.6 6 L17 12.6 Z',
    'l 11 16 10.5 20 0.8',
    'l 13 16 13.4 20 0.8',
  ],
  'warbler': [
    'e 12 12 4.5 2.4 -20',
    'e 7.8 9 2 1.8',
    'M6 8.8 L3.6 9.1 L6 9.6 Z',
    'M15.5 12.8 L20.4 16.6 L15 14.6 Z',
    'l 3 15 21 18.6 0.8',
  ],
  'thrush': [
    'e 12 12 4.5 3.6 -25',
    'e 8 7.6 2.3 2.2',
    'M5.9 7.3 L3.4 8 L6 8.4 Z',
    'M15.5 14 L20 18 L19 19 L14.5 15.5 Z',
    'l 11 15 10.5 20.5 0.9',
    'l 12.6 15 12.8 20.5 0.9',
  ],
  'finch': [
    'e 12 12.5 4.5 3.6 -15',
    'e 8 8.6 2.6 2.5',
    'M5.7 7.8 L3.2 9.2 L5.7 10.6 Z',
    'M15.5 13.4 L20.2 14.8 L19.2 15.8 L20.2 17 L15 15.6 Z',
    'l 11 15.8 10.6 20 0.9',
    'l 13 15.8 13.2 20 0.9',
  ],
  'lark': [
    'e 11.5 12 5 2.6 -5',
    'e 6.5 9.6 1.9 1.8',
    'M4.9 9.4 L2.6 9.9 L4.9 10.3 Z',
    'M15.5 11.4 L23 12.4 L23 13.8 L15.5 14 Z',
    'l 10.5 14.4 10 20 0.8',
    'l 12 14.4 12.6 20 0.8',
  ],
};

Path _shape(String s) {
  final t = s.split(' ');
  double n(int i) => double.parse(t[i]);
  if (t[0] == 'e') {
    final oval = Path()
      ..addOval(
        Rect.fromCenter(center: Offset.zero, width: n(3) * 2, height: n(4) * 2),
      );
    final m = Matrix4.translationValues(n(1), n(2), 0)
      ..rotateZ((t.length > 5 ? n(5) : 0) * pi / 180);
    return oval.transform(m.storage);
  }
  if (t[0] == 'l') {
    return Path()
      ..addPolygon(_line(Offset(n(1), n(2)), Offset(n(3), n(4)), n(5)), true);
  }
  // M L Q C Z, absolute, each command glued to its first number ('M4.8 10.5').
  final p = Path();
  final v = <double>[];
  String? cmd;
  void flush() {
    switch (cmd) {
      case 'M':
        p.moveTo(v[0], v[1]);
      case 'L':
        p.lineTo(v[0], v[1]);
      case 'Q':
        p.quadraticBezierTo(v[0], v[1], v[2], v[3]);
      case 'C':
        p.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]);
    }
    v.clear();
  }

  for (final w in t) {
    if (w.isEmpty) continue;
    if (RegExp('[MLQCZ]').hasMatch(w[0])) {
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

List<Offset> _line(Offset a, Offset b, double w) {
  final d = b - a;
  final o = Offset(-d.dy, d.dx) / d.distance * (w / 2);
  return [a + o, b + o, b - o, a - o];
}

final _paths = <String, Path>{};

/// The group's silhouette on the 24×24 grid.
Path groupPath(String group) => _paths.putIfAbsent(group, () {
  var out = Path();
  for (final s in _shapes[group]!) {
    final cut = s.startsWith('-');
    out = Path.combine(
      cut ? PathOperation.difference : PathOperation.union,
      out,
      _shape(cut ? s.substring(1) : s),
    );
  }
  return out;
});

class _GroupPainter extends CustomPainter {
  const _GroupPainter(this.group, this.color);
  final String group;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(groupPath(group), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GroupPainter old) =>
      old.group != group || old.color != color;
}

/// The bird's group in a glass circle (nothing for a family not mapped yet).
class FamilyBadge extends StatelessWidget {
  const FamilyBadge(this.family, {this.size = 34, super.key});
  final String family;
  final double size;

  @override
  Widget build(BuildContext context) {
    final group = familyGroup(family);
    if (group == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: CustomPaint(painter: _GroupPainter(group, Colors.white)),
          ),
        ),
      ),
    );
  }
}
