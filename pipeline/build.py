"""Builds the Early Bird content for one region cell.

Run from the repo root:  py pipeline/build.py
Reads GBIF (presence, taxonomy), Wikidata (EN/FR names, photo), Wikimedia Commons (photo
credits) and xeno-canto (recordings), then writes app/assets/content/ and pipeline/report.md.
Every download is cached in pipeline/cache/, so re-runs are fast.
"""

import csv
import hashlib
import html
import json
import re
import subprocess
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

CELL, LAT, LON = "N48E002", (48, 50), (2, 4)
MY_NAME = "Nathan Provin"  # credit for your own photos without a credits.csv line
# Rarity tiers: minimum share of the month's bird records for the first four;
# "legendary" only needs RARE_MIN records that month (filters out one-off errors).
TIERS = ["common", "uncommon", "rare", "epic", "legendary"]
SHARES = [0.01, 0.0025, 0.0005, 0.0001]
RARE_MIN = 20
AVONET_URL = "https://ndownloader.figshare.com/files/34480856"  # Tobias et al. 2022, CC BY 4.0

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / "cache"
OUT = ROOT.parent / "app" / "assets" / "content"
MY_PHOTOS = ROOT / "my_photos"
FFMPEG = ROOT.parent / ".tools" / "ffmpeg" / "bin" / "ffmpeg.exe"
UA = "EarlyBirdAlarm-pipeline/0.1 (https://github.com/NathanProvin/EarlyBirdAlarm)"

# Licenses that allow commercial use. Anything else (NC, ND, unknown) is rejected.
# GFDL is free but needs the full license text shipped with the photo, so it's left out too.
OK_LICENSE = re.compile(r"^(cc0|public domain|pd|attribution|cc[ -]by([ -]sa)?([ -]\d\.\d)?)(\b.*)?$", re.I)
XC_OK_LICENSE = re.compile(r"creativecommons\.org/(publicdomain/zero|licenses/(by|by-sa)/)", re.I)


def get(url, params=None, headers=None, binary=False):
    """GET with a disk cache keyed by the full URL (the xeno-canto key is left out of the key)."""
    if params:
        url += "?" + urllib.parse.urlencode(params)
    cache_key = re.sub(r"key=[^&]+", "", url)
    path = CACHE / "http" / hashlib.sha1(cache_key.encode()).hexdigest()
    if not path.exists():
        req = urllib.request.Request(url, headers={"User-Agent": UA, **(headers or {})})
        for attempt in range(6):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    data = r.read()
                break
            except Exception as e:  # network hiccup or rate limit: back off, then give up
                if attempt == 5:
                    raise RuntimeError(f"GET failed: {cache_key}") from e
                time.sleep(5 * (attempt + 1))
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


def presence():
    """{gbif species key: {month: tier}} for the cell."""
    out = {}
    for month in range(1, 13):
        r = get("https://api.gbif.org/v1/occurrence/search", {
            "classKey": 212, "month": month, "limit": 0, "facet": "speciesKey", "facetLimit": 500,
            "decimalLatitude": f"{LAT[0]},{LAT[1]}", "decimalLongitude": f"{LON[0]},{LON[1]}",
            "occurrenceStatus": "PRESENT", "hasGeospatialIssue": "false",
        })
        counts = {int(c["name"]): c["count"] for c in r["facets"][0]["counts"]}
        total = sum(counts.values())
        for key, n in counts.items():
            if t := tier(n, total):
                out.setdefault(key, {})[month] = t
    return out


def wikidata(keys):
    """{gbif key: (en, fr, [commons file names], Wikidata Latin name)}."""
    out = {}
    keys = list(keys)
    for i in range(0, len(keys), 100):
        values = " ".join(f'"{k}"' for k in keys[i:i + 100])
        # Labels are sometimes just the Latin name; the taxon common name (P1843) is the fallback.
        q = f"""SELECT ?gbif ?latin ?en ?fr (SAMPLE(?cen) AS ?commonEn) (SAMPLE(?cfr) AS ?commonFr)
          (GROUP_CONCAT(DISTINCT ?img; separator="|") AS ?images) WHERE {{
          VALUES ?gbif {{ {values} }} ?item wdt:P846 ?gbif.
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
            out[int(v["gbif"])] = (name(v.get("en"), v.get("commonEn")),
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


def xc_recording(latin, key, pinned=None):
    """The best allowed xeno-canto recording as a dict, or None."""
    query = f"nr:{pinned}" if pinned else f'sp:"{latin}" grp:birds'
    recs, page, pages = [], 1, 1
    while page <= pages:  # allowed licenses can be anywhere in the results, so read every page
        r = get("https://xeno-canto.org/api/3/recordings",
                {"query": query, "key": key, "per_page": 500, "page": page})
        recs += [x for x in r.get("recordings", []) if x.get("file") and XC_OK_LICENSE.search(x.get("lic", ""))]
        pages, page = int(r.get("numPages", 1)), page + 1
    if pinned:
        return recs[0] if recs else None

    def seconds(r):
        m, s = (r.get("length") or "0:0").split(":")[-2:]
        return int(m) * 60 + int(s)

    recs = [r for r in recs if r.get("q") in ("A", "B", "C") and seconds(r) >= 10]
    europe = {"France", "Belgium", "United Kingdom", "Netherlands", "Germany", "Spain", "Italy",
              "Switzerland", "Luxembourg", "Denmark", "Sweden", "Norway", "Poland", "Portugal"}
    recs.sort(key=lambda r: (r["q"], "song" not in r.get("type", ""), r.get("cnt") not in europe))
    if recs:
        recs[0]["seconds"] = seconds(recs[0])
    return recs[0] if recs else None


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


def main():
    xc_key_file = ROOT / "xc_key.txt"
    xc_key = xc_key_file.read_text().strip() if xc_key_file.exists() else None
    overrides = read_csv(ROOT / "overrides.csv")  # "Latin name" -> "xc=123" / "commons=File:x.jpg"
    my_credits = read_csv(MY_PHOTOS / "credits.csv")

    print("1/5 GBIF presence")
    months = presence()
    print(f"    {len(months)} species with a tier in at least one month")
    print("2/5 GBIF taxonomy")
    taxa = {k: get(f"https://api.gbif.org/v1/species/{k}") for k in months}
    print("3/5 Wikidata names and photos")
    wd = wikidata(months)

    birds, dropped, seen = [], [], {}
    tmp = CACHE / "files"
    tmp.mkdir(parents=True, exist_ok=True)
    (OUT / "audio").mkdir(parents=True, exist_ok=True)
    (OUT / "photos").mkdir(parents=True, exist_ok=True)
    print("4/5 photos, recordings" + ("" if xc_key else " (no pipeline/xc_key.txt: skipping recordings)"))
    for key in sorted(months, key=lambda k: -len(months[k])):
        t = taxa[key]
        latin = t.get("canonicalName") or t["scientificName"]
        bird_id = latin.lower().replace(" ", "_")
        en, fr, images, wd_latin = wd.get(key, (None, None, [], None))
        if not en or en.lower() == latin.lower():
            en = gbif_name(key, "eng")
        if not fr or fr.lower() == latin.lower():
            fr = gbif_name(key, "fra")
        if en and en.lower() in seen:  # two GBIF names for one bird (e.g. Parus/Poecile montanus)
            kept = seen[en.lower()]
            for m, t in months[key].items():
                kept["months"][str(m)] = min(kept["months"].get(str(m), "legendary"), t, key=TIERS.index)
            continue
        override = overrides.get(latin, "")
        if override.startswith("commons="):
            images = [override.removeprefix("commons=").removeprefix("File:")]

        def drop(reason):
            dropped.append((latin, en, reason, months[key]))

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
            src = tmp / f"{bird_id}.photo"
            src.write_bytes(get(found[0], binary=True))
            ffmpeg("-i", str(src), "-vf", "scale=600:-2", "-q:v", "4", str(photo_out))
            photo_credit = f"Photo: {found[1]}"

        if not xc_key:
            drop("recordings skipped (no API key)")
            continue
        pinned = override.removeprefix("xc=") if override.startswith("xc=") else None
        # xeno-canto may use a newer name than GBIF (Curruca vs Sylvia communis).
        rec = xc_recording(latin, xc_key, pinned) or (wd_latin and wd_latin != latin and xc_recording(wd_latin, xc_key))
        if not rec:
            drop("no xeno-canto recording with an allowed license (A/B/C quality, ≥10 s)")
            continue
        src = tmp / f"{bird_id}.audio"
        if not src.exists():
            time.sleep(1)  # be gentle with xeno-canto
        src.write_bytes(get(rec["file"], binary=True))
        length = min(30, max(rec.get("seconds", 31) - 1, 5))
        ffmpeg("-ss", "1", "-t", str(length), "-i", str(src),
               "-af", f"loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=out:st={length - 2}:d=2",
               "-ac", "1", "-ar", "44100", "-c:a", "aac", "-b:a", "48k", str(OUT / "audio" / f"{bird_id}.m4a"))
        lic = re.search(r"licenses/([a-z-]+)/([\d.]+)", rec["lic"])
        lic_name = f"CC {lic[1].upper()} {lic[2]}" if lic else "CC0"
        birds.append({
            "id": bird_id, "latin": latin, "en": en, "fr": fr,
            "order": t["order"], "family": t["family"],
            "months": {str(m): v for m, v in sorted(months[key].items())},
            "audio": f"audio/{bird_id}.m4a",
            "audioCredit": f"Song: {rec['rec']} · XC{rec['id']} · {lic_name}",
            "photo": f"photos/{bird_id}.jpg",
            "photoCredit": photo_credit,
            "_key": key, "_wd_latin": wd_latin,
        })
        seen[en.lower()] = birds[-1]
        print(f"    + {latin}")

    print("5/5 card stats, catalog and report")
    add_card_data(birds)
    for b in birds:  # self-check: the app must never ship a file that's missing or non-free
        assert (OUT / b["audio"]).exists() and (OUT / b["photo"]).exists(), b["id"]
        assert "NC" not in b["audioCredit"] and "NC" not in b["photoCredit"], b["id"]
    keep = {b["id"] for b in birds}
    for f in [*(OUT / "audio").iterdir(), *(OUT / "photos").iterdir()]:
        if f.stem not in keep:
            f.unlink()
    if birds:  # "_" fields are pipeline-only
        public = [{k: v for k, v in b.items() if not k.startswith("_")} for b in birds]
        (OUT / "catalog.json").write_text(
            json.dumps({"cell": CELL, "birds": public}, ensure_ascii=False, indent=1), encoding="utf-8")
    write_report(birds, dropped)
    print(f"    {len(birds)} birds kept, {len(dropped)} dropped. See pipeline/report.md")


def add_card_data(birds):
    """Card rarity (best monthly tier), number (taxonomic order) and stats [mean, sd]."""
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
        b["rarity"] = min(b["months"].values(), key=TIERS.index)
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


def write_report(birds, dropped):
    short = dict(zip(TIERS, "CUREL"))
    lines = [f"# Coverage report — cell {CELL}", "",
             "Tiers: " + ", ".join(f"{short[t]} = {t} (≥{s:.2%} of the month's records)" for t, s in zip(TIERS, SHARES))
             + f", L = legendary (≥{RARE_MIN} records). Columns are months 1–12.", "",
             "Rarity counts: " + ", ".join(f"{t} {sum(b['rarity'] == t for b in birds)}" for t in TIERS), "",
             f"## Kept ({len(birds)})", "",
             "| # | Bird | Latin | Card | " + " | ".join(map(str, range(1, 13)))
             + " | Weight g | Wingspan cm | Length cm | Flight km | Missing stats |",
             "|---|---|---|---|" + "---|" * 12 + "---|---|---|---|---|"]
    for b in sorted(birds, key=lambda b: b["number"]):
        cells = [short.get(b["months"].get(str(m)), "") for m in range(1, 13)]
        stats = [f"{v[0]:g} ± {v[1]:g}" if v else "—" for v in b["stats"].values()]
        lines.append(f"| {b['number']} | {b['en']} | *{b['latin']}* | {b['rarity']} | " + " | ".join(cells)
                     + " | " + " | ".join(stats) + f" | {b.pop('_stat_note')} |")
    lines += ["", f"## Dropped ({len(dropped)})", "", "| Latin | English | Reason | Months |", "|---|---|---|---|"]
    for latin, en, reason, m in dropped:
        lines.append(f"| *{latin}* | {en or ''} | {reason} | "
                     + " ".join(f"{k}{short[v]}" for k, v in sorted(m.items())) + " |")
    (ROOT / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
