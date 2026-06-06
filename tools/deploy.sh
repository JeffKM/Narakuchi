#!/usr/bin/env bash
# T24 수동 배포 — Godot 웹 export → Vercel 프로덕션. (→ ROADMAP T24 / 메모리 phase5-decisions)
#
# 산출물(export/)은 git 에 커밋하지 않는다(.gitignore). 빌드는 매번 새로 굽는다.
# 사전 1회: `vercel login` + 첫 배포 시 프로젝트명 "narakuchi" 로 link(→ narakuchi.vercel.app).
#           QR/아이콘은 tools/gen_qr.py·tools/make_pwa_icons.py 로 미리 생성(에셋 커밋됨).
#
# 사용: tools/deploy.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "▶ Godot 웹 export…"
mkdir -p export
godot --headless --export-release "Web" export/index.html

# Godot 이 export/ 로 복사하지 않는 PWA 부속물 — 직접 복사.
echo "▶ PWA 부속물 복사(vercel.json · iOS 스플래시)…"
cp vercel.json export/vercel.json
cp assets/pwa/splash_*.png export/ 2>/dev/null || echo "  (스플래시 없음 — tools/make_pwa_icons.py 먼저 실행)"

echo "▶ Vercel 프로덕션 배포…"
vercel deploy --prod export/

echo "✅ 배포 완료 — https://narakuchi.vercel.app"
