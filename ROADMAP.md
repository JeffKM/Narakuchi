# 나라쿠치 — 개발 로드맵 (1주 데모)

> 목표: 1주 안에 **감정 임팩트 + 공유성**을 증명하는 플레이 가능한 데모.
> 상세 명세는 [PRD.md](./PRD.md), 용어는 [CONTEXT.md](./CONTEXT.md), 결정은 [docs/adr/](./docs/adr/).

## 원칙

- **코어 먼저, 콘텐츠 나중**: 옥자 교감 루프가 도는 게 1순위. 의상/음료 개수는 그다음.
- **IN/OUT 사수**: 다른 멤버·의상 입히기는 스트레치/제외. 욕심내면 코어가 미완성된다.
- **옥자 아트는 표정 스왑 스탠딩**(미연시식): 리깅·프레임시트 금지. **얼굴 + 팔 자세 6장**(다리·구도 고정) + 코드 트윈(전환 = 하드컷 + 정착).
- **후처리 필수**: AI 도트화 → 축소 → 팔레트 인덱싱 → 정리까지가 1세트(→ ADR 0001).

## 두 트랙 (혼자서 병렬)

- **🧩 코드 트랙**: Godot 구현.
- **🎨 아트 트랙**: 실물 사진 → AI 도트화 → 후처리. 코드와 무관하게 매일 누적.

### 🎨 아트 물량 (데모 목표)

> 규격·마감 Phase별 체크리스트는 [docs/asset-checklist.md](./docs/asset-checklist.md) 참조.
> 진행 표기: ✅ 완료 · ⏳ 진행 · ⬜ 대기

**🛠 아트 인프라 — 먼저 구축 (코드 트랙과 병행, 캐릭터 에셋의 토대)**

- ✅ 마스터 팔레트 32색 — `assets/palettes/`(`.gpl`/`.hex`/그리드·스트립)
- ✅ 도트화 파이프라인 — `tools/dotify.py`(AI 도트화 → 축소 → 팔레트 인덱싱, 크로마키 분리)
- ✅ 옥자·시온이 Gemini 프롬프트 가이드 — `docs/gemini-prompts.md`(실물→AI 생성 입력)
- ✅ 게임기 셸 프레임 — 도트풍 레퍼런스 채택 → `tools/prep_shell.py` → `assets/sprites/shell_frame.png`
- ✅ 워터마크 제거 — `tools/dewatermark.py`(Gemini ✦ 스파클 검출→인페인트, 미리보기 우선·--box·--vertical). 신규 에셋 추가 후 1회 돌림

**🎨 캐릭터·카드 에셋 — 제작 대기 (파이프라인 위에서 생산)**

- ⬜ **옥자 표정 전신 스탠딩 6장**(기본/웃음/부끄/시무룩/제조중/말하기) — 기본 의상 = 마녀룩, 전신 `~128×288`. **다리·구도 고정, 얼굴 + 팔 자세만 변경**(idle=두 손 모음 / smile=두 손 가슴께로 모아 기뻐함 / shy=손으로 입 가림 / sad=팔 처짐 / brew=음료 든 손 / talk=한 손 듦)
- ⬜ **시온이 48×48**: idle + 교감 반응(간식/놀기/쓰담)
- ⬜ **옥자 이벤트 의상 5세트**: 지뢰계(★히어로)·유치원·힙합·집사·크리스마스
- ⬜ **시온이 이벤트 의상 2세트**: 지뢰계(쿠로미 고양이)·크리스마스(루돌프 고양이)
- ⬜ **테마 프레임 5장**(메탈하트·크레용·그래피티·은쟁반·눈리스) + **표준 프레임 1장**
- ⬜ 나라카 **지옥 배경 1**(세계관 — 지옥 풍경), 선물 아이콘 3~4

---

## Phase 0 — 셋업 (Day 0~1 앞부분)

- [x] **T01** Godot 4 프로젝트 생성 + 기존 Next/Phaser 코드 정리 (project.godot · scenes/Main.tscn · scripts/Main.gd)
- [x] **T02** 세로 캔버스 + integer scale + Nearest 필터 (project.godot) — 베이스 270×480 → **셸 채택으로 `635×877`로 확장**(내부 교감화면 = LCD 구멍 `333×480`). ⚠️ ADR 0001(베이스 270×480) 표기 보강 필요
- [x] **T03** 마스터 팔레트 32색 → `data/palette.gd` · 갈무리 로더/테마 → `scripts/systems/fonts.gd` (OFL 1.1) · ✅ `Galmuri11/9.ttf` 설치(공식 v2.40.3, OFL 1.1) — Godot이 픽셀폰트 자동 인식(subpixel off), 한글 타이틀 전환 확인
- [x] **T04** HTML5 export + PWA 파이프라인 1회 성공 — `export_presets.cfg`(Web 프리셋, PWA on, 세로 고정 portrait, standalone) · `godot --headless --export-release "Web" export/index.html` · manifest/서비스워커/오프라인페이지/아이콘 산출 + 로컬 서빙 200 확인 (아이콘 실물·호스팅은 T24)
- [x] **T05** 로컬 세이브(JSON) 골격: load/save/reset/wipe + 데모 시드 — `SaveManager` autoload(`scripts/systems/save_manager.gd`) · 밸런스 상수 `data/balance.gd`(PRD §4.5) · 웹은 `user://` → IndexedDB 자동 영속

## Phase 1 — 옥자 교감 코어 (Day 1~2)

- [x] **T06** **게임기 셸** 배치(도트풍 달걀 바디 · 캔버스 `635×877` / 내부화면 LCD `333×480`) + **3버튼**(SELECT 순환·OK 확인·CANCEL 취소) **키·터치 하이브리드 입력** → `button_pressed(action)` 신호 — `scripts/systems/shell.gd` · `Main.gd`(옥자 4버튼 컨셉 메뉴 데모 동작) · 셸 바깥 투명 배경
- [x] **T06a** 메인 교감 화면(`scripts/cafe.gd`): 배경+옥자+HUD(`scripts/ui/hud.gd`: 호감도게이지·기분·기력·코인)+4버튼+**한 줄 티커**(`scripts/ui/ticker.gd`). 옥자 보이스 풀 `data/dialogue.gd`(상황×관계단계, {nick} 치환) — 옥자 스탠딩(T07)·미터(T08)와 연결
- [x] **T06b** 온보딩(`scripts/onboarding.gd`): 닉네임 입력 → 옥자 맞이(존댓말) → 첫 방문 기념 지뢰계 일반체키 증정(`data/events.gd`) · `flags.onboarded`로 1회만 · 셸 OK 하이브리드. **🔧 폴리시**: 가운데 초대장 카드(골드 테두리 버건디 패널+그림자)로 글자를 배경/로고에서 분리해 가독성↑, 배경 딤 완화(0.94→0.82), 맥동 골드 하트 엠블럼(`HeartCursor` 재사용), 닉네임 입력칸 공용 테마 적용. **🐞 버그픽스**: 한글 IME 조합 중(preedit)인 마지막 음절이 `LineEdit.text`에 누락되던 문제 → 제출 시 `release_focus()`+한 프레임 대기로 조합 확정 후 읽기(+중복 제출 가드)
- [x] **T06c** **진입 스플래시(지옥문 타이틀 + 출석 맞이)**(`scripts/splash.gd`): 켤 때마다 귀여운 지옥문(통짜 1장을 좌/우 `AtlasTexture`로 잘라 바깥 슬라이드)이 열리며 옥자가 맞이 → 카페/온보딩 분기 · 상황별 표정(첫접속 `idle`·방치 `sad`·재방문 `smile`+폴짝) + 골드 하트 인사 카드(streak 표시) · 자동 진행 + 탭/OK 스킵. **미터 판정 분리** `Meters.evaluate_session()`(읽기전용)로 카페 진입(`begin_session`) 전에 streak/방치를 미리 노출. **공용 버튼 테마** `scripts/systems/ui_theme.gd`(버건디+골드 라운드) + **골드 하트 커서** `scripts/ui/heart_cursor.gd` → 온보딩·액션바에 적용. (이후 `ui_theme.gd`에 **입력칸 공용 테마** `style_input/input_box` 추가 — 온보딩 닉네임 등 LineEdit 재사용) 에셋 `gate_naraka.png`(333×480, 어두운 고딕 철문+이음선 ember+하트 손잡이+뿔). ※ **T14의 "출석 팝업(옥자 맞이 연출)" 흡수**
- [x] **T07** 옥자 표정 스왑 스탠딩: **얼굴 + 팔 자세 6장**(다리·구도 고정) 교체 상태머신 + 코드 트윈 — 평소 둥실 흔들/말할 때 톡톡/페이드. **표정 전환은 하드컷 + 짧은 스쿼시 정착 트윈(0.1~0.15s)**(크로스페이드 금지 — 팔 자세가 달라 고스팅·팔레트 밖 중간색이 뜸). **기쁨 "폴짝"은 별도 그림 없이 `okja_smile`(두 손 모아 기뻐함)을 체키 획득·나비 승급 등 리워드 순간에 코드 hop 트윈으로 재사용**. 슬픔은 팔 처짐 시무룩까지(우는 연출 금지). (→ ADR 0001)
- [x] **T08** 미터 로직(`scripts/systems/meters.gd`): 호감도 게이지(풀→`gauge_full` 신호, 체키는 T13), 스태미나(액션당 −5/일일 풀충전), 기분(24h+ 방치→시무룩 −20%, 교감 1회마다 회복), 관계 단계 상승 `stage_changed`(반말 컷인 T11) · SaveManager SSOT, 수치 Balance only
- [x] **T09** 옥자 4버튼(`scripts/ui/action_bar.gd` + cafe): 체키 주문(+10) · 음료 주문(brew 제조 연출) · 대화 · 선물 → 스태미나 소모 + 호감도 충전 + 티커. **SELECT 커서 순환·OK 확인·터치** 하이브리드. (음료 선호 보너스·대화 분기·선물 선호표는 T11) **🐞 버그픽스**: 스태미나 소진 시 옥자가 `sad` 표정으로 계속 축 처져 있던 문제 → `_react(&"sad")`로 잠깐 시무룩 후 무표정(`idle`) 자동 복귀(다른 리액션과 통일)
- [x] **T10** 터치 리액션: 옥자 몸통 투명 버튼 탭 → 부끄/웃음 표정 + 터치 보이스 + 소폭 호감도(+2, 무료, 세션 상한 10/도달 시 짜증 대사)
- ✅ **A1** 옥자 표정 전신 스탠딩 6장(기본 의상, 얼굴 + 팔 자세·다리 고정) + 나라카 지옥 배경(333×480) — 누끼·규격 검수 통과

## Phase 2 — 대화 분기 & 체키 획득 (Day 2~3)

- [x] **T11** 대화 팝업(짧은 2지선다) + 선물 선호표 + **관계 단계(존댓말→반말) 전환 컷인** — `대화`/`선물` → `scripts/ui/choice_popup.gd`(2~3지선다, 옥자 질문→반응 한 줄, 셸 SELECT/OK/CANCEL·터치 하이브리드, **선택 시점에만 스태미나 소모·호감도 적용**=취소 시 무변경). 토막·선호표 데이터 `data/dialogue.gd`(`TALK`/`GIFTS` + `pick_talk`/`gift_choices`/`gift_prompt`, tier→`Balance.AFF_*` 매핑은 `cafe.gd`). 단계 guest→regular 도달 시 **반말 해금 컷인** `scripts/ui/stage_cutin.gd`(옥자 3줄 시퀀스 + "반말 해금" 골드 배지 + 폴짝) — 떠 있는 오버레이(리빌·팝업·책)가 다 닫힌 뒤 발화하도록 `_maybe_cutin` 예약. 데모 시드 `DEMO_SEED_AFFINITY` 560→595(첫 교감 한 번으로 컷인 발화).
- [x] **T12** 체키 데이터 모델(`scripts/systems/cheki.gd`): 슬롯 = `캐릭터 × 이벤트`, 레코드 `{common, butterfly, shards, nickname, acquired_at}`(SaveManager SSOT) · `grade()`/`owned()` · **`pick_today()`**(아트 준비된 이벤트 중 미보유 우선 → 일반만 보유 우선 → 나비) · **`grant()`**(미보유→신규 일반, 중복→나비 조각+승급 판정). 이벤트 id↔에셋 slug 매핑(`Events.event_slug`, mine↔jirai) + 합성 레이어 경로 헬퍼(`cheki_costume/bg/frame_path`). (→ ADR 0002·0003)
- [x] **T13** **체키 획득: 호감도 게이지 가득 → 오늘의 체키 자동 획득**(`cafe._on_gauge_full`): `Cheki.grant` → `meters.consume_gauge_okja()`(재발화 방지) → 옥자 폴짝 + **리빌 오버레이**(`scripts/ui/cheki_reveal.gd`). 미보유 우선 일반 / 중복→나비 승급. 셸 OK/탭 하이브리드.
- [x] **T14** 나비 해금(연속출석 마일스톤 보상: 3일/7일 → 나비 조각) — `meters.begin_session`이 일자 갱신 후 `_update_attendance`가 돌려준 streak로 `_check_milestone`(정확히 3일/7일에만 발화) → `Cheki.grant_milestone_shards(amount)`(`ATTENDANCE_REWARD_SHARDS_3=1`/`_7=2`)가 **보유한 일반 칸 중 승급에 가장 가까운(조각 최다) 칸**에 적립(승급 판정 포함) → `meters.pending_milestone`에 적재. `Cafe.start()`가 이를 소비해 **보상 리빌**(`ChekiReveal` 재사용 + `setup(reward, headline)` 상단 골드 배너 "N일 연속 출석!", 승급이면 나비 카드) 표시. `Cheki.add_shards`/`_result_of` 헬퍼 신설. ※ 출석 맞이 연출은 T06c에서 완료.
- ✅ **A2** 옥자 지뢰계 의상(★히어로) + 체키 카드 양면 세트(표지 파치먼트·날개/나비 엠블럼·나라카 워드마크 + 사진 배경 `bg_cheki_jirai` + 표준/지뢰계 프레임) — 규격·누끼 검수 통과, 임포트·렌더 확인

## Phase 3 — 시온이 교감 모드 & 컬렉션북 (Day 3~4)

- [x] **T15** 시온이 교감 모드(`scripts/sioni.gd` + `cafe.gd`/`action_bar.gd`/`hud.gd`/`meters.gd`): 라이브 시온이(idle/간식/놀기/쓰담 반응 스왑, Okja 패턴 축소판) 카페 배치 → **시온이 탭 → 하단 4버튼 전환**(체키 주문/간식/놀기/쓰담) + HUD 게이지를 시온이로 전환 → `Meters.add_affinity_sion()`·`consume_gauge_sion()`(GAUGE_SION) → 게이지 풀 → 시온이 "오늘의 체키"(`Cheki.grant("sion",...)` = 지뢰계 `sion_jirai`) 자동 획득·리빌. **옥자 탭/CANCEL = 옥자 복귀**. `ActionBar.configure()`로 버튼 세트 주입, 액션 바 2개 토글. ⏳ 후속: 선호 간식 보너스·시온이→옥자 교차 호감도(`AFF_GIFT_SION_TO_OKJA`)·시온이 반말 전환은 없음(펫).
- [x] **T16** 컬렉션북(`scripts/ui/collection_book.gd`): 카페 우상단 아이콘/CANCEL 토글 → 풀스크린 오버레이. 캐릭터 탭(옥자·시온이 + 잠긴 미래멤버 placeholder) → **2열 세로스크롤 그리드**(`scripts/ui/cheki_slot.gd`, 칸=owned/empty/locked 3-상태, 사진 면 고정, locked도 이벤트명 노출=예고형) → owned 칸 탭 시 **확대 모달**(`scripts/ui/card_detail.gd`: 2배 + 플립 + 보유칸 prev/next + 공유 스텁). **평면 링 포커스**(SELECT 순환·OK 활성·CANCEL 뒤로, cafe action_bar 관용구 계승), 터치 주입력. `Events.events_for()` 헬퍼 추가. read-only(저장·Balance 무변경). (→ ADR 0002·0003)
- [x] **T17** 체키 카드 렌더러(`scripts/ui/cheki_card.gd`): 런타임 합성 양면 카드(120×180) — 앞=표지(파치먼트+등급 엠블럼+워드마크+닉/날짜 갈무리), 뒤=사진(배경+의상 누끼 상반신 크롭+프레임) + 등급 스왑(일반↔나비: 엠블럼+프레임 동시) + 가짜 3D 가로 플립(scale_x, 셰이더 없음). **A2 선반영으로 렌더러 코어·플립 완료**(T13 리빌에서 사용). ✅ 카드 확대 모달의 SELECT 이전/다음 카드 내비는 컬렉션북 **T16**(`card_detail.gd`)에서 완료. (→ ADR 0003)
- [x] **T16b** 체키북 장식 패스(실물 포토카드 바인더 은유): 가죽 테두리+크림 속지 / 미보유 칸=표지 디밍 재활용+참(✦반짝임·왁스 봉랍) / 미니 초상 색인 탭 / 진행도 카운터 `◆◆◇◇◇ n/m`(미래 포함) / 코너 브래킷 포커스(hop+글로우) / 이모지(🔒·?) 전량 도트 교체. 신규 `card_charm`·`focus_brackets`·`butterfly_deco`·`character_tab`. **A6 에셋 연결 완료** — 코드 플레이스홀더 → `book_frame_leather`·`book_page_parchment`·`book_watermark_n`·`corner_filigree`·`portrait_*`·`seal_wax`·`sparkle`·`butterfly_deco` 실제 텍스처 교체(에셋 없으면 플레이스홀더 폴백). 매니페스트 = asset-checklist **A6** + asset_manifest.json. 모달(`card_detail`) 폴리시는 후속. (→ ADR 0001·0003 / 장식 합의 2026-06-05)
- ✅ **A6** 체키북 장식 에셋: 가죽 프레임·크림 속지·미니 초상(옥자/시온이)·왁스 봉랍(P0) + 코너 필리그리·나비·N 워터마크·✦반짝임(P1) + 촛불·리본(P2) — 전 항목 제작·임포트·렌더 검수 완료. `portrait_sion`은 `sioni_idle` 머리 크롭으로 코드 생성. (→ docs/asset-checklist.md A6)
- ✅ **A3**(부분) 시온이 48×48(idle + 교감 반응 3종) + 시온이 쿠로미 의상(지뢰계 `sion_jirai`) 제작·임포트 완료, **T15 라이브 시온이 교감 연동 완료**. ⏳ 남은 것: 선물 아이콘(음료는 선택지 UI 없어 아이콘 불필요)

## Phase 3.5 — 메인 화면 UI 대수술 (디오라마 리프레임)

> 합의 2026-06-05(grill-me). 현 메인은 옥자 옆에 시온이가 발치에 48px로 조그맣게 붙고, 체키 진입이 우상단 임시 텍스트 버튼/CANCEL이라 부자연스럽다. **카페 디오라마**로 재구성: 중앙 옥자 전신 + **좌우 대칭 엔틱 가구**(좌=서랍장/책장+체키북 바인더, 우=포션·술병 선반+시온이) → 옥자 중앙 주인공이 또렷, 시온이는 어깨 높이로 자연 배치, 체키 진입은 디제틱 탭. (→ ADR 0001 정수배·Nearest 사수)

- [x] **T26** 디오라마 컨테이너 리팩터(`cafe.gd`): bg+옥자+시온이+가구/터치영역을 **단일 컨테이너 `_stage`(Node2D)**로 묶고 HUD·액션바·티커·미터는 형제로 분리(줌 제외). 옥자 발밑 앵커 (166,400) 유지=전신. **시온이를 발치 → 우측 바 카운터 위**(`SIONI_FEET`=(246,293), 옥자 옆)로 이동 + 크기 48→60(`sioni.gd` `SPR_SIZE`). 좌측 캐비닛 상판 **체키북 바인더**(`BINDER_FEET`=(54,303)) + 탭 영역 신설. 우상단 "체키" 텍스트 버튼 제거. ※ 우측 벽 선반이 포션으로 차 어깨높이 빈칸이 없어 **카운터 위**로 배치(배경 받침에 맞춤).
- [x] **T27** 시온이 탭 → **정수 2배 푸시 줌**: `_stage`를 시온이 몸통 중앙(`SION_FOCUS_LOCAL`) 기준 **scale 2.0**으로 0.3s 트윈(정지=2x 픽셀 또렷, 정수 위치 라운딩, 전환만 비정수) + 컨테이너가 LCD를 덮도록 **위치 클램프**. 옥자 탭/CANCEL = 1x 복귀. 기본 뷰=1x 풀 디오라마(옥자 메인), 시온이 모드만 2x 스포트라이트(옥자 얼굴 좌측 맥락 유지). 헬퍼 `_focus_stage`/`_reset_stage`/`_tween_stage`.
- [x] **T28** **나인패치 귀여운 버튼 시스템**(`ui_theme.gd`): `button_box()`/`style_button()`을 `StyleBoxTexture`(9-slice, 인셋 14px) 기반으로 교체 → 액션바·온보딩·스플래시·팝업·체키리빌 **전면 통일**. 라벨=갈무리 폰트 오버레이, NEAREST 필터, 동적 폭 대응. 포커스=골드 하트 커서 유지 + focused 나인패치(`btn_9slice_focused`) 스왑.
- [x] **T29** **체키 진입 = 디제틱 바인더 탭**(`cafe.gd`): 좌측 캐비닛 위 `cheki_binder` 스프라이트 + 투명 터치 → 컬렉션북(`_open_book`). 셸 옥자 모드 CANCEL = 체키북 열기 **보조 유지**, 시온이 모드 CANCEL = 옥자 복귀(현행).
- ✅ **A7** 메인 디오라마 배경(`bg_naraka.png` 333×480): 좌 캐비닛/책장, 우 포션선반+바 카운터, 옥자 전신 어울리는 아늑한 지옥 카페 — 받침(우 카운터·좌 캐비닛 상판) 확보. 임포트·합성 검수 통과.
- ✅ **A8** 보조 에셋: 시온이 60px(idle+반응 3종), 나인패치 버튼 틀 normal/focused(64×40), 체키북 바인더(48×56) — 임포트·렌더 확인.

## Phase 4 — 연출 & 공유 (Day 4~5)

- [x] **T18** "오늘의 체키" 획득 연출(게이지 풀 → 카드 팝업 + 사운드 자리) — 리빌(`cheki_reveal.gd`)에 **골든 광선 버스트**(`scripts/ui/burst_rays.gd`, 셰이더 없이 `_draw` 방사 + 스핀) + **카드 중앙 스케일 팝**(오버슈트) 추가. **사운드 자리** = `Sfx` 오토로드(`scripts/systems/sfx.gd`) — 큐 키→`assets/audio/` 경로만 매핑하고 **파일 없으면 무음 no-op**(S3에서 8비트 효과음 드롭인 시 자동 발화), 런타임 SFX 버스. 비트 연결: 주문/UI=`tap`·`order`(`action_bar._choose`, id 기준), 게이지 풀=`gauge_full`, 획득=`cheki_get`, 플립=`flip`, 나비 승급=`butterfly`, 체키북=`book`, 공유 저장=`shutter`. 가이드 `assets/audio/README.md`.
- [x] **T19** 공유: 카드/컬렉션 → 이미지 내보내기 + 워터마크(@나라카 + QR 자리) — `scripts/ui/share_card.gd`(ShareCard 오버레이): **SubViewport 합성**(크림 골드 액자 + 체키 사진면 정수 2배 + 푸터[`@나라카` 워드마크 · QR 자리]) → 한 프레임 렌더 → `get_image()` 미리보기 → **저장**(웹=`JavaScriptBridge` base64 다운로드 / 그 외=`user://shares/*.png`). QR 자리 = `scripts/ui/qr_placeholder.gd`(파인더+더미 모듈 `_draw`, 실제 QR은 T24 호스팅 후). 진입 = **카드 확대 모달**(`card_detail.gd` 공유 버튼, 스텁 제거) + **획득 리빌**(사진 공개 후 `공유` 버튼/SELECT — 자랑 피크). 셸 OK=저장·CANCEL=닫기·바깥 탭=닫기. (→ PRD §5.4 / ADR 0003)
- ✅ **A4** 옥자 의상 추가: 유치원·힙합·집사 + 테마 프레임 3(크레용·그래피티·은쟁반) + 사진 배경 3(놀이터·그래피티골목·저택홀) — 의상 `okja_{kinder/hiphop/butler}`(128×288 누끼) · 프레임 `frame_*`(120×180, 사진 창 투명) · 배경 `bg_cheki_*`(120×180 불투명) **임포트·알파·렌더 검수 통과**(`tools/verify_cheki_art.gd`). `events.gd` `ART_READY` 켬 → 옥자 3겹 합성 자동 적용. ※ `frame_butler`는 크로마 창 펀치 누락분 후처리로 복구(`_src/frame_butler_raw.png` 백업).

## Phase 5 — 통합 & 폴리시 (Day 5~6)

> 합의 2026-06-07(grill-me → 메모리 `phase5-decisions`). **작업 순서**: T20 → T23-로직 → T21 → T24 → T23-실기기 → T22.
> 테스트 재설계를 앞에 둬 이후 변경의 안전망으로, 실기기 검증은 배포(T24) 뒤로.
> ✅ **미리 필요한 신규 AI 아트 없음** — PWA 아이콘·QR·잠긴 실루엣 전부 기존 에셋 재활용 + 도구 스크립트.
> ⚠️ **사용자 액션**: `vercel login`(배포 전 1회) · Python `qrcode`+`Pillow` 설치.

- [x] **T20** 전 도트 에셋 교체 → **"감사 스윕"으로 재정의**(교체는 사실상 완료): ① 팔레트 32색 인덱싱 일괄 검증(벗어난 픽셀 리포트→재인덱싱) ② 정렬/규격 점검(옥자 앵커·체키 120×180·셸 LCD 333×480) ③ 진행도 핍·책 나비 데코 등 코드드로잉은 **현행 유지**(도트 일관·신규 에셋 0). **완료**: 일괄 검수 도구 `tools/audit_sweep.py`(`dotify.audit` 재사용, 매니페스트 53개 일괄·`--fix` 재인덱싱) 신설 → 위반 5개(`frame_cover_bg`·`frame_standard`·`frame_jirai`·`bg_cheki_jirai`·`gate_naraka`, 근접 중복색) 재인덱싱(픽셀 변경 ≤0.5%) → **53/53 통과**. `shell_frame`은 ADR 0001 채택 레퍼런스 베젤이라 **소프트 면제**(치수만 검사), `emblem_wing`은 코드가 자연 크기 사용 → 매니페스트 96×56→64×64 정정. 체키 레이어 로드 재검증(`verify_cheki_art.gd`) 통과.
- ✅ **A5** 옥자 크리스마스 의상(`okja_xmas` 누끼·3겹 합성) + 시온이 루돌프 체키(`photo_sion_xmas` 배경 베이크 컷) + 크리스마스 테마 프레임(눈·리스 `frame_xmas`) + 사진 배경(눈 내리는 거리 `bg_cheki_xmas`) → **총 5세트/5프레임 완성**. 임포트·알파·렌더 검수 통과(`tools/verify_cheki_art.gd`). `ART_READY` xmas 켬. ※ 시온이는 누끼 대신 배경 포함 베이크 컷 방식(지뢰계 `photo_sion_jirai`와 동일) — 매니페스트 `sion_xmas`→`photo_sion_xmas` 갱신.
- [x] **T21** 잠긴 멤버 + "한정" 슬롯 + 확장 슬라이드 — 옥자·시온이 + **바나·멜·미호 3개 네임드 잠금 탭**(이름 노출, 초상=`character_tab.gd` 코드 실루엣 + `seal_wax`). ① **확장 슬라이드**(잠긴 탭 OK → 파치먼트+가죽 톤 오버레이 1장: 실루엣·이름·"다음 업데이트에 만나요" + 펫 확장 한 줄, CANCEL 닫기) ② **"한정" 슬롯**(옥자 그리드 끝 1칸: 표지 디밍+봉랍, 문구는 **컨셉/예정으로 톤다운** — 데모에선 실제 해금 불가). 펫(코코·선아·수아·규종이)은 슬라이드 문구로만. 신규 에셋 0. **완료**: `MemberSilhouette`(코드 흉상, 탭·슬라이드 공용)·`ExpansionSlide`(파치먼트 톤 예고 오버레이) 신설, `CharacterTab` 잠금 탭=실루엣+봉랍 배지+accent색, `ChekiSlot` `STATE_LIMITED` 추가, `CollectionBook` 통합(5탭·한정 슬롯·슬라이드 위임). 색=바나 보라/멜 청록/미호 핑크(CONTEXT 로스터 일치). `test_phase2` T21 스모크 8단언 추가 → 79통과.
- [x] **T22** 첫 화면 임팩트만 가볍게 — splash 페이싱(문 열림→옥자 폴짝→이름 호명이 0~10초에) + 첫 진입(온보딩→첫 체키) 무결성. ※ **데모 시나리오 리허설은 보류**(데모 다시 살릴 때). **완료**: grill-me로 *두 절↔두 경로* 확정 — **0~10초 페이싱=재방문**(자동재생·결정적), **무결성=첫 접속**(이름 호명이 타이핑 의존이라 타이밍 아닌 정합성 관심사). ① **재방문 스플래시**: 닫힘 0.25+열림 1.4+카드 0.3+머무름 0.9 = 자동재생 ~2.85s(헤드리스 `finished` 실측 2.71s, 0~10초 여유). 폴짝(`hop` 0.42s)+이름 카드가 ~1.65s에 동시 터지는 "타-다!" 합동 비트 — **프레임 캡처 픽셀 검토**로 혼탁 없음 확인(폴짝은 위로↑·카드는 하단, 수직 분리 + z-order상 카드가 옥자 앞이라 "또 왔네, {닉}님" 또렷) → **현행 유지(순차 안무 불필요)**. ② **첫 접속 무결성**: 온보딩→첫 지뢰계 체키 grant가 **닉을 표지 헌사로 스냅샷**(`cheki.gd:91`, 순서 역전 시 "손님"으로 빔)하는 계약을 `test_phase2` 회귀 assert 2개로 못 박음(스냅샷 + 첫 획득 닉 고정 불변성) → **81통과**. IME 마지막 글자·빈값→"손님"·웹 prompt·재진입 시 온보딩 미노출은 실입력 확인 통과. 첫 접속 스플래시 폴짝은 `idle`(시크한 첫 만남 톤) 유지 — 손대지 않음. 프로덕션 코드 무변경(테스트 +2).
- [x] **T23** 버그픽스 + 밸런스 + **테스트 재설계** — 합의 2026-06-07(grill-me). **완료**: 헤드리스 165통과/0실패 + 라이브 자동 스모크 + **실기기 확인**(iOS 한글 IME 조합·네이티브 공유 시트 둘 다 동작 — 2026-06-07).
  - ✅ ① **테스트 재설계(확장)**: 구 1단계(`DEMO_SEED` 제거 + `build_state`/`apply_dev_preset` 빌더)를 넘어 **날짜 기반 시스템까지** 덮음. ⓐ **`Clock` seam 신설**(`scripts/systems/clock.gd` — `now()/today()/day_string/set_day/advance_days/freeze_at/reset`, 기본=시스템, 테스트만 override): `meters.evaluate_session`·`begin_session`·`_update_attendance`·`save_manager.save_game`·`cheki.acquired_at`의 시스템 시계 호출을 전부 라우팅 → "날짜를 하루씩 넘기는" 진짜 멀티데이 체인 가능. **부수 버그픽스**: 과거 `evaluate_session`이 today=로컬·yesterday=UTC로 갈려 tz 자정 부근 연속출석 오판 소지 → Clock 으로 **로컬 단일 기준 통일**. ⓑ **공유 `TestBase`**(백업/원복으로 플레이어 실세이브 보호 — 구 `test_phase2`는 끝에 `wipe()`로 실세이브 삭제했음 = **클로버링 버그 픽스**) + `tools/run_tests.sh`(import 선행 + 3씬 합산 exit code). ⓒ **모놀리스 분할**: `test_phase2` → `test_systems`(76)·`test_content`(72), `test_cutin`(17) 유지. ⓓ **신규 커버리지 A~E**: A 출석/날짜(1→7일 체인·끊김 streak=1 리셋·같은날 멱등·마일스톤3/7), B 기분/방치(24h 경계·시무룩 −20% 실적용·교감당 1단계 회복), D 세이브 영속(wipe 파일삭제·reset·**save→load 라운드트립**·**손상 JSON 폴백**), E 스태미나(6액션 소진+`stamina_empty`·새날 풀충전).
  - ✅ ② **실기기 패스 — 부분 방어선 + 라이브 자동 스모크**: ✅ 웹 한글 렌더(→T24) / ✅ **영속 직렬화 정합**(D 라운드트립+손상폴백) / ✅ **공유 합성 스모크**(`ShareCard`→네이티브 PNG, 무크래시). **라이브 Playwright 스모크**(2026-06-07, narakuchi.vercel.app, iPhone13 에뮬, `docs/device-test-checklist.md`): 부팅 200·캔버스 390×664·**콘솔 에러 0/pageerror 0**·한글 .notdef 0·닉네임 prompt() 발화 / **세이브 영속 실증** — 리로드 후 IndexedDB `/userfs` 유지 + **카페 복귀 + 저장 닉 인사("또 왔네요 테스트닉님")** = 웹 save→load 라이브 동작. **실기기 확인 완료**(2026-06-07): iOS Safari 한글 IME 조합·`navigator.share` 네이티브 공유 시트 둘 다 동작.
  - ✅ ③ **밸런스(케이던스 테스트로 코드화)**: 클럭 체인 × 전형 플레이(상한=알찬 교감/하한=무난 대화) → **단골(200) 알찬 3일·무난 5일 / 반말(600) 알찬 7일·무난 14일** 측정 = 설계 의도(단골 ~3일·반말 ~1주) 부합 → **수치 무변경**. 넓은 설계 밴드 하드 단언(단골 ≤7일·반말 ≤16일·단조성·반말 최소 5일+)으로 회귀 고정. **벽시계 1~3분 실측은 디바이스 세션 몫**.
  - 🔧 **데모 프리셋 C**: `regular_edge`(단골 등극 직전) 신설 + **디버그 키 7** 매핑(comfy_edge=키2 유지), 테스트가 동일 프리셋 opts 재사용(실연=회귀 단일 출처). `test_cutin`에 단골 등극 비트 5단언 추가.
  - ⚠️ **관찰(미조정)**: `MOOD_PENALTY_HOURS=24` 정확 경계 — 매일 *같은 시각* 방문 시 24.0h라 시무룩 트리거(다른 시각이면 회피). "벌 없는 설계"상 −20%·1교감 회복으로 가벼워 **확인만, 무변경**. 게이지 시드 라이브 체키 연출 데모는 **보류**.
- [x] **T24** PWA 마감 + 호스팅 + QR — **호스팅** Vercel `https://narakuchi.vercel.app`(무료 서브도메인, 단일 스레드 유지→COOP/COEP 불필요). **배포** CLI 수동 `tools/deploy.sh`(`godot export` → `vercel --prod export/`, 산출물 git 커밋 안 함). **PWA 아이콘** 옥자 얼굴 재활용 합성 `tools/make_pwa_icons.py`(192/512/180/144 + iOS 스플래시). **QR** 빌드타임 Python `qrcode` `tools/gen_qr.py`→`qr_naraka.png`(2색)→**공유 카드만**(`qr_placeholder` 교체). `vercel.json` 최소(헤더 불필요). **완료**: `gen_qr.py`(버전3·111px 버건디/크림)·`make_pwa_icons.py`(옥자 얼굴 크롭+버건디 라운드+골드 링, 144/180/192/512+iOS 스플래시 3종+head_include)·`deploy.sh`·`vercel.json`(SW no-cache) 신설, 프리셋 COOP/COEP off+아이콘 연결+head_include, `share_card` QR 네이티브 1:1 연결·푸터 확대(QrPlaceholder 폴백 유지). **웹 export 빌드 통과**(매니페스트·apple-touch·옥자 아이콘 확인), audit 58/58·테스트 79+12. ✅ **호스팅 라이브**(2026-06-07): `vercel link --project narakuchi`(→ `jeffkms-projects/narakuchi`) + 프로덕션 배포 완료 → `https://narakuchi.vercel.app` 200(공개 OK·배포보호 없음), `index.wasm`=`application/wasm`·SW=`no-cache` 헤더 확인. 이후 재배포는 `tools/deploy.sh`. 🐛 **웹 한글 깨짐 수정**(2026-06-07, 실기기 1차에서 발견): 셸 LCD=`SubViewport`라 내부 Control 이 루트 Window 테마를 못 받아 엔진 기본폰트(Open Sans, 한글 없음)로 폴백 → 한글이 .notdef 박스(데스크톱은 OS 시스템폴백이 가려 안 보였음). `Fonts.install_global()`로 `ThemeDB.get_default_theme().default_font`=갈무리 교체(`Main._ready`에서 1회) → 전역 해결. Playwright(로컬+라이브) 렌더 검증, 재배포 완료.

## Phase 6 — 버퍼 & 스트레치 (Day 7)

- [ ] **T25** 최종 빌드/배포 + 폰 실기기 점검 + 데모 리허설 2회
- [ ] **S1** (스트레치) 수집 의상 라이브 옥자에 입히기
- [ ] **S2** (스트레치) 시온이 놀기 미니 인터랙션(레이저 포인터 등)
- [ ] **S3** (스트레치) 8비트 효과음(오더/획득/나비 해금)

---

## Phase 7 — 캐릭터·펫 확장 + 로스터 선택 (MVP 이후)

> 합의 2026-06-07(grill-me → 메모리 `character-expansion-plan`). 옥자·시온이 MVP 이후 메인(바나·멜·미호)·펫(코코·규종이·선아·수아)을 추가하고 로스터 선택을 넣는다.
> ⚠️ Phase 5 `phase5-decisions`의 "잠긴 멤버=영구 실루엣" 방침을 **의도적으로 뒤집는다** — 그 멤버들이 실제 플레이 가능 캐릭터가 된다.

**원칙**
- **수직 슬라이스, 한 명씩**: 매 슬라이스 *아트 에셋 생산 → 코드/대사 배선*. **첫 슬라이스=미호**(펫 규종이 1:1). **멜은 최후**(펫 선아·수아 2마리 → 단일 펫으로 모델 검증 후 확장).
- **해금·화폐(♡)는 전 캐릭터 추가 후 맨 마지막**. 그전까진 추가된 캐릭터는 *전부 열린 채* 자유 선택.
- **슬라이스 DoD(B)**: 라이브 완성(표정 6·티커·`대화` 선택지·시그니처 음료·존댓말→반말 컷인·인트로 체키 1벌). **이벤트 의상 체키는 별도 아트 트랙으로 점증**(5벌 선결 금지). 비대칭 그리드 정상(시온이 선례).

**📍 추적 이슈 — 미호 슬라이스 (실행 단위의 단일 진실)**

> 아래 T-태스크는 *레이어형 묶음*이고, 실제 작업은 GitHub 이슈에서 *수직 슬라이스*로 재편됐다. 상세(수용 기준·차단)는 이슈 본문 참조: `gh issue view <번호>`.

부모 추적: **[#7](https://github.com/JeffKM/Narakuchi/issues/7)** (`gh issue view 7`)

| 이슈 | 슬라이스 | 타입 | 차단 | 상태 |
|---|---|---|---|---|
| [#1](https://github.com/JeffKM/Narakuchi/issues/1) | 🎨 미호 아트 에셋 생산 | HITL | — | ✅ 완료 |
| [#2](https://github.com/JeffKM/Narakuchi/issues/2) | 🧩 캐릭터 레지스트리 + 미호 라이브 (트레이서) | AFK | #1 | ✅ 완료 (T30) |
| [#3](https://github.com/JeffKM/Narakuchi/issues/3) | 🎴 로스터 선택 화면 | AFK | #2 | ✅ 완료 (T31) |
| [#4](https://github.com/JeffKM/Narakuchi/issues/4) | 💬 미호 완전 교감 파리티 + 반말 컷인 | AFK | #2, #1 | ✅ 완료 (T33) |
| [#5](https://github.com/JeffKM/Narakuchi/issues/5) | 📸 미호 인트로 체키 + 컬렉션북 탭 | AFK | #2, #1 | ✅ 완료 (T34) |
| [#6](https://github.com/JeffKM/Narakuchi/issues/6) | 🐈‍⬛ 펫 규종이 슬라이스 | AFK | #2, #3 + 규종이 아트 | ✅ 완료 (T35) |

**🧩 코드 트랙 (슬라이스마다 반복, 패턴은 첫 슬라이스에서 확립)**

- [x] **T30** 캐릭터 일반화 토대 `(미호=#2)` — **완료(트레이서)**: `data/characters.gd` 레지스트리 신설(메인 옥자·미호 / 펫 시온이 — kind·표정경로·게이지풀·대사/버튼키·인트로이벤트). `SaveManager` 캐릭터 상태를 **레지스트리 주도**로(okja/sion 하드코딩 제거, 미호 블록·`flags.active_main` 추가) + **버전 범프 v1→v2 + 클린 리셋**. `Meters` 제네릭화(`add_affinity_main`/`consume_gauge_main`/`stage_of`/`_add_main`/`_post_affinity_main`/`_recover_mood(char)`, 기존 `*_okja`는 백호환 래퍼) + `stage()`·터치·방치는 active_main 기준. `Okja` 스탠딩이 `character` 로 임의 메인 렌더(표정=레지스트리 파생). `Hud` 게이지/기분이 active_main 기준. `cafe` 가 `active_main` 을 들고 제네릭 호출. `DebugTools` 키 8 = active_main 토글(미호 라이브 확인). 미호를 `mine` 이벤트 참여로. **검수**: 테스트 89+202+17 통과(미호 레지스트리 13단언 신규), verify_cheki_art 26레이어 회귀 OK, 헤드리스 부팅 무에러. **이연**: 대사는 미호=옥자 템플릿 공유(#4), 로스터 선택 UI·splash "고른 메인 맞이"(#3), 펫 일반화(#6).
- [x] **T31** 로스터 선택 화면 `(미호=#3)` — **완료**: 재사용 오버레이 `scripts/ui/roster_screen.gd`(RosterScreen)로 메인+펫을 **자유 조합**으로 선택. 레지스트리 주도 카드(포트레이트·이름·관계단계/소개·accent) + 셸 3버튼 + 골드 하트 포커스. 온보딩(닉네임 다음)에서 첫 `active_main`+`active_pet` 선택 → **고른 메인이 맞이(템플릿 인사) + 그 메인의 인트로 체키**(`onboarding.gd` 옥자/`mine` 하드코딩 제거). 카페 **좌상단 진입 버튼 + `swap_active`** 런타임 교체(라이브 스탠딩 텍스처만 스왑, `okja.set_character`로 표정 6종 재로드·트리/트윈 보존). `save_manager`에 `flags.active_pet` 스키마 + `build_state` 지원, `debug_tools` 키 8 = 라이브 swap 경로. 시스템 95 통과(active_pet 스키마 + 로스터 결정 경로 회귀).
- [~] **T32** 컬렉션북 탭 일반화 `(미호 탭=#5 ✅ · 펫 섹션=#6 ✅)` — 메인 4 + 펫 5 = 9탭 "메인/펫" 섹션 그룹핑. **메인/펫 섹션 그룹핑은 #6에서 도입**(`TABS` 항목에 `section` 메타[main/pet/locked] + `_build_tabs` 가 섹션 경계에 `SECTION_GAP` 삽입). 남은 분: 캐릭터 전수 확장(9탭)·잠긴 탭 **3-상태 수명**(미빌드 실루엣 → 빌드+무료 → 빌드+♡게이트).
- [x] **T34** 미호 인트로 체키 + 컬렉션북 탭 `(미호=#5)` — **완료**: 미호 체키 파리티를 관통. ① **컬렉션북 미호 탭 잠금 해제**(`collection_book.gd` `TABS` 미호 `locked:true→false` + 메인(옥자·미호)→펫(시온이)→잠긴 예고(바나·멜) 순으로 재배치) — 실루엣 → 실제 그리드. 미호 참여 이벤트만(`events_for("miho")`=지뢰계) **비대칭 그리드 정상**(시온이 선례, DoD-B 5벌 선결 금지), 미보유=예고형 빈칸(`STATE_EMPTY`)·보유=`owned` 칸 → 확대 모달(`CardDetail`)·공유(`ShareCard`)는 캐릭터 무관 `ChekiCard` 합성(`bg_cheki_miho_jirai`+`miho_jirai`+표준/지뢰계 프레임)으로 그대로 동작. ② **마일스톤 보상 파리티**(`cheki.gd grant_milestone_shards` `[okja,sion]` 하드코딩 → `Characters.all_ids()` 전수) — 미호 메인 플레이어도 출석 나비 조각이 닿게(누락 버그 차단). 인트로 체키·게이지 풀 자동 획득은 이미 T31/T30·`cafe._on_gauge_full(character)`·`onboarding._grant_first_cheki(main_id)`로 일반화돼 회귀 없음. `Characters.all_ids()` 헬퍼 신설. **검수**: 콘텐츠 228(미호 탭 9·마일스톤 파리티 3 신규)·시스템 95·컷인 17 통과, 옥자·시온이·T21 회귀 없음(잠긴 탭 테스트 동적 인덱스화).
- [x] **T35** 펫 규종이 슬라이스 — 정식 배선 `(규종이=#6)` — **완료**: f9ff7c7 임시 검수 코드(`_sioni.sprite_prefix = "gyujong"` 하드코딩)를 **active_pet 기반 정식 배선**으로 교체. 시온이 하드코딩을 **제네릭 펫 경로**로 끌어올려 규종이를 시온이 미러로 합류. ① **시스템 일반화**: `Meters` `add_affinity_sion`/`consume_gauge_sion` → `add_affinity_pet`/`consume_gauge_pet(character)`(게이지 풀=`Characters.gauge_full` 단일 출처, 기존 `*_sion`은 백호환 래퍼), `Dialogue.sion_line` → `pet_line(key, action)`(dialogue_key 로 티커 풀 분기·sion 폴백), `Hud` 펫 게이지 표시 `_focus=="sion"` → `not Characters.is_main` 일반 분기, `Sioni.set_prefix()` 런타임 스프라이트 교체(로스터 펫 스왑). ② **cafe 배선**: `_active_pet` 변수 + 게이지 적립/소진·교감모드 진입·`swap_active`(펫 라이브 스왑)·`debug_grant_cheki` 전부 활성 펫 기준. ③ **데이터**: `characters.gd` 규종이 레지스트리(PET·`buttons:sion` 공유·`dialogue:gyujong` 전용)·`gauge_full` 매치, `balance.gd` `GAUGE_GYUJONG`, `events.gd` `GYUJONG`+지뢰계 참여, `ticker.json` 규종이 전용 풀(까만 턱시도·초록 눈). ④ **컬렉션북**: 규종이 펫 탭 + `section` 메타로 메인/펫 섹션 그룹핑(→ T32). 규종이 해금으로 `ExpansionSlide` 예고 목록에서 제외. **검수**: 시스템·콘텐츠 테스트 전수 녹색(규종이 펫 미터·체키·탭 미러 신규 + 시온이/미호/옥자 회귀 가드). 세이브·로스터·체키는 레지스트리 주도라 코드 무수정 자동 확장.
- [x] **T33+** 슬라이스 #1 미호 배선 `(라이브=#2 ✅ · 교감=#4 ✅ · 체키=#5 ✅ · 펫 규종이=#6 ✅)` → 이후 바나 → 멜(펫 2마리) — 각자 레지스트리 1항 + 에셋 + 대사 파일. **교감 파리티(#4) 완료**: `data/dialogue.gd` 캐릭터별 일반화(폴백 방식 — ticker 키 직접 / talk·gifts `_section` 폴백으로 옥자 평면 legacy 유지 → content_studio 무손상), 미호 전용 대사(`ticker.json` `miho`+`miho_cutin` / `talk.json` `miho` / `gifts.json` `miho`, 톤=포근·애교·영리한 여우 + 시그니처 '미호 스파클링'), 미호 600 도달 **전용 반말 컷인**(`stage_cutin` character 렌더 + `cutin(key)`), `cafe`(`_dialogue_key`)·`splash`(`_main_id` — 재방문 맞이도 active_main)·`characters`(미호 `dialogue:miho`) 배선. `is_casual` 은 stage 만 받아 character-agnostic(옥자/미호 말투 누설 없음 — 테스트 못박음). `docs/script-miho.md` 신설. **체키 파리티(#5) 완료**: 미호 탭 잠금 해제·마일스톤 전수(→ T34). **펫 규종이(#6) 완료**(→ T35, active_pet 정식 배선) — 미호 슬라이스(라이브·교감·체키·펫) 전부 완료.
- [ ] **T39(최후)** 해금 경제 — ♡ 화폐(데일리 교감 적립·HUD·세이브 필드) + 상점에서 확정 해금(펫 저렴). 잠긴 탭을 ♡게이트로 전환. *(이슈 미발행 — 전 캐릭터 추가 후)*

**🎨 아트 트랙 (코드보다 항상 선행)**

- [~] 신규 메인 1명당: 표정 6장(idle/smile/shy/sad/brew/talk) + 초상 + 인트로(지뢰계) 체키 의상 1벌 → 이벤트 의상 점증 `(미호=#1)` — **미호 ✅ 완료**(표정6·초상·지뢰계 의상·체키 배경, SD 재수정), 바나·멜 대기
- [~] 신규 펫 1마리당: 반응 4컷(idle/간식/놀기/쓰담) + 초상 + 인트로 체키 베이크컷 `(규종이=#6)` — **규종이 ✅ 완료**(반응 4컷·초상·지뢰계 베이크컷, b98fc44 — 까만 턱시도·흰 블레이즈·초록 눈, 마이멜로디풍 핑크 체키), 코코·선아·수아 대기
- [ ] 시그니처 음료 연출 컷(블러디 미드나잇·청운 에이드·미호 스파클링) `(미호 스파클링=#1)`

---

## 데모 합격 체크리스트 (이게 다 되면 들고 간다)

- [ ] 링크 열면 **옥자가 살아 움직이며 맞이한다**
- [x] 옥자 4버튼(체키주문/음료/대화/선물)이 작동, **음료 제조 연출** + **대화 선택지 분기**(T11)
- [x] **시온이 탭 → 버튼이 시온이용으로 전환**되어 시온이와 교감
- [ ] **호감도 게이지 가득 → 체키 자동 획득** + **중복→나비 승급**
- [x] 컬렉션북에 **모은 체키 + 잠긴 칸**이 보인다
- [x] **공유 카드 이미지**(QR 자리 포함) 내보내기가 된다 (T19 — 카드 확대 모달·획득 리빌 → 합성 미리보기 → 저장)
- [ ] **폰에서 PWA**로 추가·실행된다
- [ ] 옥자 의상 **최소 3세트**(목표 5) + 시온이 **1세트**(목표 2)

## 컷 라인 (일정 밀리면 이 순서로 버린다)

1. S1/S2/S3 스트레치 → 2. 시온이 교감 모드(시온이 정적 컴패니언으로) → 3. 옥자 의상 5→3·시온이 2→1 → 4. 공유 연출 단순화(워터마크만) → 5. 대화 분기 축소(1~2 토막)
> **절대 사수**: 옥자 4버튼 교감 · 게이지 풀 체키 획득 · 컬렉션북 · 공유 이미지 1장.
