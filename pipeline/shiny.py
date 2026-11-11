"""Shiny cards (roadmap 1.1, step 2): free photos of leucistic / melanistic birds of the
catalog, from iNaturalist aberration projects, an iNaturalist "melanistic" search and the
Commons category "Leucism in birds". Being in a project doesn't prove the aberration, so
each species gets a numbered contact sheet and the user picks.

    py pipeline/shiny.py     → cache/shiny/candidates.json, cache/shiny/sheets/<id>.jpg,
                               pipeline/shiny.csv (fill "pick": a number, blank = no shiny;
                               "kind": blank keeps the guessed one, else leucistic / melanistic)
"""
import csv
import io
import json

from PIL import Image, ImageDraw, ImageFont

from build import CACHE, OUT, ROOT, get
from variants import details

INAT = "https://api.inaturalist.org/v1/observations"
PROJECTS = [44275, 223038, 133673, 173534]  # Albino & Leucistic birds, Leucistic Birds,
# Albino, Leucistic & Melanistic Animals, Bird Aberrations (looked up 2026-11-11)
FREE = "cc0,cc-by,cc-by-sa"
PER_SPECIES = 9  # one 3 × 3 sheet
DIR = CACHE / "shiny"


def inat(params):
    """Every observation of an iNat query (200 a page)."""
    out, page = [], 1
    while True:
        r = get(INAT, {**params, "iconic_taxa": "Aves", "photo_license": FREE,
                       "per_page": 200, "page": page, "order_by": "votes"})
        out += r.get("results", [])
        if page * 200 >= min(r.get("total_results", 0), 10000):
            return out
        page += 1


def kind_of(obs, default):
    text = " ".join([obs.get("description") or "", *(obs.get("tags") or [])]).lower()
    return "melanistic" if "melan" in text else default


def main():
    species = json.loads((OUT / "species.json").read_text(encoding="utf-8"))
    by_latin = {b["latin"]: b for b in species}
    found = {}  # id -> candidates

    def add(latin, cand):
        b = by_latin.get(" ".join((latin or "").split()[:2]))  # subspecies → species
        if b and len(found.setdefault(b["id"], [])) < PER_SPECIES and \
                cand["url"] not in {c["url"] for c in found[b["id"]]}:
            found[b["id"]].append(cand)

    sources = [({"project_id": p}, "leucistic") for p in PROJECTS] + [({"q": "melanistic"}, "melanistic")]
    for params, default in sources:
        for o in inat(params):
            for ph in o.get("photos", [])[:1]:  # the observation's first photo
                if ph.get("license_code") not in FREE.split(","):
                    continue
                add((o.get("taxon") or {}).get("name"), {
                    "url": ph["url"].replace("/square.", "/medium."), "credit": ph.get("attribution", ""),
                    "kind": kind_of(o, default), "source": f"https://www.inaturalist.org/observations/{o['id']}"})

    r = get("https://commons.wikimedia.org/w/api.php", {
        "action": "query", "format": "json", "list": "categorymembers", "cmtitle": "Category:Leucism in birds",
        "cmtype": "file", "cmlimit": 500})
    titles = [m["title"] for m in r["query"]["categorymembers"] if m["title"].lower().endswith((".jpg", ".jpeg"))]
    for t, (thumb, credit, cats) in details(titles).items():
        for c in cats:
            add(c, {"url": thumb, "credit": credit, "kind": "leucistic",
                    "source": "https://commons.wikimedia.org/wiki/" + t.replace(" ", "_")})

    (DIR / "sheets").mkdir(parents=True, exist_ok=True)
    (DIR / "candidates.json").write_text(json.dumps(found, ensure_ascii=False, indent=1), encoding="utf-8")
    font = ImageFont.truetype("arialbd.ttf", 40)
    for bid, cands in found.items():
        sheet = Image.new("RGB", (900, 300 * ((len(cands) + 2) // 3)), "white")
        for i, c in enumerate(cands):
            img = Image.open(io.BytesIO(get(c["url"], binary=True))).convert("RGB")
            img.thumbnail((296, 296))
            x, y = 300 * (i % 3), 300 * (i // 3)
            sheet.paste(img, (x + (300 - img.width) // 2, y + (300 - img.height) // 2))
            ImageDraw.Draw(sheet).text((x + 8, y + 4), str(i + 1), fill="red", font=font,
                                       stroke_width=3, stroke_fill="white")
        sheet.save(DIR / "sheets" / f"{bid}.jpg", quality=85)

    picks = ROOT / "shiny.csv"
    old = {row["id"]: row for row in csv.DictReader(picks.open(encoding="utf-8"))} if picks.exists() else {}
    with picks.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, ["id", "en", "candidates", "pick", "kind"])
        w.writeheader()
        en = {b["id"]: b["en"] for b in species}
        for bid in sorted(found, key=en.get):
            prev = old.get(bid, {})
            w.writerow({"id": bid, "en": en[bid], "candidates": len(found[bid]),
                        "pick": prev.get("pick", ""), "kind": prev.get("kind", "")})
    print(f"{len(found)} species with candidates, {sum(map(len, found.values()))} photos; "
          f"sheets in {DIR / 'sheets'}, picks in {picks}")


if __name__ == "__main__":
    main()
