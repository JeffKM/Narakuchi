# 미호 보이스 스크립트 (구미호 메이드)

> 미호 슬라이스 #4 — 미호 전용 대사. **실데이터는 `data/ticker.json`(`miho`·`miho_cutin`) · `data/talk.json`(`miho`) · `data/gifts.json`(`miho`)** 에 있고(콘텐츠 스튜디오/JSON 편집), 이 문서는 **톤 가이드 + 설계 근거**다.
> 관련: [CONTEXT.md](../CONTEXT.md) 도메인 용어 · [docs/script-okja.md](./script-okja.md) 옥자 대비 · [gemini-prompts-miho.md](./gemini-prompts-miho.md) 비주얼 · 추적 이슈 [#4](https://github.com/JeffKM/Narakuchi/issues/4).

## 🦊 캐릭터 톤

- **정체성**: 구미호 메이드. 반려묘 **규종이**(까만 고양이, 별 슬라이스 #6). 시그니처 음료 **미호 스파클링**(톡 쏘는 황금빛 탄산).
- **무드**: **포근·애교 + 영리한 여우 + 약간 장난기.** 시크·츤데레의 옥자와 **정반대 대비** — 미호는 솔직하고 살갑다.
  - 옥자: "기다린 건 아니고, 그냥 언제 오나 싶긴 했어요." (츤데레)
  - 미호: "오실 줄 알았어요. 여우는 눈치가 빠르거든요. 후훗." (애교·자신감)
- **셀프 모티프**(대사에 자연스럽게 녹임): 여우 귀·**복슬 꼬리**(반가우면 살랑/삐지면 처짐)·**도깨비불(귀신불)**·**홀린다**(여우의 장난)·반려묘 **규종이**·**미호 스파클링**.
- **말버릇**: "후훗", "헤헤", "~걸요", "~잖아". 과하지 않게.

## 🗣 말투 분기 (옥자와 동일 규칙)

| 단계 | 임계(누적) | 말투 | 비고 |
|---|---|---|---|
| 손님 guest | 0 | 존댓말 + "{nick}님" | 애교 있는 존댓말 |
| 단골 regular | 200 | **아직 존댓말**(살가운) | 단골 등극 컷인 |
| 편해진 사이 comfy | 600 | **반말 전환** | 반말 해금 컷인(핵심 보상) |
| 마음 연 사이 close | 2000 | 반말(속내) | 전용 연출 후속 |

> 분기 단일 출처 `Balance.is_casual(stage)` — character별 `affinity_total` 로 stage 만 계산해 넘기면 옥자/미호가 독립 분기(서로 말투 누설 없음). 데이터는 ticker/talk/gifts 의 `guest`(존댓말)·`regular`(반말) 풀.

## 📟 티커 (상황 × 단계) — `ticker.json` `miho`

옥자와 **같은 상황 키 미러**: `enter`·`neglect`·`cheki`·`drink`·`talk`·`gift`·`touch`·`touch_cap`·`no_stamina`·`cheki_get`·`idle`. (코드 연동이라 키 추가/삭제 금지, 내용만 편집)

- **drink = 미호 스파클링 제조 보이스**(시그니처). 별도 음료 데이터 없이 이 풀로 표현 — 라이브는 `miho_brew` 표정(스파클링 든 손) + brew 연출 공유.
- 대표 라인:
  - enter(guest): "어머, {nick}님! 오실 줄 알았어요. 여우는 눈치가 빠르거든요. 후훗."
  - drink(guest): "미호 스파클링, 정성껏 만들어 드릴게요. 톡— 쏘는 황금빛이에요."
  - touch(guest): "어머, 간지러워요! 여우 꼬리는 약한걸요."
  - idle(guest): "규종이가 또 꼬리를 베고 자네요."

## 💬 대화 토막 — `talk.json` `miho`

`대화` 버튼 2~3지선다(guest/regular 각 3토막). 미호 모티프로 분기: 꼬리 만지기·도깨비불 색·규종이 간식. `good`(↑↑) 선택은 애교 보상, `plain`(↑)은 장난.

## 🎁 선물 선호표 — `gifts.json` `miho`

옥자와 **동일 라인업·tier·아이콘**, reply 만 미호 톤. 고양이 츄르는 반려묘 **규종이** 것(`sion` tier = 매우 좋아함). 폭신한 동물 인형 = `match`(미호 취향).

## 🎬 단계 컷인 — `ticker.json` `miho_cutin`

`StageCutin` 오버레이(다음 입장 1회). `regular`=단골 등극(존댓말 유지), `comfy`=반말 해금(핵심 보상).

- regular reveal: "앞으로도 자주 와주실 거죠, {nick}님?" / badge "✦ 단골 등극 ✦"
- comfy reveal: "이제부터 반말할게, {nick}." / badge "✦ 반말 해금 ✦"
  - 컷인 3줄: "{nick}님. ……아니." → "이제 그냥 {nick}이라고 부를래. 우리, 그 정도는 됐잖아?" → "여우가 마음을 연 거야. 영광인 줄 알아? 후훗."

> 옥자 comfy 컷인("……착각 마. 부르기 편해서야." — 츤데레)과 대비되는 **솔직·당당** 톤이 미호다움.

## 🔌 배선 (코드)

- `data/characters.gd`: 미호 `dialogue: "miho"` (버튼·표정 매핑은 `okja` 공유 — 6표정 동일).
- `data/dialogue.gd`: 전 함수가 `dialogue_key` 첫 인자. ticker 는 키 직접, talk/gifts 는 `_section` 폴백(옥자 평면 legacy / 미호 character 키) — **content_studio 무손상**.
- `cafe.gd`(`_dialogue_key()`) · `splash.gd`(`_main_id()`) · `stage_cutin.gd`(`setup(…, character)`) 가 active_main 을 따라 미호 대사·렌더.
