#!/usr/bin/env python3
"""Generates the launcher icons from the brand tokens.

Design (v2 "Ink & Paper"): a Cormorant Garamond "FJ" monogram in paper on ink,
with a short hairline beneath — the same type-first language as the app.
v1 used Noto Serif KR on accent green (#365B4C) with paper #F8F7F3.

Usage: python3 tool/generate_icons.py   (requires Pillow)
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), '..')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'CormorantGaramond-SemiBold.ttf')
ACCENT = (0x17, 0x17, 0x14, 255)  # ink
PAPER = (0xF4, 0xF0, 0xE7, 255)
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')

LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
ADAPTIVE = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}


def draw_monogram(size, glyph_box, background):
    """Draws "FJ" plus a hairline, optically centred inside [glyph_box] px."""
    img = Image.new('RGBA', (size, size), background)
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, int(glyph_box * 0.46))
    text = 'FJ'
    tracking = glyph_box * 0.015
    widths = [d.textlength(ch, font=font) for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    bbox = d.textbbox((0, 0), text, font=font)  # includes the J descender
    glyph_h = bbox[3] - bbox[1]
    gap = glyph_box * 0.07
    line_h = max(1, glyph_box * 0.011)
    block_h = glyph_h + gap + line_h
    top = (size - block_h) / 2
    x = (size - total) / 2
    for ch, w in zip(text, widths):
        d.text((x, top - bbox[1]), ch, font=font, fill=PAPER)
        x += w + tracking
    line_w = glyph_box * 0.16
    line_y = top + glyph_h + gap
    d.rectangle([(size - line_w) / 2, line_y, (size + line_w) / 2, line_y + line_h], fill=PAPER)
    return img


def rounded(img, radius_ratio=0.22):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1], radius=int(img.size[0] * radius_ratio), fill=255)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def main():
    for density, px in LEGACY.items():
        folder = os.path.join(RES, f'mipmap-{density}')
        os.makedirs(folder, exist_ok=True)
        big = draw_monogram(px * 4, px * 4, ACCENT)
        rounded(big).resize((px, px), Image.LANCZOS).save(os.path.join(folder, 'ic_launcher.png'))
    for density, px in ADAPTIVE.items():
        folder = os.path.join(RES, f'mipmap-{density}')
        # Adaptive foreground: glyph inside the 66/108 safe zone, transparent bg.
        fg = draw_monogram(px * 4, int(px * 4 * 66 / 108), (0, 0, 0, 0))
        fg.resize((px, px), Image.LANCZOS).save(os.path.join(folder, 'ic_launcher_foreground.png'))
    # Store / documentation icon.
    os.makedirs(os.path.join(ROOT, 'docs', 'design'), exist_ok=True)
    rounded(draw_monogram(1024, 1024, ACCENT)).save(os.path.join(ROOT, 'docs', 'design', 'app_icon_1024.png'))
    draw_monogram(512, 512, ACCENT).save(os.path.join(ROOT, 'docs', 'design', 'play_store_icon_512.png'))
    print('icons written')


if __name__ == '__main__':
    main()
