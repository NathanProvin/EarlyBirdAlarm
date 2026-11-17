"""Card variants (roadmap 1.1, step 2): up to 5 extra photos per species from Commons
Featured, Valued and Quality images, best first, free licences only (same filter as the
catalog photo), then (1.2) iNaturalist research-grade photos, most faved first, to fill up to 5.
Writes cache/variants.json {species id: [{file, thumb, credit, kind}]}.

    py pipeline/variants.py          (all species, cached HTTP: a rerun is quick)
"""
import io
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

from build import CACHE, IDS, ROOT, NOT_A_PHOTO, OK_LICENSE, OUT, PHOTO_WIDTH, WORKERS, get, html, synonyms

MAX = 5
# Off-topic iNaturalist photos (a bird on a kangaroo, a sign, a net), spotted on contact sheets:
# one "file" per line (inat-<photo id>, or a Commons file name); the next candidate takes the place.
REJECTS = ROOT / "photo_rejects.csv"
KEY_OF = {i: k for k, i in json.loads(IDS.read_text(encoding="utf-8")).items()} if IDS.exists() else {}
API = "https://commons.wikimedia.org/w/api.php"
KINDS = [  # best first
    ("featured", 'incategory:"Featured_pictures_on_Wikimedia_Commons"'),
    ("valued", 'hastemplate:"VI"'),
    ("quality", 'hastemplate:"Quality image"'),
]
# Museum skins and eggs (Toulouse MHNT), on top of the catalog's NOT_A_PHOTO.
NOT_ALIVE = re.compile(r"\bMHNT\b|\bHdB\b|\bzoo\b", re.I)  # zoo: captive birds, not wild ones
assert NOT_ALIVE.search("Corvus corax MHNT.ZOO.2010.11.175.1.jpg")
assert NOT_ALIVE.search("Triton cockatoo (Cacatua galerita triton), Gembira Loka Zoo, Yogyakarta.jpg")


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


def inat_taxon(latin):
    """(iNaturalist taxon id, its current name) for this exact name, or (None, None)."""
    t = get("https://api.inaturalist.org/v1/taxa", {"q": latin, "rank": "species", "per_page": 10})
    return next(((x["id"], x["name"]) for x in t.get("results", [])
                 if (x.get("matched_term") or "").lower() == latin.lower()), (None, None))


def ahash(url):
    """64-bit average hash of a photo: the same shot uploaded twice (a crop, a re-edit) is within a few bits."""
    img = Image.open(io.BytesIO(get(url, binary=True))).convert("L").resize((8, 8))
    px = list(img.getdata())
    return sum(1 << i for i, p in enumerate(px) if p > sum(px) / 64)


def variants(bird, old=()):
    """Up to MAX photos: old (the last run's picks, kept in place: photo files are numbered in this
    order and cards point at them), then Commons under both names, then iNaturalist."""
    taxon, alt = inat_taxon(bird["latin"])
    # A GBIF name iNaturalist doesn't know (American Goshawk: Falco atricapillus): its GBIF synonyms.
    for syn in synonyms(KEY_OF[bird["id"]]) if not taxon and bird["id"] in KEY_OF else ():
        if (found := inat_taxon(syn))[0]:
            taxon, alt = found
            break
    # Commons may file the bird under its other name (Australian Magpie: Gymnorhina tibicen).
    names = [bird["latin"]] + ([alt] if alt and alt != bird["latin"] else [])
    found = [x for kind, query in KINDS for latin in names for x in commons_kind(latin, kind, query)]
    found += inat_photos(taxon, MAX)
    rejects = set(REJECTS.read_text(encoding="utf-8").splitlines()[1:]) if REJECTS.exists() else set()
    found = [x for x in found if x["file"] not in rejects]
    out = [x for x in old if x["file"] not in rejects]  # only new (iNat) photos get rejected: numbering holds
    hashes = [ahash(x["thumb"].replace("/original.", "/medium.")) for x in out]
    for x in found:  # best first
        h = ahash(x["thumb"].replace("/original.", "/medium."))
        # One per photographer (a burst of the same bird is within the hash's reach of a real
        # second photo, 2026-11-15 sample) and no re-upload of the same shot.
        if len(out) < MAX and x["credit"] not in {o["credit"] for o in out}                 and all(bin(h ^ k).count("1") > 6 for k in hashes):
            out.append(x)
            hashes.append(h)
    return out


def commons_kind(latin, kind, query):
    titles = [t for t in search(latin, query) if t.lower().endswith((".jpg", ".jpeg"))
              and not NOT_A_PHOTO.search(t) and not NOT_ALIVE.search(t)]
    info = details(titles)
    # Its own categories must name the species (not a cuckoo egg in a robin's nest).
    return [{"file": t.removeprefix("File:"), "thumb": info[t][0], "credit": info[t][1], "kind": kind}
            for t in titles if t in info and any(c == latin or c.startswith(latin + " ") for c in info[t][2])]


INAT_LIC = {"cc0": "CC0", "cc-by": "CC BY 4.0", "cc-by-sa": "CC BY-SA 4.0"}
MIN_WIDTH = 1200  # the card photo box is ~920 px wide full screen: no upscaled photo


def inat_photos(taxon, n):
    """Up to n free iNaturalist photos (research grade), most faved observations first, landscape
    and at least MIN_WIDTH wide, one per observer. Appended after Commons, so existing picks keep
    their place (photo files are numbered in this order)."""
    if not taxon or n <= 0:
        return []
    query = {"taxon_id": taxon, "quality_grade": "research", "photo_license": ",".join(INAT_LIC),
             "order_by": "votes", "per_page": 50}
    # Annotated "Alive" first (unannotated picks were often dead birds, birds in a hand, feathers),
    # then any not annotated "Dead"; faved ones before the rest (rejected half as often on review).
    obs = []
    for extra in ({"term_id": 17, "term_value_id": 18}, {"without_term_value_id": 19}):
        obs += get("https://api.inaturalist.org/v1/observations", query | extra).get("results", [])
    obs.sort(key=lambda o: not o.get("faves_count"))
    out, users = [], set()
    for o in obs:
        user = (o.get("user") or {}).get("name") or (o.get("user") or {}).get("login")
        for p in (o.get("photos") or [])[:1]:  # the observer's first photo: usually their best
            dims = p.get("original_dimensions") or {}
            if len(out) >= n or user in users or p.get("license_code") not in INAT_LIC \
                    or not p.get("url", "").lower().endswith((".jpg", ".jpeg", ".png")) \
                    or dims.get("width", 0) < MIN_WIDTH or dims["width"] < dims.get("height", 0):
                continue
            users.add(user)  # also skips an observation both queries returned
            out.append({"file": f"inat-{p['id']}", "thumb": p["url"].replace("/square.", "/original."),
                        "credit": f"{user} · iNaturalist · {INAT_LIC[p['license_code']]}", "kind": "inaturalist"})
    return out


def main():
    species = json.loads((OUT / "species.json").read_text(encoding="utf-8"))
    only = set(sys.argv[1].split(",")) if len(sys.argv) > 1 else None  # ids, for a quick test
    species = [b for b in species if not only or b["id"] in only]
    path = CACHE / "variants.json"
    old = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    with ThreadPoolExecutor(WORKERS) as pool:
        result = dict(zip([b["id"] for b in species], pool.map(lambda b: variants(b, old.get(b["id"], [])), species)))
    (CACHE / "variants.json").write_text(json.dumps(old | result, ensure_ascii=False, indent=1), encoding="utf-8")
    counts = [len(v) for v in result.values()]
    print(f"{len(counts)} species: " + ", ".join(
        f"{n} photos {sum(c == n for c in counts)}" for n in range(MAX, -1, -1)))
    print("by kind:", {k: sum(p["kind"] == k for v in result.values() for p in v) for k in [*dict(KINDS), "inaturalist"]})


if __name__ == "__main__":
    main()
