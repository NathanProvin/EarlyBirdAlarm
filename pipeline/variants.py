"""Card variants (roadmap 1.1, step 2): up to 5 extra photos per species from Commons
Featured, Valued and Quality images, best first, free licences only (same filter as the
catalog photo). Writes cache/variants.json {species id: [{file, thumb, credit, kind}]}.

    py pipeline/variants.py          (all species, cached HTTP: a rerun is quick)
"""
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor

from build import CACHE, NOT_A_PHOTO, OK_LICENSE, OUT, PHOTO_WIDTH, WORKERS, get, html

MAX = 5
API = "https://commons.wikimedia.org/w/api.php"
KINDS = [  # best first
    ("featured", 'incategory:"Featured_pictures_on_Wikimedia_Commons"'),
    ("valued", 'hastemplate:"VI"'),
    ("quality", 'hastemplate:"Quality image"'),
]
# Museum skins and eggs (Toulouse MHNT), on top of the catalog's NOT_A_PHOTO.
NOT_ALIVE = re.compile(r"\bMHNT\b|\bHdB\b|\bZOO\.\d", re.I)
assert NOT_ALIVE.search("Corvus corax MHNT.ZOO.2010.11.175.1.jpg")


def search(latin, query):
    r = get(API, {"action": "query", "format": "json", "list": "search", "srnamespace": 6,
                  "srsearch": f'"{latin}" {query}', "srlimit": 50})
    return [h["title"] for h in r.get("query", {}).get("search", [])]


def details(titles):
    """title -> (thumb URL, credit, categories) for the free-licensed photos among titles."""
    out = {}
    for i in range(0, len(titles), 50):
        r = get(API, {"action": "query", "format": "json", "titles": "|".join(titles[i:i + 50]),
                      "prop": "imageinfo|categories", "cllimit": "max", "clshow": "!hidden",
                      "iiprop": "url|extmetadata", "iiurlwidth": PHOTO_WIDTH,
                      "iiextmetadatafilter": "LicenseShortName|Artist"})
        for p in r.get("query", {}).get("pages", {}).values():
            info = (p.get("imageinfo") or [{}])[0]
            meta = info.get("extmetadata", {})
            lic = meta.get("LicenseShortName", {}).get("value", "").strip()
            if not info.get("thumburl") or not OK_LICENSE.match(lic):
                continue
            artist = html.unescape(re.sub(r"<[^>]+>", "", meta.get("Artist", {}).get("value", ""))).strip()
            cats = [c["title"].removeprefix("Category:") for c in p.get("categories", [])]
            out[p["title"]] = (info["thumburl"], f"{artist or 'Wikimedia Commons'} · {lic}", cats)
    return out


def variants(bird):
    latin = bird["latin"]
    found, seen = [], set()
    for kind, query in KINDS:
        titles = [t for t in search(latin, query) if t not in seen
                  and t.lower().endswith((".jpg", ".jpeg"))
                  and not NOT_A_PHOTO.search(t) and not NOT_ALIVE.search(t)]
        info = details(titles)
        for t in titles:
            if t not in info:
                continue
            thumb, credit, cats = info[t]
            # Its own categories must name the species (not a cuckoo egg in a robin's nest).
            if not any(c == latin or c.startswith(latin + " ") for c in cats):
                continue
            seen.add(t)
            found.append({"file": t.removeprefix("File:"), "thumb": thumb, "credit": credit, "kind": kind})
    return found[:MAX]


def main():
    species = json.loads((OUT / "species.json").read_text(encoding="utf-8"))
    only = set(sys.argv[1].split(",")) if len(sys.argv) > 1 else None  # ids, for a quick test
    species = [b for b in species if not only or b["id"] in only]
    with ThreadPoolExecutor(WORKERS) as pool:
        result = dict(zip([b["id"] for b in species], pool.map(variants, species)))
    (CACHE / "variants.json").write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")
    counts = [len(v) for v in result.values()]
    print(f"{len(counts)} species: " + ", ".join(
        f"{n} photos {sum(c == n for c in counts)}" for n in range(MAX, -1, -1)))
    print("by kind:", {k: sum(p["kind"] == k for v in result.values() for p in v) for k, _ in KINDS})


if __name__ == "__main__":
    main()
