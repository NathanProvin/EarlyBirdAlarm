"""Builds app/assets/map/world.json, the offline map of the region screen, from Natural Earth
1:50m (public domain): land polygons (with their lakes as holes) and land borders as flat [lon, lat, lon, lat, ...]
lists in hundredths of a degree, simplified to drop points closer than STEP.
Usage: py pipeline/world_map.py"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from build import get  # cached HTTP

NE = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/"
STEP = 4  # hundredths of a degree (~4 km): finer than a 2° cell needs
OUT = Path(__file__).parent.parent / "app" / "assets" / "map" / "world.json"


def lines(geojson):
    """Every ring or line of the features, as rounded flat lists."""
    for f in geojson["features"]:
        g = f["geometry"]
        parts = {"Polygon": [g["coordinates"]], "MultiPolygon": g["coordinates"],
                 "LineString": [[g["coordinates"]]], "MultiLineString": [g["coordinates"]]}[g["type"]]
        for part in parts:
            for ring in part:  # land: outer ring then holes (Caspian, Great Lakes), filled even-odd
                yield simplify(ring)


def simplify(ring):
    out = []
    for lon, lat in ring:
        p = (round(lon * 100), round(lat * 100))
        if not out or max(abs(p[0] - out[-2]), abs(p[1] - out[-1])) >= STEP:
            out += p
    if len(out) < 2 or (out[-2], out[-1]) != p:
        out += p  # keep the last point so rings close and lines reach their end
    return out


assert simplify([(0, 0), (0.01, 0), (0.05, 0), (0.06, 0)]) == [0, 0, 5, 0, 6, 0]


def main():
    # Lakes (Caspian, Great Lakes...) are a layer of their own; inside land, even-odd makes them water.
    land = [r for f in ("ne_50m_land", "ne_50m_lakes") for r in lines(get(NE + f + ".geojson")) if len(r) >= 6]
    borders = [r for r in lines(get(NE + "ne_50m_admin_0_boundary_lines_land.geojson")) if len(r) >= 4]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"land": land, "borders": borders}, separators=(",", ":")))
    points = sum(map(len, land + borders)) // 2
    print(f"{len(land)} land rings, {len(borders)} borders, {points} points, {OUT.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
