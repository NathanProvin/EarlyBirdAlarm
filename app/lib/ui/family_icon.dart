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
  'cuckoo': ['Cuculidae'],
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
  ],
  'woodpecker': [
    'Picidae',
    'Certhiidae',
    'Furnariidae',
    'Climacteridae',
    'Tichodromidae',
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

/// The bird's group silhouette, white on the 24×24 grid (nothing for an unmapped family).
Widget? groupIcon(String family) => switch (familyGroup(family)) {
  final g? => CustomPaint(painter: _GroupPainter(g, Colors.white)),
  null => null,
};

const _habitatIcons = <String, IconData>{
  'forest': Icons.forest,
  'woodland': Icons.park,
  'shrubland': Icons.eco,
  'grassland': Icons.grass,
  'wetland': Icons.water,
  'riverine': Icons.waves,
  'coastal': Icons.beach_access,
  'marine': Icons.sailing,
  'desert': Icons.wb_sunny,
  'rock': Icons.landscape,
  'human_modified': Icons.location_city,
};
const _dietIcons = <String, IconData>{
  'frugivore': Icons.energy_savings_leaf,
  'granivore': Icons.grain,
  'nectarivore': Icons.local_florist,
  'herbivore_aquatic': Icons.spa,
  'herbivore_terrestrial': Icons.grass,
  'invertivore': Icons.pest_control,
  'vertivore': Icons.cruelty_free,
  'aquatic_predator': Icons.set_meal,
  'scavenger': Icons.recycling,
  'omnivore': Icons.restaurant,
};

/// AVONET's word as a key: "Human Modified" -> human_modified.
String traitKey(String avonet) => avonet.toLowerCase().replaceAll(' ', '_');

IconData? habitatIcon(String? h) =>
    h == null ? null : _habitatIcons[traitKey(h)];
IconData? dietIcon(String? d) => d == null ? null : _dietIcons[traitKey(d)];

/// A glass cartridge tinted with [color], the height of the card's play button: [icon]
/// alone, and a tap slides out [label] ("Family · Turdidae") for 3 s.
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
  Widget build(BuildContext context) {
    final color = widget.color;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _toggle,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
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
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(dimension: 27, child: widget.icon),
                    if (_open)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6, right: 6),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
