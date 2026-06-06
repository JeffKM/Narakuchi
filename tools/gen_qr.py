#!/usr/bin/env python3
"""T24 빌드타임 QR — 배포 링크를 2색(버건디/크림) 도트 QR PNG 로 굽는다.

공유 카드(share_card.gd)의 QR 자리(qr_placeholder)를 실제 스캔 가능한 QR 로 교체한다.
런타임 인코더를 쓰지 않고 빌드타임에 한 번 생성(링크는 호스팅 확정 후 고정).
QR 모듈은 1비트라 AA 가 없어 정수 box_size 로 도트룩이 깨지지 않는다.

사용:
  tools/.venv/bin/python tools/gen_qr.py                       # 기본 URL·box=3
  tools/.venv/bin/python tools/gen_qr.py --url https://... --box 4
"""
import argparse
import os

import numpy as np
import qrcode
from qrcode.constants import ERROR_CORRECT_M
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_URL = "https://narakuchi.vercel.app"
OUT = os.path.join(ROOT, "assets", "sprites", "qr_naraka.png")

# 마스터 팔레트 2색 — 어두운 버건디 모듈 / 크림 배경(브랜드 + 충분한 명암 대비).
DARK = (0x7a, 0x1f, 0x3d)   # Palette.BURGUNDY
LIGHT = (0xf7, 0xec, 0xd0)  # Palette.CREAM


def main() -> None:
  ap = argparse.ArgumentParser(description="나라쿠치 배포 링크 QR 생성")
  ap.add_argument("--url", default=DEFAULT_URL, help="인코딩할 링크")
  ap.add_argument("--box", type=int, default=3, help="모듈 한 칸 픽셀(정수, 도트 정렬)")
  ap.add_argument("--out", default=OUT, help="저장 경로")
  args = ap.parse_args()

  # error_correction=M: 28바이트 URL → 보통 버전 2(25모듈). border=4 = 콰이어트 존(스캔 필수).
  qr = qrcode.QRCode(error_correction=ERROR_CORRECT_M, box_size=args.box, border=4)
  qr.add_data(args.url)
  qr.make(fit=True)

  # 흑백 1비트로 굽고 → 팔레트 2색으로 치환(AA 0, 정확히 2색).
  bw = qr.make_image(fill_color="black", back_color="white").convert("L")
  arr = np.array(bw)
  out = np.empty((arr.shape[0], arr.shape[1], 4), np.uint8)
  dark_mask = arr < 128
  out[dark_mask] = [*DARK, 255]
  out[~dark_mask] = [*LIGHT, 255]
  Image.fromarray(out, "RGBA").save(args.out)

  print("✅ QR 생성: %s (%d×%d, 버전 %s, %s)"
        % (os.path.relpath(args.out, ROOT), out.shape[1], out.shape[0],
           qr.version, args.url))


if __name__ == "__main__":
  main()
