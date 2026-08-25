#!/usr/bin/env python3
"""Generate PanSou app icons (64x64 & 256x256).

Renders a rounded square background with a magnifier glyph and the text "PS".
"""

from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def rounded_rect(size: int, radius_ratio: float = 0.22):
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    r = int(size * radius_ratio)

    grad = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    top = (20, 160, 140)
    bottom = (10, 90, 80)
    for y in range(size):
        t = y / max(size - 1, 1)
        cr = int(top[0] + (bottom[0] - top[0]) * t)
        cg = int(top[1] + (bottom[1] - top[1]) * t)
        cb = int(top[2] + (bottom[2] - top[2]) * t)
        gd.line([(0, y), (size, y)], fill=(cr, cg, cb, 255))

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=r, fill=255
    )
    base.paste(grad, (0, 0), mask)
    return base


def draw_magnifier(im: Image.Image):
    d = ImageDraw.Draw(im)
    size = im.size[0]
    cx, cy = int(size * 0.40), int(size * 0.40)
    r = int(size * 0.22)
    line = max(3, size // 22)
    d.ellipse(
        (cx - r, cy - r, cx + r, cy + r),
        outline=(255, 255, 255, 240),
        width=line,
    )
    hx1, hy1 = int(cx + r * 0.72), int(cy + r * 0.72)
    hx2, hy2 = int(cx + r * 1.75), int(cy + r * 1.75)
    d.line((hx1, hy1, hx2, hy2), fill=(255, 255, 255, 240), width=line + 1)
    d.ellipse(
        (hx2 - line // 2, hy2 - line // 2,
         hx2 + line // 2, hy2 + line // 2),
        fill=(255, 255, 255, 240),
    )


def draw_label(im: Image.Image, text: str = "PS"):
    d = ImageDraw.Draw(im)
    size = im.size[0]
    font_size = int(size * 0.32)
    font = None
    for path in (
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ):
        try:
            font = ImageFont.truetype(path, font_size)
            break
        except OSError:
            continue
    if font is None:
        font = ImageFont.load_default()

    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = size - tw - int(size * 0.14) - bbox[0]
    y = size - th - int(size * 0.16) - bbox[1]
    d.text((x + max(1, size // 128), y + max(1, size // 128)),
           text, font=font, fill=(0, 0, 0, 90))
    d.text((x, y), text, font=font, fill=(255, 255, 255, 245))


def make_icon(size: int, out: Path):
    im = rounded_rect(size)
    draw_magnifier(im)
    out.parent.mkdir(parents=True, exist_ok=True)
    im.save(out, "PNG", optimize=True)
    print(f"wrote {out} ({size}x{size})")


if __name__ == "__main__":
    make_icon(64, ROOT / "ICON.PNG")
    make_icon(256, ROOT / "ICON_256.PNG")
    make_icon(64, ROOT / "app/ui/images/icon-64.png")
    make_icon(256, ROOT / "app/ui/images/icon-256.png")
