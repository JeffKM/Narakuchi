#!/usr/bin/env python3
"""나라쿠치 워터마크 제거 — Gemini ✦ 스파클을 도트 에셋에서 찾아 인페인트.

Gemini/Imagen 생성 이미지는 우하단에 은색 4각 스파클(✦) 워터마크를 박는다.
dotify 처리 후에도 작은 은빛/크림빛 덩어리로 남아 인게임에 거슬린다. 이 도구가:
  1) 우하단 코너에서 '채도 낮고(은색) 국소적으로 밝은' 스파클을 검출
     (연결요소 + 크기·형태·고립 필터로 흰 옷·금속 하이라이트 오검출 배제)
  2) 주변 픽셀로 인페인트해 지운다(투명 보존). 세로 줄무늬 구조는 --vertical.
검출이 애매하면 --box 로 영역을 직접 지정한다(은색 자동 / --solid 면 박스 통째).

작업 흐름(권장): 먼저 미리보기로 검출을 눈으로 확인 → 맞으면 --apply.
  - 미리보기는 `<파일>.prev.png`(빨강=검출), 적용 시 원본은 `<파일>.bak` 로 백업
    (둘 다 .gitignore 대상). PNG만 고치므로 적용 후 Godot 에디터에서 재임포트하면 된다.

사용:
  # 검출 미리보기(원본 불변) — 기본 동작
  tools/.venv/bin/python tools/dewatermark.py assets/sprites/gate_naraka.png
  # 적용
  tools/.venv/bin/python tools/dewatermark.py assets/sprites/bg_naraka.png --apply
  # 영역 직접 지정 + 세로채움(문틀 같은 세로 줄무늬 보존)
  tools/.venv/bin/python tools/dewatermark.py assets/sprites/gate_naraka.png --box 303,448,17,18 --vertical --apply
  # 따뜻한 톤 스파클(은색 아님) — 박스 통째 인페인트
  tools/.venv/bin/python tools/dewatermark.py assets/sprites/frame_standard.png --box 106,167,11,10 --solid --apply
  # 여러 장 한 번에 미리보기
  tools/.venv/bin/python tools/dewatermark.py assets/sprites/*.png
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

# ── 기본 파라미터 (플레이테스트로 조정 가능) ────────────────────
SAT_MAX = 0.12        # 은색 판정: 채도(max-min)가 이 값 미만
BRIGHT_MIN = 0.45     # 은색 판정: 밝기((r+g+b)/3)가 이 값 초과
LOCAL_DELTA = 0.12    # 자동 검출: 국소 평균보다 이만큼 밝아야(떠 있는 스파클)
CORNER_W = 0.45       # 자동 검출 범위: 우측 폭 비율
CORNER_H = 0.40       # 자동 검출 범위: 하단 높이 비율
MIN_PX = 5            # 스파클 연결요소 최소 픽셀
MAX_PX = 120          # 최대 픽셀(이상은 옷·배경 덩어리로 보고 배제)
MAX_DIM = 28          # 스파클 bbox 한 변 최대(px)
MIN_FILL = 0.22       # bbox 채움률 최소(컴팩트한 덩어리만)
ISOLATION = 0.10      # 고립: bbox 바깥 링이 덩어리보다 이만큼 어두워야


def _load_rgba(path):
  """PNG → (H,W,4) float[0,1]."""
  im = Image.open(path).convert("RGBA")
  return np.asarray(im, dtype=np.float32) / 255.0


def _save_rgba(path, arr):
  out = np.clip(arr, 0.0, 1.0) * 255.0
  # 백업은 `<name>.png.bak` 라 확장자로 포맷 추론이 안 됨 → PNG 명시
  Image.fromarray(out.round().astype(np.uint8), "RGBA").save(path, format="PNG")


def _bright(arr):
  return arr[..., :3].mean(axis=-1)


def _sat(arr):
  return arr[..., :3].max(axis=-1) - arr[..., :3].min(axis=-1)


def _local_mean(b, radius=4):
  """적분영상으로 (2r+1)² 박스 평균 — 국소 밝기 기준."""
  h, w = b.shape
  ii = np.zeros((h + 1, w + 1), dtype=np.float64)
  ii[1:, 1:] = np.cumsum(np.cumsum(b, axis=0), axis=1)
  out = np.empty_like(b, dtype=np.float64)
  for y in range(h):
    y0, y1 = max(0, y - radius), min(h, y + radius + 1)
    for x in range(w):
      x0, x1 = max(0, x - radius), min(w, x + radius + 1)
      area = (y1 - y0) * (x1 - x0)
      s = ii[y1, x1] - ii[y0, x1] - ii[y1, x0] + ii[y0, x0]
      out[y, x] = s / area
  return out.astype(np.float32)


def _components(flag):
  """boolean (H,W) → 8연결 컴포넌트 좌표 리스트들."""
  h, w = flag.shape
  seen = np.zeros_like(flag, dtype=bool)
  comps = []
  ys, xs = np.nonzero(flag)
  for sy, sx in zip(ys, xs):
    if seen[sy, sx]:
      continue
    stack = [(sy, sx)]
    seen[sy, sx] = True
    comp = []
    while stack:
      y, x = stack.pop()
      comp.append((y, x))
      for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
          ny, nx = y + dy, x + dx
          if 0 <= ny < h and 0 <= nx < w and flag[ny, nx] and not seen[ny, nx]:
            seen[ny, nx] = True
            stack.append((ny, nx))
    comps.append(comp)
  return comps


def detect_auto(arr, args):
  """우하단 코너에서 은색 스파클 마스크(boolean H,W)를 자동 검출."""
  h, w = arr.shape[:2]
  b = _bright(arr)
  sat = _sat(arr)
  alpha = arr[..., 3]
  lm = _local_mean(b, radius=4)

  x0 = 0 if args.region == "full" else int(w * (1.0 - args.corner_w))
  y0 = 0 if args.region == "full" else int(h * (1.0 - args.corner_h))
  region = np.zeros((h, w), dtype=bool)
  region[y0:, x0:] = True

  flag = region & (alpha > 0.4) & (sat < args.sat_max) & (b > args.bright_min) & ((b - lm) > args.local_delta)

  mask = np.zeros((h, w), dtype=bool)
  kept = 0
  for comp in _components(flag):
    n = len(comp)
    if n < args.min_px or n > args.max_px:
      continue
    cy = [p[0] for p in comp]
    cx = [p[1] for p in comp]
    mny, mxy, mnx, mxx = min(cy), max(cy), min(cx), max(cx)
    bw, bh = mxx - mnx + 1, mxy - mny + 1
    if bw > args.max_dim or bh > args.max_dim:
      continue
    if n / float(bw * bh) < args.min_fill:
      continue
    if not (0.45 <= bw / float(bh) <= 2.2):
      continue
    # 고립: bbox 바깥 2px 링이 덩어리보다 어두워야(스파클은 어두운 데 떠 있음)
    blob_b = float(np.mean([b[p] for p in comp]))
    ry0, ry1 = max(0, mny - 2), min(h, mxy + 3)
    rx0, rx1 = max(0, mnx - 2), min(w, mxx + 3)
    ring = arr[ry0:ry1, rx0:rx1]
    ring_in = np.zeros((ry1 - ry0, rx1 - rx0), dtype=bool)
    ring_in[(mny - ry0):(mxy - ry0 + 1), (mnx - rx0):(mxx - rx0 + 1)] = True
    ring_pix = ring[(~ring_in) & (ring[..., 3] > 0.4)]
    if ring_pix.size == 0 or (blob_b - float(ring_pix[..., :3].mean())) <= args.isolation:
      continue
    for p in comp:
      mask[p] = True
    kept += 1
  return mask, kept


def detect_box(arr, box, solid, args):
  """--box 영역 마스크. solid=박스 통째, 아니면 은색 픽셀만."""
  x, y, bw, bh = box
  h, w = arr.shape[:2]
  mask = np.zeros((h, w), dtype=bool)
  x1, y1 = min(w, x + bw), min(h, y + bh)
  if solid:
    mask[y:y1, x:x1] = True
  else:
    sub = arr[y:y1, x:x1]
    b = _bright(sub)
    sat = _sat(sub)
    sel = (sub[..., 3] > 0.4) & (sat < args.sat_max) & (b > args.bright_min)
    mask[y:y1, x:x1] = sel
  return mask


def _grow(arr, mask, args):
  """검출된 코어에서 스파클의 흐릿한 후광까지 채워 넣는다(채도낮음+국소밝음 따라 확장).
  코어만 인페인트하면 가장자리 후광이 남아 잔상이 되므로, 인페인트 전에 전체를 덮는다."""
  h, w = arr.shape[:2]
  b = _bright(arr)
  sat = _sat(arr)
  lm = _local_mean(b, radius=4)
  relaxed = (arr[..., 3] > 0.4) & (sat < args.sat_max * 1.4) & \
            (((b - lm) > args.local_delta * 0.4) | (b > args.bright_min))
  grown = mask.copy()
  for _ in range(10):
    nb = _dilate(grown, 1) & relaxed & (~grown)
    if not nb.any():
      break
    grown |= nb
  return grown


def _dilate(mask, n):
  for _ in range(n):
    m = mask.copy()
    m[:-1, :] |= mask[1:, :]
    m[1:, :] |= mask[:-1, :]
    m[:, :-1] |= mask[:, 1:]
    m[:, 1:] |= mask[:, :-1]
    mask = m
  return mask


def inpaint_average(arr, mask):
  """반복 이웃 평균 인페인트(RGBA, 투명 보존). 가장자리부터 안쪽으로 채움."""
  h, w = arr.shape[:2]
  todo = mask.copy()
  out = arr.copy()
  for _ in range(80):
    if not todo.any():
      break
    known = ~todo
    acc = np.zeros((h, w, 4), dtype=np.float64)
    cnt = np.zeros((h, w), dtype=np.float64)
    for dy in (-1, 0, 1):
      for dx in (-1, 0, 1):
        if dx == 0 and dy == 0:
          continue
        ys0, ys1 = max(0, dy), h + min(0, dy)
        xs0, xs1 = max(0, dx), w + min(0, dx)
        ty0, ty1 = max(0, -dy), h + min(0, -dy)
        tx0, tx1 = max(0, -dx), w + min(0, -dx)
        src_known = known[ty0:ty1, tx0:tx1]
        acc[ys0:ys1, xs0:xs1][src_known] += out[ty0:ty1, tx0:tx1][src_known]
        cnt[ys0:ys1, xs0:xs1][src_known] += 1.0
    fillable = todo & (cnt > 0)
    if not fillable.any():
      break
    out[fillable] = acc[fillable] / cnt[fillable, None]
    todo[fillable] = False
  return out


def inpaint_vertical(arr, mask):
  """세로 줄무늬 구조 보존: 각 컬럼의 마스크 구간을 위/아래 클린 픽셀로 선형보간."""
  h, w = arr.shape[:2]
  out = arr.copy()
  for x in range(w):
    col = np.nonzero(mask[:, x])[0]
    if col.size == 0:
      continue
    y0, y1 = int(col.min()), int(col.max())
    top = y0 - 1
    while top >= 0 and mask[top, x]:
      top -= 1
    bot = y1 + 1
    while bot < h and mask[bot, x]:
      bot += 1
    ca = out[max(top, 0), x]
    cb = out[min(bot, h - 1), x]
    span = float(bot - top)
    for y in range(y0, y1 + 1):
      t = (y - top) / span
      out[y, x] = ca * (1 - t) + cb * t
  return out


def _bbox(mask):
  ys, xs = np.nonzero(mask)
  if ys.size == 0:
    return None
  return (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))


def process(path, args):
  arr = _load_rgba(path)
  if args.box:
    mask = detect_box(arr, args.box, args.solid, args)
    kept = 1 if mask.any() else 0
  else:
    mask, kept = detect_auto(arr, args)

  name = os.path.basename(path)
  if not mask.any():
    print(f"  {name:20s} 워터마크 미검출 (--box 로 직접 지정 가능)")
    return

  # 스파클 후광까지 확장(코어만 지우면 잔상이 남음). --solid 박스는 사용자 지정이라 제외.
  if not args.solid:
    mask = _grow(arr, mask, args)
  total = int(mask.sum())
  bb = _bbox(mask)

  mask = _dilate(mask, args.dilate)
  bbtxt = f"bbox=({bb[0]},{bb[1]})-({bb[2]},{bb[3]})" if bb else ""
  print(f"  {name:20s} 검출 {kept}덩어리 {total}px (팽창후 {int(mask.sum())}px) {bbtxt}")

  if not args.apply:
    prev = arr.copy()
    prev[mask] = np.array([1.0, 0.0, 0.0, 1.0], dtype=np.float32)  # 빨강 표시
    out_path = os.path.splitext(path)[0] + ".prev.png"
    _save_rgba(out_path, prev)
    print(f"    → 미리보기 {out_path} (빨강=제거 대상). 맞으면 --apply")
    return

  fixed = inpaint_vertical(arr, mask) if args.vertical else inpaint_average(arr, mask)
  if not args.no_backup:
    bak = path + ".bak"
    if not os.path.exists(bak):
      _save_rgba(bak, arr)
  _save_rgba(path, fixed)
  print(f"    → 제거 적용{' (백업 ' + name + '.bak)' if not args.no_backup else ''}. Godot 에디터에서 재임포트하세요.")


def _parse_box(s):
  parts = s.split(",")
  if len(parts) != 4:
    raise argparse.ArgumentTypeError("--box 는 x,y,w,h 형식")
  return tuple(int(p) for p in parts)


def main():
  ap = argparse.ArgumentParser(
    description="Gemini ✦ 워터마크 제거 (검출 미리보기 → --apply)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=__doc__)
  ap.add_argument("paths", nargs="+", help="대상 PNG (여러 장/글롭 가능)")
  ap.add_argument("--apply", action="store_true", help="실제 제거 적용(기본=미리보기만)")
  ap.add_argument("--box", type=_parse_box, metavar="x,y,w,h",
                  help="검출 대신 이 영역에서 처리(은색만; --solid 면 통째)")
  ap.add_argument("--solid", action="store_true", help="--box 영역 전체를 인페인트(따뜻한 톤 ✦ 등)")
  ap.add_argument("--vertical", action="store_true", help="세로 줄무늬 보존 채움(문틀 등 고대비 경계)")
  ap.add_argument("--dilate", type=int, default=1, help="마스크 팽창 px (기본 1)")
  ap.add_argument("--no-backup", action="store_true", help="적용 시 .bak 백업 생략")
  ap.add_argument("--region", choices=["corner", "full"], default="corner",
                  help="자동 검출 범위 (기본 corner=우하단)")
  # 임계값 미세조정
  ap.add_argument("--sat-max", type=float, default=SAT_MAX, dest="sat_max")
  ap.add_argument("--bright-min", type=float, default=BRIGHT_MIN, dest="bright_min")
  ap.add_argument("--local-delta", type=float, default=LOCAL_DELTA, dest="local_delta")
  ap.add_argument("--corner-w", type=float, default=CORNER_W, dest="corner_w")
  ap.add_argument("--corner-h", type=float, default=CORNER_H, dest="corner_h")
  ap.add_argument("--min-px", type=int, default=MIN_PX, dest="min_px")
  ap.add_argument("--max-px", type=int, default=MAX_PX, dest="max_px")
  ap.add_argument("--max-dim", type=int, default=MAX_DIM, dest="max_dim")
  ap.add_argument("--min-fill", type=float, default=MIN_FILL, dest="min_fill")
  ap.add_argument("--isolation", type=float, default=ISOLATION, dest="isolation")
  args = ap.parse_args()

  if args.box and len(args.paths) != 1:
    ap.error("--box 는 파일 하나에만 쓸 수 있습니다(좌표가 이미지별로 다름).")

  mode = "적용" if args.apply else "미리보기"
  print(f"[dewatermark] {mode} — {len(args.paths)}개")
  for path in args.paths:
    if not os.path.isfile(path):
      print(f"  (건너뜀) 파일 없음: {path}")
      continue
    if path.endswith((".bak", ".prev.png")):
      continue
    process(path, args)


if __name__ == "__main__":
  main()
