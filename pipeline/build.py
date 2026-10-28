"""Builds the Early Bird content for every region of Europe and North America.

Run from the repo root:  py pipeline/build.py            (all regions)
                         py pipeline/build.py N48E002,FR (a few regions, for testing)
                         py pipeline/build.py fallback   (copy the offline birds into the app)
Reads GBIF (presence, taxonomy), Wikidata (EN/FR names, photo), Wikimedia Commons (photo
credits), xeno-canto (recordings), AVONET and Wikipedia (card stats), then writes the static
site to pipeline/site/v1/ (published on GitHub Pages) and pipeline/report.md.
Every download is cached in pipeline/cache/, so re-runs are fast.
"""

import csv
import hashlib
import html
import json
import re
import subprocess
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

MY_NAME = "Nathan Provin"  # credit for your own photos without a credits.csv line
# Rarity tiers: minimum share of the month's bird records for the first four;
# "legendary" only needs RARE_MIN records that month (filters out one-off errors).
TIERS = ["common", "uncommon", "rare", "epic", "legendary"]
SHARES = [0.01, 0.0025, 0.0005, 0.0001]
RARE_MIN = 20
MIN_RECORDS = 1000  # regions (mostly sea cells) with fewer bird records a year are skipped
AVONET_URL = "https://ndownloader.figshare.com/files/34480856"  # Tobias et al. 2022, CC BY 4.0

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / "cache"
OUT = ROOT / "site" / "v1"
MY_PHOTOS = ROOT / "my_photos"
FFMPEG = ROOT.parent / ".tools" / "ffmpeg" / "bin" / "ffmpeg.exe"
UA = "EarlyBirdAlarm-pipeline/0.1 (https://github.com/NathanProvin/EarlyBirdAlarm)"

# Licenses that allow commercial use. Anything else (NC, ND, unknown) is rejected.
# GFDL is free but needs the full license text shipped with the photo, so it's left out too.
OK_LICENSE = re.compile(r"^(cc0|public domain|pd|attribution|cc[ -]by([ -]sa)?([ -]\d\.\d)?)(\b.*)?$", re.I)
XC_OK_LICENSE = re.compile(r"creativecommons\.org/(publicdomain/zero|licenses/(by|by-sa)/)", re.I)
# Non-commercial fallback (decided 2026-10-28): only for species with no free recording, flagged "nc"
# in species.json so they can be replaced before any monetization. ND is never used (we trim clips).
XC_NC_LICENSE = re.compile(r"creativecommons\.org/licenses/(by-nc|by-nc-sa)/", re.I)


def get(url, params=None, headers=None, binary=False):
    """GET with a disk cache keyed by the full URL (the xeno-canto key is left out of the key)."""
    if params:
        url += "?" + urllib.parse.urlencode(params, doseq=True)  # lists = repeated params
    cache_key = re.sub(r"key=[^&]+", "", url)
    path = CACHE / "http" / hashlib.sha1(cache_key.encode()).hexdigest()
    if not path.exists():
        req = urllib.request.Request(url, headers={"User-Agent": UA, **(headers or {})})
        for attempt in range(8):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    data = r.read()
                if not binary and data.lstrip().startswith(b"{") and b'"error"' in data[:200]:
                    raise RuntimeError(data[:200])  # e.g. "search too busy": retry, never cache it
                break
            except Exception as e:  # network hiccup or rate limit: back off, then give up
                if attempt == 7:
                    raise RuntimeError(f"GET failed: {cache_key}") from e
                time.sleep(15 * (attempt + 1))  # ~7 min in total: rides out short API outages
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    data = path.read_bytes()
    return data if binary else json.loads(data)


def tier(count, total):
    for t, share in zip(TIERS, SHARES):
        if count >= share * total:
            return t
    return "legendary" if count >= RARE_MIN else None


# --- Card stats: weight, wingspan, length, flight distance, each as [mean, standard deviation] ---

NUM = r"(\d+(?:\.\d+)?)(?:\s*(?:–|-|—|to)\s*(\d+(?:\.\d+)?))?\s*(cm|mm|m)\b"
WINGSPAN_RE = [re.compile(r"wing\s?-?span[^.;]{0,40}?" + NUM, re.I),
               re.compile(NUM + r"[^.;]{0,25}?wing\s?-?span", re.I)]
LENGTH_RE = [re.compile(NUM + r"[^.;]{0,25}?\b(?:long|in length|in total length)\b", re.I),
             re.compile(r"\b(?:length|measures|measuring)\b[^.;]{0,30}?" + NUM, re.I)]
PART = re.compile(r"wing|tail|bill|beak|tarsus|leg|egg|feather|crest", re.I)


def find_size(text, patterns, exclude_parts):
    """(mean cm, sd cm or None) from the first matching "13–14 cm" style phrase."""
    for p in patterns:
        for m in p.finditer(text):
            context = text[max(0, m.start() - 20):m.end()]
            if exclude_parts and PART.search(context):
                continue  # "wing length 7 cm" is not the body length
            lo, hi, unit = float(m[1]), float(m[2] or m[1]), m[3]
            scale = {"mm": 0.1, "cm": 1, "m": 100}[unit]
            if hi < lo:
                continue
            return (lo + hi) / 2 * scale, ((hi - lo) / 4 * scale) or None  # a range ≈ ±2 sd
    return None


def wikipedia_sizes(title):
    """(wingspan, length) from the English Wikipedia article, each (mean cm, sd) or None."""
    r = get("https://en.wikipedia.org/w/api.php", {
        "action": "query", "format": "json", "prop": "extracts", "explaintext": 1,
        "redirects": 1, "titles": title})
    text = next(iter(r["query"]["pages"].values())).get("extract", "")
    span, length = find_size(text, WINGSPAN_RE, False), find_size(text, LENGTH_RE, True)
    if length and not 5 <= length[0] <= 200:
        length = None
    if span and (not 8 <= span[0] <= 350 or (length and span[0] < 0.9 * length[0])):
        span = None
    return span, length


def avonet():
    """{Latin name (BirdLife or eBird taxonomy): (mass g, wing-length coefficient of variation)}."""
    cached = CACHE / "avonet" / "avonet.json"
    if cached.exists():
        return {k: tuple(v) for k, v in json.loads(cached.read_text()).items()}
    xlsx = CACHE / "avonet" / "avonet.xlsx"
    if not xlsx.exists():
        xlsx.parent.mkdir(parents=True, exist_ok=True)
        xlsx.write_bytes(get(AVONET_URL, binary=True))
    raw = read_xlsx(xlsx, "AVONET_Raw_Data")
    h = raw[0]
    wings = {}
    for r in raw[1:]:
        try:
            w = float(r[h.index("Wing.Length")])
        except (TypeError, ValueError):
            continue
        for name in (r[h.index("Species1_BirdLife")], r[h.index("Species2_eBird")]):
            wings.setdefault(name, []).append(w)
    out = {}
    for sheet, col in (("AVONET2_eBird", "Species2"), ("AVONET1_BirdLife", "Species1")):
        rows = read_xlsx(xlsx, sheet)
        h = rows[0]
        for r in rows[1:]:
            try:
                mass = float(r[h.index("Mass")])
            except (TypeError, ValueError):
                continue
            w = wings.get(r[h.index(col)], [])
            cv = None
            if len(w) >= 5:
                mean = sum(w) / len(w)
                cv = (sum((x - mean) ** 2 for x in w) / (len(w) - 1)) ** 0.5 / mean
            out[r[h.index(col)]] = (mass, cv)
    cached.write_text(json.dumps(out))
    return out


def wikidata_wingspans(latins):
    """{Latin name: wingspan cm} from Wikidata (P2050), for gaps in Wikipedia."""
    latins, out = sorted(set(latins)), {}
    for i in range(0, len(latins), 100):  # one query for all would exceed the URL length limit
        values = " ".join(f'"{n}"' for n in latins[i:i + 100])
        r = get("https://query.wikidata.org/sparql", {"query": f"""SELECT ?latin (SAMPLE(?ws) AS ?span) WHERE {{
            VALUES ?latin {{ {values} }} ?item wdt:P225 ?latin; p:P2050/psn:P2050/wikibase:quantityAmount ?ws.
            }} GROUP BY ?latin"""}, {"Accept": "application/sparql-results+json"})
        out |= {b["latin"]["value"]: float(b["span"]["value"]) * 100 for b in r["results"]["bindings"]}
    return out


def mean_latitude(key, month):
    """Mean latitude of the species' GBIF records in a month, from counts in 10° bands."""
    counts = [(lat + 5, get("https://api.gbif.org/v1/occurrence/search", {
        "speciesKey": key, "month": month, "decimalLatitude": f"{lat},{lat + 10}", "limit": 0,
        "occurrenceStatus": "PRESENT", "hasGeospatialIssue": "false"})["count"])
        for lat in range(-40, 80, 10)]
    n = sum(c for _, c in counts)
    return sum(lat * c for lat, c in counts) / n if n else None


def flight_km(key):
    """North–south distance between the January and June ranges (≈0 for sedentary birds).
    shortcut: latitude only and observer-biased GBIF data; fine for a game stat, not for science."""
    jan, jun = mean_latitude(key, 1), mean_latitude(key, 6)
    return None if jan is None or jun is None else abs(jun - jan) * 111


# Europe: country code -> (English, French); optional (lat, lon) box keeps out far islands.
COUNTRIES = {
    "AL": ("Albania", "Albanie"), "AT": ("Austria", "Autriche"), "BA": ("Bosnia and Herzegovina", "Bosnie-Herzégovine"),
    "BE": ("Belgium", "Belgique"), "BG": ("Bulgaria", "Bulgarie"), "BY": ("Belarus", "Biélorussie"),
    "CH": ("Switzerland", "Suisse"), "CY": ("Cyprus", "Chypre"), "CZ": ("Czechia", "Tchéquie"),
    "DE": ("Germany", "Allemagne"), "DK": ("Denmark", "Danemark"), "EE": ("Estonia", "Estonie"),
    "ES": ("Spain", "Espagne"), "FI": ("Finland", "Finlande"), "FR": ("France", "France"),
    "GB": ("United Kingdom", "Royaume-Uni"), "GR": ("Greece", "Grèce"), "HR": ("Croatia", "Croatie"),
    "HU": ("Hungary", "Hongrie"), "IE": ("Ireland", "Irlande"), "IS": ("Iceland", "Islande"),
    "IT": ("Italy", "Italie"), "LT": ("Lithuania", "Lituanie"), "LU": ("Luxembourg", "Luxembourg"),
    "LV": ("Latvia", "Lettonie"), "MD": ("Moldova", "Moldavie"), "ME": ("Montenegro", "Monténégro"),
    "MK": ("North Macedonia", "Macédoine du Nord"), "MT": ("Malta", "Malte"), "NL": ("Netherlands", "Pays-Bas"),
    "NO": ("Norway", "Norvège"), "PL": ("Poland", "Pologne"), "PT": ("Portugal", "Portugal"),
    "RO": ("Romania", "Roumanie"), "RS": ("Serbia", "Serbie"), "SE": ("Sweden", "Suède"),
    "SI": ("Slovenia", "Slovénie"), "SK": ("Slovakia", "Slovaquie"), "UA": ("Ukraine", "Ukraine"),
    "XK": ("Kosovo", "Kosovo"),
}
MAINLAND = {"ES": ((35, 44), (-10, 5)), "PT": ((36, 43), (-10, -6))}  # no Canaries / Azores / Madeira
# Bioregions of large countries: id -> (English, French, GBIF filter). US/Canada by GADM state ids.
US = lambda *n: {"gadmGid": [f"USA.{i}_1" for i in n]}
CA = lambda *n: {"gadmGid": [f"CAN.{i}_1" for i in n]}
BIOREGIONS = {
    "US-NE": ("USA — Northeast", "États-Unis — Nord-Est", US(7, 8, 9, 20, 21, 22, 30, 31, 33, 39, 40, 46, 47, 49)),
    "US-SE": ("USA — Southeast", "États-Unis — Sud-Est", US(1, 4, 10, 11, 18, 19, 25, 34, 41, 43)),
    "US-MW": ("USA — Midwest", "États-Unis — Midwest", US(14, 15, 16, 23, 24, 26, 36, 50)),
    "US-GP": ("USA — Great Plains", "États-Unis — Grandes Plaines", US(17, 28, 35, 37, 42)),
    "US-MT": ("USA — Mountain West", "États-Unis — Rocheuses", US(6, 13, 27, 45, 51)),
    "US-SW": ("USA — Southwest", "États-Unis — Sud-Ouest", US(3, 29, 32, 44)),
    "US-PC": ("USA — Pacific Coast", "États-Unis — Côte Pacifique", US(5, 38, 48)),
    "US-AK": ("USA — Alaska", "États-Unis — Alaska", US(2)),
    "CA-AQ": ("Canada — Atlantic & Quebec", "Canada — Atlantique et Québec", CA(4, 5, 7, 10, 11)),
    "CA-ON": ("Canada — Ontario", "Canada — Ontario", CA(9)),
    "CA-PR": ("Canada — Prairies", "Canada — Prairies", CA(1, 3, 12)),
    "CA-BN": ("Canada — British Columbia & North", "Canada — Colombie-Britannique et Nord", CA(2, 6, 8, 13)),
    "RU-EU": ("European Russia", "Russie d'Europe", {"country": "RU", "decimalLongitude": "19,60"}),
}
# 2°×2° cells for GPS: Europe and the US + Canada.
CELL_AREAS = [((34, 72), (-12, 42)), ((24, 72), (-170, -52))]


def cell_id(lat, lon):
    return f"{'N' if lat >= 0 else 'S'}{abs(lat):02d}{'E' if lon >= 0 else 'W'}{abs(lon):03d}"


def region_list():
    """[(id, kind, English, French, GBIF filter)] for every region."""
    out = []
    for (lat0, lat1), (lon0, lon1) in CELL_AREAS:
        for lat in range(lat0, lat1, 2):
            for lon in range(lon0, lon1, 2):
                out.append((cell_id(lat, lon), "cell", None, None,
                            {"decimalLatitude": f"{lat},{lat + 2}", "decimalLongitude": f"{lon},{lon + 2}"}))
    for code, (en, fr) in COUNTRIES.items():
        f = {"country": code}
        if code in MAINLAND:
            (a, b), (c, d) = MAINLAND[code]
            f |= {"decimalLatitude": f"{a},{b}", "decimalLongitude": f"{c},{d}"}
        out.append((code, "country", en, fr, f))
    out += [(rid, "bioregion", en, fr, f) for rid, (en, fr, f) in BIOREGIONS.items()]
    return out


def presence(region_filter):
    """{gbif species key: {month: tier}} for a region; {} if it has too few records."""
    base = {"classKey": 212, "limit": 0, "occurrenceStatus": "PRESENT", "hasGeospatialIssue": "false",
            **region_filter}
    if get("https://api.gbif.org/v1/occurrence/search", base)["count"] < MIN_RECORDS:
        return {}
    out = {}
    for month in range(1, 13):
        r = get("https://api.gbif.org/v1/occurrence/search",
                {**base, "month": month, "facet": "speciesKey", "facetLimit": 1500})
        counts = {int(c["name"]): c["count"] for c in r["facets"][0]["counts"]}
        total = sum(counts.values())
        for key, n in counts.items():
            if t := tier(n, total):
                out.setdefault(key, {})[month] = t
    return out


def wikidata(keys, by_latin=False):
    """{gbif key (or Latin name with by_latin): (en, fr, [commons file names], Wikidata Latin name)}."""
    out = {}
    keys = list(keys)
    match = "wdt:P225" if by_latin else "wdt:P846"  # taxon name, or GBIF id
    for i in range(0, len(keys), 100):
        values = " ".join(f'"{k}"' for k in keys[i:i + 100])
        # Labels are sometimes just the Latin name; the taxon common name (P1843) is the fallback.
        q = f"""SELECT ?gbif ?latin ?en ?fr (SAMPLE(?cen) AS ?commonEn) (SAMPLE(?cfr) AS ?commonFr)
          (GROUP_CONCAT(DISTINCT ?img; separator="|") AS ?images) WHERE {{
          VALUES ?gbif {{ {values} }} ?item {match} ?gbif.
          OPTIONAL {{ ?item wdt:P225 ?latin }}
          OPTIONAL {{ ?item rdfs:label ?en FILTER(lang(?en)="en") }}
          OPTIONAL {{ ?item rdfs:label ?fr FILTER(lang(?fr)="fr") }}
          OPTIONAL {{ ?item wdt:P1843 ?cen FILTER(lang(?cen)="en") }}
          OPTIONAL {{ ?item wdt:P1843 ?cfr FILTER(lang(?cfr)="fr") }}
          OPTIONAL {{ ?item wdt:P18 ?img }} }} GROUP BY ?gbif ?latin ?en ?fr"""
        r = get("https://query.wikidata.org/sparql", {"query": q},
                {"Accept": "application/sparql-results+json"})
        for b in r["results"]["bindings"]:
            v = {k: x["value"] for k, x in b.items()}
            latin = v.get("latin", "").lower()

            def name(label, common):
                return cap(common if (not label or label.lower() == latin) and common else label)

            images = [urllib.parse.unquote(u.rsplit("/", 1)[1]) for u in v.get("images", "").split("|") if u]
            out[v["gbif"] if by_latin else int(v["gbif"])] = (name(v.get("en"), v.get("commonEn")),
                                   name(v.get("fr"), v.get("commonFr")), images, v.get("latin"))
    return out


def gbif_name(key, lang):
    """Most frequent GBIF vernacular name in lang ("eng"/"fra"), for gaps on Wikidata."""
    r = get(f"https://api.gbif.org/v1/species/{key}/vernacularNames", {"limit": 200})
    names = [n["vernacularName"].strip() for n in r["results"] if n.get("language") == lang]
    return cap(max(names, key=lambda n: sum(m.lower() == n.lower() for m in names))) if names else None


def cap(s):
    return s[0].upper() + s[1:] if s else s


def commons_photo(file_name):
    """(thumbnail URL, credit) or None when the license isn't allowed."""
    r = get("https://commons.wikimedia.org/w/api.php", {
        "action": "query", "format": "json", "prop": "imageinfo", "titles": f"File:{file_name}",
        "iiprop": "url|extmetadata", "iiurlwidth": 600,
        "iiextmetadatafilter": "LicenseShortName|Artist",
    })
    info = next(iter(r["query"]["pages"].values())).get("imageinfo", [{}])[0]
    meta = info.get("extmetadata", {})
    lic = meta.get("LicenseShortName", {}).get("value", "")
    if not info.get("thumburl") or not OK_LICENSE.match(lic.strip()):
        return None
    artist = html.unescape(re.sub(r"<[^>]+>", "", meta.get("Artist", {}).get("value", ""))).strip()
    return info["thumburl"], f"{artist or 'Wikimedia Commons'} · {lic}"


KINDS = ["song", "call", "alarm"]
SKIP_TYPES = re.compile(r"begging|nestling|hatchling|imitation|uncertain|aberrant", re.I)  # last resort only
# Recordings per species, by its commonest tier in any region: common birds are heard often,
# so they get more variety; rare ones keep one.
RECORDINGS_PER_TIER = {"common": 5, "uncommon": 3, "rare": 2, "epic": 1, "legendary": 1}


def kind(xc_type):
    """Map a xeno-canto type ("alarm call", "dawn song", "drumming"...) to song / call / alarm."""
    t = xc_type.lower()
    if "alarm" in t or "distress" in t:
        return "alarm"
    if "song" in t or "drum" in t:
        return "song"
    return "call"


def xc_recordings(latin, key, n, pinned=None):
    """Up to n allowed xeno-canto recordings, as varied as possible: kinds rotate
    song -> call -> alarm, and each pick prefers a new recordist and country.
    Falls back to non-commercial licenses only when no free recording is usable."""
    picked = xc_pick(xc_search(latin, key, ("PD", "BY", "BY-SA"), XC_OK_LICENSE, pinned), n, pinned)
    if not picked:
        picked = xc_pick(xc_search(latin, key, ("BY-NC", "BY-NC-SA"), XC_NC_LICENSE, pinned), n, pinned)
        for r in picked:
            r["nc"] = True
    return picked


def xc_search(latin, key, licenses, allowed, pinned=None):
    # Ask only for the wanted licenses (most recordings are NC, so this saves reading thousands).
    queries = [f'sp:"{latin}" grp:birds lic:{t}' for t in licenses]
    recs = []
    for query in ([f"nr:{pinned}"] if pinned else []) + queries:
        page, pages = 1, 1
        while page <= pages:
            r = get("https://xeno-canto.org/api/3/recordings",
                    {"query": query, "key": key, "per_page": 500, "page": page})
            recs += [x for x in r.get("recordings", []) if x.get("file") and allowed.search(x.get("lic", ""))]
            pages, page = int(r.get("numPages", 1)), page + 1
    return recs


def xc_pick(recs, n, pinned=None):

    def seconds(r):
        m, s = (r.get("length") or "0:0").split(":")[-2:]
        return int(m) * 60 + int(s)

    for r in recs:
        r["seconds"], r["kind"] = seconds(r), kind(r.get("type", ""))
    pinned_rec = [r for r in recs if pinned and r["id"] == pinned][:1]  # overrides.csv pick goes first
    usable = [r for r in recs if r.get("q") in ("A", "B", "C") and r["seconds"] >= 10 and r not in pinned_rec]
    recs = [r for r in usable if not SKIP_TYPES.search(r.get("type", ""))]
    def in_area(r):  # recorded in Europe or North America: the dialect our users hear
        try:
            lat, lon = float(r.get("lat")), float(r.get("lon") or r.get("lng"))
        except (TypeError, ValueError):
            return False
        return any(a <= lat <= b and c <= lon <= d for (a, b), (c, d) in CELL_AREAS)

    # Local first; nocturnal flight calls (faint, far away) last; best quality; long enough.
    recs.sort(key=lambda r: (not in_area(r), "nocturnal" in r.get("type", ""), r["q"], -min(r["seconds"], 60)))
    picked = list(pinned_rec)
    rotation = [k for _ in range(n) for k in KINDS]
    for k in rotation:
        if len(picked) >= n:
            break
        pool = [r for r in recs if r["kind"] == k and r not in picked]
        new_rec = [r for r in pool if r.get("rec") not in {p.get("rec") for p in picked}]
        new_both = [r for r in new_rec if r.get("cnt") not in {p.get("cnt") for p in picked}]
        # A new call type is preferred only at the same quality as the best candidate.
        best = (new_both or new_rec or [{}])[0]
        new_type = [r for r in new_both if r.get("type") not in {p.get("type") for p in picked}
                    and r["q"] == best.get("q") and in_area(r) == in_area(best)]
        if choice := (new_type or new_both or new_rec or [None])[0]:  # same recordist twice adds little
            picked.append(choice)
    if not picked and usable:  # better a begging or uncertain recording than no bird at all
        picked = sorted(usable, key=lambda r: (r["q"], -min(r["seconds"], 60)))[:1]
    return picked


def read_xlsx(path, sheet_name):
    """Rows of one sheet as lists of strings (stdlib only; AVONET ships as .xlsx)."""
    ns = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
    with zipfile.ZipFile(path) as z:
        shared = ["".join(t.text or "" for t in si.iter(f"{ns}t"))
                  for si in ET.fromstring(z.read("xl/sharedStrings.xml")).iter(f"{ns}si")]
        rels = {r.get("Id"): r.get("Target") for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))}
        sheets = ET.fromstring(z.read("xl/workbook.xml")).iter(f"{ns}sheet")
        rid = next(s.get("{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id")
                   for s in sheets if s.get("name") == sheet_name)
        rows = []
        with z.open("xl/" + rels[rid].removeprefix("/xl/")) as f:
            for _, el in ET.iterparse(f):
                if el.tag != f"{ns}row":
                    continue
                row = {}
                for c in el.iter(f"{ns}c"):
                    col = re.match(r"[A-Z]+", c.get("r"))[0]
                    v = c.find(f"{ns}v")
                    text = None if v is None else v.text
                    if c.get("t") == "s" and text is not None:
                        text = shared[int(text)]
                    elif c.get("t") == "inlineStr":
                        text = "".join(t.text or "" for t in c.iter(f"{ns}t"))
                    row[col] = text
                rows.append(row)
                el.clear()
    cols = sorted({c for r in rows for c in r}, key=lambda c: (len(c), c))
    return [[r.get(c) for c in cols] for r in rows]


def ffmpeg(*args):
    subprocess.run([str(FFMPEG), "-y", "-loglevel", "error", *args], check=True)


def read_csv(path):
    if not path.exists():
        return {}
    with open(path, newline="", encoding="utf-8") as f:
        return {row[0].strip(): row[1].strip() for row in csv.reader(f) if len(row) >= 2}


FALLBACK = ROOT.parent / "app" / "assets" / "content"
FALLBACK_PER_CONTINENT = 15


def build_fallback():
    """Bundle the commonest birds of Europe and of North America in the app, with one song each,
    so an alarm still rings with a real bird when the phone is offline."""
    species = {b["id"]: b for b in json.loads((OUT / "species.json").read_text(encoding="utf-8"))}
    score = {"eu": {}, "na": {}}  # bird id -> regions where it's common
    for f in (OUT / "regions").iterdir():
        rid = f.stem
        continent = "na" if rid.startswith(("US-", "CA-")) or (rid[0] in "NS" and "W" in rid) else "eu"
        for bird, months in json.loads(f.read_text(encoding="utf-8")).items():
            if "common" in months.values():
                score[continent][bird] = score[continent].get(bird, 0) + 1
    chosen = []
    for continent in ("eu", "na"):
        ranked = sorted(score[continent], key=lambda b: -score[continent][b])
        chosen += [b for b in ranked if b not in chosen][:FALLBACK_PER_CONTINENT]
    for sub in ("audio", "photos"):
        (FALLBACK / sub).mkdir(parents=True, exist_ok=True)
        for f in (FALLBACK / sub).iterdir():
            f.unlink()
    bundled = []
    for bid in chosen:
        b = dict(species[bid])
        recs = sorted(b["recordings"], key=lambda r: (r.get("nc", False), r["kind"] != "song"))
        b["recordings"] = recs[:1]  # one song keeps the APK small
        for f in (b["photo"], b["recordings"][0]["file"]):
            (FALLBACK / f).write_bytes((OUT / f).read_bytes())
        bundled.append(b)
    (FALLBACK / "catalog.json").unlink(missing_ok=True)  # old single-region format
    write_json(FALLBACK / "species.json", bundled)
    print(f"{len(bundled)} fallback birds:", ", ".join(b["en"] for b in bundled))


def main():
    if sys.argv[1:] == ["fallback"]:
        return build_fallback()
    xc_key_file = ROOT / "xc_key.txt"
    xc_key = xc_key_file.read_text().strip() if xc_key_file.exists() else None
    overrides = read_csv(ROOT / "overrides.csv")  # "Latin name" -> "xc=123" / "commons=File:x.jpg"
    my_credits = read_csv(MY_PHOTOS / "credits.csv")

    print("1/6 GBIF presence per region")
    only = sys.argv[1].split(",") if len(sys.argv) > 1 else None  # e.g. "N48E002,FR" for a quick test run
    regions = [r for r in region_list() if not only or r[0] in only]
    with ThreadPoolExecutor(4) as pool:  # more trips GBIF rate limits
        pres = dict(zip([r[0] for r in regions], pool.map(lambda r: presence(r[4]), regions)))
    regions = [r for r in regions if pres[r[0]]]
    keys = sorted({k for r in regions for k in pres[r[0]]})
    reach = {k: sum(k in pres[r[0]] for r in regions) for k in keys}  # regions a species is in
    best_tier = {k: min((t for r in regions for t in pres[r[0]].get(k, {}).values()), key=TIERS.index)
                 for k in keys}  # commonest tier anywhere: decides how many recordings it gets
    print(f"    {len(regions)} regions, {len(keys)} species")
    print("2/6 GBIF taxonomy")
    with ThreadPoolExecutor(4) as pool:
        taxa = dict(zip(keys, pool.map(lambda k: get(f"https://api.gbif.org/v1/species/{k}"), keys)))
    print("3/6 Wikidata names and photos")
    wd = wikidata(keys)
    # GBIF renumbers some species (Junco hyemalis: 9362842 vs 2492010 on Wikidata): match those by name.
    unmatched = {(taxa[k].get("canonicalName") or taxa[k]["scientificName"]): k for k in keys if k not in wd}
    wd |= {unmatched[latin]: v for latin, v in wikidata(unmatched, by_latin=True).items()}

    birds, dropped, seen, id_of = [], [], {}, {}  # id_of: GBIF key -> bird id
    tmp = CACHE / "files"
    tmp.mkdir(parents=True, exist_ok=True)
    (OUT / "audio").mkdir(parents=True, exist_ok=True)
    (OUT / "photos").mkdir(parents=True, exist_ok=True)
    print("4/6 photos, recordings" + ("" if xc_key else " (no pipeline/xc_key.txt: skipping recordings)"))
    for key in sorted(keys, key=lambda k: -reach[k]):
        t = taxa[key]
        latin = t.get("canonicalName") or t["scientificName"]
        bird_id = latin.lower().replace(" ", "_")
        en, fr, images, wd_latin = wd.get(key, (None, None, [], None))
        if not en or en.lower() == latin.lower():
            en = gbif_name(key, "eng")
        if not fr or fr.lower() == latin.lower():
            fr = gbif_name(key, "fra")
        if en and en.lower() in seen:  # two GBIF names for one bird (e.g. Parus/Poecile montanus)
            id_of[key] = seen[en.lower()]["id"]
            continue
        override = overrides.get(latin, "")
        if override.startswith("commons="):
            images = [override.removeprefix("commons=").removeprefix("File:")]

        def drop(reason):
            dropped.append((latin, en, reason, reach[key]))

        if not (en and fr) or latin.lower() in (en.lower(), fr.lower()):
            drop("no EN/FR common name on Wikidata")
            continue
        if not t.get("order") or not t.get("family"):
            drop("no order/family on GBIF")
            continue

        # Photo: yours first, then Commons.
        photo_out = OUT / "photos" / f"{bird_id}.jpg"
        mine = MY_PHOTOS / f"{latin.replace(' ', '_')}.jpg"
        if mine.exists():
            ffmpeg("-i", str(mine), "-vf", "scale=600:-2", "-q:v", "4", str(photo_out))
            photo_credit = f"Photo: {my_credits.get(mine.name, '© ' + MY_NAME)}"
        else:
            found = next(filter(None, map(commons_photo, images)), None)
            if not found:
                drop("no photo with an allowed license")
                continue
            if not photo_out.exists():
                src = tmp / f"{bird_id}.photo"
                src.write_bytes(get(found[0], binary=True))
                ffmpeg("-i", str(src), "-vf", "scale=600:-2", "-q:v", "4", str(photo_out))
            photo_credit = f"Photo: {found[1]}"

        if not xc_key:
            drop("recordings skipped (no API key)")
            continue
        pinned = override.removeprefix("xc=") if override.startswith("xc=") else None
        n = RECORDINGS_PER_TIER[best_tier[key]]
        # xeno-canto may use a newer name than GBIF (Curruca vs Sylvia communis).
        recs = xc_recordings(latin, xc_key, n, pinned) or (
            wd_latin and wd_latin != latin and xc_recordings(wd_latin, xc_key, n)) or []
        recordings = []
        for i, rec in enumerate(recs, 1):
            audio_out = OUT / "audio" / f"{bird_id}-{i}.m4a"
            if not audio_out.exists():  # shortcut: delete site/v1/audio to re-encode after changing picks
                src = tmp / f"{bird_id}-{rec['id']}.audio"
                src.write_bytes(get(rec["file"], binary=True))
                length = min(30, max(rec["seconds"] - 1, 5))
                try:  # -vn: some files carry a cover image
                    ffmpeg("-ss", "1", "-t", str(length), "-i", str(src), "-vn",
                           "-af", f"loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=out:st={length - 2}:d=2",
                           "-ac", "1", "-ar", "44100", "-c:a", "aac", "-b:a", "48k", str(audio_out))
                except subprocess.CalledProcessError:
                    audio_out.unlink(missing_ok=True)
                    print(f"    ! XC{rec['id']} ({latin}) could not be converted")
                    continue
            lic = re.search(r"licenses/([a-z-]+)/([\d.]+)", rec["lic"])
            recordings.append({
                "file": f"audio/{bird_id}-{i}.m4a", "kind": rec["kind"],
                "credit": f"{rec['rec']} · XC{rec['id']} · {f'CC {lic[1].upper()} {lic[2]}' if lic else 'CC0'}",
                **({"nc": True} if rec.get("nc") else {}),
            })
        if not recordings:
            drop("no usable xeno-canto recording with an allowed license (A/B/C quality, ≥10 s)")
            continue
        birds.append({
            "id": bird_id, "latin": latin, "en": en, "fr": fr,
            "order": t["order"], "family": t["family"],
            "recordings": recordings,
            "photo": f"photos/{bird_id}.jpg",
            "photoCredit": photo_credit,
            "_key": key, "_wd_latin": wd_latin, "_reach": reach[key],
        })
        seen[en.lower()] = birds[-1]
        id_of[key] = bird_id
        print(f"    + {latin}")

    print("5/6 card stats")
    add_card_data(birds)
    files = set()
    for b in birds:  # self-check: the app must never get a file that's missing or non-free
        files |= {b["photo"], *(r["file"] for r in b["recordings"])}
        assert all((OUT / f).exists() for f in files), b["id"]
        assert "NC" not in b["photoCredit"], b["id"]
        assert all(("NC" in r["credit"]) == bool(r.get("nc")) for r in b["recordings"]), b["id"]  # NC only if flagged
        assert all(r["kind"] in KINDS for r in b["recordings"]), b["id"]
    keep = {b["id"] for b in birds}
    for f in [*(OUT / "audio").iterdir(), *(OUT / "photos").iterdir()]:
        if f"{f.parent.name}/{f.name}" not in files:
            f.unlink()

    print("6/6 site and report")
    region_birds = {}  # region id -> {bird id: {month: tier}}, duplicates merged to the commoner tier
    for rid, *_ in regions:
        rb = region_birds[rid] = {}
        for key, months in pres[rid].items():
            if id_of.get(key) in keep:
                m = rb.setdefault(id_of[key], {})
                for month, t in months.items():
                    m[str(month)] = min(m.get(str(month), "legendary"), t, key=TIERS.index)
    (OUT / "regions").mkdir(exist_ok=True)
    for f in (OUT / "regions").iterdir():
        f.unlink()
    for rid, rb in region_birds.items():
        write_json(OUT / "regions" / f"{rid}.json", rb)
    write_json(OUT / "regions.json", [{"id": rid, "kind": kind, "en": en, "fr": fr} for rid, kind, en, fr, _ in regions])
    write_json(OUT / "species.json", [{k: v for k, v in b.items() if not k.startswith("_")} for b in birds])
    write_report(birds, dropped, regions, region_birds)
    print(f"    {len(birds)} birds kept, {len(dropped)} dropped, {len(regions)} regions. See pipeline/report.md")


def write_json(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def add_card_data(birds):
    """Card number (taxonomic order over all species) and stats [mean, sd]."""
    mass = avonet()
    spans = wikidata_wingspans([b["latin"] for b in birds] + [b["_wd_latin"] for b in birds if b["_wd_latin"]])
    with ThreadPoolExecutor(4) as pool:  # ~24 small GBIF count queries per bird; more trips rate limits
        km = dict(zip([b["id"] for b in birds], pool.map(lambda b: flight_km(b["_key"]), birds)))
    ratios = []
    for b in birds:
        names = [n for n in (b["latin"], b["_wd_latin"]) if n]
        w_span, length = next((x for x in map(wikipedia_sizes, names) if any(x)), (None, None))
        m, cv = next((mass[n] for n in names if n in mass), (None, None))
        if not w_span and any(n in spans for n in names):
            w_span = (next(spans[n] for n in names if n in spans), None)
        if w_span and not w_span[1]:
            w_span = (w_span[0], w_span[0] * (cv or 0.04))
        if w_span and length:
            ratios.append(length[0] / w_span[0])
        b["stats"] = {
            "weight": [m, m * 0.1] if m else None,  # shortcut: AVONET has no mass spread; 10% CV
            "wingspan": list(w_span) if w_span else None,
            "length": list(length) if length else None,
            "distance": [km[b["id"]], max(km[b["id"]] * 0.2, 50)] if km[b["id"]] is not None else None,
        }
    ratio = sorted(ratios)[len(ratios) // 2] if ratios else 0.6
    for b in birds:  # missing length: wingspan × the median length/wingspan ratio
        st = b["stats"]
        st["source_length"] = "Wikipedia" if st["length"] else None
        if not st["length"] and st["wingspan"]:
            mean = st["wingspan"][0] * ratio
            st["length"], st["source_length"] = [mean, mean * 0.04], "estimated"
    for i, b in enumerate(sorted(birds, key=lambda b: (b["order"], b["family"], b["latin"])), 1):
        b["number"] = i
    for b in birds:
        st = b["stats"]
        source = st.pop("source_length")
        b["_stat_note"] = ", ".join(k for k, v in st.items() if v is None) or (
            "length estimated" if source == "estimated" else "")
        for k, v in st.items():
            # a single value ("14 cm") has no spread: ±4%, like the other estimates
            st[k] = [round(v[0], 1), round(v[1] if v[1] else v[0] * 0.04, 1)] if v else None


def write_report(birds, dropped, regions, region_birds):
    lines = ["# Coverage report", "",
             "Tiers per region and month: "
             + ", ".join(f"{t} ≥{s:.2%} of the month's records" for t, s in zip(TIERS, SHARES))
             + f", legendary ≥{RARE_MIN} records. A card's rarity is the bird's best tier in the region.", "",
             f"## Regions ({len(regions)})", "",
             "| Region | Name | Birds | " + " | ".join(TIERS) + " |", "|---|---|---|" + "---|" * len(TIERS)]
    for rid, region_kind, en, _, _ in regions:
        best = [min(m.values(), key=TIERS.index) for m in region_birds[rid].values()]
        lines.append(f"| {rid} | {en or region_kind} | {len(best)} | "
                     + " | ".join(str(best.count(t)) for t in TIERS) + " |")
    all_recs = [r["kind"] for b in birds for r in b["recordings"]]
    lines += ["", f"## Species ({len(birds)})", "",
              f"Recordings: {len(all_recs)} (" + ", ".join(f"{all_recs.count(k)} {k}" for k in KINDS) + ").", "",
              "| # | Bird | Latin | Regions | Recordings | Weight g | Wingspan cm | Length cm | Flight km | Missing stats |",
              "|---|---|---|---|---|---|---|---|---|---|"]
    for b in sorted(birds, key=lambda b: b["number"]):
        stats = [f"{v[0]:g} ± {v[1]:g}" if v else "—" for v in b["stats"].values()]
        kinds = [r["kind"] for r in b["recordings"]]
        recs = " ".join(f"{kinds.count(k)}{k[0]}" for k in KINDS if k in kinds)  # e.g. "2s 2c 1a"
        lines.append(f"| {b['number']} | {b['en']} | *{b['latin']}* | {b['_reach']} | {recs} | " + " | ".join(stats)
                     + f" | {b['_stat_note']} |")
    nc = [b for b in birds if any(r.get("nc") for r in b["recordings"])]
    lines += ["", f"## Non-commercial recordings ({len(nc)} species)", "",
              "Used only because no free recording exists. Replace or remove before any monetization.", ""]
    lines += [f"- {b['en']} (*{b['latin']}*): " + ", ".join(r["credit"] for r in b["recordings"]) for b in nc]
    lines += ["", f"## Dropped ({len(dropped)})", "", "| Latin | English | Reason | Regions |", "|---|---|---|---|"]
    for latin, en, reason, reach in sorted(dropped, key=lambda d: -d[3]):
        lines.append(f"| *{latin}* | {en or ''} | {reason} | {reach} |")
    (ROOT / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
