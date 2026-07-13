#!/usr/bin/env python3
"""Generates the SMART Rajasthan launcher icons.

Outputs:
  assets/icon/icon.png            -> full 1024 icon (navy bg + emblem + wordmark)
  assets/icon/icon_foreground.png -> emblem only, transparent (adaptive foreground)

Run:  python3 tool/make_icon.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

S = 1024
SS = 4               # supersample factor for smooth edges
W = S * SS

NAVY      = (0, 48, 135)
NAVY_DK   = (0, 32, 92)
GOLD      = (255, 179, 0)
SAFFRON   = (255, 107, 0)
WHITE     = (255, 255, 255)

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
os.makedirs(OUT_DIR, exist_ok=True)


def vgradient(size, top, bottom):
    img = Image.new("RGB", (1, size), 0)
    for y in range(size):
        t = y / (size - 1)
        img.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img.resize((size, size))


def load_font(px):
    for path in [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
    ]:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, px)
            except Exception:
                pass
    return ImageFont.load_default()


def draw_emblem(d, cx, cy, scale, with_ring=True):
    """A classic pillared government building inside a gold ring."""
    r = int(300 * SS * scale)
    if with_ring:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
        ring = int(26 * SS * scale)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=GOLD, width=ring)

    u = r / 300.0  # unit relative to ring radius

    # Roof (triangle pediment)
    roof_w = int(330 * u)
    roof_h = int(95 * u)
    roof_top = cy - int(150 * u)
    d.polygon([
        (cx, roof_top),
        (cx - roof_w // 2, roof_top + roof_h),
        (cx + roof_w // 2, roof_top + roof_h),
    ], fill=NAVY)

    # Architrave bar under roof
    bar_y = roof_top + roof_h
    bar_h = int(26 * u)
    d.rectangle([cx - roof_w // 2, bar_y, cx + roof_w // 2, bar_y + bar_h], fill=NAVY)

    # Pillars
    p_top = bar_y + bar_h + int(14 * u)
    p_bot = cy + int(120 * u)
    n = 4
    span = int(250 * u)
    pw = int(34 * u)
    left = cx - span // 2
    gap = (span - pw) / (n - 1)
    for i in range(n):
        x = int(left + i * gap)
        d.rectangle([x, p_top, x + pw, p_bot], fill=NAVY)

    # Base steps (gold)
    step_y = p_bot + int(8 * u)
    d.rectangle([cx - int(160 * u), step_y, cx + int(160 * u), step_y + int(22 * u)], fill=GOLD)
    d.rectangle([cx - int(185 * u), step_y + int(22 * u), cx + int(185 * u), step_y + int(48 * u)], fill=GOLD)


# ── Full icon ────────────────────────────────────────────────────────────────
bg = vgradient(W, NAVY, NAVY_DK)
icon = bg.copy()
d = ImageDraw.Draw(icon)

cx, cy = W // 2, int(W * 0.43)
draw_emblem(d, cx, cy, scale=1.0)

# Saffron accent + wordmark
font = load_font(int(150 * SS))
text = "SMART"
tb = d.textbbox((0, 0), text, font=font)
tw, th = tb[2] - tb[0], tb[3] - tb[1]
ty = int(W * 0.74)
d.text((cx - tw // 2 - tb[0], ty - tb[1]), text, font=font, fill=WHITE)
d.rounded_rectangle(
    [cx - int(90 * SS), ty + th + int(40 * SS), cx + int(90 * SS), ty + th + int(72 * SS)],
    radius=int(16 * SS), fill=SAFFRON,
)

icon = icon.resize((S, S), Image.LANCZOS)
icon.save(os.path.join(OUT_DIR, "icon.png"))

# ── Adaptive foreground (emblem only, transparent, within safe zone) ──────────
fg = Image.new("RGBA", (W, W), (0, 0, 0, 0))
fd = ImageDraw.Draw(fg)
draw_emblem(fd, W // 2, W // 2, scale=0.62)  # keep inside adaptive safe area
fg = fg.resize((S, S), Image.LANCZOS)
fg.save(os.path.join(OUT_DIR, "icon_foreground.png"))

print("wrote", os.path.join(OUT_DIR, "icon.png"))
print("wrote", os.path.join(OUT_DIR, "icon_foreground.png"))
