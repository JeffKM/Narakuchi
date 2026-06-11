# 효과음 바인딩: 평면 이벤트→파일 데이터화 + 카테고리 기본값 + 콘텐츠 스튜디오 연동

> 신규 2026-06-07. T18의 "사운드 자리"(`Sfx.play(&"cue")` 하드코딩 + `gen_sfx.py` 8종)를 **데이터 주도 이벤트 바인딩**으로 승격한다. 밸런스/대사의 단일 출처 규율([CLAUDE.md], `Balance` 게이트웨이·`GameData`)을 **소리에도 동형으로** 적용한다.

## 배경 (문제)

기존 사운드 시스템은 두 층이 모두 코드에 박혀 있었다.

- **큐→파일** 매핑은 `scripts/systems/sfx.gd`의 `CUES` 상수에.
- **상호작용→큐** 호출은 각 UI 스크립트에 흩어진 `Sfx.play(&"tap")` 로.

이 때문에 ① 무음인 상호작용이 많고(옥자 터치·시온이 터치·SELECT 커서 이동·CANCEL·팝업 열림·온보딩 입력·화면 전환), ② 의미가 다른데 같은 `tap` 을 재사용해 부자연스럽고(대화·선물·시온이·카드상세·컬렉션북·리빌닫기), ③ **핵심 보상인 단계 상승 컷인(반말 전환)이 완전 무음**이며, ④ 콘텐츠 스튜디오(대사·밸런스 편집 GUI)에서 소리를 손댈 수 없었다.

## 결정

소리를 **평면 이벤트→파일 바인딩 테이블**(`data/sound.json`)로 데이터화하고, 게임은 **의미 이벤트**만 발화한다. 콘텐츠 스튜디오가 같은 JSON 을 편집한다(대사·밸런스와 동일 단일 출처).

### 1) 평면 모델 — 이벤트→{file, pitch, jitter}

큐라는 중간 추상(이벤트→큐→파일 2층)을 **두지 않는다**. 데모 규모(이벤트 ~26 · wav ~20)에서 비코더 편집자에게 큐는 머릿속에 없는 개념이라, 스튜디오 **한 줄 = 한 상호작용**이 되도록 평면으로 둔다. 같은 소리 공유는 "드롭다운에서 같은 파일 선택"으로 충분하고, tier 변주는 같은 파일 + **pitch** 로 짠다(예: `talk_pick_good` = `talk.wav`×1.15, `talk_pick_plain` = ×1.0).

### 2) 카테고리 기본값(fallback) — "무음"을 구조적으로 제거

이벤트마다 `cat`(`ui`/`interaction`/`reward`/`transition`)을 갖고, `file` 을 비우면 **그 카테고리 기본음이 자동 재생**된다. `action_bar`·셸 3버튼덱·팝업 같은 공통 길목이 안 매어 있어도 기본 클릭을 내므로, **새 버튼을 추가해도 결코 무음이 아니다**. 특별히 다르게 할 곳만 `file` 로 덮어쓴다 → 무음(②④)과 부자연한 재사용(①)이 동시에 풀린다.

```jsonc
{
  "defaults": { "ui": "ui_tick.wav", "interaction": "ui_soft.wav",
                "reward": null, "transition": "ui_woosh.wav" },
  "gain":     { "ui": -6, "interaction": -3, "reward": 0, "transition": -4 },
  "events": {
    "okja_touch":     { "label": "옥자 쓰담",   "cat": "interaction", "file": "soft_touch.wav", "jitter": 0.06 },
    "cancel":         { "label": "뒤로",        "cat": "ui",          "file": "ui_back.wav" },
    "talk_pick_good": { "label": "대화·좋은선택", "cat": "interaction", "file": "talk.wav", "pitch": 1.15 },
    "stage_up_reveal":{ "label": "단계상승·공개", "cat": "reward",      "file": "stage_reveal.wav" }
    // … 약 26개
  }
}
```

### 3) 이벤트 키 = 코드 소유, 바인딩 값 = 스튜디오 소유 (+ 테스트 가드)

이벤트가 존재하는 이유는 코드가 그 순간 소리를 부르기 때문이다. 따라서 **키·라벨·`cat` 은 코드가 소유**(`sound.json` 에 사전 시딩)하고, 스튜디오는 그 목록을 **추가/삭제 못 하며 `file`·`pitch`·음소거만 편집**한다. `tools/run_tests.sh`(헤드리스 회귀)에 **"코드의 `Sfx.event` id 집합 == `sound.json` 키 집합 + 바인딩 파일 존재"** 파리티 테스트를 두어, 고아(코드 없는 이벤트)·누락(json 없는 호출)·죽은 파일을 **하드 실패**로 잡는다. `Balance` 단일 출처 규율과 동형.

### 4) 런타임 — `Sfx.event` 전면 교체

`sfx.gd` 의 `CUES` 상수를 제거하고 `GameData.sound()` 로 읽는다(밸런스 동형). API 를 `Sfx.event(&"id")` 하나로 통일한다.

- 해소 순서: `events[id].file` → 없으면 `defaults[cat]` → 그래도 없으면 **무음**(no-op, 기존 "사운드 자리" 관용 유지).
- `pitch` × **지터**(`randf_range(-jitter, +jitter)` 가산 — 커서/터치 연타의 머신건 반복 제거).
- 카테고리 **`gain`(dB)** 적용으로 ui 는 작게·reward 는 크게 균형.
- **`flags.sfx_on=false`** 면 전역 음소거. 메모리 경고(웹 HTML5 런타임 `add_bus` → 무음)대로 **별도 버스 없이** 플레이어 볼륨/플래그로 끈다.

### 5) 에셋 — 칩튠 절차 생성 (감정 단위 별도 파일)

오디오 트랙·외부 수급 없이 `tools/gen_sfx.py`(표준 라이브러리 칩튠 합성)를 확장해 신규 ~12종을 떨군다: `ui_tick`·`ui_soft`·`ui_back`·`ui_woosh`·`soft_touch`·`touch_cap`·`stage_appear`·`stage_reveal`·`talk`·`gift`·`sioni_chirp`·`day_advance`. 기존 8종(`order`·`cheki_get`·`butterfly`·`flip`·`tap`·`gauge_full`·`book`·`shutter`)은 재사용. **감정/의미가 다른 순간만 별도 파일**, tier 변주는 pitch. 품질은 "프로그래머 SFX"(데모 충분), 스튜디오로 언제든 교체 가능한 게 안전망.

### 6) 콘텐츠 스튜디오 — 사운드 탭 (2차)

`tools/content_studio.py` 에 사운드 탭 추가: 이벤트 한 줄 = `[파일 드롭다운 ▾(assets/audio 스캔)] [pitch] [▶미리듣기] [🔇음소거]`, `defaults`·`gain` 편집. 로컬 HTTP 로 wav 서빙 + `<audio>` 재생(편집하며 들어봄). 플레이어용 SFX 끄기는 셸 코너 스피커 글리프(4번째 터치 존, `flags.sfx_on` 세이브)로.

### 이벤트 맵 (카테고리별, ~26개)

- **ui**: `cursor_move`·`confirm`·`cancel`·`popup_open`·`popup_close`·`tab_switch`·`card_open`·`nickname_key`·`nickname_confirm`
- **interaction**: `okja_touch`·`okja_touch_cap`·`sioni_touch`·`drink_order`·`cheki_order`·`talk_pick_good`·`talk_pick_plain`·`gift_match`·`gift_sion`·`gift_plain`·`sioni_snack`·`sioni_play`·`sioni_pet`
- **reward**: `gauge_full`·`cheki_get`·`card_flip`·`butterfly_upgrade`·`stage_up_appear`·`stage_up_reveal`·`book_open`·`share_save`
- **transition**: `scene_enter`·`day_advance`

> 바인더 탭은 `book_open` 을 부르므로 별도 `binder_touch` 이벤트는 두지 않는다.

## 이유 / 트레이드오프

- **평면 > 2층**: 큐 인덱싱은 "정석"이나 데모 규모에선 비코더에게 추상 1층을 더 얹을 뿐. 평면은 "이 상호작용엔 이 소리"라는 멘탈 모델과 1:1이라 스튜디오 UX 가 직관적. 공유·변주 비용은 파일 재선택·pitch 로 흡수.
- **카테고리 기본값 > 명시 전용**: "무음 많다"의 근본 원인은 공통 길목의 미배선. 기본값은 길목이 자동으로 소리를 내게 해 **무음을 구조적으로** 없애고, 새 UI 추가 시 회귀를 막는다. 명시 전용은 통제는 좋으나 빠뜨림이 반복된다.
- **코드 소유 키 + 테스트 가드**: 소리도 밸런스처럼 단일 출처로 묶되, 이벤트의 진짜 출처는 호출하는 코드다. 가드가 코드·데이터 표류를 CI 에서 잡아 "스튜디오에서 지웠더니 조용해짐" 류 사고를 차단.
- **절차 생성 에셋**: 1주 데모에 오디오 파이프라인을 세울 수 없다. 기존 8종이 이미 칩튠 합성이라 같은 결로 확장하면 **응집감 + 도트 미감 정합 + 작업량 0**. 한계(전문 사운드 디자인 아님)는 스튜디오 교체 경로로 흡수.

## 폐기된 대안

- **이벤트→큐→파일 2층 유지** → 데모 규모에서 추상 비용만 큼. 큐 재사용 이득이 평면의 단순함을 못 이긴다.
- **명시 전용(기본값 없음)** → 모든 이벤트를 일일이 채워야 하고 새 버튼마다 무음 회귀. "무음 많다" 해결의 지속성이 떨어짐.
- **스튜디오 자유 편집(이벤트 추가/삭제)** → 고아·기본음 낙하 사고. 단일 출처 규율이 흔들림.
- **이벤트별 신규 wav 풀세트(~20)** → 아트/오디오 트랙 부담이 1주 데모에 비현실적. 감정 단위 분리 + pitch 변주로 충분.
- **`add_bus` 기반 음량/뮤트** → 웹 HTML5 에서 무음 유발(메모리 기록). 플레이어 볼륨·플래그로 우회.

## 영향 (구현 메모)

- **데이터(신규)**: `data/sound.json`(events·defaults·gain). `GameData.sound()` 정적 캐시 로더 추가(다른 로더와 동형). `flags.sfx_on` 세이브 필드(기본 true).
- **런타임(`scripts/systems/sfx.gd`)**: `CUES` 상수 제거. `event(id)` 디스패처 + `_binding_for(id)`(file→cat 기본→null) + 지터/gain/뮤트. `play(cue)` 는 제거(전면 `event` 교체).
- **호출부 교체(1차)**: 기존 8개 `Sfx.play` → `Sfx.event` 의미 이벤트로. 신규 무음 길목 배선 — 셸 `_trigger`(cursor_move/confirm/cancel) · `cafe.gd`(옥자/시온이 터치·scene_enter·tier 분기) · `choice_popup`/선물팝업(popup_open) · `stage_cutin`(appear/reveal) · `onboarding`(nickname). 
- **테스트(`tests/test_content.gd`)**: `_test_sound_binding()` — `scripts/` 전 파일에서 `Sfx.event(&"…")` id 수집 → `sound.json` 키와 양방향 일치 + 바인딩 파일 존재 단언.
- **2차 분리**: 콘텐츠 스튜디오 사운드 탭 + 셸 스피커 토글(1차 검증 후 착수).
- **관련 문서**: [CLAUDE.md](../../CLAUDE.md)(수치 단일 출처 규칙) · [PRD.md] §10(사운드) · [ADR 0001](./0001-dot-art-spec.md)(셸 3버튼·도트 규격).

## 개정 — 코너 스피커 토글 → 설정 패널 승격 (2026-06-11)

§6의 **셸 코너 스피커 글리프(원탭 음소거)** 를 **설정 패널 진입 기어**로 승격해 교체한다. 우상단 진입점을 하나로 통일하고, 음소거에 **볼륨**과 **게임 초기화**를 한곳에 모은다(사용자 요청). 결정 번복이 아니라 같은 자리·같은 `flags.sfx_on` 위에 기능을 더한 확장이다.

- **진입점**: 코너 글리프를 `ShellSpeaker`(스피커/X) → `SettingsButton`(도트 톱니, `scripts/ui/settings_button.gd`)로 교체. 같은 베젤 좌표(`ShellFrame.GEAR_POS/GEAR_SIZE`, 구 `SPEAKER_POS`). 누르면 `ShellFrame.settings_requested` → **Main** 이 `SettingsPanel`(`scripts/ui/settings_panel.gd`)을 `_lcd_root` 최상단에 띄운다(스플래시/온보딩/카페/북 무엇 위든 덮는 모달). 셸 3버튼은 Main 이 "패널 > 그 외 화면" 우선으로 위임.
- **가용 범위**: 스플래시 연출 중엔 기어 비활성(`set_settings_enabled(false)`, 진입 차단), 끝나면 활성. 온보딩 중엔 패널은 열되 **초기화 행 숨김**(`SettingsPanel.setup(show_reset=false)` — 이미 새 게임이라 무의미).
- **① 음소거**: 기존 `flags.sfx_on` 게이트 그대로(`Sfx._enabled`). 패널 음소거 행은 `ShellSpeaker` 글리프를 **재활용**(노드 보존). 볼륨과 독립 — 음소거 해제 시 직전 볼륨으로 복원.
- **② 볼륨(신규)**: `flags.volume`(0.0~1.0 **선형**, 기본 1.0) 세이브 필드 추가. 6레벨(0~5) 세그먼트 바, `level/5`. `Sfx.apply_volume(linear)` 가 `linear_to_db` 로 환산해 **기본 Master 버스(인덱스 0)** 에 적용 — 부팅(`Sfx._ready`) 1회 + 변경 시. **폐기된 대안 "`add_bus` 기반 음량"의 웹 무음 함정과 무관**하다: Master 는 런타임 추가 버스가 아니라 기본 버스라 `set_bus_volume_db` 가 안전하고, Sfx 가 이미 Master 로 직접 출력하므로 단일 레버로 모든 소리를 덮는다(향후 BGM 도 자동 적용). 변경 시 `confirm` 프리뷰 블립으로 레벨을 귀로 확인(음소거면 자연히 무음). `_merge_defaults` 가 구세이브에 키를 자동 보강 → `SAVE_VERSION` 유지(마이그레이션 불필요).
- **③ 게임 초기화(신규)**: 패널 내 **인라인 2단계 확인**(문구 + [취소][초기화], 기본 포커스 취소). 확정 시 `SettingsPanel.reset_requested` → Main 이 `SaveManager.wipe()` + `reload_current_scene()`(디버그 KEY_1 검증 경로 재사용, 웹 IndexedDB 정리). `onboarded=false` 로 스플래시·온보딩에 복귀.
- **입력(평면 링 [음소거·볼륨·(초기화)·닫기])**: SELECT=순환 · OK=실행(음소거 토글 / 볼륨 한 칸↑ **wrap** / 초기화 확인 / 닫기) · CANCEL=닫기(확인 중이면 확인 취소). 터치가 주(토글 탭·볼륨 칸 직접 탭·드래그·백드롭 탭으로 닫기), 3버튼 보조.
