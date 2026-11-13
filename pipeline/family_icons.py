"""Bird group icons from PhyloPic (public domain: CC0 / Public Domain Mark only).

  py family_icons.py candidates   fetches up to 10 silhouettes per group into
                                  cache/family_icons/ and writes candidates.json (24 grid)
  py family_icons.py build        the picks below -> app/lib/ui/family_paths.dart

A pick is (image uuid, crop, flip): crop (x0, y0, x1, y1) in 0..1 of the silhouette's
box keeps a part of it (a head and bill profile); flip mirrors it so the bird faces left.
"""
import json
import re
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).parent
CACHE = HERE / "cache/family_icons"
API = "https://api.phylopic.org"
OUT = HERE.parent / "app/lib/ui/family_paths.dart"

# The clade searched for each group's candidates (a family, or a genus for a profile).
SEARCH = {
    "duck": ["Anatidae"], "gamebird": ["Phasianidae", "Odontophoridae"],
    "diver": ["Podicipedidae", "Gaviidae"], "pigeon": ["Columbidae"],
    "cuckoo": ["Cuculidae"], "nightjar": ["Caprimulgidae"],
    "swift": ["Apodidae", "Hirundinidae"], "hummingbird": ["Trochilidae"],
    "rail": ["Rallidae"], "heron": ["Ardeidae", "Gruidae"],
    "shorebird": ["Scolopacidae", "Recurvirostridae"], "gull": ["Laridae"],
    "auk": ["Alcidae"], "seabird": ["Procellariidae", "Diomedeidae"],
    "cormorant": ["Phalacrocoracidae", "Pelecanidae"], "raptor": ["Accipitridae"],
    "falcon": ["Falconidae"], "owl": ["Strigidae", "Tytonidae"],
    "kingfisher": ["Alcedinidae", "Ramphastidae"], "woodpecker": ["Picidae"],
    "parrot": ["Psittacidae", "Psittaciformes"], "crow": ["Corvidae"],
    "flycatcher": ["Tyrannidae", "Bombycillidae"], "shrike": ["Laniidae"],
    "tit": ["Paridae", "Troglodytidae", "Sittidae"], "warbler": ["Parulidae", "Sylviidae", "Phylloscopidae"],
    "thrush": ["Turdidae", "Sturnidae"], "finch": ["Fringillidae", "Cardinalidae"],
    "lark": ["Motacillidae", "Alaudidae"],
}

PICKS = {  # group -> (uuid, crop or None, flip)
    "duck": ("16313909-e337-4eef-9ab3-7f77cc8da4ce", None, False),  # Aythya collaris
    "gamebird": ("c7e2cbb6-d375-48eb-a49d-5eed0147d035", None, True),  # Perdix perdix
    "diver": ("deba1d91-daa8-40a6-8d48-7a9f295bc662", None, False),  # Podiceps cristatus
    "pigeon": ("310b4994-af54-4d7b-93ac-27bbf80f7706", None, False),  # Columba livia
    "cuckoo": ("5311f33f-6db1-47b0-94c4-c60fa7521884", None, True),  # Cuculinae
    "nightjar": ("19899811-afff-4ba8-8084-cc7fe762da7e", None, True),  # Caprimulgus
    "swift": ("cf38be70-f0a8-4a47-b387-e797ec16c7c1", None, True),  # Hirundo rustica
    "hummingbird": ("618b6a9d-6aa6-4316-bf25-2a7a3f788e88", None, False),  # Archilochus colubris
    "rail": ("cd5ca1a2-b0a9-4ce9-b163-5c004e327d9d", None, False),  # Rallus
    "heron": ("afaed2dc-f0e9-442a-bae2-7ef437033356", None, False),  # Egretta rufescens
    "shorebird": ("057a14be-9294-4877-8041-55668e3bd759", None, False),  # Gallinago stricklandii
    "gull": ("71526878-5cc3-4456-8785-69336ac3c93e", None, False),  # Rissa tridactyla
    "auk": ("18ff6244-3ec9-4750-a29a-aaad7e2f14ad", None, False),  # Fratercula arctica
    "seabird": ("deb35243-40b4-42ae-b538-846d72e4ec98", None, False),  # Macronectes halli
    "cormorant": ("b901c16b-7a36-4533-81cc-e8e38b387c86", None, False),  # Phalacrocorax carbo
    "raptor": ("2ed36bac-299a-4c53-b6c5-3077ebee048a", None, False),  # Accipiter gentilis
    "falcon": ("9db60762-6b38-475e-a013-a9e7b71bc46a", None, False),  # Falco tinnunculus
    "owl": ("54236b89-b197-4918-b9c8-92f576505c4f", None, False),  # Aegolius acadicus
    "kingfisher": ("632580ed-9bf0-4e01-b3b6-3cf31fcf417e", (0, 0, 0.7, 0.5), False),  # Alcedo atthis
    "woodpecker": ("91fff72a-a346-4207-8f61-8386254f031a", None, True),  # Dryocopus martius
    "parrot": ("d791cad7-c2bc-41ed-9ec2-d49e0e3152bb", (0.35, 0, 1, 0.35), True),  # Psittacus erithacus
    "crow": ("f0662de3-3161-4db6-b7bf-1b69e408b242", None, False),  # Corvus brachyrhynchos
    "flycatcher": ("5cdb0c82-1cd3-4ce7-bf3c-e5228d2517e6", None, False),  # Tyrannus forficatus
    "shrike": ("4d96aa6b-ef47-48c7-a069-ac01668fbf67", None, True),  # Laniidae
    "tit": ("1e43b8d5-7cd1-492f-830e-3bbf13001510", None, True),  # Nannus hiemalis
    "warbler": ("076f4f45-4b4f-4982-a04f-7b133e3b0464", None, False),  # Mniotilta varia
    "thrush": ("ec11f62e-ed3e-49bb-bcff-4e47b281d378", None, True),  # Turdus merula
    "finch": ("6174bd27-8161-44c0-8629-293f3b618db3", None, True),  # Loxia curvirostra
    "lark": ("f4327bb3-76b9-4f60-b407-45e2c9ac602b", None, True),  # Motacilla alba
}


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "bird-icons-pipeline"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read()


def build_no():
    import urllib.error
    try:
        get(API + "/nodes?build=1&filter_name=aves")
    except urllib.error.HTTPError as e:  # an outdated build index names the current one
        return json.loads(e.read())["build"]


def images(clade, build):
    q = f"{API}/nodes?build={build}&filter_name={clade.lower()}&page=0"
    items = json.loads(get(q))["_links"]["items"]
    if not items:
        return []
    node = items[0]["href"].split("/")[2].split("?")[0]
    q = (f"{API}/images?build={build}&filter_clade={node}&filter_license_by=false"
         "&filter_license_nc=false&filter_license_sa=false&embed_items=true&page=0")
    out = []
    for i in json.loads(get(q)).get("_embedded", {}).get("items", []):
        lic = i["_links"]["license"]["href"]
        if "publicdomain" not in lic:
            continue
        out.append((i["uuid"], i["_links"]["specificNode"].get("title", ""), lic))
    return out


def svg(uuid):
    f = CACHE / f"{uuid}.svg"
    if not f.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        f.write_bytes(get(f"https://images.phylopic.org/images/{uuid}/vector.svg"))
    return f.read_text(encoding="utf-8")


def subpaths(text):
    """Every path as absolute cubic subpaths [[(x, y) start, (c1, c2, p), ...]] in SVG
    user units (the potrace group's translate / scale applied)."""
    tx, ty, sx, sy = 0.0, 0.0, 1.0, 1.0
    m = re.search(r'transform="translate\(([-\d.]+),([-\d.]+)\) scale\(([-\d.]+),([-\d.]+)\)"', text)
    if m:
        tx, ty, sx, sy = map(float, m.groups())
    out = []
    for d in re.findall(r'<path[^>]*\sd="([^"]+)"', text):
        toks = re.findall(r"[MmLlCcZzHhVvSsQq]|-?[\d.]+(?:e-?\d+)?", d)
        i, cmd, x, y, sx0, sy0 = 0, None, 0.0, 0.0, 0.0, 0.0
        cur = None
        last_c2 = None

        def num():
            nonlocal i
            i += 1
            return float(toks[i - 1])

        while i < len(toks):
            if re.match(r"[A-Za-z]", toks[i]):
                cmd = toks[i]
                i += 1
                if cmd in "Zz":
                    if cur:
                        cur.append(("L", (sx0, sy0)))
                    x, y = sx0, sy0
                    cur = None
                    continue
            rel = cmd.islower()
            c = cmd.upper()
            bx, by = (x, y) if rel else (0.0, 0.0)
            if c == "M":
                x, y = bx + num(), by + num()
                sx0, sy0 = x, y
                cur = [(x, y)]
                out.append(cur)
                cmd = "l" if rel else "L"  # later pairs are lines
            elif c == "L":
                x, y = bx + num(), by + num()
                cur.append(("L", (x, y)))
            elif c == "H":
                x = bx + num()
                cur.append(("L", (x, y)))
            elif c == "V":
                y = (y if rel else 0.0) + num()
                cur.append(("L", (x, y)))
            elif c == "C":
                c1 = (bx + num(), by + num())
                c2 = (bx + num(), by + num())
                x, y = bx + num(), by + num()
                cur.append(("C", c1, c2, (x, y)))
                last_c2 = c2
            elif c == "S":
                c1 = (2 * x - last_c2[0], 2 * y - last_c2[1]) if last_c2 else (x, y)
                c2 = (bx + num(), by + num())
                x, y = bx + num(), by + num()
                cur.append(("C", c1, c2, (x, y)))
                last_c2 = c2
            elif c == "Q":
                q1 = (bx + num(), by + num())
                x0, y0 = x, y
                x, y = bx + num(), by + num()
                cur.append(("C", (x0 + 2 / 3 * (q1[0] - x0), y0 + 2 / 3 * (q1[1] - y0)),
                            (x + 2 / 3 * (q1[0] - x), y + 2 / 3 * (q1[1] - y)), (x, y)))
            if c not in "CS":
                last_c2 = None
    T = lambda p: (tx + sx * p[0], ty + sy * p[1])
    res = []
    for sp in out:
        r = [T(sp[0])]
        for seg in sp[1:]:
            r.append((seg[0], *[T(p) for p in seg[1:]]))
        res.append(r)
    return res


def to_grid(sps, crop=None, flip=False, size=24.0, margin=1.0):
    pts = [p for sp in sps for p in [sp[0]] + [q for s in sp[1:] for q in s[1:]]]
    x0, x1 = min(p[0] for p in pts), max(p[0] for p in pts)
    y0, y1 = min(p[1] for p in pts), max(p[1] for p in pts)
    if crop:  # the crop box, in the silhouette's box (the app clips to it)
        cx0, cy0, cx1, cy1 = crop
        x0, x1 = x0 + cx0 * (x1 - x0), x0 + cx1 * (x1 - x0)
        y0, y1 = y0 + cy0 * (y1 - y0), y0 + cy1 * (y1 - y0)
    k = (size - 2 * margin) / max(x1 - x0, y1 - y0)
    ox = margin + ((size - 2 * margin) - k * (x1 - x0)) / 2
    oy = margin + ((size - 2 * margin) - k * (y1 - y0)) / 2

    def f(p):
        x = ox + k * (p[0] - x0)
        if flip:
            x = size - x
        return f"{x:.1f} {oy + k * (p[1] - y0):.1f}".replace(".0 ", " ").removesuffix(".0")

    parts = []
    for sp in sps:
        parts.append("M" + f(sp[0]))
        for s in sp[1:]:
            parts.append(("L" if s[0] == "L" else "C") + " ".join(f(p) for p in s[1:]))
        parts.append("Z")
    return " ".join(parts)


if __name__ == "__main__":
    if sys.argv[1] == "candidates":
        b = build_no()
        cands = {}
        for g, clades in SEARCH.items():
            seen = []
            for c in clades:
                for uuid, name, lic in images(c, b):
                    if len(seen) < 10 and uuid not in [s[0] for s in seen]:
                        seen.append((uuid, name, lic))
            cands[g] = [{"uuid": u, "name": n, "path": to_grid(subpaths(svg(u)))}
                        for u, n, _ in seen if subpaths(svg(u))]  # skips non-potrace files
            print(g, len(seen), [n for _, n, _ in seen])
        (CACHE / "candidates.json").write_text(json.dumps(cands), encoding="utf-8")
    elif sys.argv[1] == "build":
        lines = []
        for g, (uuid, crop, flip) in PICKS.items():
            lines.append(f"  '{g}': '{to_grid(subpaths(svg(uuid)), crop, flip)}',")
            if crop:
                lines.append(f"  // {g}: cropped to the head")
        OUT.write_text(
            "// Generated by pipeline/family_icons.py from PhyloPic silhouettes (public domain:\n"
            "// CC0 / Public Domain Mark). Do not edit; change the picks there.\n\n"
            "const familyPaths = <String, String>{\n" + "\n".join(lines) + "\n};\n",
            encoding="utf-8")
        print("ok", len(PICKS))
