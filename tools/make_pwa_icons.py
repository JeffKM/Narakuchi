#!/usr/bin/env python3
"""T24 PWA 아이콘/스플래시 — 옥자 얼굴을 재활용해 앱 아이콘을 합성한다(신규 AI 아트 0).

옥자 기본 스탠딩(okja_idle)의 머리(마녀모자+얼굴)를 크롭해 버건디 라운드 배경 +
골드 링 위에 얹는다. nearest 업스케일로 굵은 픽셀 = 도트 아이덴티티를 유지.

산출:
  - 앱 아이콘  assets/sprites/pwa_icon_{144,180,192,512}.png  (Godot PWA 프리셋이 144/180/512 사용)
  - iOS 스플래시 assets/pwa/splash_*.png + head_include.html (deploy.sh 가 export/ 로 복사)

사용:
  tools/.venv/bin/python tools/make_pwa_icons.py
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "sprites", "okja_idle.png")
SPR = os.path.join(ROOT, "assets", "sprites")
PWA = os.path.join(ROOT, "assets", "pwa")

# 마스터 팔레트(→ data/palette.gd)
INK = (0x0d, 0x0b, 0x12, 255)
BURGUNDY_DARK = (0x4d, 0x12, 0x26, 255)
BURGUNDY = (0x7a, 0x1f, 0x3d, 255)
GOLD = (0xca, 0xa7, 0x5a, 255)

# okja_idle(128×288)에서 머리(마녀모자 중단~턱 아래) 정사각 크롭 영역.
HEAD_BOX = (16, 30, 112, 126)   # 96×96 — 모자 윗꼭지는 덜고 눈·코·입이 다 들어오게

ICON_SIZES = [512, 192, 180, 144]
# iOS 스플래시 — 현행 아이폰 세로 해상도 일부(나머지는 background_color 로 폴백).
SPLASH = [
  (1170, 2532),  # iPhone 12/13/14/15
  (1290, 2796),  # iPhone 15 Pro Max / 16 Plus
  (1179, 2556),  # iPhone 15/16
]


def _head() -> Image.Image:
  """옥자 머리 크롭(투명 배경 유지)."""
  return Image.open(SRC).convert("RGBA").crop(HEAD_BOX)


def make_icon(size: int, head: Image.Image) -> Image.Image:
  """정사각 앱 아이콘 — 버건디 라운드 배경 + 골드 링 + 옥자 머리(nearest 업스케일)."""
  img = Image.new("RGBA", (size, size), BURGUNDY_DARK)
  d = ImageDraw.Draw(img)
  # 중앙 버건디 원 + 골드 링(메이드/마녀 브랜드 점).
  m = size * 0.06
  ring = round(size * 0.025)
  d.ellipse([m, m, size - m, size - m], fill=BURGUNDY, outline=GOLD, width=max(2, ring))

  # 머리 — 원 안에 들어오게 ~70% 정사각으로 nearest 업스케일, 중앙(살짝 위).
  target = round(size * 0.70)
  face = head.resize((target, target), Image.NEAREST)
  fx = (size - target) // 2
  fy = round(size * 0.5 - target * 0.5 + size * 0.02)
  img.alpha_composite(face, (fx, fy))
  return img


def make_splash(w: int, h: int, icon512: Image.Image) -> Image.Image:
  """세로 스플래시 — 먹빛 배경 중앙에 아이콘(width 의 ~42%)."""
  img = Image.new("RGBA", (w, h), INK)
  side = round(w * 0.42)
  ic = icon512.resize((side, side), Image.NEAREST)
  img.alpha_composite(ic, ((w - side) // 2, (h - side) // 2))
  return img


def head_include() -> str:
  """export_presets html/head_include 에 넣을 apple-touch-startup-image 링크 블록."""
  lines = ['<link rel="apple-touch-icon" href="index.180x180.png">']
  for (w, h) in SPLASH:
    media = ("(device-width: %dpx) and (device-height: %dpx) and "
             "(-webkit-device-pixel-ratio: 3)") % (w // 3, h // 3)
    lines.append('<link rel="apple-touch-startup-image" media="%s" href="splash_%dx%d.png">'
                 % (media, w, h))
  return "\n".join(lines)


def main() -> None:
  os.makedirs(PWA, exist_ok=True)
  head = _head()

  icon512 = make_icon(512, head)
  for s in ICON_SIZES:
    icon = icon512 if s == 512 else make_icon(s, head)
    icon.save(os.path.join(SPR, "pwa_icon_%d.png" % s))
  print("✅ 앱 아이콘: pwa_icon_%s.png" % "/".join(str(s) for s in sorted(ICON_SIZES)))

  for (w, h) in SPLASH:
    make_splash(w, h, icon512).save(os.path.join(PWA, "splash_%dx%d.png" % (w, h)))
  print("✅ iOS 스플래시: %d종 → assets/pwa/" % len(SPLASH))

  snippet = os.path.join(PWA, "head_include.html")
  with open(snippet, "w") as f:
    f.write(head_include() + "\n")
  print("✅ head_include 스니펫: %s" % os.path.relpath(snippet, ROOT))


if __name__ == "__main__":
  main()
