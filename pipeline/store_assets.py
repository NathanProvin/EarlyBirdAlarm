"""Builds the Google Play graphics from the app's own icon shapes and colours:
  store/icon-512.png        512 × 512 app icon (Play applies its own rounded mask)
  store/feature-graphic.png 1024 × 500 feature graphic
  docs/logo.png             the README logo (same as the icon)
  app/assets/icon.png       the logo on shared cards (same as the icon)
The icon is the vector of app/android/app/src/main/res/drawable/ic_launcher_foreground.xml
(108-unit canvas), drawn at 4× and scaled down for smooth edges. Lettering: Roboto (Apache 2.0,
shipped with Flutter). Usage: py pipeline/store_assets.py"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).parent.parent
FONTS = ROOT / ".tools" / "flutter" / "bin" / "cache" / "artifacts" / "material_fonts"
PAPER, INK, CORAL = (246, 241, 234), (28, 27, 26), (232, 106, 79)  # ui/theme.dart
RARITY = [(140, 133, 123), (79, 143, 91), (59, 125, 184), (138, 79, 176), (217, 162, 27)]
SS = 4  # supersampling


def bird(draw, s, ox, oy):
    """The icon's sun, horizon and perched bird; one icon unit = s pixels, offset (ox, oy)."""
    P = lambda x, y: (ox + x * s, oy + y * s)
    def ellipse(cx, cy, rx, ry, fill):
        draw.ellipse([P(cx - rx, cy - ry), P(cx + rx, cy + ry)], fill=fill)
    draw.pieslice([P(30, 42), P(78, 90)], 180, 360, fill=CORAL)   # half-sun, centre (54, 66) r 24
    draw.rectangle([P(24, 66), P(84, 69)], fill=INK)              # horizon
    ellipse(66, 59, 8, 6, INK)                                    # body
    ellipse(73, 52, 4, 4, INK)                                    # head
    draw.polygon([P(76.5, 50.8), P(81.5, 52.5), P(76.5, 54.2)], fill=INK)            # beak
    draw.polygon([P(59, 57), P(50, 63), P(54.5, 64.2), P(61.5, 61)], fill=INK)        # tail
    draw.rectangle([P(64, 64), P(65.4, 66.5)], fill=INK)          # legs
    draw.rectangle([P(68.5, 64), P(69.9, 66.5)], fill=INK)
    ellipse(74.5, 51.4, 0.9, 0.9, PAPER)                          # eye


def icon(size):
    # Launchers show the central 72 units of the 108-unit adaptive canvas: the same here.
    big = Image.new("RGB", (size * SS, size * SS), PAPER)
    s = size * SS / 72
    bird(ImageDraw.Draw(big), s, -18 * s, -18 * s)
    return big.resize((size, size), Image.LANCZOS)


def feature_graphic():
    w, h = 1024, 500
    big = Image.new("RGB", (w * SS, h * SS), PAPER)
    d = ImageDraw.Draw(big)
    # The icon scene on the left, large: the horizon line spans the left half.
    s = 6.6 * SS
    bird(d, s, -16 * s, (h * SS - 108 * s) / 2 + 6 * s)  # horizon ends ~450 px, before the text
    font = lambda name, px: ImageFont.truetype(str(FONTS / name), px * SS)
    x = 500 * SS
    d.text((x, 150 * SS), "Early Bird", font=font("roboto-bold.ttf", 76), fill=INK)
    d.text((x, 240 * SS), "Wake up to real bird songs.", font=font("roboto-regular.ttf", 32), fill=INK)
    d.text((x, 284 * SS), "Guess the bird, win its card.", font=font("roboto-regular.ttf", 32), fill=INK)
    for i, c in enumerate(RARITY):  # the five rarities
        cx, cy, r = x + (12 + i * 34) * SS, 360 * SS, 11 * SS
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)
    return big.resize((w, h), Image.LANCZOS)


def main():
    out = ROOT / "store"
    out.mkdir(exist_ok=True)
    (ROOT / "docs").mkdir(exist_ok=True)
    icon(512).convert("RGBA").save(out / "icon-512.png")  # Play wants a 32-bit PNG
    icon(512).save(ROOT / "docs" / "logo.png")
    icon(192).save(ROOT / "app" / "assets" / "icon.png")  # the logo on shared cards
    feature_graphic().save(out / "feature-graphic.png")
    print("store/icon-512.png, store/feature-graphic.png, docs/logo.png, app/assets/icon.png")


if __name__ == "__main__":
    main()
