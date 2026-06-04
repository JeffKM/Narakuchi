# 도트화 파이프라인 (tools/)

AI(Gemini/Midjourney)가 만든 **도트풍 큰 그림**을 받아, **규격을 코드로 강제**해 규격 도트 에셋으로 변환한다.
AI는 픽셀 정확도(정확한 px·투명칸·32색)를 못 지키므로 — **AI는 형태·색감만, 규격은 이 툴이 책임진다.**

## 설치 (최초 1회)

```bash
python3 -m venv tools/.venv
tools/.venv/bin/pip install -r tools/requirements.txt
```

> `tools/.venv/`는 git 추적 제외(.gitignore). Godot 프로젝트라 게임 런타임과 무관한 보조 도구다.

## 사용법

```bash
# 프리셋으로 변환 (+검수 리포트 +×3 미리보기)
tools/.venv/bin/python tools/dotify.py 원본.png --preset frame --out out.png

# 직접 규격 지정
tools/.venv/bin/python tools/dotify.py 원본.png --size 120x180 --transparent --out cheki.png
```

### 프리셋 (→ ADR 0001 규격)

| 프리셋 | 규격 | 투명 | LCD 구멍 |
|---|---|---|---|
| `okja`  | 128×288 | ✅ | — |
| `sioni` | 48×48   | ✅ | — |
| `bg`    | 270×480 | ❌ | — |
| `frame` | 460×630 | ✅ | 270×480 @ (95,30) |
| `cheki` | 120×180 | ✅ | — |

## 파이프라인 (dotify.py)

1. **비율 맞춰 축소(fit)** — 왜곡 없이 규격 캔버스에 중앙 안착
2. **마스터 32색 팔레트 인덱싱** — `assets/palettes/narakatchi.hex` 기준 최근접 매핑 → 색 폭발 해결
3. **알파 이진화** — 반투명 제거(도트는 0/255만)
4. **LCD 투명 마스킹** — `frame` 프리셋은 게임 화면칸을 투명으로 뚫음
5. **검수 리포트** — 치수·색 수·팔레트 외 색·반투명·LCD 투명을 자동 판정(통과 시 exit 0)

## 한계 (중요)

- 툴은 규격을 강제하지만 **입력 그림의 구도가 규격과 어긋나면 못 메운다.**
  특히 `frame`은 원본 그림의 LCD가 `270×480 @ (95,30)`에 맞게 그려져 있어야 구멍과 정합한다.
  → AI 프롬프트에서 **LCD 위치·비율을 못박아** 받아야 한다.
- AI 도트풍 특유의 디더링 노이즈는 인덱싱 후에도 남을 수 있어 **pixilart 수동 정리**가 마지막 단계다.
