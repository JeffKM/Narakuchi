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
tools/.venv/bin/python tools/dotify.py 원본.png --preset okja --out okja_idle.png

# 직접 규격 지정
tools/.venv/bin/python tools/dotify.py 원본.png --size 120x180 --transparent --out cheki.png

# 단색(크로마키) 배경 제거 — AI가 단색 배경으로 준 캐릭터 분리
tools/.venv/bin/python tools/dotify.py okja_raw.png --preset okja --chroma 00ff00 --out okja.png
```

> Gemini 프롬프트로 캐릭터를 받을 땐 [docs/gemini-prompts.md](../docs/gemini-prompts.md) 참고 — 단색 배경으로 받아 `--chroma`로 분리한다.

## 도트 스튜디오 GUI (dot_studio.py)

CLI 옵션을 외우지 않고 **브라우저에서 슬라이더로 조정 → 실시간 미리보기 → `assets/` 저장**하는 인터랙티브 툴.
(pixelartvillage 스타일) 규격 변환 로직은 `dotify.dotify_image()`를 그대로 재사용하므로 결과는 CLI와 동일하다.

```bash
tools/.venv/bin/python tools/dot_studio.py            # 브라우저 자동 오픈(127.0.0.1:8765)
tools/.venv/bin/python tools/dot_studio.py --port 8800 --no-browser
```

- **에셋 체크리스트(왼쪽 열)**: `docs/asset-checklist.md`를 구조화한 `tools/asset_manifest.json`을 읽어 **만들 에셋 전부를 빈 슬롯으로 표시**한다. 파일이 있으면 ✓+썸네일(완료), 없으면 ▢(미제작). 상단에 진행도(예: `2 / 37`)와 막대. 슬롯을 클릭하면 **그 에셋의 규격(프리셋/사이즈)과 저장 경로가 자동 세팅**되므로, 이미지를 올리고 저장만 하면 칸이 채워진다(저장 즉시 슬롯 갱신).
- **워크플로**: ① 왼쪽에서 만들 슬롯 클릭 → ② 이미지 드래그 → ③ (크로마키/알파/팔레트) 조정 → ④ 검수 리포트 확인 → ⑤ 저장(경로는 슬롯이 자동 입력). 슬롯이 ✓로 바뀐다.
- **슬롯 추가/변경**: `tools/asset_manifest.json`을 편집한다(그룹·라벨·preset 또는 size·path). 음료/선물 개수 등은 거기서 조정.
- **실시간 검수**: 치수·색 수·팔레트 외 색·반투명·LCD 투명을 변환 즉시 패널에 표시(✅/❌).
- **`32색 팔레트 적용` 토글**: 끄면 팔레트 인덱싱 전 원본 색으로 미리보기(전후 비교용).
- **팔레트 편집**: 스와치를 클릭해 색 변경, `+ 색 추가`/삭제(×)로 구성 변경 → **편집 즉시 미리보기에 반영**. `되돌리기`는 파일 팔레트로 복귀, `팔레트 저장`은 `assets/palettes/`의 **네 파일을 한 번에 갱신**한다 — `narakatchi.hex`(파이프라인 원본) · `narakatchi.gpl`(색이 그대로면 기존 이름 보존, 바뀐/새 색은 `COLOR_NN`) · `narakatchi_strip.png`(색당 1px) · `narakatchi_grid.png`(8열·48px 셀). 색 개수가 바뀌면 strip/grid 크기도 자동 적응(grid는 8열 기준 행 수 증감).
- 추가 의존성 없음 — 표준 라이브러리 `http.server` + 기존 `pillow`/`numpy`. 저장은 **프로젝트 폴더 안 `.png`만** 허용(경로 탈출 차단).

### 프리셋 (→ ADR 0001 규격)

| 프리셋 | 규격 | 투명 | LCD 구멍 |
|---|---|---|---|
| `okja`  | 128×288 | ✅ | — |
| `sioni` | 48×48   | ✅ | — |
| `bg`    | 333×480 | ❌ | — |
| `cheki` | 120×180 | ✅ | — |

> 게임기 셸(`shell_frame.png`)은 이 파이프라인 대상이 아니라 **`tools/prep_shell.py`** 전용이다(흰 배경 누끼 + LCD 정밀 펀칭 필요). dot_studio 체크리스트에서도 `prep_shell.py · 635×877` 로만 표시되고 GUI 변환은 막혀 있다.

## 파이프라인 (dotify.py)

1. **비율 맞춰 축소(fit)** — 왜곡 없이 규격 캔버스에 중앙 안착
2. **마스터 32색 팔레트 인덱싱** — `assets/palettes/narakatchi.hex` 기준 최근접 매핑 → 색 폭발 해결
3. **알파 이진화** — 반투명 제거(도트는 0/255만)
4. **LCD 투명 마스킹** — LCD 사각을 지정한 프리셋/규격은 게임 화면칸을 투명으로 뚫음
5. **검수 리포트** — 치수·색 수·팔레트 외 색·반투명·LCD 투명을 자동 판정(통과 시 exit 0)

## 한계 (중요)

- 툴은 규격을 강제하지만 **입력 그림의 구도가 규격과 어긋나면 못 메운다.**
  → AI 프롬프트에서 **위치·비율을 못박아** 받아야 한다.
- AI 도트풍 특유의 디더링 노이즈는 인덱싱 후에도 남을 수 있어 **pixilart 수동 정리**가 마지막 단계다.
