#!/usr/bin/env python3
"""나라쿠치 도트화 파이프라인 — AI 생성 이미지를 규격 도트 에셋으로 강제 변환.

Gemini/Midjourney가 만든 '도트풍 큰 그림'을 받아 규격을 코드로 강제한다:
  1) 목표 규격으로 비율 맞춰 축소(fit)
  2) 마스터 32색 팔레트로 인덱싱 → 색 폭발 해결
  3) 알파 이진화(반투명 제거) → 도트 규격
  4) (LCD 사각 지정 시) 해당 칸을 투명 마스킹
  5) 검수 리포트 출력 → 규격 통과 여부 자동 판정
AI 결과 품질과 무관하게 산출물은 항상 규격에 맞는다.
(※ 게임기 셸 shell_frame.png는 tools/prep_shell.py 전용 — 이 파이프라인 대상 아님)

사용 예:
  python tools/dotify.py 원본.png --preset okja  --out okja_idle.png
  python tools/dotify.py 원본.png --preset cheki --out cheki.png
  python tools/dotify.py 원본.png --size 120x180 --transparent --out cheki.png
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PALETTE_HEX = os.path.join(ROOT, "assets", "palettes", "narakuchi.hex")

# 프리셋: (폭, 높이, 투명배경?, LCD사각 or None)
#  LCD = (x, y, w, h) — 셸 내부 게임 화면 구멍 (→ ADR 0001)
#  ⚠️ 게임기 셸(shell_frame.png)은 이 파이프라인이 아니라 tools/prep_shell.py로 생성한다.
#     (흰 배경 누끼 + LCD 정밀 펀칭이 필요해 fit+팔레트 파이프라인으로는 못 만든다)
PRESETS = {
  "okja":     (128, 288, True,  None),
  "sioni":    (48,  48,  True,  None),
  "bg":       (333, 480, False, None),  # 내부 교감화면 = 셸 LCD 구멍 333×480 (→ ADR 0001)
  "cheki":    (120, 180, True,  None),
  "portrait": (24,  24,  True,  None),  # 탭/로스터 미니 초상 — 콘텐츠 크롭 후 사방 균등 여백 중앙 정렬
}

# 캐릭터 프리셋 = 자동 충전(콘텐츠 크롭→높이 충전·하단정렬) 기본 on.
#  여백째 축소돼 작게 떠는 문제를 막아 모든 캐릭터·표정이 옥자와 같은 스케일로 정합된다.
#  배경(bg/cheki)은 화면을 꽉 채우는 그림이라 충전 대상 아님.
FILL_PRESETS = {"okja", "sioni"}

# 중앙 정렬 프리셋 = 콘텐츠만 크롭한 뒤 사방 균등 여백으로 '양축 중앙' 배치(하단정렬 아님).
#  얼굴 흉상 초상은 소스 프레이밍(가로로 넓게 잡힘)에 따라 좌우 여백이 0이 돼 "잘린 것처럼"
#  보이던 문제를 없앤다 — 소스가 어떻게 잡혀도 항상 사방에 숨 쉴 여백이 생긴다.
CENTER_PRESETS = {"portrait"}
CENTER_MARGIN = 0.12  # 초상 사방 여백 비율 (24px 기준 ~3px)


def load_palette(path=PALETTE_HEX):
  """마스터 팔레트(.hex)를 (N,3) float 배열로 로드."""
  with open(path) as f:
    hexes = [ln.strip().lstrip("#") for ln in f if ln.strip()]
  return np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in hexes], dtype=np.float32)


def fit_resize(im, target_w, target_h):
  """비율 유지 축소 후 중앙 배치(남는 곳 투명). 왜곡 없이 규격 캔버스에 안착."""
  src_w, src_h = im.size
  scale = min(target_w / src_w, target_h / src_h)
  new_w, new_h = max(1, round(src_w * scale)), max(1, round(src_h * scale))
  resized = im.resize((new_w, new_h), Image.BOX)
  canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
  canvas.paste(resized, ((target_w - new_w) // 2, (target_h - new_h) // 2))
  return canvas


def content_mask(arr, chroma=None, chroma_tol=48, alpha_thr=128):
  """배경(크로마/투명)을 뺀 콘텐츠(캐릭터) 픽셀 마스크. 크로마키·투명 PNG 모두 대응."""
  rgb, alpha = arr[:, :, :3], arr[:, :, 3]
  if chroma is not None:
    ck = np.array(chroma, dtype=np.float32)
    dist = np.sqrt(((rgb.astype(np.float32) - ck) ** 2).sum(2))
    return (dist > chroma_tol) & (alpha > alpha_thr)
  return alpha > alpha_thr


def crop_to_content(im, chroma=None, chroma_tol=48, alpha_thr=128):
  """원본 해상도에서 캐릭터 영역만 bbox로 잘라낸다(주변 여백 제거).
  축소 '전'에 잘라야 캐릭터가 캔버스를 꽉 채운다 — 여백째 줄면 작게 떠버린다."""
  mask = content_mask(np.array(im), chroma, chroma_tol, alpha_thr)
  ys, xs = np.where(mask)
  if len(xs) == 0:
    return im  # 콘텐츠 없음 — 원본 그대로
  return im.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def fill_canvas(im, target_w, target_h, head_margin=0.04):
  """캐릭터를 캔버스에 충전: 높이 우선으로 키워 머리 위 약간 여백·발은 바닥에 정렬.
  단 폭이 캔버스를 넘으면 폭 기준으로 제한(팔·꼬리 잘림 방지) — 이땐 높이가 덜 찬다.
  옥자 idle(충전 ~96%·바닥여백 0)과 같은 스케일로 모든 캐릭터·표정을 정합시킨다."""
  src_w, src_h = im.size
  scale = (target_h * (1 - head_margin)) / src_h  # 높이 우선
  if src_w * scale > target_w:                     # 폭 초과 → 폭 기준 제한
    scale = target_w / src_w
  new_w, new_h = max(1, round(src_w * scale)), max(1, round(src_h * scale))
  resized = im.resize((new_w, new_h), Image.BOX)
  canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
  canvas.paste(resized, ((target_w - new_w) // 2, target_h - new_h))  # 가로 중앙·하단 정렬
  return canvas


def center_fit_canvas(im, target_w, target_h, margin=CENTER_MARGIN):
  """콘텐츠를 양축 '중앙'에 사방 균등 여백으로 안착(초상 흉상용).
  fill_canvas(하단정렬)와 달리 위·아래·좌·우 여백을 똑같이 둬 작은 정사각 초상이
  어느 가장자리에도 붙지 않게 한다 — 호출 전 crop_to_content 로 배경 여백을 떼고 쓴다."""
  src_w, src_h = im.size
  avail_w, avail_h = target_w * (1 - margin), target_h * (1 - margin)
  scale = min(avail_w / src_w, avail_h / src_h)
  new_w, new_h = max(1, round(src_w * scale)), max(1, round(src_h * scale))
  resized = im.resize((new_w, new_h), Image.BOX)
  canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
  canvas.paste(resized, ((target_w - new_w) // 2, (target_h - new_h) // 2))  # 양축 중앙
  return canvas


def index_to_palette(rgb, pal):
  """각 픽셀을 가장 가까운 팔레트색으로 매핑(RGB 유클리드 최근접)."""
  flat = rgb.reshape(-1, 3).astype(np.float32)
  d = ((flat[:, None, :] - pal[None, :, :]) ** 2).sum(2)
  return pal[d.argmin(1)].astype(np.uint8).reshape(rgb.shape)


def dotify_image(im, target_w, target_h, transparent, lcd, alpha_thr=128,
                 chroma=None, chroma_tol=48, apply_palette=True, palette=None, fill=False,
                 center=False):
  """핵심 파이프라인(메모리 이미지): (충전/중앙정렬) → 축소 → (크로마키 제거) → 알파 이진화 → 팔레트 인덱싱 → LCD 투명.

  CLI(dotify)와 GUI(dot_studio)가 공유하는 단일 처리 함수. 규격 로직은 여기 한 곳에서만 산다.
  apply_palette=False는 팔레트 인덱싱 전 원본 색을 유지(미리보기 비교용).
  palette=(N,3) 배열을 주면 파일 대신 그 팔레트로 인덱싱(스튜디오 라이브 편집용).
  fill=True면 캐릭터를 캔버스에 꽉 충전(콘텐츠 크롭→높이 충전·하단정렬). 배경(bg/cheki)은 False.
  center=True면 콘텐츠 크롭→사방 균등 여백 양축 중앙(초상 흉상용 — 좌우 잘림 방지). fill 보다 우선.
  """
  im = im.convert("RGBA")
  if center:
    im = crop_to_content(im, chroma=chroma, chroma_tol=chroma_tol, alpha_thr=alpha_thr)
    im = center_fit_canvas(im, target_w, target_h)
  elif fill:
    im = crop_to_content(im, chroma=chroma, chroma_tol=chroma_tol, alpha_thr=alpha_thr)
    im = fill_canvas(im, target_w, target_h)
  else:
    im = fit_resize(im, target_w, target_h)
  arr = np.array(im)
  rgb, alpha = arr[:, :, :3], arr[:, :, 3]

  if chroma is not None:
    # 단색(크로마키) 배경 → 투명. AI가 만든 단색 배경 분리용.
    ck = np.array(chroma, dtype=np.float32)
    dist = np.sqrt(((rgb.astype(np.float32) - ck) ** 2).sum(2))
    mask = (dist > chroma_tol) & (alpha > alpha_thr)
  elif transparent:
    mask = alpha > alpha_thr
  else:
    mask = np.ones(alpha.shape, bool)
  if apply_palette:
    pal = palette if palette is not None else load_palette()
    mapped = index_to_palette(rgb, pal)
  else:
    mapped = rgb
  out = np.dstack([mapped, np.where(mask, 255, 0).astype(np.uint8)])

  if lcd:
    x, y, w, h = lcd
    out[y:y + h, x:x + w, 3] = 0  # 게임 화면 구멍 = 완전 투명

  return Image.fromarray(out, "RGBA")


def dotify(src_path, target_w, target_h, transparent, lcd, alpha_thr=128,
           chroma=None, chroma_tol=48, fill=False, center=False):
  """파일 경로 → 규격 도트 이미지(CLI용 얇은 래퍼)."""
  return dotify_image(Image.open(src_path), target_w, target_h, transparent, lcd,
                      alpha_thr=alpha_thr, chroma=chroma, chroma_tol=chroma_tol,
                      fill=fill, center=center)


def audit(img, target_w, target_h, pal, lcd, check_fill=False):
  """규격 검수 리포트. (통과여부, 라인들) 반환. check_fill=True면 충전·정렬도 검사(캐릭터)."""
  arr = np.array(img)
  w, h = img.size
  alpha = arr[:, :, 3]
  opaque = arr[alpha > 10][:, :3]
  uniq = np.unique(opaque.reshape(-1, 3), axis=0) if len(opaque) else np.empty((0, 3))

  # 팔레트 외 색 검출
  palset = {tuple(c) for c in pal.astype(np.uint8)}
  off = [tuple(c) for c in uniq if tuple(c) not in palset]
  # 반투명(0/255 외) 검출
  semi = int(((alpha > 10) & (alpha < 245)).sum())

  lines, ok = [], True
  def chk(cond, msg):
    nonlocal ok
    ok = ok and cond
    lines.append(("  ✅ " if cond else "  ❌ ") + msg)

  chk((w, h) == (target_w, target_h), f"치수 {w}×{h} (목표 {target_w}×{target_h})")
  chk(len(uniq) <= 32, f"고유 색 {len(uniq)}개 (≤32)")
  chk(len(off) == 0, f"팔레트 외 색 {len(off)}개 (=0)")
  chk(semi == 0, f"반투명 픽셀 {semi}개 (=0, 도트는 0/255만)")
  if check_fill:
    bbox = img.split()[3].getbbox()  # (l,t,r,b)
    if bbox:
      fillpct = (bbox[3] - bbox[1]) / h * 100
      foot = h - bbox[3]
      chk(fillpct >= 90, f"높이충전 {fillpct:.0f}% (≥90, 옥자 idle≈96%)")
      chk(foot <= 4, f"바닥여백 {foot}px (≤4, 발이 바닥에)")
    else:
      chk(False, "콘텐츠 없음(빈 이미지)")
  if lcd:
    x, y, lw, lh = lcd
    hole = arr[y:y + lh, x:x + lw, 3]
    chk(int(hole.max()) == 0, f"LCD칸({lw}×{lh}@{x},{y}) 완전 투명")
  return ok, lines


def main():
  ap = argparse.ArgumentParser(description="나라쿠치 도트화 파이프라인")
  ap.add_argument("src", help="원본 이미지(PNG)")
  ap.add_argument("--preset", choices=PRESETS.keys(), help="규격 프리셋")
  ap.add_argument("--size", help="직접 규격 지정 (예: 120x180)")
  ap.add_argument("--transparent", action="store_true", help="--size 사용 시 투명배경 처리")
  ap.add_argument("--out", required=True, help="출력 PNG 경로")
  ap.add_argument("--chroma", help="단색 배경색(예: 00ff00)을 투명 처리 — AI 단색 배경 분리용")
  ap.add_argument("--chroma-tol", type=int, default=48, help="크로마키 색 허용 오차(기본 48)")
  ap.add_argument("--preview", type=int, default=3, help="×N nearest 확대 미리보기 배율 (0=off)")
  ap.add_argument("--fill", dest="fill", action="store_true", default=None,
                  help="캐릭터를 캔버스에 꽉 충전(크롭→높이 충전·하단정렬). 캐릭터 프리셋은 기본 on")
  ap.add_argument("--no-fill", dest="fill", action="store_false",
                  help="자동 충전 끄기(여백 유지 중앙 배치)")
  ap.add_argument("--center", dest="center", action="store_true", default=None,
                  help="콘텐츠 크롭 후 사방 균등 여백 중앙 정렬(초상 흉상 — 좌우 잘림 방지). portrait 프리셋은 기본 on")
  ap.add_argument("--no-center", dest="center", action="store_false", help="중앙 정렬 끄기")
  args = ap.parse_args()

  chroma = None
  if args.chroma:
    h = args.chroma.lstrip("#")
    chroma = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

  if args.preset:
    tw, th, transparent, lcd = PRESETS[args.preset]
    fill_default = args.preset in FILL_PRESETS
    center_default = args.preset in CENTER_PRESETS
  elif args.size:
    tw, th = (int(v) for v in args.size.lower().split("x"))
    transparent, lcd = args.transparent, None
    fill_default = False
    center_default = False
  else:
    ap.error("--preset 또는 --size 중 하나는 필수")

  fill = fill_default if args.fill is None else args.fill        # --fill/--no-fill로 명시 시 우선
  center = center_default if args.center is None else args.center  # --center/--no-center로 명시 시 우선
  img = dotify(args.src, tw, th, transparent or chroma is not None, lcd, chroma=chroma,
               chroma_tol=args.chroma_tol, fill=fill, center=center)
  img.save(args.out)

  if args.preview > 0:
    pv = os.path.splitext(args.out)[0] + f"_x{args.preview}.png"
    img.resize((tw * args.preview, th * args.preview), Image.NEAREST).save(pv)

  ok, lines = audit(img, tw, th, load_palette(), lcd, check_fill=fill)
  print(f"\n=== 도트화: {os.path.basename(args.src)} → {args.out} ===")
  mode_note = "  (자동 충전 on)" if fill else ("  (중앙 정렬 on)" if center else "")
  print(f"프리셋: {args.preset or args.size}{mode_note}")
  print("\n[검수 리포트]")
  print("\n".join(lines))
  print(f"\n{'✅ 규격 통과 — 그대로 사용 가능' if ok else '⚠️ 일부 항목 미달 — pixilart 수동 정리 필요'}")
  if args.preview > 0:
    print(f"미리보기: {pv}")
  sys.exit(0 if ok else 1)


if __name__ == "__main__":
  main()
