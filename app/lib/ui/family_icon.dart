import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'family_paths.dart';

/// Bird group icons (2026-11-13): each catalog family belongs to one group, drawn as a
/// public-domain PhyloPic silhouette (pipeline/family_icons.py) on a 24×24 grid. Shown
/// in a glass cartridge tinted with the rarity, at the bottom left of the card's photo,
/// beside the habitat and diet badges (AVONET).

const familyGroups = <String, List<String>>{
  'duck': ['Anatidae', 'Anseranatidae'],
  'gamebird': [
    'Phasianidae', 'Odontophoridae', 'Numididae', 'Cracidae', 'Tinamidae', //
    'Turnicidae', 'Otididae', 'Megapodiidae',
  ],
  'diver': ['Gaviidae', 'Podicipedidae'],
  'pigeon': ['Columbidae', 'Pteroclididae'],
  'cuckoo': ['Cuculidae', 'Musophagidae'],
  'nightjar': [
    'Caprimulgidae',
    'Nyctibiidae',
    'Aegothelidae',
    'Podargidae',
    'Steatornithidae',
  ],
  'swift': ['Apodidae', 'Hirundinidae'],
  'hummingbird': ['Trochilidae'],
  'rail': ['Rallidae', 'Heliornithidae'],
  'heron': [
    'Ardeidae', 'Ciconiidae', 'Threskiornithidae', 'Phoenicopteridae', //
    'Gruidae', 'Aramidae', 'Eurypygidae', 'Scopidae',
  ],
  'shorebird': [
    'Scolopacidae', 'Charadriidae', 'Haematopodidae', 'Recurvirostridae', //
    'Burhinidae',
    'Glareolidae',
    'Jacanidae',
    'Rostratulidae',
    'Pedionomidae',
    'Dromadidae',
  ],
  'gull': ['Laridae', 'Stercorariidae'],
  'auk': ['Alcidae'],
  'seabird': [
    'Procellariidae', 'Diomedeidae', 'Hydrobatidae', 'Phaethontidae', //
    'Fregatidae', 'Sulidae', 'Pelecanoididae',
  ],
  'cormorant': ['Phalacrocoracidae', 'Anhingidae', 'Pelecanidae'],
  'raptor': ['Accipitridae', 'Cathartidae', 'Pandionidae'],
  'falcon': ['Falconidae'],
  'owl': ['Strigidae', 'Tytonidae'],
  'kingfisher': [
    'Alcedinidae', 'Coraciidae', 'Meropidae', 'Momotidae', 'Upupidae', //
    'Trogonidae',
    'Ramphastidae',
    'Bucerotidae',
    'Coliidae',
    'Bucconidae',
    'Galbulidae',
    'Capitonidae',
    'Semnornithidae',
    'Lybiidae',
    'Megalaimidae',
    'Phoeniculidae',
  ],
  'woodpecker': [
    'Picidae',
    'Certhiidae',
    'Furnariidae',
    'Climacteridae',
    'Tichodromidae',
    'Indicatoridae',
  ],
  'parrot': ['Psittacidae', 'Cacatuidae', 'Psittaculidae'],
  'crow': [
    'Corvidae',
    'Cracticidae',
    'Corcoracidae',
    'Ptilonorhynchidae',
    'Paradisaeidae',
  ],
  'flycatcher': [
    'Tyrannidae', 'Cotingidae', 'Thamnophilidae', 'Bombycillidae', //
    'Ptilogonatidae',
    'Pipridae',
    'Formicariidae',
    'Grallariidae',
    'Conopophagidae',
    'Rhinocryptidae',
    'Sapayoaidae',
    'Monarchidae',
    'Rhipiduridae',
    'Petroicidae',
    'Platysteiridae',
    'Stenostiridae',
  ],
  'shrike': [
    'Laniidae',
    'Malaconotidae',
    'Prionopidae',
    'Vireonidae',
    'Campephagidae',
    'Artamidae',
    'Pachycephalidae',
    'Oreoicidae',
    'Machaerirhynchidae',
    'Dicruridae',
    'Hypocoliidae',
  ],
  'tit': [
    'Paridae', 'Aegithalidae', 'Remizidae', 'Panuridae', 'Troglodytidae', //
    'Sittidae', 'Cinclidae', 'Maluridae', 'Acanthisittidae', 'Neosittidae',
  ],
  'warbler': [
    'Parulidae', 'Phylloscopidae', 'Sylviidae', 'Acrocephalidae', //
    'Locustellidae', 'Cettiidae', 'Cisticolidae', 'Regulidae', 'Polioptilidae',
    'Scotocercidae', 'Peucedramidae', 'Zosteropidae', 'Leiothrichidae',
    'Pycnonotidae',
    'Nectariniidae',
    'Meliphagidae',
    'Acanthizidae',
    'Pardalotidae',
    'Dasyornithidae',
    'Dicaeidae',
    'Notiomystidae',
    'Timaliidae',
    'Pomatostomidae',
    'Macrosphenidae',
  ],
  'thrush': [
    'Turdidae', 'Muscicapidae', 'Mimidae', 'Sturnidae', 'Icteridae', //
    'Oriolidae',
    'Pittidae',
    'Psophodidae',
    'Orthonychidae',
    'Callaeatidae',
    'Menuridae',
    'Atrichornithidae',
    'Donacobiidae',
  ],
  'finch': [
    'Fringillidae', 'Passerellidae', 'Passeridae', 'Emberizidae', //
    'Calcariidae', 'Cardinalidae', 'Thraupidae', 'Estrildidae', 'Ploceidae',
    'Viduidae',
    'Rhodinocichlidae',
    'Prunellidae',
    'Spindalidae',
    'Mitrospingidae',
  ],
  'lark': ['Alaudidae', 'Motacillidae'],
  'ratite': [
    'Dromaiidae', 'Casuariidae', 'Struthionidae', 'Apterygidae', //
    'Dinornithidae', 'Emeidae',
  ],
  'penguin': ['Spheniscidae'],
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

class _PathPainter extends CustomPainter {
  const _PathPainter(this.path, this.color);
  final Path path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.clipRect(
      const Rect.fromLTWH(0, 0, 24, 24),
    ); // a head profile is cropped
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.path != path || old.color != color;
}

/// The bird's group silhouette, white on the 24×24 grid (nothing for an unmapped family).
Widget? groupIcon(String family) => switch (familyGroup(family)) {
  final g? => CustomPaint(painter: _PathPainter(groupPath(g), Colors.white)),
  null => null,
};

/// The card's badge diameter (40 until 2026-11-19, then 35, then 31.5).
const badgeSize = 31.5;

/// Trait icons Material lacks, on the 24×24 grid (holes wound the other way). Hand-drawn
/// with a throwaway script (fish, bushes, wetland, wave, dune and palm, town, banana, skull), or PhyloPic
/// public-domain silhouettes, simplified: oak Quercus robur, lily pad Nymphaea odorata,
/// grasshopper Arcyptera fusca, vole Microtus pennsylvanicus (2026-11-19).
const _traitPaths = <String, String>{
  'fish': 'M2 12 C4.5 7 11 6 15.5 10.2 L21.5 6.5 L19.6 12 L21.5 17.5 L15.5 13.8 C11 18 4.5 17 2 12 Z M6.6 10 C5.94 10 5.4 10.54 5.4 11.2 C5.4 11.86 5.94 12.4 6.6 12.4 C7.26 12.4 7.8 11.86 7.8 11.2 C7.8 10.54 7.26 10 6.6 10 Z',
  'bushes': 'M12.78 5.91 L13.31 5.98 L13.9 5.9 L14.49 5.98 L15.08 6.24 L15.57 6.66 L15.97 7.36 L16.1 8.16 L16.36 8.83 L16.48 9.49 L16.89 10.13 L17.09 10.86 L17.1 11.17 L16.45 11.1 L15.8 11.16 L15.19 11.35 L14.58 11.68 L14.14 12.06 L13.78 12.48 L13.51 12.96 L13.31 13.5 L12.39 13.5 L12.24 12.68 L11.89 11.88 L11.39 11.23 L10.71 10.67 L10.14 10.37 L9.45 10.17 L8.76 10.1 L8.09 10.16 L8.52 9.49 L8.73 8.55 L8.97 8.01 L9.31 7.49 L9.51 6.76 L9.98 6.11 L10.56 5.71 L11.23 5.52 L11.98 5.55 Z M7.35 11.01 L8.01 11.1 L8.82 11 L9.61 11.14 L10.05 11.32 L10.44 11.58 L11.04 12.22 L11.4 13.02 L11.5 13.82 L11.82 14.67 L11.97 15.49 L12.43 16.15 L12.68 16.84 L12.74 17.79 L12.49 18.72 L12.12 19.35 L11.6 19.87 L10.97 20.24 L10.26 20.46 L9.75 20.5 L9.26 20.46 L4.18 20.5 L3.59 20.43 L3.03 20.24 L2.29 19.77 L1.72 19.1 L1.36 18.3 L1.25 17.43 L1.31 16.91 L1.45 16.42 L1.68 15.96 L2.03 15.49 L2.29 14.32 L2.59 13.64 L3.01 12.98 L3.24 12.14 L3.54 11.61 L3.9 11.21 L4.39 10.86 L4.95 10.62 L5.55 10.51 L6.09 10.52 L6.61 10.64 Z M17.8 12.44 L18.36 12.51 L19.04 12.43 L19.77 12.56 L20.43 12.92 L20.93 13.46 L21.24 14.14 L21.32 14.82 L21.6 15.54 L21.73 16.24 L22.12 16.8 L22.33 17.39 L22.38 18.2 L22.17 18.98 L21.85 19.52 L21.41 19.96 L20.87 20.28 L20.27 20.46 L15.1 20.5 L14.6 20.44 L14.13 20.28 L13.59 19.96 L13.12 19.47 L13.46 18.71 L13.63 17.89 L13.61 16.92 L13.32 15.92 L13.61 14.95 L14.11 14.11 L14.22 13.6 L14.43 13.14 L14.74 12.73 L15.14 12.39 L15.7 12.12 L16.32 12 L17.01 12.07 Z',
  'oak': 'M2.33 13.08 L2.2 12.9 L1.88 12.94 L1.38 12.86 L1.3 12.7 L1.4 12.5 L1.1 12.4 L1.03 12.22 L1.17 12.04 L1.68 11.75 L2.5 11.5 L2.3 11.1 L2.7 11.2 L2.8 10.69 L2.6 10.5 L2.88 10.36 L2.76 10.01 L2.99 9.99 L3.2 9.6 L3.01 9.35 L3.3 9.3 L2.74 8.85 L2.8 8.3 L3.1 8.3 L3.11 8.22 L3.27 8.29 L3.01 8.04 L2.9 7.8 L3.4 7.6 L3.01 7.37 L3.59 6.98 L3.5 6.6 L3.6 6.4 L4.3 6.6 L4.5 6.4 L4.4 6.1 L4.6 6.2 L4.6 6 L4.7 5.9 L4.6 5.8 L4.6 5.4 L4.5 5.2 L5.16 5.18 L5.2 4.7 L5.38 4.67 L5.7 4.1 L5.8 4 L6 4 L6.4 3.7 L6.6 3.7 L6.5 3.1 L6.61 2.87 L7.31 3.14 L7.5 3.3 L7.8 3.2 L7.72 3.01 L8.4 3 L8.4 2.8 L8.7 3.1 L8.8 3 L8.87 2.11 L9.2 2.4 L9.2 2.1 L9.6 2.3 L9.6 2.1 L9.68 2.06 L10.35 1.97 L10.74 2.14 L10.9 2.3 L10.91 2.46 L11.6 2.1 L11.7 2 L11.62 1.81 L12 1.8 L12.7 1.4 L12.8 1.45 L12.73 1.89 L13.32 2.12 L13.9 2.6 L13.8 2.2 L15.1 2.5 L15.23 2.14 L15.6 1.8 L15.8 2.3 L15.8 2.8 L15.9 2.7 L16.1 3 L16.22 3.59 L16.3 3.6 L16.3 3.6 L16.3 3.6 L16.3 3.6 L16.3 3.6 L16.3 3.59 L16.3 3.57 L16.3 3.55 L16.3 3.5 L16.39 3.35 L16.4 3.2 L16.8 3.7 L17.1 3.7 L17.5 3.9 L18.2 3.5 L18.4 3.5 L18.3 4.1 L19.2 4 L19 4.3 L19 4.4 L19 4.4 L19.04 4.44 L19.17 4.5 L19.2 4.5 L19.29 4.5 L19.3 4.5 L19.3 4.4 L19.53 4.54 L19.8 5 L20.91 5.29 L20.4 5.8 L20.99 6.46 L21.2 7 L21.39 7.18 L21.1 7.3 L21 7.5 L21.8 7.4 L21.57 7.73 L21.1 7.81 L21 8 L21.2 7.9 L21.52 7.94 L22.2 8.3 L22 8.5 L22.1 8.5 L22.3 8.73 L22.57 9.21 L22.64 9.51 L22.4 9.7 L22.5 9.8 L22.5 10 L23 9.8 L22.8 10.6 L22.83 11.42 L22.71 11.87 L22.53 12.16 L21.9 12.5 L21.9 12.6 L22.47 12.77 L22.56 13.04 L22.3 13.2 L22.2 13.4 L22.2 13.8 L21.9 13.9 L21.91 14.22 L21.7 14.3 L21.78 14.47 L21.6 14.6 L21.1 14.6 L21.04 15.3 L20.9 15.34 L20.7 15.2 L20.5 15.2 L20.5 15.6 L20.4 15.6 L20.26 15.79 L19.6 15.9 L19.33 16.52 L18.88 16.92 L18.73 16.92 L18.63 16.78 L18.5 16.1 L18.13 16.06 L18 16.1 L18 16.3 L18.19 16.64 L18.12 16.89 L17.3 16.8 L16.85 16.6 L16.5 16.3 L16.2 16.3 L15.44 16.83 L14.8 17 L14.59 17.84 L14.13 18.65 L13.3 19.4 L12.7 19.6 L12.7 22.3 L12.4 22.6 L11 22.6 L10.8 22.3 L10.7 22.3 L10.7 19 L9.44 17.67 L8.4 16.1 L8.3 16.5 L8.49 16.66 L8.6 16.9 L8.02 16.91 L8 17 L7.7 17.1 L7.21 17.68 L6.64 17.89 L6.31 17.86 L6.1 17.7 L6.2 17.3 L5.8 17 L5.31 17.19 L5.3 16.8 L5.09 16.95 L4.77 17 L4.7 16.8 L3.53 16.68 L3.2 16.5 L2.55 16.39 L2.51 16.22 L2.7 16 L2.19 15.76 L2.2 15.5 L2.7 15.2 L3.08 14.43 L2.5 14.3 L2.51 14.22 L3 13.9 L3.3 13.9 L3.3 13.7 L3.4 13.6 L3 13.6 L2.9 13.5 L2.8 13.2 L2.89 13.18 L2.9 12.9 Z M6.2 17.3 L6.2 17.3 L6.2 17.3 Z M6.2 17.3 L6.2 17.3 L6.2 17.3 Z M19 4.4 L19 4.4 L19 4.4 Z M2.2 12.9 L2.2 12.9 L2.2 12.9 Z M20.49 15.2 L20.48 15.2 L20.49 15.2 Z M20.42 15.2 L20.42 15.2 L20.44 15.2 Z M18.3 4.1 L18.3 4.1 L18.3 4.1 Z M11 2.6 L10.93 2.5 L10.95 2.54 Z M7.4 4.7 L7.54 4.69 L7.7 4.6 L7.6 4.5 Z M16.9 4.8 L17 4.8 L16.91 4.62 L16.9 4.65 Z M20.34 7.4 L20.67 7.4 L20.8 7.4 L20.4 7.1 Z M21.2 9.1 L21.1 9.1 L21.1 9.2 Z M14.16 15.9 L14.7 15 L14.7 14.8 L14.5 14.6 L14.2 14.7 L14.1 14.5 L14.1 14.9 L14 14.9 L14.3 15.4 L13.8 15.4 L13.8 15.5 Z M14.2 15.9 L14.2 15.9 L14.2 15.9 Z M15.76 15.1 L15.6 15 L15.08 16.09 L15.5 15.8 L15.45 15.59 Z M9.45 15.41 L9.4 15.2 L9 15.2 L9.1 15.3 L9.2 15.8 L10.04 16.85 L10.7 17.5 L10.7 16.4 L10.1 16.1 L10.2 15.9 L9.86 15.84 Z M4.5 15.6 L4.3 15.8 L4.4 15.8 Z M4.88 15.77 L4.9 15.8 L4.9 15.7 Z M4.9 15.8 L4.9 15.8 L4.9 15.8 Z M12.8 16 L12.72 16.08 L12.7 16.7 L13.4 16.38 L14.1 16.2 L14.1 16 L13.7 16.1 Z M13.8 17.3 L13.6 17.3 L12.7 17.9 L12.7 18.5 L13.26 18.08 Z M9.6 2.1 L9.6 2.1 L9.6 2.1 Z M16.3 3.6 L16.3 3.6 L16.3 3.6 Z M19 4.4 L19 4.4 L19 4.4 Z M19.3 4.5 L19.3 4.5 L19.3 4.5 Z',
  'wetland': 'M13.19 6.06 L13.29 6.8 L13.28 7.59 L13.17 8.29 L12.96 8.81 L13.17 11.69 L13.47 10.64 L13.81 9.86 L14.24 9.14 L14.96 8.26 L15.59 7.66 L16.54 6.93 L17.85 6.11 L19 5.5 L17.11 7.96 L15.87 9.84 L13.77 13.83 L13.25 14.7 L13.2 15.2 L11.9 14.38 L10.51 12.09 L9.82 11.09 L9.04 10.14 L7.5 8.5 L8.42 8.83 L9.47 9.31 L10.24 9.75 L10.9 10.27 L11.45 10.87 L11.78 11.39 L12.11 12.16 L12.32 13.01 L12.09 9.24 L11.64 8.9 L11.21 8.24 L10.89 7.34 L10.72 6.33 L10.71 5.47 L10.83 4.71 L11.07 4.14 L11.38 3.81 L11.15 2.5 L11.23 2.25 L11.43 2.08 L11.78 2.09 L12.02 2.33 L12.34 4.07 L12.63 4.46 L12.86 4.93 Z M2.36 17.42 L1.85 17.04 L1.65 16.59 L1.67 16.34 L1.79 16.03 L2.17 15.72 L2.41 15.65 L2.74 15.69 L4.23 16.52 L4.67 16.64 L5.08 16.64 L5.9 16.34 L7.45 15.36 L8.16 14.99 L8.8 14.76 L9.44 14.66 L10.09 14.68 L10.9 14.91 L11.64 15.27 L13.48 16.41 L13.96 16.59 L14.38 16.65 L14.79 16.59 L15.27 16.41 L17.11 15.27 L17.89 14.89 L18.72 14.68 L19.59 14.68 L20.59 14.99 L21.81 15.68 L22.2 16.02 L22.35 16.5 L22.29 16.82 L22.1 17.1 L21.83 17.28 L21.5 17.35 L21.1 17.25 L20.29 16.74 L19.65 16.44 L19.22 16.35 L18.71 16.41 L17.96 16.74 L16.55 17.64 L15.84 18.01 L15.2 18.24 L14.56 18.34 L13.91 18.32 L13.1 18.09 L12.36 17.73 L10.65 16.66 L10.15 16.44 L9.72 16.35 L9.32 16.38 L8.86 16.53 L6.53 17.93 L5.91 18.18 L5.34 18.32 L4.69 18.34 L4 18.23 L3.22 17.93 Z M2.36 21.52 L1.85 21.14 L1.65 20.69 L1.67 20.44 L1.79 20.13 L2.17 19.82 L2.5 19.75 L2.74 19.79 L4.23 20.62 L4.67 20.74 L5.08 20.74 L5.9 20.44 L7.45 19.46 L8.16 19.09 L8.8 18.86 L9.44 18.76 L10.09 18.78 L10.9 19.01 L11.64 19.37 L13.48 20.51 L13.96 20.69 L14.38 20.75 L14.79 20.69 L15.27 20.51 L17.11 19.37 L17.89 18.99 L18.72 18.78 L19.59 18.78 L20.59 19.09 L21.81 19.78 L22.2 20.12 L22.35 20.6 L22.29 20.92 L22.1 21.2 L21.83 21.38 L21.5 21.45 L21.1 21.35 L20.29 20.84 L19.65 20.54 L19.22 20.45 L18.71 20.51 L17.96 20.84 L16.55 21.74 L15.84 22.11 L15.2 22.34 L14.56 22.44 L13.91 22.42 L13.1 22.19 L12.36 21.83 L10.65 20.76 L10.15 20.54 L9.72 20.45 L9.32 20.48 L8.86 20.63 L6.53 22.03 L5.91 22.28 L5.34 22.42 L4.69 22.44 L4 22.33 L3.22 22.03 Z',
  'wave': 'M21.63 12.36 L22.1 12.65 L22.31 12.88 L22.48 13.25 L22.48 13.66 L22.34 14.04 L22.05 14.33 L21.68 14.49 L21.27 14.5 L20.6 14.19 L19.52 13.23 L16.15 9.23 L14.58 7.62 L13.95 7.12 L13.35 6.75 L12.61 6.45 L12.06 6.36 L11.72 6.44 L10.91 6.42 L10.37 6.5 L9.87 6.68 L9.23 7.09 L8.9 7.45 L8.56 8.05 L8.41 8.69 L8.44 9.3 L8.72 9.99 L9.2 10.48 L9.47 10.63 L9.89 10.75 L10.52 10.68 L10.95 10.39 L11.14 9.96 L11.1 9.67 L10.79 9.31 L10.64 8.94 L10.64 8.63 L10.76 8.24 L11.03 7.93 L11.3 7.78 L11.7 7.71 L12.09 7.8 L12.45 8.05 L12.78 8.42 L13.15 9.2 L13.23 9.72 L13.22 10.16 L12.97 11.07 L12.67 11.57 L12.27 12.01 L11.78 12.38 L11.31 12.61 L10.68 12.79 L10.26 12.84 L9.58 12.81 L9.01 12.69 L8.27 12.36 L7.68 11.94 L7.17 11.4 L6.76 10.76 L6.48 10.04 L6.33 9.26 L6.33 8.45 L6.49 7.64 L6.98 6.57 L7.5 5.87 L8.25 5.22 L9.03 4.77 L10.27 4.39 L11.51 4.35 L11.86 4.27 L12.58 4.31 L13.43 4.52 L14.07 4.77 L14.9 5.25 L15.68 5.82 L16.46 6.52 L17.96 8.13 L20.57 11.29 Z M2.31 18.95 L1.77 18.66 L1.61 18.45 L1.51 18.11 L1.54 17.75 L1.65 17.51 L1.9 17.26 L2.14 17.14 L2.66 17.14 L3.89 17.6 L4.73 17.83 L5.32 17.91 L5.91 17.91 L7.13 17.65 L10.02 16.58 L10.83 16.39 L11.63 16.29 L12.51 16.31 L13.58 16.51 L14.38 16.76 L16.73 17.65 L17.96 17.91 L18.54 17.91 L19.34 17.79 L21.2 17.14 L21.55 17.11 L21.81 17.18 L22.1 17.37 L22.3 17.67 L22.36 17.93 L22.25 18.45 L21.88 18.81 L20.04 19.48 L18.64 19.72 L17.79 19.71 L16.73 19.53 L15.68 19.21 L13.34 18.33 L12.13 18.11 L11.54 18.12 L10.73 18.27 L7.67 19.38 L6.86 19.6 L6.07 19.71 L5.23 19.72 L4.36 19.61 L3.32 19.33 Z',
  'dune': 'M7.99 5.02 L8.36 4.57 L8.8 4.2 L9.28 3.97 L9.8 3.85 L10.37 3.85 L10.96 3.94 L12.4 4.4 L10.53 5.1 L8.87 5.82 L9.37 5.81 L9.95 5.89 L10.45 6.11 L10.87 6.45 L11.22 6.91 L11.51 7.47 L12 9 L10.24 7.74 L7.95 6.62 L8.01 8.84 L8.16 11.01 L8.4 13.18 L8.55 14.27 L8.75 15.56 L8.72 15.77 L8.61 15.96 L8.45 16.09 L8.18 16.15 L7.88 16.05 L7.69 15.8 L7.39 13.95 L7 10.31 L6.85 6.53 L4.09 7.49 L2 8.6 L2.42 7.72 L2.89 6.96 L3.3 6.44 L3.77 6.04 L4.3 5.76 L4.88 5.63 L5.53 5.63 L6.27 5.76 L3.2 3.6 L4.3 3.47 L5.29 3.51 L6.02 3.74 L6.6 4.19 L6.76 3.61 L7.07 3.12 L7.7 2.5 L8.4 2 Z M21.9 20.59 L22.63 20.91 L23 21 L1 21 L1.73 20.18 L4.3 17.02 L5.4 15.87 L6.13 15.21 L7.43 14.31 L7.65 15.69 L7.7 15.85 L7.83 16.02 L8.02 16.13 L8.24 16.16 L8.4 16.12 L8.54 16.04 L8.66 15.92 L8.73 15.78 L8.76 15.62 L8.49 13.81 L9.43 13.57 L10.17 13.5 L10.9 13.54 L12 13.78 L13.1 14.23 L14.2 14.84 L16.03 16.13 L20.07 19.39 L21.17 20.16 Z',
  'lilypad': 'M1.01 10.98 L1.2 9.8 L1.5 9.2 L1.93 8.74 L2.49 7.79 L2.7 7.7 L3.09 7.21 L3.7 6.7 L4.5 6.3 L5.2 5.8 L6.3 5.3 L8.4 4.7 L10.02 4.49 L10.58 4.3 L13.32 4.29 L14.2 4.2 L14.4 4.3 L16.16 4.3 L16.6 4.6 L17.5 4.8 L17.51 4.89 L17.9 5.1 L18.58 5.26 L18.8 5.5 L19.18 5.51 L19.2 5.6 L19.38 5.61 L19.4 5.7 L19.95 6.04 L20.9 6.5 L21 6.7 L21.5 6.9 L21.8 7.3 L22.3 7.7 L22.4 8.1 L22.52 8.16 L22.7 8.7 L22.8 8.7 L23 9.6 L23 10.9 L22.88 11.36 L22.6 11.6 L21.55 11.88 L20.67 11.97 L17.71 12.1 L15 12.1 L14.76 12.19 L14.01 12.21 L14 12.3 L14.62 12.64 L15.54 13.35 L17.94 15.54 L18.7 16.3 L19 17.1 L19 17.6 L18.64 17.64 L18.1 18 L18.1 18.1 L17.76 18.38 L16.95 18.84 L15.18 19.45 L14.3 19.6 L12.16 19.61 L10.87 19.74 L10.21 19.68 L9.75 19.55 L9.4 19.3 L7.7 18.9 L6.9 18.2 L6.15 18.25 L5.52 17.97 L5 17.6 L4.7 17.2 L4.29 17.07 L3.87 16.71 L3.14 15.92 L1.8 14.1 L1.33 13.08 L1.12 12.39 L1 11.52 L1.01 11.21 L1.14 11.08 Z',
  'banana': 'M7.16 4.01 L8.02 2.76 L10.48 4.49 L9.62 5.71 L9.03 5.36 L8.81 5.45 L8.72 5.67 L8.92 7.16 L9.26 8.78 L9.63 10.02 L10.2 11.48 L10.76 12.58 L11.56 13.89 L12.48 15.12 L13.32 16.05 L14.24 16.94 L15.26 17.77 L18.23 19.79 L18.55 20.18 L18.5 20.67 L18.07 20.98 L17.63 21.11 L16.79 21.22 L15.94 21.23 L15.08 21.14 L13.81 20.87 L12.17 20.26 L10.63 19.39 L9.23 18.28 L8.3 17.31 L7.24 15.87 L6.59 14.68 L5.94 13.02 L5.56 11.28 L5.45 9.95 L5.55 8.2 L5.81 6.92 L6.08 6.09 L6.41 5.31 L7.13 4.16 Z',
  'grasshopper': 'M13.3 6.2 L13.5 6.1 L14.2 6.1 L14.7 6.3 L14.94 6.63 L15.38 6.81 L15.47 6.96 L15.9 7.2 L16.1 7.2 L16.2 7.4 L16.4 7.4 L16.5 7.6 L16.78 7.61 L17 7.8 L17.3 7.8 L17.2 7.9 L17.6 8 L17.6 8.1 L17.89 8.12 L17.94 8.38 L18.19 8.47 L18.3 8.4 L18.5 8.7 L18.7 8.7 L18.8 8.6 L18.7 8.8 L19.1 8.9 L19.3 9.1 L19.6 9.1 L19.6 9.2 L19.9 9.4 L20.2 9.4 L20.22 9.49 L20.54 9.54 L20.98 9.48 L21.6 9.2 L22 9.2 L22.5 8.9 L22.4 8.7 L22.7 8.9 L22.8 9.2 L22.7 9.3 L22.14 9.32 L21.8 9.69 L20.85 9.91 L20.7 10 L20.8 10.1 L20.6 10.1 L20.6 10 L20.42 9.96 L20.42 10.06 L20.6 10.2 L20.43 10.2 L20.3 10 L20.1 10 L20 9.9 L19.94 9.97 L19.86 9.82 L19.7 9.8 L19.7 9.7 L19 9.5 L18.9 9.3 L18.65 9.29 L18.5 9.1 L17.8 8.8 L17.5 8.5 L17.3 8.5 L17.3 8.4 L17.1 8.3 L16.9 8.3 L16.9 8.2 L16.4 8 L15.7 7.6 L15.68 7.51 L15.5 7.5 L15.11 7.16 L14.7 7 L14.7 6.9 L14.2 6.7 L14.19 7.25 L13.13 8.29 L12.51 9.35 L12.22 10.07 L12.81 10.09 L13.6 9.75 L14.1 9.2 L14.35 9.05 L14.5 8.7 L14.89 8.24 L15.2 8.1 L15.2 8 L15.96 8.01 L16.39 8.25 L16.7 8.7 L16.9 8.7 L16.94 9.03 L17.22 9.37 L17.67 9.77 L17.7 9.9 L18 10 L18 10.2 L18.22 10.47 L18.4 10.5 L18.45 10.75 L18.8 10.8 L18.7 10.9 L18.7 11.1 L18.81 11.11 L19 11.4 L19.3 11.5 L19.2 11.6 L19.3 11.6 L19.5 11.9 L19.86 11.92 L19.7 12 L19.7 12.1 L19.91 12.29 L20.2 12.3 L20.1 12.5 L20.4 12.8 L20.6 12.8 L20.5 12.9 L20.8 13.2 L21 13.1 L21 13.3 L21.5 13.3 L21.6 13.22 L22.1 13.3 L22.1 13.2 L22.8 13.2 L22.8 13 L22.9 13 L22.98 13.46 L22.86 13.59 L22.2 13.6 L22.2 13.7 L21.76 13.62 L21.7 13.7 L20.9 13.7 L20.8 13.56 L20.74 13.77 L20.66 13.62 L20.2 13.3 L18.6 11.5 L18.6 11.4 L18.11 11.05 L18 10.8 L17.68 10.53 L17.37 11.54 L18.4 11.7 L18.7 11.9 L18.7 12.1 L17.7 12.4 L16.3 13.29 L14.6 13.9 L13.5 14.1 L13.46 14.19 L12.62 14.21 L12.41 14.39 L11 14.6 L11.03 14.76 L11.3 14.9 L11.51 15.29 L11.99 16.41 L12 16.8 L12.15 16.99 L12.5 17.11 L13.19 17.59 L13.1 17.9 L12.2 17.3 L12 17.3 L11.8 17.1 L11.58 16.17 L11.2 15.4 L10.8 14.9 L10.33 14.9 L10.2 14.8 L8.84 14.9 L7.6 14.6 L7 14 L7 13.9 L6.9 13.9 L6.9 13.8 L5.7 14.8 L4.96 15.06 L4.62 15.81 L4.5 16.7 L3.48 17.26 L3.3 17.5 L3.1 17.5 L3.2 17.3 L2.92 17.29 L2.9 17.2 L3.5 17.1 L3.5 17 L3.9 16.9 L4.1 16.6 L4.3 16.5 L4.5 15.57 L4.78 15.01 L4.71 14.92 L4.8 14.9 L4.81 14.71 L5.1 14.6 L5.1 14.5 L4.7 14.5 L4.4 14.2 L4.22 14.17 L3.8 13.7 L3.3 13.7 L2.8 14.3 L2.78 14.49 L2.46 14.98 L2.2 15 L2.17 15.1 L1.38 15.1 L1.03 15.19 L1.2 15.1 L1.1 14.8 L1.93 14.9 L2.27 14.78 L2.59 14.45 L2.8 13.9 L3.3 13.5 L3.35 13.26 L3.5 13.2 L3.31 12.72 L3.1 11.2 L2.6 10.6 L2.4 10.5 L1.91 9.58 L1.6 9.4 L1.1 8.9 L1.4 8.9 L1.9 9.4 L2.7 10.6 L2.9 10.7 L3.2 11.1 L3.3 10.9 L3.2 10.8 L3.2 10.6 L2.75 10.14 L1.5 8.1 L1.6 8.1 L1.8 8.4 L1.9 8.4 L2.38 9.36 L3.4 10.8 L3.95 10.5 L4.51 10.51 L4.6 10.6 L5.1 10.7 L5.5 10.5 L5.97 10.5 L6.1 10.4 L7.36 10.36 L8.31 10.5 L9.4 10.3 L9.98 10.29 L10.47 9.88 L10.54 9.72 L10.9 9.5 L11.2 9 L12.1 8.3 L12.7 7.5 L12.8 6.8 Z M15.7 9.2 L15.48 9.47 L15.1 9.6 L15.1 9.7 L14.82 9.81 L14.8 9.9 L15.8 9.9 L16.23 10.39 L16.44 10.5 L16.7 10.4 L17.2 10.4 L17.37 10.29 L16.6 9.4 L16.6 9.3 L16.3 9.1 L16.3 9 L16.02 8.72 L15.9 8.7 Z M15.5 9.4 L15.5 9.4 L15.5 9.4 Z M5.87 14.1 L6.3 13.9 L6.1 13.6 L5.9 13.7 Z M19.4 11.5 L19.39 11.57 L19.3 11.5 Z M6.1 14 L6.1 14 L6.1 14 Z M6.2 13.8 L6.2 13.8 L6.2 13.8 Z M16.8 7.6 L16.8 7.6 L16.8 7.6 Z M16.82 7.6 L16.82 7.6 L16.82 7.6 Z M16.85 7.6 L16.84 7.6 L16.89 7.6 Z M16.9 7.6 L16.9 7.6 L16.9 7.6 Z M18.35 8.4 L18.34 8.4 L18.37 8.4 Z M18.4 8.4 L18.4 8.4 L18.4 8.4 Z M17.31 9.28 L17.3 9.2 L17.4 9.2 Z M17.3 9.4 L17.3 9.3 L17.4 9.3 L17.38 9.37 Z M18.9 9.5 L18.9 9.5 L18.9 9.5 Z M18.97 9.5 L19 9.5 L18.95 9.5 Z M19.4 9.8 L19.4 9.8 L19.4 9.8 Z M19.91 10.04 L19.9 10 L19.94 10.01 Z M1 14.7 L1.1 14.7 L1.1 14.8 L1 14.8 Z',
  'vole': 'M12.01 6.7 L12.9 6.7 L14.87 7.39 L15.42 7.78 L17.02 9.51 L17.5 10.4 L17.9 11.8 L18.1 12.93 L17.87 13.99 L17.3 15.1 L20.4 15.3 L22.71 15.26 L23 15.4 L22.97 15.78 L19.82 15.9 L16.8 15.8 L16.71 16.26 L17.08 16.95 L16.83 17.1 L16.51 16.86 L16.5 17.3 L15.8 17.1 L15.5 17.3 L15.23 17.27 L15.21 17.1 L15 17.2 L14.6 17.2 L14.79 16.61 L14.9 16.5 L15.6 16.4 L15.6 16.1 L15.4 16.2 L14.6 16.2 L13.19 16.39 L10.05 16.43 L8.5 16.7 L7.9 17.2 L6.42 17.19 L5.7 17 L5.76 16.81 L5.5 16.71 L4.78 16.74 L4.5 16.47 L4.5 16.3 L4.79 16.12 L5.5 16.2 L6.1 15.9 L6.28 15.45 L6.1 14.91 L5.27 14.51 L3.3 14.3 L2.8 14.1 L2.14 13.99 L1.57 13.72 L1.07 13.16 L1.07 12.57 L2.1 10.3 L2.97 9.43 L4.77 8.27 L4.8 8 L5.26 7.25 L5.7 7.1 L6 7.7 L8.59 7.69 L9.7 7.4 L10.7 6.9 Z M7.83 15.83 L7.2 15.8 L6.96 15.91 L6.72 16.19 L6.69 16.49 L7.15 16.49 L7.42 16.39 L7.9 16 Z',
  'town': 'M2.5 9 L1.6 9 L6.5 4 L11.4 9 L10.5 9 L10.5 15.5 L7.5 15.5 L7.5 11.5 L5.5 11.5 L5.5 15.5 L2.5 15.5 Z M14.06 14.5 L13.68 21 L9.84 21 L11.72 15.18 L12.5 14.5 Z M14.7 14.5 L16.84 14.5 L18.17 21 L14.32 21 Z M17.49 14.5 L20.5 14.5 L23 21 L18.82 21 Z M9.18 21 L5 21 L10.79 15.99 L9.2 20.9 Z',
  'skull': 'M8.5 5.6 L12 5.5 L15.5 5.6 L18.5 5 L20.6 3.2 L21.8 0.9 L22.4 3 L21.6 6 L19.4 8.2 L16.6 8.9 L16.2 11 L14.9 13.2 L14.3 15.5 L14.4 19.5 L13.6 21.6 L12 22.2 L10.4 21.6 L9.6 19.5 L9.7 15.5 L9.1 13.2 L7.8 11 L7.4 8.9 L4.6 8.2 L2.4 6 L1.6 3 L2.2 0.9 L3.4 3.2 L5.5 5 Z M11.1 10.26 L10.97 9.57 L10.64 9.04 L10.17 8.7 L9.63 8.6 L9.1 8.76 L8.66 9.16 L8.38 9.73 L8.3 10.43 L8.45 11.06 L8.76 11.56 L9.23 11.9 L9.77 12 L10.27 11.85 L10.71 11.47 L11.01 10.91 Z M15.7 10.26 L15.57 9.57 L15.24 9.04 L14.77 8.7 L14.23 8.6 L13.7 8.76 L13.26 9.16 L12.98 9.73 L12.9 10.43 L13.05 11.06 L13.36 11.56 L13.83 11.9 L14.37 12 L14.87 11.85 L15.31 11.47 L15.61 10.91 Z M11.55 19.58 L11.48 19.16 L11.28 18.83 L11.01 18.7 L10.74 18.81 L10.54 19.12 L10.45 19.56 L10.51 20 L10.68 20.34 L10.97 20.5 L11.26 20.39 L11.48 20.04 Z M13.55 19.58 L13.48 19.16 L13.28 18.83 L13.01 18.7 L12.74 18.81 L12.54 19.12 L12.45 19.56 L12.51 20 L12.68 20.34 L12.97 20.5 L13.26 20.39 L13.48 20.04 Z',
};

/// A habitat or diet icon: a Material icon, or one of [_traitPaths] by name.
const _habitatIcons = <String, Object>{
  'forest': Icons.forest,
  'woodland': 'oak',
  'shrubland': 'bushes',
  'grassland': Icons.grass,
  'wetland': 'wetland',
  'riverine': Icons.waves,
  'coastal': Icons.beach_access,
  'marine': 'wave',
  'desert': 'dune',
  'rock': Icons.landscape,
  'human_modified': 'town',
};
const _dietIcons = <String, Object>{
  'frugivore': 'banana',
  'granivore': Icons.grain,
  'nectarivore': Icons.local_florist,
  'herbivore_aquatic': 'lilypad',
  'herbivore_terrestrial': Icons.eco,
  'invertivore': 'grasshopper',
  'vertivore': 'vole',
  'aquatic_predator': 'fish',
  'scavenger': 'skull',
  'omnivore': Icons.restaurant,
};

/// AVONET's word as a key: "Human Modified" -> human_modified.
String traitKey(String avonet) => avonet.toLowerCase().replaceAll(' ', '_');

final _traitPathCache = <String, Path>{};

Widget? _traitIcon(Object? v) => switch (v) {
  final IconData i => Icon(i, color: Colors.white, size: badgeSize * 0.74),
  final String name => CustomPaint(
    painter: _PathPainter(
      _traitPathCache.putIfAbsent(
        name,
        () => parseIconPath(_traitPaths[name]!),
      ),
      Colors.white,
    ),
  ),
  _ => null,
};

Widget? habitatIcon(String? h) =>
    h == null ? null : _traitIcon(_habitatIcons[traitKey(h)]);
Widget? dietIcon(String? d) =>
    d == null ? null : _traitIcon(_dietIcons[traitKey(d)]);

/// Every habitat and diet key (AVONET's words as keys), for the dev badge sheet.
Iterable<String> get habitatKeys => _habitatIcons.keys;
Iterable<String> get dietKeys => _dietIcons.keys;

/// A glass circle tinted with [color] showing [icon]; a tap slides [label] ("Family ·
/// Turdidae") out of it on the same cartridge for 3 s (the 2026-11-15 design, back on
/// 2026-11-19 instead of a tooltip), text sized to the badge.
class GlassBadge extends StatefulWidget {
  const GlassBadge({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });
  final Widget icon;
  final String label;
  final Color color;

  @override
  State<GlassBadge> createState() => _GlassBadgeState();
}

class _GlassBadgeState extends State<GlassBadge> {
  bool _open = false;
  Timer? _close;

  void _toggle() {
    unawaited(HapticFeedback.selectionClick());
    _close?.cancel();
    setState(() => _open = !_open);
    if (_open) {
      _close = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _open = false);
      });
    }
  }

  @override
  void dispose() {
    _close?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: _toggle,
      child: _Glass(
        color: widget.color,
        radius: badgeSize / 2,
        child: SizedBox(
          height: badgeSize,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(badgeSize * 0.13),
                  child: SizedBox.square(
                    dimension: badgeSize * 0.74,
                    child: widget.icon,
                  ),
                ),
                if (_open)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: badgeSize * 0.35),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: badgeSize * 0.4,
                          shadows: const [
                            Shadow(color: Color(0x99000000), blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// "📷 2/6" (2026-11-17, "Art 2/6" until 2026-11-19): which of the species' photos the card shows, in italics at the
/// stat names' size, on a rounded glass cartridge like the badges.
class ArtLabel extends StatelessWidget {
  const ArtLabel(this.art, {required this.color, super.key});
  final (int, int) art;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    // A serif italic, lighter glass (user, 2026-11-17); 15 % larger, a camera for "Art"
    // (2026-11-19).
    final textStyle = style?.copyWith(
      color: Colors.white,
      fontFamily: 'serif',
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
      fontSize: (style.fontSize ?? 14) * 0.77,
      shadows: const [Shadow(color: Color(0x99000000), blurRadius: 2)],
    );
    return _Glass(
      color: color,
      radius: 9,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera,
              color: Colors.white,
              size: (style?.fontSize ?? 14) * 0.85,
              shadows: const [Shadow(color: Color(0x99000000), blurRadius: 2)],
            ),
            const SizedBox(width: 3),
            Text('${art.$1}/${art.$2}', style: textStyle),
          ],
        ),
      ),
    );
  }
}

/// Frosted glass tinted with [color], with a light rim: the badges' and Art's cartridge.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.color,
    required this.radius,
    required this.child,
  });
  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: color.withValues(
            alpha: 0.18,
          ) /* Art's; the badges' since 2026-11-19 */,
          border: Border.all(
            color: Color.lerp(
              color,
              Colors.white,
              0.45,
            )!.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        child: child,
      ),
    ),
  );
}
