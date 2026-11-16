"""Go / no-go sweep for a new zone: how many of its birds have a free recording, what each
recording source adds, and how many are already in the catalog.

Run from the repo root:  py pipeline/sweep_oc.py                (Australia, New Zealand: 1.2)
                         py pipeline/sweep_oc.py out.md "North Africa=MA,DZ,TN" "Mexico=MX,GT"
Species per country from GBIF (whole-year share, build.tier), then build.py's recording chain in
order: free xeno-canto (Latin name, then English name), iNaturalist (name), then the 1.2 sources:
GBIF sounds by species key (local or not), Wikimedia Commons audio. (xeno-canto by Wikidata's name
and iNaturalist by Wikidata's id were measured too: 1 species in all, dropped.) Writes pipeline/sweep_oc.md
(or the given file). Uses build.py's cache.
"""

import json
import sys
from collections import Counter

import build
from build import (ROOT, TIERS, commons_audio, gbif_name, gbif_sounds, get, inat_recordings, tier,
                   wikidata, xc_recordings)

ZONES = {"Australia": ["AU"], "New Zealand": ["NZ"]}
SOURCES = ["xeno-canto", "iNaturalist", "GBIF sounds, local", "GBIF sounds, captive / abroad", "Commons audio", "none"]


def species(countries):
    """{gbif key: (latin, tier)} of a zone's birds, by their share of all its bird records."""
    r = get("https://api.gbif.org/v1/occurrence/search",
            {"classKey": 212, "limit": 0, "occurrenceStatus": "PRESENT", "hasGeospatialIssue": "false",
             "country": countries, "facet": "speciesKey", "facetLimit": 1500})
    counts = {int(c["name"]): c["count"] for c in r["facets"][0]["counts"]}
    total = sum(counts.values())
    out = {}
    for key, n in counts.items():
        if t := tier(n, total):
            s = get(f"https://api.gbif.org/v1/species/{key}")
            out[key] = (s.get("canonicalName") or s["scientificName"], t)
    return out


def source(key, latin, en, xc_key):
    """The first source of build.py's chain that gives this species a recording."""
    if xc_recordings(latin, xc_key, 1) or (en and xc_recordings(latin, xc_key, 1, en=en)):
        return "xeno-canto"
    if inat_recordings(latin, 1):
        return "iNaturalist"
    if g := gbif_sounds(key, 1):
        return "GBIF sounds, local" if g[0]["local"] else "GBIF sounds, captive / abroad"
    return "Commons audio" if commons_audio(latin, 1) else "none"


def main():
    xc_key = (ROOT / "xc_key.txt").read_text().strip()
    out = ROOT / (sys.argv[1] if len(sys.argv) > 1 else "sweep_oc.md")
    zones = {name: codes.split(",") for name, codes in (a.split("=") for a in sys.argv[2:])} or ZONES
    catalog = {b["latin"] for b in json.loads((build.OUT / "species.json").read_text(encoding="utf-8"))}
    lines = [f"# Sweep: free recordings for {', '.join(zones)}", "",
             "First source of the recording chain that gives each species a clip (≥ 5 s, free licence).", ""]
    for name, codes in zones.items():
        birds = species(codes)
        wd = wikidata(birds)
        print(f"{name}: {len(birds)} species", flush=True)
        found, no_en, missing, known = {t: Counter() for t in TIERS}, Counter(), {}, Counter()
        for i, (key, (latin, t)) in enumerate(sorted(birds.items(), key=lambda kv: TIERS.index(kv[1][1]))):
            en = wd.get(key, ({},))[0].get("en") or gbif_name(key, "eng")
            if not en:
                no_en[t] += 1
            if latin in catalog:
                known[t] += 1
            src = source(key, latin, en, xc_key)
            found[t][src] += 1
            if src == "none":
                missing.setdefault(t, []).append(f"{latin} ({en})" if en else latin)
            if i % 100 == 0:
                print(f"  {i}/{len(birds)}", flush=True)
        lines += [f"## {name} ({', '.join(codes)}: {len(birds)} species)", "",
                  "| Tier | Species | Already in catalog | " + " | ".join(SOURCES) + " | Covered | No English name |",
                  "|---" * (len(SOURCES) + 5) + "|"]
        for t in TIERS:
            n = sum(found[t].values())
            if n:
                lines.append(f"| {t} | {n} | {known[t]} | " + " | ".join(str(found[t][s]) for s in SOURCES)
                             + f" | {100 * (n - found[t]['none']) // n} % | {no_en[t]} |")
        lines.append("")
        for t in TIERS[:3]:
            if missing.get(t):
                lines.append(f"No free recording ({t}): {', '.join(sorted(missing[t]))}")
        lines.append("")
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Written to {out}")


if __name__ == "__main__":
    sys.exit(main())
