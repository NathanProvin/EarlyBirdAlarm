"""Builds every logo image from pipeline/logo.png (1024 px, transparent, from the user, 2026-11-20):
  Android launcher icon   res/mipmap-*/ic_launcher_foreground.png, ic_launcher_monochrome.png
                          (adaptive layers, 108 dp) and ic_launcher.png (legacy, 48 dp)
  status-bar icon         res/drawable-*/ic_notification.png (white silhouette, 24 dp)
  store/icon-512.png      512 × 512 Play icon (Play applies its own rounded mask)
  store/feature-graphic.png 1024 × 500 feature graphic
  docs/logo.png           the README logo
  app/assets/icon.png     the logo on shared cards
  app/assets/logo.png     the logo on boosters and card backs (transparent)
  app/assets/logo_shadow.png the Alarm page's blurred backdrop (white silhouette, tinted in the app)
Lettering: Roboto (Apache 2.0, shipped with Flutter). Usage: py pipeline/store_assets.py"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).parent.parent
FONTS = ROOT / ".tools" / "flutter" / "bin" / "cache" / "artifacts" / "material_fonts"
RES = ROOT / "app" / "android" / "app" / "src" / "main" / "res"
PAPER, INK = (246, 241, 234), (28, 27, 26)  # ui/theme.dart; PAPER = ic_launcher_background.xml
RARITY = [(140, 133, 123), (79, 143, 91), (59, 125, 184), (138, 79, 176), (217, 162, 27)]
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
LOGO = Image.open(ROOT / "pipeline" / "logo.png").convert("RGBA")


def reach(img):
    """The farthest visible pixel from the centre, as a share of the image's width."""
    a, (w, h) = img.getchannel("A").load(), img.size
    return max(math.hypot(x - w / 2, y - h / 2) for y in range(0, h, 2) for x in range(0, w, 2) if a[x, y] > 16) / w


# Adaptive icons guarantee only a 66-unit circle of the 108-unit canvas: the logo is scaled to fit it.
SCALE = 33 / 108 / reach(LOGO)  # logo width / canvas width
assert 0.5 < SCALE < 1.2, SCALE


def canvas(size, units=108, bg=None):
    """The logo on a size-px square showing the central `units` of the 108-unit adaptive canvas."""
    side = round(size * 108 / units * SCALE)
    out = Image.new("RGBA", (size, size), bg or (0, 0, 0, 0))
    logo = LOGO.resize((side, side), Image.LANCZOS)
    out.alpha_composite(logo, ((size - side) // 2, (size - side) // 2)) if side <= size else \
        out.alpha_composite(logo.crop(((side - size) // 2,) * 2 + ((side + size) // 2,) * 2))
    return out


def white(img):
    """The image's silhouette in white (Android tints monochrome and status-bar icons)."""
    out = Image.new("RGBA", img.size, (255, 255, 255, 0))
    out.putalpha(img.getchannel("A"))
    return out


def icon(size):
    # Launchers show the central 72 units of the 108-unit canvas, on the paper background.
    return canvas(size, 72, PAPER + (255,)).convert("RGB")


def feature_graphic():
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), PAPER)
    logo = LOGO.resize((round(h * 0.84 / (2 * reach(LOGO))),) * 2, Image.LANCZOS)  # ~84 % of the height
    img.paste(logo, (250 - logo.width // 2, (h - logo.height) // 2), logo)
    big = img.resize((w * 4, h * 4), Image.LANCZOS)  # lettering supersampled
    d = ImageDraw.Draw(big)
    font = lambda name, px: ImageFont.truetype(str(FONTS / name), px * 4)
    x = 500 * 4
    d.text((x, 150 * 4), "Early Bird", font=font("roboto-bold.ttf", 76), fill=INK)
    d.text((x, 240 * 4), "Wake up to real bird songs.", font=font("roboto-regular.ttf", 32), fill=INK)
    d.text((x, 284 * 4), "Guess the bird, win its card.", font=font("roboto-regular.ttf", 32), fill=INK)
    for i, c in enumerate(RARITY):  # the five rarities
        cx, cy, r = x + (12 + i * 34) * 4, 360 * 4, 11 * 4
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)
    return big.resize((w, h), Image.LANCZOS)


def main():
    for name, k in DENSITIES.items():
        (RES / f"mipmap-{name}").mkdir(exist_ok=True)
        (RES / f"drawable-{name}").mkdir(exist_ok=True)
        fg = canvas(round(108 * k))
        fg.save(RES / f"mipmap-{name}" / "ic_launcher_foreground.png")
        white(fg).save(RES / f"mipmap-{name}" / "ic_launcher_monochrome.png")
        icon(round(48 * k)).save(RES / f"mipmap-{name}" / "ic_launcher.png")
        # Status bar: the logo filling 22 of the 24 dp.
        white(canvas(round(24 * k), 108 * 2 * reach(LOGO) * SCALE / (22 / 24))).save(
            RES / f"drawable-{name}" / "ic_notification.png")
    (ROOT / "store").mkdir(exist_ok=True)
    (ROOT / "docs").mkdir(exist_ok=True)
    icon(512).convert("RGBA").save(ROOT / "store" / "icon-512.png")  # Play wants a 32-bit PNG
    icon(512).save(ROOT / "docs" / "logo.png")
    icon(192).save(ROOT / "app" / "assets" / "icon.png")
    feature_graphic().save(ROOT / "store" / "feature-graphic.png")
    # Cropped to the logo's circle, so it fills the booster's paper disc.
    r = reach(LOGO) * LOGO.width
    c = LOGO.width / 2
    LOGO.crop((round(c - r),) * 2 + (round(c + r),) * 2).resize((384, 384), Image.LANCZOS) \
        .save(ROOT / "app" / "assets" / "logo.png")
    # Backdrop: a 512 px silhouette with room for its blur (bigger, sharper: 2026-11-22).
    shadow = white(canvas(512, 108 * 1.1)).filter(ImageFilter.GaussianBlur(9))
    shadow.save(ROOT / "app" / "assets" / "logo_shadow.png")
    print("launcher, notification, store, docs and app logo images written")


if __name__ == "__main__":
    main()
