# Gemini 도트 변환 프롬프트 가이드 (옥자 · 시온이)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**. 상상 생성이 아니라 **사진 변환(img2img)**이 기본이다 — 인물 고증·일관성을 위해.

## 핵심 원칙 (왜 이렇게 쓰나)

1. **사진 변환 우선** — 옥자/시온이는 실존 컨셉이므로 실물 사진을 첨부해 "이 사진을 픽셀아트로" 요청한다. 텍스트만으로 새로 생성하면 매번 얼굴이 달라진다.
2. **단색 배경(크로마키)으로 받는다** — Gemini는 투명 배경을 못 만든다. **캐릭터에 없는 선명한 단색**을 배경으로 깔게 하고, `dotify --chroma`로 투명 분리한다.
   - 기본: 크로마 그린 `#00ff00` · 초록 의상(크리스마스)이면 마젠타 `#ff00ff`
3. **정확한 px·색 수는 요구하지 않는다** — "270×480" "32색" 같은 건 Gemini가 못 지킨다. **구도·비율·무드만** 지정하고 나머지는 후처리에 맡긴다.
4. **표정 6종은 다리·구도 고정, 얼굴 + 팔 자세만 변경** — 다리·하체·프레이밍은 모든 표정에서 동일하게, **얼굴과 팔 자세**만 바꾼다(팔도 그림에 박는 **아트 레벨**, 컷아웃 리깅 아님). 전환은 하드컷이라 크로스페이드 고스팅 걱정은 없다(→ ADR 0001 리스크).

---

## 공통 베이스 (옥자)

```
Convert the attached photo into retro pixel art / dot art, full body, front-facing standing pose.
Subject: "Okja", the witch-owner of a maid cafe — a hell witch. Chic, tsundere, playful.
Base outfit: witch-maid look (dark antique witch dress with maid accents).
Style: 8-bit pixel sprite, limited palette, hard pixel edges, NO anti-aliasing, NO gradients.
Color mood: dark antique — deep burgundy, blood red, antique gold, ink black, candle yellow.
Framing: full body centered, head near top, feet near bottom, tall vertical 4:9 portrait ratio,
         even margins, consistent crop across all expressions.
         Lower body and legs IDENTICAL across all expressions — only the FACE and ARM pose change.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (공통)

```
no text, no watermark, no signature, no multiple characters, no cropped limbs,
no background scenery, no gradient background, no soft anti-aliased edges,
no realistic photo finish, no 3D render.
```

### 표정 6종 — 베이스에 한 줄만 추가

**다리·하체·프레이밍은 고정**하고, **얼굴 표정 + 팔 자세**를 바꾼다(팔도 그림에 박는다 — 리깅 아님). (표정별 사진이 있으면 각각 변환이 더 정확)

| 파일명 | 추가 문구 |
|---|---|
| `okja_idle`    | `Expression: calm, mouth closed. Arms: both hands clasped together in front (default).` |
| `okja_smile`   | `Expression: soft warm smile, eyes gently curved. Arms: both hands clasped together up near the chest, delighted / pleased.` |
| `okja_shy`     | `Expression: shy, blushing cheeks, eyes averted. Arms: one hand raised, covering the mouth.` |
| `okja_sad`     | `Expression: sulky / pouting, downturned mouth (NEVER crying). Arms: lowered and drooping limply.` |
| `okja_brew`    | `Expression: focused "brewing". Arms: holding a drink / cup in both hands.` |
| `okja_talk`    | `Expression: mouth slightly open, talking. Arms: one hand raised in a gesture.` |

> ⚠️ **6종 전부 팔 자세가 다르다** (다리·하체·프레이밍만 고정). 전환은 하드컷 + 스쿼시 정착이라 팔 차이가 커도 OK. 기쁨 "팔 벌려 폴짝" 같은 전신 포즈는 별도로 그리지 않고 `okja_smile`을 리워드 순간에 **코드 hop**으로 재사용한다. 슬픔은 **팔 처짐 시무룩까지** — 우는 그림 금지(벌 없는 설계).

---

## 옥자 SD(데포르메) 버전 ★권장 — 라이브 스탠딩용

> **왜 SD인가**: 다마고치 LCD는 작아서 1:7 실사 비율이면 얼굴이 ~35px로 쪼그라들어 **표정 차이가 안 읽힌다.** 코어 메커닉이 "표정 9할 + 표정 스왑 6종"이므로 머리를 키운 SD가 표정 가독성·공유성·제작 일관성에서 유리하다(→ 실사 정교판은 타이틀 키비주얼·★히어로 체키 등 감상용으로 분리).
> **비율**: 극단 아기치비 말고 **1:3~1:4 "미니"** — 시크·츤데레 매력은 유지하되 얼굴·눈을 또렷하게.

```
Convert the attached photo into a CUTE CHIBI / SD pixel art sprite, full body, front-facing standing pose.
Subject: "Okja", the witch-owner of a maid cafe — a hell witch. Chic, tsundere, playful.
Proportions: super-deformed, head-to-body ratio about 1:3 ~ 1:4 — BIG head, large expressive eyes,
             short rounded body and short legs. Keep her recognizable witch-maid silhouette.
Base outfit: witch-maid look (dark antique witch dress with maid accents, witch hat).
Style: 8-bit pixel sprite / dot art, limited palette, hard pixel edges, NO anti-aliasing, NO gradients.
Color mood: dark antique — deep burgundy, blood red, antique gold, ink black, candle yellow.
Framing: full body centered, big head near top, short legs near bottom, tall vertical 4:9 portrait ratio,
         even margins, consistent crop across all expressions.
         Lower body and short legs IDENTICAL across all expressions — only the FACE and ARM pose change.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (SD 추가분 — 공통 네거티브에 더한다)

```
no realistic body proportions, no long thin legs, no adult tall figure,
no tiny face, no baby-only infantile style (keep her chic witch charm).
```

> 표정 6종은 **위 "표정 6종" 표를 그대로** 쓴다(베이스만 이 SD 프롬프트로 교체). 규격도 동일 — `dotify --preset okja`(128×288)로 후처리하면 머리 큰 SD가 캔버스 상단에 또렷하게 안착한다.
> 팁: SD는 눈이 큰 만큼 **표정 변화(눈 곡선·홍조·입모양)를 과장**해야 다마고치 크기에서 확 읽힌다.

---

## 옥자 지뢰계(★히어로) 의상 (이벤트 의상 1세트)

> 이벤트 데이 "지뢰계" 의상의 옥자. ★히어로 = 데모 5종 중 대표라 가장 공들인다(→ [asset-checklist.md](./asset-checklist.md) A2).
> **🔑 이건 체키 카드용 정적 아트다 — 표정 스왑 호환 불필요.** 이벤트 의상은 **교감화면에서 갈아입는 스킨이 아니라** 체키(정적 수집물)에만 들어간다(→ PRD §6·§9.1, 라이브 옥자는 마녀룩 고정). 그러니 idle 포즈·와인레드에 묶일 필요 없이 **레퍼런스 사진 그대로 카드답게 멋진 포즈·머리색**으로 뽑는다.
> **🔑 워크플로우**: 텍스트만으로 새로 뽑으면 옥자 얼굴이 흔들린다. **① 확정된 `okja_idle.png`(SD 도트 — 얼굴·정체성·등신비 락) + ② 지뢰계 레퍼런스 사진(의상·머리색·포즈 락) + ③ 신발 레퍼런스 사진(신발 락)** 세 장을 첨부하고 "1번 캐릭터를 2·3번 코디로 다시 그려라"로 요청한다(멀티 이미지 편집).
> **지뢰계 레퍼 코디**(첨부 사진): 레오파드 무늬 베레모 · 흰 시스루 시폰 블라우스(앞 리본 레이스업) · 검정 레이스 캐미솔 + 가슴 크로스 장식 · 연청 데님 미니 플리츠 · 십자가 목걸이 · 메탈하트/리본 벨트 체인 · **금발 트윈테일** · **갸루 포즈(고개 살짝 기울이고 한 손 얼굴 옆 손가락 펼침, 새침한 태도)** · **검정 통굽 플랫폼 크리퍼 스니커즈(별 장식 + 은색 체인) + 흰 슬라우치 양말**.

```
[Attach THREE images — 1: okja_idle.png (confirmed SD dot, identity lock),
 2: the jirai-kei outfit reference photo, 3: the shoes reference photo]

Keep image 1's character IDENTITY: same face shape, same eyes, same chic tsundere look,
same SD chibi proportions (head:body ≈ 1:3~1:4). RESTYLE her as the jirai-kei coordinate,
matching image 2 for outfit, HAIR and POSE, and image 3 for the shoes:
- Hair: BLONDE long TWIN-TAILS (NOT wine-red, NOT brown — bright blonde).
- Pose: a playful GYARU selfie pose — head tilted slightly, hip cocked to one side, sassy attitude,
        ONE hand raised up beside the face / temple with fingers spread (relaxed peace-ish gesture,
        like image 2), the other arm relaxed. NOT the clasped-hands idle pose.
- Headwear: a LEOPARD-PRINT beret / hunting cap.
- Top: white SHEER chiffon long-sleeve blouse with a front ribbon lace-up,
       over a BLACK LACE camisole, with a black CROSS ornament on the chest.
- Bottom: light-wash DENIM pleated mini skirt.
- Accessories: silver CROSS necklace, a metal-HEART & ribbon belt chain at the waist.
- Shoes: chunky BLACK PLATFORM creeper sneakers with STAR charms and a silver CHAIN,
         worn with WHITE SLOUCH socks (match image 3).
- Expression: calm, cool, mouth closed.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her chic tsundere charm; jirai-kei girly-grunge mood but still the SAME Okja.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom,
         tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (지뢰계 — 공통 네거티브에 더한다)

```
no realistic body proportions, no long thin legs, no adult tall figure, no tiny face,
no different face, no extra characters, no cropped feet, no hidden shoes,
no witch hat, no wine-red hair, no brown hair (this cut is BLONDE), no original burgundy witch dress
(it is fully replaced by the jirai-kei outfit),
no plain flat shoes, no over-sexualized outfit (keep it cute girly-grunge, age-safe brand).
```

> ⚠️ **검수 포인트**: 체키 카드 안에 들어갈 정적 아트이므로 idle 앵커 일치는 불필요. **얼굴(옥자 정체성) 일관성 + 신발까지 프레임 안에 다 들어왔는지**를 본다. 레오파드/데님/체인은 색이 튀니 후처리 **마스터 팔레트 인덱싱 필수**. 저장: `assets/sprites/okja_jirai.png`.
> 💡 신발 사진 첨부가 안 되면(2장만 지원), `Shoes:` 줄의 텍스트 묘사만으로도 충분하다 — 3번 이미지 참조 문구만 지운다.
> 📌 **나머지 4종 의상(유치원·힙합·집사·크리스마스)도 같은 방식** — 모두 체키 카드용 정적 아트라 포즈·머리색 자유. 이 프롬프트를 베이스로 의상·신발 레퍼런스만 갈아끼우면 된다.

---

## 체키 카드 (양면 — 런타임 합성) → ADR 0003

> **🃏 모델**: 체키는 더 이상 "구운 1장 PNG"가 아니다. **앞면(표지) + 뒷면(사진)을 런타임에 레이어 합성**해 만든다(→ ADR 0003). 닉네임·날짜가 동적이라 한 장으로 못 굽는다. 아래 아트들은 모두 **합성용 공용 조각**이며, 텍스트(닉네임·날짜)는 아트가 아니라 **갈무리 도트 폰트 런타임 렌더**다.
> **실물 레퍼런스**(나라카 체키): 바깥 표지 = 검정 잉크 **날개/나비 + 나라카 붓글씨** + 손글씨 헌사, 안쪽 = **폴라로이드 사진 + 손편지**. 우린 2면으로 압축 — **앞=표지(로고+닉네임), 뒤=사진**. (QR·손편지는 데모 보류)

### 앞면 표지 — 파치먼트 배경 (`frame_cover_bg`)

> 표지의 **바탕 1장**(공용). 그 위에 등급 엠블럼 + 나라카 워드마크 + 닉네임·날짜(갈무리)가 런타임 합성된다. 카드 `120×180` 꽉, 누끼 불필요(불투명 카드).

```
Pixel art / dot art of a blank vintage CARD COVER — aged KRAFT / SEPIA PARCHMENT, antique and worn,
with a ROUGH TORN, slightly CHARRED-BURNT dark edge all around (burnt vignette). NO text, NO emblem, NO character.
Tall vertical portrait, aspect ratio 120:180 (2:3), the parchment fills the whole card.
Leave the CENTER fairly EMPTY (an emblem and handwritten name are composited on later).
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique — aged tan/sepia kraft paper, ink black, charred brown edges, faint candle-warm tint.
Background: the parchment IS the image edge-to-edge (opaque card, no chroma needed).
```

### 앞면 표지 — 등급 엠블럼 2종 (`emblem_wing` 일반 · `emblem_butterfly` 나비)

> 등급을 표지에서 가르는 **핵심 변태(metamorphosis) 모티프**(→ ADR 0002·0003). **🔑 실물 나라카 로고 그대로**(레퍼런스 `assets/sprites/_src/naraka_logo_ref.png`): 비대칭 한 쌍 날개 — **왼쪽 깃털 완전날개 + 오른쪽 그을린·구멍난 탄날개(나방/나비)** + 붉은 잉크 스플래터. **일반 = 이 쌍날개 그대로**, **나비 = 그 쌍날개가 온전한 대칭 지옥풍 나비로 변태(탄날개 구멍이 아물어 나비가 됨) + 앤틱 골드**. 중복→나비 승급이 "탄날개가 나비로 부화"하는 그림으로 표지에서 문자 그대로 일어난다. **각각 단색 배경(크로마 그린)으로 받아 누끼** → 표지 위에 합성.

```
[일반 — emblem_wing] (= 실물 나라카 쌍날개 크레스트, 레퍼런스 첨부 권장)
Pixel art / dot art of the NARAKA twin-wing crest: a PAIR of ASYMMETRIC black-ink WINGS spread wide,
hand-painted SUMI-E brush look. The LEFT wing is a FEATHERED angel/bird wing (full, intact — "완전날개");
the RIGHT wing is a TATTERED MOTH / butterfly wing with BURNT HOLES and ragged charred edges ("탄날개"),
the two meeting at a thin center. A few sparse BLOOD-RED ink SPLATTER specks around it. NO text, NO body.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color: INK BLACK wings, charred dark brown on the tattered side, sparse blood-red splatter.
Background: FLAT SOLID chroma green (#00ff00), nothing else.

[나비 — emblem_butterfly] (= 쌍날개가 완전한 나비로 변태)
Pixel art / dot art of a HELL-THEMED BUTTERFLY, wings spread WIDE and fully OPEN, perfectly SYMMETRIC, front view —
the twin wings have COMPLETED their metamorphosis (both sides now whole butterfly wings, the burnt holes HEALED).
INK-BLACK wings with ANTIQUE-GOLD edge tracing and faint EMBER-RED veins, a tiny HEART or small SKULL on the body,
sparse blood-red splatter. NOT a cute spring butterfly — gothic / underworld.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique — ink black wings, antique-gold trim, ember-red accents.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

### 앞면 표지 — 나라카 붓글씨 워드마크 (`wordmark_naraka`)

> 표지 하단의 **핏빛 붓글씨 "나라카" 로고**(공용 1장). 크로마 그린 누끼.

```
Pixel art / dot art of the word "나라카" in rough BLOOD-RED BRUSH CALLIGRAPHY (Korean), dripping ink feel,
hand-painted, slightly uneven. NO other text, NO frame.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color: BLOOD RED / deep burgundy ink only.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

> 💡 **닉네임·날짜는 아트가 아니다** — 표지 중앙~하단에 갈무리 폰트로 `"○○ 님"` + 획득일을 런타임 렌더(손글씨 헌사 느낌). 박슥자가 이름을 적어 넣는 미세 비트(획득 팝업, → ADR 0003).
> 🦋 **QR은 보류** — 표지에 빈 레이어 자리만 남기고 데모엔 안 그린다(공유는 @나라카 워터마크만).

---

### 뒷면 사진 프레임 — 표준 (`frame_standard`, 일반체키 공용)

> 캐릭터 의상 아트(`okja_*` 등) 위에 얹는 **사진 면 테두리**(공용 1장). **로고·워드마크·QR은 전부 표지로 갔다** — 여기엔 없다. **크라프트 테두리 + 폴라로이드 붉은 드립만** 남겨 의상을 가리지 않는 깨끗한 쇼케이스.
> **🔑 워크플로우(누끼)**: AI는 투명창을 못 만든다. **가운데 사진 창을 크로마 그린(`#00ff00`) 단색으로** 깔게 하고, `dotify --chroma 00ff00`로 그 창만 뚫어 투명 슬롯을 만든다(여기로 의상 아트가 비친다). 양피지 테두리는 불투명.
> **🔑 규격(큰 폴라로이드)**: 카드 `120×180`, **얇은 균일 테두리 `~6px`** + 사진 창 **`~108×162`**(카드의 ~90% 차지). **별도 캡션 스트립 없음** — 데이 라벨("○○ 데이")은 **런타임에 사진 창 윗쪽에 오버레이**(실물 체키가 사진 위에 손글씨 적던 자리)라 아트엔 안 굽는다. **사진 창만** 크로마 그린, 테두리만 불투명 양피지.

```
Pixel art / dot art of an EMPTY vintage POLAROID-style photo (cheki) FRAME, front view, NO character, NO photo, NO logo, NO text.
This is an OVERLAY border: the inside is a hollow PHOTO WINDOW where the costume artwork is composited later.
Card: an aged KRAFT / SEPIA PARCHMENT card, antique and worn, with a ROUGH TORN, slightly CHARRED-BURNT dark edge
      all around the outer rim (burnt vignette). Tall vertical portrait, aspect ratio 120:180 (2:3), card fills the frame.
Photo window: ONE BIG empty rectangular window filling MOST of the card — a THIN even parchment border (~6px) on ALL
      four sides, the window occupying roughly 90% (about 108 wide × 162 tall).
      FLAT SOLID chroma green (#00ff00) and completely EMPTY. NO bottom caption strip.
      Along the TOP edge of the window, a thin BLOOD-RED paint DRIP / splatter (classic polaroid top edge).
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique — aged tan/sepia kraft paper, ink black, blood red, charred brown edges.
Composition: one BIG centered photo window with a thin even border + red drip along its top; the window stays PURE chroma green.
```

### 네거티브 (사진 프레임 — 공통 네거티브에 더한다)

```
no character, no person, no face, no cat, no photo or picture inside the window,
no scenery in the window (the center window MUST stay flat solid chroma green and empty),
no logo, no wing, no butterfly, no wordmark, no QR code, no clock, no numbers, no readable text,
no shiny foil, no holographic, no glossy reflections, no clean modern white border,
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render,
no rounded corners cut off, no off-center window, no asymmetry.
```

> ⚠️ **검수 포인트**: ① 사진 창이 **순수 크로마 그린 한 덩어리**(카드의 ~90%, ≈`108×162`)인지 ② **하단에 캡션 스트립이 없는지**(균일 ~6px 테두리만 — 데이 라벨은 런타임 오버레이라 아트엔 없음) ③ **로고·워드마크·QR이 안 들어갔는지**(표지로 갔다) ④ 양피지·붉은 드립이 마스터 팔레트(~32색)에 인덱싱되는지. 저장: `assets/sprites/frame_standard.png`.
> 💡 **이벤트 테마 프레임(나비체키)도 같은 골격** — 이 사진 프레임을 베이스로 **테두리 데코만 그 이벤트 테마로** 갈아끼운다(지뢰계=메탈하트·리본, 유치원=크레용·무지개, 힙합=그래피티·체인, 집사=은쟁반·장미, 크리스마스=눈·리스). 가운데 크로마 그린 창·규격은 **그대로 유지**.

### 뒷면 사진 프레임 — 지뢰계 테마 (`frame_jirai`, 나비체키용)

> 표준 프레임(`frame_standard`)과 **골격·규격·누끼 방식 동일** — 테두리 데코만 갈아끼운 변형. 사진 창은 여전히 **순수 크로마 그린**(배경은 `bg_cheki_jirai`가 별도 레이어로 책임지고, 의상 누끼가 그 위에 합성됨). **배경(시부야풍 네온 밤거리)과 같은 네온 야경 팔레트로 통일** — 양피지/세피아가 아니라 **네이비·블랙 베이스 + 네온 핑크·퍼플 튜브 글로우**. 밤거리 사진 위에 **네온 사인틀**을 두른 느낌이라 의상·배경과 한 세트로 붙는다(지뢰계 디테일=글로우 하트·별·리본·십자가·은 체인).
> **🔑 규격(표준과 동일)**: 카드 `120×180`, 얇은 균일 테두리 `~6px` + 사진 창 `~108×162`(카드의 ~90%). 사진 창만 크로마 그린, 테두리만 불투명. 캡션 스트립 없음(데이 라벨은 런타임 오버레이). 로고·워드마크·QR 없음(표지로 갔다).
> **🔑 글로우 도트 주의**: 네온 글로우는 **소프트 블러가 아니라 2~3단 계단형 플랫 픽셀 헤일로**로(→ ADR 0001 Nearest·노 그라데이션). 그라데이션·번짐 금지.

```
Pixel art / dot art of an EMPTY decorated POLAROID-style photo (cheki) FRAME, front view, NO character, NO photo, NO logo, NO text.
This is an OVERLAY border in JIRAI-KEI ("landmine girl") style, themed to MATCH a NEON NIGHT-CITY photo inside:
      the inside is a hollow PHOTO WINDOW where the costume artwork is composited later.
Card: a dark NAVY-BLACK card whose inner rim is a GLOWING NEON TUBE outline, gothic-cute and girly. Tall vertical portrait, aspect ratio 120:180 (2:3), card fills the frame.
Photo window: ONE BIG empty rectangular window filling MOST of the card — a THIN even decorated border (~6px) on ALL
      four sides, the window occupying roughly 90% (about 108 wide × 162 tall).
      FLAT SOLID chroma green (#00ff00) and completely EMPTY. NO bottom caption strip.
Border decoration (NEON JIRAI-KEI): the inner rim glows as a hot-pink & electric-purple NEON TUBE; small glowing NEON HEARTS and little STARS,
      black & pink RIBBON BOWS at the corners, tiny silver CROSS charms, a thin silver CHAIN run along the edges.
      Along the TOP edge of the window, a thin PINK-RED neon DRIP / splatter (classic polaroid top edge).
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading;
      neon glow rendered as 2-3 STEPPED flat pixel halos, NOT a soft blur.
Color mood: neon jirai-kei night — navy/black base, hot pink, magenta, electric purple, a touch of cyan, silver chain, blood-red accents.
Composition: one BIG centered photo window framed by a glowing neon tube + symmetric corner ribbons; the window stays PURE chroma green.
```

#### 네거티브 (지뢰계 프레임 — 공통 네거티브에 더한다)

```
no character, no person, no face, no cat, no photo or picture inside the window,
no scenery in the window (the center window MUST stay flat solid chroma green and empty),
no logo, no wing, no butterfly, no wordmark, no QR code, no clock, no numbers, no readable text,
no kraft/sepia parchment look (this frame is NAVY-BLACK with NEON, not aged paper),
no soft glow blur (neon glow must be stepped flat pixels), no holographic, no glossy reflections,
no smooth gradient, no soft anti-aliased edges, no 3D render,
no rounded corners cut off, no off-center window, no asymmetry.
```

> ⚠️ **검수 포인트**: ① 사진 창이 **순수 크로마 그린 한 덩어리**(표준과 같은 `~108×162`)인지 ② 테두리가 **네온 야경 톤**(네이비·블랙 + 네온 핑크·퍼플 튜브 글로우 + 글로우 하트·별·리본·십자가·체인)이라 **배경 밤거리와 한 세트**로 붙는지 — 세피아 양피지로 새지 않았는지 ③ 글로우가 **소프트 블러가 아니라 계단형 플랫 도트**인지 ④ 로고·QR·캡션 스트립이 없는지 ⑤ 마스터 팔레트(~32색) 인덱싱. 저장: `assets/sprites/frame_jirai.png`.

### 체키 사진 배경 — 지뢰계 (`bg_cheki_jirai`, 의상 종속 레이어)

> **왜 별도 레이어인가**: 옥자 의상 아트(`okja_jirai`)는 **누끼(투명 배경)** 라 사진 창에 그대로 얹으면 뒤가 빈다. 그래서 사진 면은 `[배경 레이어] + [의상 누끼] + [사진 프레임 테두리]` **3겹 합성**(→ ADR 0003)이고, 이 배경은 **의상(이벤트)에 종속** — 지뢰계 옥자 뒤엔 지뢰계 풍경. 등급이 프레임을 표준↔테마로 스왑해도 배경은 항상 유지된다.
> **🔑 무드(풍경)**: 평면 패턴 벽이 아니라 **실제 장소감 있는 풍경** — 지뢰계 정체성에 맞는 **시부야풍 네온 밤거리**. 캐릭터가 "그 앞에서 찍은 스냅샷"처럼 보여야 해서, **중앙은 흐릿한 보케/심플**(누끼 옥자 상반신이 그 앞에 서니 가독성 확보)하고 네온사인·간판 디테일은 위·옆으로 민다.
> **🔑 규격**: **카드 풀사이즈 `120×180` 불투명**(누끼 X, 크로마 X). 프레임 테두리(불투명)가 바깥을 덮으니 실제로 보이는 건 사진 창(`~108×162`) 영역. 네온 글로우로 가장자리를 채우되 중앙 하단(옥자 발치)은 비교적 비운다.

```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a JIRAI-KEI ("landmine girl") girl's NIGHT CITY street, Shibuya/Harajuku vibe.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a neon-lit night street at the top and sides — glowing PINK and PURPLE NEON SIGNS and shop signboards (abstract glyph-like glow, NOT real letters),
      tall city buildings receding into the dark, a couple of STREET LAMPS, soft round BOKEH light orbs floating in the air;
      a WET sidewalk / asphalt at the bottom catching pink-purple neon REFLECTIONS.
Depth: detailed glowing signs along the TOP and the two SIDE edges; the CENTER is a softer, blurrier BOKEH haze of city lights so a standing character reads clearly;
      the LOWER-CENTER (character's feet area) stays calmer, just wet-ground reflection.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh done as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: jirai-kei night — deep navy/black sky, hot pink, magenta, electric purple, a touch of cyan and warm lamp amber.
```

#### 네거티브 (지뢰계 배경 — 공통 네거티브에 더한다)

```
no character, no person, no face, no cat, no hands,
no photo frame, no card border, no polaroid edge (the frame is a separate layer),
no readable text, no real words, no legible signage, no logo, no QR code, no watermark,
no chroma green, no transparency, no empty/hollow window (this layer is FULLY OPAQUE),
no flat repeating pattern wall, no argyle, no polka-dot wallpaper (this is a SCENE, not a pattern),
no busy/cluttered center, no large object in the middle blocking the character,
no smooth gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① **완전 불투명**인지(투명·크로마 그린이 한 픽셀도 없어야 — 누끼 옥자를 받쳐야 함) ② **풍경(장소감)**인지 — 평면 패턴 벽으로 새지 않았는지 ③ **중앙(특히 하단 발치)이 비교적 비어** 캐릭터가 읽히는지 ④ 간판 글자가 **읽히는 실제 글자가 아닌** 추상 네온인지(저작권·가독 방해 회피) ⑤ 네온 핑크/퍼플 야경이 마스터 팔레트(~32색)에 인덱싱되는지. 저장: `assets/sprites/bg_cheki_jirai.png`.
> 💡 **다른 의상도 같은 풍경 레이어** — 유치원=햇살 놀이터, 힙합=그래피티 골목/도시, 집사=앤틱 저택 홀, 크리스마스=눈 내리는 거리로 **장소만 갈아끼운다**(규격 `120×180` 불투명·중앙 비움·도트 보케 동일).

---

## A4·A5 — 의상·프레임·배경 확장 (유치원·힙합·집사·크리스마스) → ROADMAP 아트트랙

> 지뢰계(★히어로)에서 확립한 3종 레이어(**의상 누끼 + 테마 프레임 + 사진 배경**)를 **나머지 4개 이벤트로 복제**한다. 골격·규격·워크플로우는 위 지뢰계 섹션과 **완전히 동일** — 아래는 "무엇만 갈아끼우는지"만 적는다. 파일명 접미사는 `data/events.gd`의 **slug**(유치원=`kinder` · 힙합=`hiphop` · 집사=`butler` · 크리스마스=`xmas`)를 따른다.
> **🔑 공통 규칙(재확인)**: ① 의상은 모두 **체키 카드용 정적 아트** — idle 앵커 일치 불필요, 포즈·머리색 자유(라이브 옥자는 마녀룩 고정). ② 의상 캔버스는 **`128×288`(preset okja)**, 머리 위는 비우고 발끝까지 프레임 안. ③ 프레임은 표준/지뢰계 골격 그대로, **가운데 사진 창은 순수 크로마 그린 `~108×162`** 유지(테두리 데코만 교체). ④ 배경은 **`120×180` 완전 불투명**(누끼 X·크로마 X), 중앙·하단 발치 비움. ⑤ 전부 마스터 팔레트(~32색) 인덱싱.
> **⚠️ 크리스마스만 크로마키 예외**: 산타 의상·홀리에 **초록이 들어가므로 크로마 그린 대신 마젠타 `#ff00ff`** 로 받는다(→ 핵심 원칙 #2). 프레임·배경도 초록 데코가 있으면 마젠타로.

### A4-의상 ① 유치원 (`okja_kinder`)

> 레퍼 코디: 노란 **버킷햇** · **하늘색 카라 셔츠**(가슴 빨강 **명찰**) · 흰 **주름 스커트** · 흰 무릎양말 + 흰 신발 · **펭귄(핑구) 인형 백팩** · 보라 곱창밴드 트윈테일 · 빨강 손목밴드. 천진난만·해맑게.

```
[Attach TWO images — 1: okja_idle.png (confirmed SD dot, identity lock), 2: a kindergarten / preschool uniform reference photo]
Keep image 1's character IDENTITY: same face shape, same eyes, same chic tsundere look,
same SD chibi proportions (head:body ≈ 1:3~1:4). RESTYLE her as a cute KINDERGARTEN pupil coordinate (image 2):
- Hair: low TWIN-TAILS tied with PURPLE scrunchies, bright and youthful — NOT the witch look.
- Pose: innocent and childlike — one fist rubbing an eye (sleepy / about-to-cry cute gesture), or both hands held happily.
- Headwear: a YELLOW bucket hat.
- Top: a LIGHT-BLUE (sky blue) collared smock shirt, with a small round RED NAME TAG / badge on the chest.
- Bottom: a short WHITE PLEATED skirt.
- Accessory: a cute PENGUIN (Pingu-style) plush BACKPACK on her back with orange straps; a RED WRISTBAND.
- Shoes: WHITE knee socks and small WHITE sneakers.
- Expression: bright innocent face, slightly pouty / teary-cute.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her recognizable as the SAME Okja, just dressed as a sweet kindergartener.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom, tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no witch hat, no witch dress (fully replaced), no yellow suspender shorts (top is light-blue shirt, bottom is white skirt), no over-mature outfit (keep it childlike & age-safe), no different face, no cropped feet.`

### A4-의상 ② 힙합 (`okja_hiphop`)

> 레퍼 코디: 오버핏 **흑+실버 컬러블록 풋볼 저지**(올드잉글리시 블랙레터 레터링) + 안에 검정 티 레이어드 · 차콜 **니트 비니**(고딕 자수) · **실버 체인** · 빨강 손목시계 · 손가락 힙합 제스처. 고스 스트릿 무드.

```
[Attach TWO images — 1: okja_idle.png (identity lock), 2: a streetwear / hip-hop outfit reference photo]
Keep image 1's character IDENTITY: same face, same chic tsundere look, same SD chibi proportions (1:3~1:4).
RESTYLE her as a GOTH-STREET / HIP-HOP coordinate (image 2):
- Hair: long straight ASH-SILVER hair with blunt bangs and GREEN dip-dyed tips, plus one thin braided strand — cool and edgy.
- Pose: a confident HIP-HOP gesture — one hand throwing a relaxed finger sign near the face, swagger attitude.
- Top: an OVERSIZED football-style JERSEY in BLACK & SILVER color-block with OLD-ENGLISH / blackletter lettering, layered over a black tee, baggy fit.
- Headwear: a slouchy CHARCOAL KNIT BEANIE with small gothic embroidery (NOT a snapback).
- Bottom: BAGGY wide pants.
- Accessories: a thin SILVER CHAIN necklace, a RED wristwatch.
- Shoes: chunky sneakers.
- Expression: cool and chic, pale makeup, slight smirk.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her clearly the SAME Okja, urban goth-street mood.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom, tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no witch hat, no witch dress (fully replaced), no snapback cap (it's a knit beanie), no gold chain (use silver), no different face, no cropped feet, no over-sexualized outfit (keep it cool & age-safe).`

### A4-의상 ③ 집사 (`okja_butler`)

> 레퍼 코디: 검정 **와이드브림 페도라** · 검정 **수트 재킷/롱코트** · 흰 셔츠 + **검정 넥타이** · **검정 장갑** · 얇은 **안경** · **십자가 펜던트 체인** · 한 손 턱에 괸 시크 포즈. 다크 고딕·음울한 기품.

```
[Attach TWO images — 1: okja_idle.png (identity lock), 2: a butler / tuxedo outfit reference photo]
Keep image 1's character IDENTITY: same face, same chic tsundere look, same SD chibi proportions (1:3~1:4).
RESTYLE her as a DARK GOTHIC BUTLER coordinate (image 2):
- Hair: free choice but NEAT and tidy, dark.
- Pose: a chic brooding stance — one BLACK-gloved hand resting on the chin, the other tucked, composed and aloof.
- Headwear: a black WIDE-BRIM FEDORA hat.
- Outfit: a black tailored SUIT JACKET / long coat over a white dress shirt with a black NECKTIE.
- Accessories: BLACK GLOVES on both hands, thin GLASSES, a silver CROSS PENDANT on a chain.
- Shoes: polished black formal shoes.
- Expression: calm, cool and dignified, faint aloof look (chic, moody).
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her clearly the SAME Okja, classy and prim, dark gothic mood.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom, tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no witch hat (it's a fedora), no witch dress (fully replaced), no maid skirt, no tailcoat tails (it's a suit jacket), no white gloves (use black), no bow tie (use a necktie), no different face, no cropped feet.`

### A5-의상 ④ 크리스마스 (`okja_xmas`)

> 레퍼 코디: 빨강 **산타 드레스** + 흰 **퍼 트림** · 그 위에 **초록 후드 케이프/망토**(흰 퍼 + 금색 땡땡이·별 = 크리스마스 트리 모티프, 후드 착용) · 볼 빨강 **X·하트** 데코 · 빨강 부츠. ⚠️ **크로마키 = 마젠타 `#ff00ff`**(초록 케이프/배경 대비).

```
[Attach TWO images — 1: okja_idle.png (identity lock), 2: a cute Santa / Christmas dress reference photo]
Keep image 1's character IDENTITY: same face, same chic tsundere look, same SD chibi proportions (1:3~1:4).
RESTYLE her as a cozy CHRISTMAS / Santa coordinate (image 2):
- Hair: free choice, festive and cute, bangs.
- Pose: warm and inviting — both hands holding the hood by the cheeks, or one hand by the cheek; gentle festive cheer.
- Outfit: a RED SANTA DRESS trimmed with WHITE FUR (cuffs, hem, collar).
- Outerwear: a GREEN HOODED CAPE / cloak with WHITE FUR trim, decorated with GOLD polka-dots and little STAR ornaments (Christmas-tree motif), the HOOD worn up over her head.
- Headwear: the green hood up (instead of a santa hat).
- Accessories: small star ornaments; a tiny red X mark and a heart drawn cutely on one cheek.
- Shoes: short RED BOOTS with white fur.
- Expression: warm cute smile.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her clearly the SAME Okja, cozy Christmas mood, age-safe.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom, tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma MAGENTA (#ff00ff), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no witch hat, no witch dress (fully replaced), no chroma green anywhere (use MAGENTA bg — the cape is green), no different face, no cropped feet.`

> 💡 시온이 루돌프(`photo_sion_xmas`, 배경 포함 베이크)는 아래 **"시온이 체키 사진" 섹션**에 프롬프트가 있다(A5에서 같이 뽑는다).

---

### A4·A5-프레임 — 테마 사진 프레임 4종

> **베이스 = 위 "뒷면 사진 프레임 — 지뢰계" 프롬프트.** 골격·규격(`120×180`, 균일 ~6px 테두리 + 사진 창 `~108×162` 순수 크로마 그린, 캡션 스트립 없음, 로고/QR 없음)·네거티브 **전부 그대로** 두고, **테두리 데코 + 색 무드만** 아래로 교체한다. 각 프레임의 색은 **짝이 되는 배경(`bg_cheki_*`)과 같은 팔레트**로 통일해 한 세트로 붙게 한다.

| 파일명 | `Border decoration` 교체 문구 | `Color mood` 교체 문구 |
|---|---|---|
| `frame_kinder` (유치원) | the inner rim is drawn in chunky CRAYON strokes; small RAINBOW arcs, toy BLOCKS, a star sticker and a round NAME-TAG badge at the corners; a wavy crayon line along the top edge. | bright primary crayon — sunny yellow, sky blue, grass green, candy red, white. |
| `frame_hiphop` (힙합) | the inner rim is a spray-paint GRAFFITI outline; a silver CHAIN runs along the edges, a small BOOMBOX and a sneaker doodle at the corners, drips of paint along the top edge. | urban street — concrete gray, black, electric green & magenta spray, gold chain accents. |
| `frame_butler` (집사) | the inner rim is an ornate ANTIQUE gilt PICTURE-FRAME molding; a silver SERVING TRAY motif and red ROSES at the corners, a thin lace doily edge along the top. | refined antique — deep wine, antique gold, silver tray sheen, ivory lace, rose red. |
| `frame_xmas` (크리스마스) ⚠️마젠타 | the inner rim is a green HOLLY & RED-BERRY WREATH; SNOW piled on the top edge, small ORNAMENT baubles and a bow at the corners, tiny candy canes. | warm Christmas — pine green, holly red, snow white, gold ornament, against a soft night blue. |

> ⚠️ `frame_xmas`는 초록 홀리가 들어가니 **크로마키를 마젠타 `#ff00ff`** 로(프롬프트의 `chroma green (#00ff00)` → `chroma magenta (#ff00ff)` 로 치환, 단 **사진 창은 여전히 크로마**로 비워야 하므로 창도 마젠타). 나머지 3종은 크로마 그린 그대로.

#### 전체 프롬프트 4종 (바로 복붙)

> 골격·규격·`#### 네거티브`·검수 포인트는 **위 "뒷면 사진 프레임 — 지뢰계"와 동일**. 아래는 카드 베이스색·`Border decoration`·`Color mood`만 그 이벤트로 바꾼 완성본이다. 사진 창은 **순수 크로마 그린(`#00ff00`)** 유지(크리스마스만 마젠타 `#ff00ff`). 저장 경로는 각 `frame_*.png`.

**`frame_kinder` (유치원)**
```
Pixel art / dot art of an EMPTY decorated POLAROID-style photo (cheki) FRAME, front view, NO character, NO photo, NO logo, NO text.
This is an OVERLAY border in a cute KINDERGARTEN / crayon style, themed to MATCH a sunny playground photo inside:
      the inside is a hollow PHOTO WINDOW where the costume artwork is composited later.
Card: a bright cream-white card whose inner rim is drawn in chunky CRAYON strokes, childlike and playful. Tall vertical portrait, aspect ratio 120:180 (2:3), card fills the frame.
Photo window: ONE BIG empty rectangular window filling MOST of the card — a THIN even decorated border (~6px) on ALL
      four sides, the window occupying roughly 90% (about 108 wide × 162 tall).
      FLAT SOLID chroma green (#00ff00) and completely EMPTY. NO bottom caption strip.
Border decoration (KINDERGARTEN crayon): the inner rim is drawn in chunky CRAYON strokes; small RAINBOW arcs, toy BLOCKS,
      a star sticker and a round NAME-TAG badge at the corners; a wavy crayon line along the TOP edge.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading.
Color mood: bright primary crayon — sunny yellow, sky blue, grass green, candy red, white.
Composition: one BIG centered photo window framed by crayon strokes + symmetric corner stickers; the window stays PURE chroma green.
```

**`frame_hiphop` (힙합)**
```
Pixel art / dot art of an EMPTY decorated POLAROID-style photo (cheki) FRAME, front view, NO character, NO photo, NO logo, NO text.
This is an OVERLAY border in a STREET / GRAFFITI style, themed to MATCH a graffiti-alley photo inside:
      the inside is a hollow PHOTO WINDOW where the costume artwork is composited later.
Card: a concrete-gray & black card whose inner rim is a spray-paint GRAFFITI outline, urban and edgy. Tall vertical portrait, aspect ratio 120:180 (2:3), card fills the frame.
Photo window: ONE BIG empty rectangular window filling MOST of the card — a THIN even decorated border (~6px) on ALL
      four sides, the window occupying roughly 90% (about 108 wide × 162 tall).
      FLAT SOLID chroma green (#00ff00) and completely EMPTY. NO bottom caption strip.
Border decoration (GRAFFITI): the inner rim is a spray-paint GRAFFITI outline; a silver CHAIN runs along the edges,
      a small BOOMBOX and a sneaker doodle at the corners, drips of paint along the TOP edge.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading.
Color mood: urban street — concrete gray, black, magenta & teal-LIME spray (keep the lime a teal tone, NOT pure #00ff00), silver chain accents.
Composition: one BIG centered photo window framed by a graffiti outline + symmetric corner doodles; the window stays PURE chroma green.
```

**`frame_butler` (집사)**
```
Pixel art / dot art of an EMPTY decorated POLAROID-style photo (cheki) FRAME, front view, NO character, NO photo, NO logo, NO text.
This is an OVERLAY border in an ANTIQUE / aristocratic style, themed to MATCH an antique mansion-hall photo inside:
      the inside is a hollow PHOTO WINDOW where the costume artwork is composited later.
Card: a deep-wine card whose inner rim is an ornate ANTIQUE gilt PICTURE-FRAME molding, refined and stately. Tall vertical portrait, aspect ratio 120:180 (2:3), card fills the frame.
Photo window: ONE BIG empty rectangular window filling MOST of the card — a THIN even decorated border (~6px) on ALL
      four sides, the window occupying roughly 90% (about 108 wide × 162 tall).
      FLAT SOLID chroma green (#00ff00) and completely EMPTY. NO bottom caption strip.
Border decoration (ANTIQUE): the inner rim is an ornate ANTIQUE gilt PICTURE-FRAME molding; a silver SERVING TRAY motif
      and red ROSES at the corners, a thin lace doily edge along the TOP.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading.
Color mood: refined antique — deep wine, antique gold, silver tray sheen, ivory lace, rose red.
Composition: one BIG centered photo window framed by gilt molding + symmetric corner roses; the window stays PURE chroma green.
```

**`frame_xmas` (크리스마스)** ⚠️ 창·키잉 = 마젠타 `#ff00ff` (테두리에 초록 홀리)
```
Pixel art / dot art of an EMPTY decorated POLAROID-style photo (cheki) FRAME, front view, NO character, NO photo, NO logo, NO text.
This is an OVERLAY border in a CHRISTMAS / wreath style, themed to MATCH a snowy-night photo inside:
      the inside is a hollow PHOTO WINDOW where the costume artwork is composited later.
Card: a soft night-blue card whose inner rim is a green HOLLY & RED-BERRY WREATH, warm and festive. Tall vertical portrait, aspect ratio 120:180 (2:3), card fills the frame.
Photo window: ONE BIG empty rectangular window filling MOST of the card — a THIN even decorated border (~6px) on ALL
      four sides, the window occupying roughly 90% (about 108 wide × 162 tall).
      FLAT SOLID chroma MAGENTA (#ff00ff) and completely EMPTY. NO bottom caption strip.
Border decoration (CHRISTMAS): the inner rim is a green HOLLY & RED-BERRY WREATH; SNOW piled on the TOP edge,
      small ORNAMENT baubles and a bow at the corners, tiny candy canes.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading.
Color mood: warm Christmas — pine green, holly red, snow white, gold ornament, against a soft night blue.
Composition: one BIG centered photo window framed by a holly wreath + symmetric corner baubles; the window stays PURE chroma magenta. NO pure chroma green anywhere (the holly is darker pine green, the window key is MAGENTA).
```

---

### A4·A5-배경 — 체키 사진 배경 4종

> **베이스 = 위 "체키 사진 배경 — 지뢰계" 프롬프트.** 규격(`120×180` **완전 불투명**, 누끼 X·크로마 X, 중앙·하단 발치 비움, 도트 보케) 그대로 두고 **장소(Scene)만** 아래로 교체. 짝 프레임과 같은 팔레트.

| 파일명 | `Scene` 교체 문구 | `Color mood` 교체 문구 |
|---|---|---|
| `bg_cheki_kinder` (유치원) | a sunny KINDERGARTEN PLAYGROUND — colorful slide & swings in the back, a rainbow arch, fluffy clouds, soft grass; the LOWER-CENTER (feet area) kept open. | bright sunny day — sky blue, sunny yellow, grass green, candy-colored equipment. |
| `bg_cheki_hiphop` (힙합) | a GRAFFITI ALLEY / city street at dusk — colorful spray-paint murals on the back wall (abstract glyphs, NOT real letters), a chain-link fence, a couple of street lamps; lower-center open. | urban dusk — concrete gray, brick, vivid spray-paint green/magenta/blue, warm lamp amber. |
| `bg_cheki_butler` (집사) | an ANTIQUE MANSION HALL — a grand staircase and chandelier in the back (softly blurred), tall arched windows, a red carpet; lower-center open. | refined antique — deep wine walls, antique gold, warm candle glow, ivory marble. |
| `bg_cheki_xmas` (크리스마스) | a SNOWY night STREET — gently falling snow, a glowing Christmas tree and warm shop windows in the back (soft bokeh), string lights; lower-center open. | cozy Christmas night — deep night blue, snow white, warm window amber, pine green, holly red. |

> ⚠️ 배경은 **완전 불투명**이라 원래도 크로마가 없다 — 크리스마스 배경도 마젠타 걱정 없이 그대로 `--size 120x180`(아래 후처리)로 뽑으면 된다.

#### 전체 프롬프트 4종 (바로 복붙)

> 골격·`#### 네거티브`·검수 포인트는 **위 "체키 사진 배경 — 지뢰계"와 동일**. 아래는 `Scene`/`Depth`/`Color mood`만 그 이벤트로 바꾼 완성본이다. 저장 경로는 각 `bg_cheki_*.png`.

**`bg_cheki_kinder` (유치원)**
```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a sunny KINDERGARTEN PLAYGROUND.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a cheerful playground — a colorful SLIDE and SWINGS in the back, a big RAINBOW arch, fluffy white CLOUDS in a blue sky,
      soft green GRASS and a few round bushes; candy-colored play equipment along the top and sides.
Depth: detailed playground equipment along the TOP and the two SIDE edges; the CENTER is a softer, blurrier BOKEH haze of sky and clouds so a standing character reads clearly;
      the LOWER-CENTER (character's feet area) stays calmer, just soft grass.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh done as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: bright sunny day — sky blue, sunny yellow, grass green, candy red, white.
```

**`bg_cheki_hiphop` (힙합)**
```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a GRAFFITI ALLEY / city street at dusk.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a back alley at dusk — colorful spray-paint GRAFFITI murals on the back wall (abstract glyph-like shapes, NOT real letters),
      a CHAIN-LINK fence, a couple of STREET LAMPS, some pipes and a dumpster silhouette; soft round BOKEH light orbs in the air.
Depth: detailed graffiti and lamps along the TOP and the two SIDE edges; the CENTER is a softer, blurrier BOKEH haze of dusk light so a standing character reads clearly;
      the LOWER-CENTER (character's feet area) stays calmer, just wet asphalt reflection.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh done as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: urban dusk — concrete gray, brick red, vivid spray-paint green / magenta / blue, warm lamp amber.
```

**`bg_cheki_butler` (집사)**
```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — an ANTIQUE MANSION HALL.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a grand mansion interior — a sweeping STAIRCASE and a crystal CHANDELIER in the back (softly blurred), tall arched WINDOWS with drapes,
      ornate gilt wall molding, a deep red CARPET; soft round BOKEH of warm candle light.
Depth: detailed chandelier, windows and molding along the TOP and the two SIDE edges; the CENTER is a softer, blurrier BOKEH haze of warm light so a standing character reads clearly;
      the LOWER-CENTER (character's feet area) stays calmer, just red carpet.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh done as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: refined antique — deep wine walls, antique gold, warm candle glow, ivory marble.
```

**`bg_cheki_xmas` (크리스마스)**
```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a SNOWY NIGHT STREET.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a cozy snowy street at night — gently falling SNOW, a glowing CHRISTMAS TREE and warm lit SHOP WINDOWS in the back (soft bokeh),
      STRING LIGHTS strung overhead, a streetlamp, snow piled on rooftops; soft round BOKEH light orbs in the air.
Depth: detailed tree, string lights and shop windows along the TOP and the two SIDE edges; the CENTER is a softer, blurrier BOKEH haze of warm lights and snow so a standing character reads clearly;
      the LOWER-CENTER (character's feet area) stays calmer, just snow-covered ground.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh done as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency (the pine-green tree is opaque art, NOT a chroma key).
Color mood: cozy Christmas night — deep night blue, snow white, warm window amber, pine green, holly red.
```

---

## 시온이 (펫 — 교감화면)

> 옥자의 흰 얼룩 고양이. **교감화면 라이브 펫은 항상 기본 흰 고양이**(이벤트 의상은 체키 전용 → 아래 "시온이 체키 의상").
> **🔑 실물 레퍼런스 첨부 필수**: `assets/sprites/_src/sion_ref.png`(시온이 실물, = IMG_0171)를 첨부해 **img2img(사진 변환)** 으로 뽑는다 — **아주 뚱뚱·동글동글한 공 같은 체형**과 **비대칭 얼굴 얼룩**이 정체성이라 텍스트만으론 매번 흔들린다.
> **얼룩(고정)**: 바탕 흰색 · **검은색이 메인 얼룩** — 몸·꼬리, 그리고 머리/얼굴은 **가운데 흰 줄로 갈린(가르마) 대칭 검은 두건** · **작은 핑크 코에 갈색 점 하나**(갈색은 코에만 — 얼굴 전체로 번지면 안 됨).
> **규격**: `48×48`(preset `sioni`). 48px는 AI가 직접 못 그리니 **크게 받아 `dotify --preset sioni`로 축소** — 동글고 단순한 실루엣으로(작아도 읽히게).

```
[Attach: assets/sprites/_src/sion_ref.png — Sioni's real reference photo (= IMG_0171)]
Convert the attached cat into a CUTE retro pixel art / dot art chibi sprite, front view, sitting. Subject: "Sioni", Okja's pet cat.
Body: VERY CHUBBY and ROUND — a fat, plump, BALL-SHAPED body with short stubby legs, exaggerated roundness (like the photo).
      Big round eyes, small pink nose, tiny mouth, cozy and friendly.
Fur & MARKINGS (keep EXACT): base coat MOSTLY WHITE.
      - BLACK is the MAIN marking color, on the BODY, TAIL and HEAD/FACE. On the head it looks like a
        CENTER HAIR-PARTING ("gareuma"): a BLACK CAP over the top of the head and ears, SPLIT down the
        middle by a WHITE center stripe / blaze, roughly SYMMETRIC. Some black on the back and tail too.
      - The small PINK NOSE has ONE tiny BROWN mark on it. Brown appears ONLY as this small nose mark —
        NOT a large face patch, NOT covering the eyes, ears or cheeks.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: white fur, BLACK markings (main, center-parted head + tail), a tiny BROWN nose mark, pink nose, against the cafe's dark antique palette.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

### 네거티브 (시온이)

```
no human, no person, no character besides the cat, no clothes (this is the BASE plain cat),
no slim / thin / athletic cat (she must look VERY FAT and round), no long legs,
no large BROWN face patch (brown is ONLY a tiny mark on the pink nose), no brown over the eyes / ears / cheeks,
no all-white head (keep the BLACK center-parted head cap + tail), no missing nose mark,
no text, no watermark, no scenery, no chroma green on the cat,
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render.
```

### 반응 4종 — 베이스에 한 줄만 추가 (얼굴·자세만 변경)

| 파일명 | 추가 문구 |
|---|---|
| `sioni_idle`  | `Pose: sitting calmly, tail curled around the feet, content.` |
| `sioni_snack` | `Pose: looking UP happily at a treat, mouth open, eager.` |
| `sioni_play`  | `Pose: playful pounce, front paws up, ears perked.` |
| `sioni_pet`   | `Pose: eyes closed, blissful, head tilted as if being petted.` |

> 팁: idle 1장을 확정한 뒤 그 결과를 레퍼런스로 첨부해 나머지 3종을 뽑으면 흰 얼룩 패턴·체형이 일관된다.

---

## 시온이 체키 의상 (쿠로미풍 · 루돌프) → 체키 카드용 정적 아트

> 시온이도 **수집 캐릭터** — 지뢰계·크리스마스 데이 체키가 있다(→ PRD §9.1). 옥자 이벤트 의상과 같은 원리로 **체키(정적 수집물)에만** 들어가고, 교감화면 라이브 시온이는 기본 흰 고양이 고정.
> **🔑 규격(중요·베이크 전환됨)**: 시온이 체키는 **배경 포함 베이크 사진** — 사진 면을 `[배경]+[누끼]+[프레임]` 3겹으로 합성하지 않고, **고양이 전신 + 풍경을 한 장으로 굽는다**(→ 커밋 `시온이 지뢰계 체키를 배경 포함 베이크 사진으로 전환`). `cheki_card.gd`는 `photo_{char}_{slug}.png`(= `cheki_photo_path`)가 있으면 그걸 사진 면으로 쓰고, 없으면 3겹 폴백. 그래서 파일명은 **`photo_sion_jirai` / `photo_sion_xmas`** (← 의상 누끼 `sion_*`·펫 반응 `sioni_*`와 접두어 다름 주의).
> **🔑 캔버스**: 카드 사진 창 비율에 맞춰 **`120×180`(2:3) 완전 불투명**(누끼 X·크로마 X). 고양이 **전신이 잘리지 않게** 화면 안에 두고, 발치(하단 중앙)는 비교적 비워 캐릭터가 읽히게, 풍경 디테일은 위·옆으로 민다(짝 배경 `bg_cheki_*`와 같은 장소·팔레트).
> **🔑 워크플로우**: 확정된 `sioni_idle`(정체성 락) + 의상 레퍼런스(+선택: 풍경 레퍼)를 첨부해 "이 고양이에게 이 코디를 입혀 **이 풍경 앞에서 찍은 한 장**으로".

### 지뢰계 (`photo_sion_jirai`, 쿠로미풍 + 네온 밤거리)

> 산리오 쿠로미를 **직접 베끼지 말고**(IP 회피) 그 *분위기*만 — 검정 후드 망토 + 분홍 해골 + 광대 칼라 + 작은 악마 꼬리의 지뢰계풍 고양이가 **시부야풍 네온 밤거리** 앞에 선 한 장.

```
[Attach: 1 = sioni_idle.png (confirmed cat, identity lock), 2 = jirai-kei / punk-goth pet outfit reference]
ONE baked PHOTO (cheki snapshot): a JIRAI-KEI costumed cat standing in front of a NEON NIGHT-CITY street. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's CAT identity: the SAME VERY CHUBBY round white cat with her EXACT markings
(BLACK center-parted cap on the head + black on tail/body; ONE tiny BROWN mark on the small pink nose only — no large brown face patch), same face.
Costume — dress it in a JIRAI-KEI / punk-goth outfit:
- a BLACK hooded cape / hood with little devil-ear points, a PINK SKULL emblem on the hood,
- a small jester-style frilled collar, pink & black ribbon accents, a tiny curled DEVIL TAIL.
  Cute gothic, age-safe. Clearly the SAME cat, just costumed.
Background (baked in): a Shibuya-style NEON night street — glowing PINK & PURPLE neon signs (abstract glyph-like glow, NOT real letters),
  buildings receding into the dark, soft round BOKEH orbs; detailed along the TOP and SIDES, a softer bokeh haze in the CENTER, calm wet-ground reflection at the bottom.
Composition: the FULL cat (whole body, NOT cropped) sits in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & neon glow as clusters of flat stepped pixels.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: jirai-kei night — black & hot-pink costume over white fur, deep navy/black street, hot pink, magenta, electric purple, a touch of cyan.
```

### 크리스마스 (`photo_sion_xmas`, 루돌프 + 눈 내리는 밤거리)

```
[Attach: 1 = sioni_idle.png (identity lock), 2 = reindeer / Rudolph costume reference (optional)]
ONE baked PHOTO (cheki snapshot): a cute RUDOLPH reindeer cat standing in front of a SNOWY night street. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's CAT identity: the SAME VERY CHUBBY round white cat with her EXACT markings
(BLACK center-parted cap on the head + black on tail/body; ONE tiny BROWN mark on the small pink nose only — no large brown face patch).
Costume — dress it as a cute RUDOLPH reindeer:
- small brown ANTLERS headband, a glowing RED NOSE, a green/red HOLLY collar with a jingle bell,
- optional tiny red cape. Cozy Christmas, age-safe. Clearly the SAME cat.
Background (baked in): a cozy SNOWY night street — gently falling SNOW, a glowing CHRISTMAS TREE and warm lit shop windows (soft bokeh),
  STRING LIGHTS overhead; detailed along the TOP and SIDES, a softer bokeh haze in the CENTER, calm snow-covered ground at the bottom.
Composition: the FULL cat (whole body, NOT cropped) sits in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & lights as clusters of flat stepped pixels.
FULLY OPAQUE — solid fill everywhere, NO transparency (the pine-green tree is opaque art, NOT a chroma key).
Color mood: cozy Christmas night — warm red & green costume, brown antlers over white fur, deep night blue, snow white, warm window amber, pine green, holly red.
```

### 네거티브 (시온이 체키 사진 — 공통)

```
no human, no person, no second character, no text, no watermark, no logo, no QR code,
no photo frame, no card border, no polaroid edge (the frame is a separate overlay layer composited later),
no exact Sanrio Kuromi copy, no trademarked character (style/mood only),
no readable signage, no real words, no cropped cat (the whole body must be inside the frame),
no chroma green, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the cat, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① 같은 흰 얼룩 고양이 정체성 유지 ② **`120×180`(2:3) 완전 불투명**인지(투명·크로마 그린 한 픽셀도 없어야) ③ 고양이 **전신이 안 잘리고** 중앙에 읽히는지(발치 비움), 배경은 **평면 패턴이 아닌 풍경**인지 ④ 간판이 **읽히는 실제 글자가 아닌** 추상 글로우인지 ⑤ 마스터 팔레트(~32색) 인덱싱. 저장: `assets/sprites/photo_sion_jirai.png` · `assets/sprites/photo_sion_xmas.png`.

---

## 나라카 지옥 배경 (교감화면 무대)

> ⚠️ **Phase 3.5에서 대체됨** → 아래 "**메인 디오라마 배경 v2 (A7)**" 사용. 이 v1은 좌우 가구가 단순 장식이라 시온이/바인더 받침이 없다. 구도·네거티브 참고용으로 남겨둔다.
> 옥자가 그 앞에 서는 **무대 배경**. 내부 LCD 구멍 `333×480`(세로)에 꽉 차게, 크로마키 없이 통째로 쓴다(캐릭터처럼 누끼 안 침). **SD 옥자에 어울리는 "귀엽고 아늑한 지옥 메이드카페"** 무드 — 무섭지 않고 포근하게.
> **🔁 재생성 메모(왜 다시 뽑나)**: 1차 결과가 ① **270×480로 좁게** 나와 LCD(333폭)를 못 채웠고 ② **찻잔 선반이 화면 정중앙(옥자 상체 높이)**을 점령해 캐릭터 뒤가 산만했다. 아래 프롬프트는 이 둘을 **강하게 교정**한 버전.
> **구도 핵심 ①(비율)**: **가로로 넓은 방** — 화면을 **7:10(≈333:480) 비율로 가장자리까지 꽉** 채운다. 좁고 긴 세로 복도/한쪽 벽만 보이는 구도 **금지**. **좌·우 양쪽 벽이 다 보이는 넓은 실내**.
> **구도 핵심 ②(중앙 비움)**: 캐릭터가 **정중앙~하단**에 서므로, **중앙 기둥·정중앙 뒷벽·중앙 바닥은 비운다.** **찻잔 선반·바 카운터·큰 가구는 전부 좌·우 측벽으로** 밀고, 중앙엔 **단순한 뒷벽 + 깔끔한 빈 바닥**만.
> **이상적으론** 실제 나라카 카페 내부 사진을 첨부해 "이 인테리어를 귀여운 지옥풍 픽셀아트로" 변환(img2img)하면 고증·마케팅 다리가 산다. 사진이 없으면 아래 텍스트만으로 생성.

```
Pixel art interior background of a COZY, CUTE hell-themed maid cafe ("Naraka"), no characters.
WIDE room interior filling the FULL frame edge-to-edge, aspect ratio about 7:10 (≈333:480) —
       NOT a narrow tall strip, NOT a corridor; show BOTH the LEFT and RIGHT side walls.
Back wall across the top, wide wooden/stone floor across the bottom.
Mood: cozy and charming, NOT scary — a warm candlelit witch's cafe in a gentle underworld.
Scene: dark antique cafe — push all big furniture to the SIDES: a bar counter and stools on the RIGHT wall,
       shelves with potion bottles, teacups and a brewing kettle on the LEFT wall;
       softly glowing candles and small CUTE round flames, a heart-shaped sign high on the back wall,
       tiny cute skulls and little bats as decor, dripping-candle wall sconces,
       an arched gothic window on a side wall with faint ember glow.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique — deep burgundy walls, blood red, antique gold trim, ink black, warm candle yellow glow.
Composition: the CENTER COLUMN and the LOWER-CENTER FLOOR are EMPTY (a standing character goes there) —
             plain back wall + clear open floor in the middle, ALL props and furniture against the side walls.
```

### 네거티브 (배경)

```
no characters, no people, no cat, no text, no watermark, no signature,
no gradient sky, no soft anti-aliased edges, no realistic photo finish, no 3D render,
no gore, no horror, no scary monsters, no clutter in the center,
no narrow tall strip, no corridor framing, no furniture in the center, no shelf in the middle.
```

> 톤 팁: "지옥"이지만 **캔들 옐로 따뜻한 광원 + 둥근 귀여운 불꽃 + 하트·작은 해골**로 *아늑한 마녀카페*에 가깝게. 무섭거나 칙칙하면 SD 옥자의 귀여움과 안 붙는다.

---

## 게임기 셸 프레임 (다마고치 바디)

> 화면을 감싸는 **다마고치형 달걀 하드웨어**. 가운데 **큰 세로 LCD 구멍**(여기에 게임이 비침) + 하단 **동글 3버튼**(SELECT·OK·CANCEL). 캐릭터·배경과 같은 다크 앤티크 무드로 통일. (→ ADR 0001)
> **⚠️ 캐릭터와 누끼 방식이 다르다 — 크로마 그린이 아니라 "흰색 누끼"다.** `tools/prep_shell.py`는 근백색 픽셀을 **전부** 투명화한 뒤 LCD 안쪽을 뚫는다. 따라서:
>   - **배경 = 순수 흰색 `#ffffff`**, **LCD 화면 안쪽 = 순수 흰색**(빈 화면 — 나중에 게임이 합성됨).
>   - **셸 바디·버튼·데코엔 흰색/근백색 금지**(누끼되어 구멍 난다). 하이라이트도 골드·크림 톤으로(순백 X).
> **구도 핵심**: 좌우 대칭, 세로 포트레이트(가로:세로 ≈ 0.72), LCD 구멍은 7:10(≈333:480)으로 상단~중앙을 크게, 3버튼은 하단 한 줄. 화면 둘레 여백은 균일하게 얇게.

```
Pixel art / dot art of a CUTE handheld virtual-pet toy SHELL (like a Tamagotchi), front view, NO character inside.
Body: a rounded EGG-shaped handheld console body, with a small NECKLACE LOOP / RING at the very top (keychain hole).
Screen: ONE big TALL rectangular LCD window in the UPPER-CENTER, aspect ratio about 7:10 (≈333:480);
        the screen INTERIOR is FLAT SOLID WHITE and completely EMPTY (game art is composited in later),
        framed by a thin dark bezel.
Buttons: exactly THREE round Tamagotchi-style capsule buttons in a single row across the LOWER body
         (SELECT / OK / CANCEL), antique-gold / brass colored.
Decor: tiny cute gothic emblems engraved on the body (a small bat, a heart, a tiny skull), warm candle-gold rim light.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique to match the cafe — deep burgundy / blood-red body, antique gold trim, ink-black outlines.
Framing: the toy fills the frame as a TALL vertical portrait (width:height ≈ 0.72), fully SYMMETRIC and centered,
         with a small even margin all around.
Background: FLAT SOLID PURE WHITE (#ffffff), nothing else.
```

### 네거티브 (셸)

```
no character, no face, no cat, no person, no eyes on the screen, no text, no numbers, no clock digits,
no watermark, no signature, no white or near-white anywhere on the body or buttons
(reserve white ONLY for the background and the empty screen),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no glossy reflections,
no multiple screens, no extra buttons beyond the three, no clutter, asymmetry.
```

> 🔧 **새 레퍼런스를 뽑으면 계측값을 다시 맞춰야 한다.** `prep_shell.py`의 `SRC_LCD`(LCD x0,y0,x1,y1)·`SRC_BTN_CX`(3버튼 중심 x)·`SRC_BTN_Y`·`SRC_BTN_W/H`는 **현재 레퍼런스 이미지 기준 하드코딩 계측값**이다. 새 이미지는 구멍·버튼 위치가 달라지므로, 행/열 알파 프로파일로 다시 측정해 이 상수들을 갱신한 뒤 실행한다. 실행하면 `prep_shell.py`가 환산된 `shell.gd` 상수(`CANVAS`/`LCD_OFFSET`/`LCD_SIZE`/`BTN_*`)를 출력하니 그대로 `scripts/systems/shell.gd`에 반영한다.
> 저장 위치: 받은 PNG는 `assets/sprites/_src/damagochi_frame.png`로 두고 아래 후처리 명령 실행.

---

## 지옥문 (타이틀/출석 스플래시 — 통짜 1장)

> 게임을 켜면 셸 LCD 안에서 **귀여운 지옥문이 양쪽으로 쫙 열리며** 옥자가 맞이하는 진입 연출(= 데일리 출석 화면, T14 흡수). **닫힌 문 한 장만** 그리면 된다 — 코드가 가운데(x≈166)에서 좌/우로 잘라 바깥으로 슬라이드해 여닫는다. 그러므로 **완벽한 좌우 대칭**이 생명.
> **무드**: "지옥문"이지만 무섭지 않게 — **어두운 고딕 철문 + 버건디**가 본체, **이음선에서 새어나오는 붉은 불빛(ember glow)**으로 "안쪽이 지옥"임을 암시. **골드는 하트 손잡이 + 얇은 트림 액센트로만**(전체 골드 프레임 금지 — 화려한 성문/궁전처럼 보임). **상단 가운데 작은 둥근 뿔**로 장난기. SD 옥자/셸과 같은 다크 앤티크 팔레트.
> **누끼**: 캐릭터처럼 크로마 그린. 단 **문 본체는 화면을 꽉 채워 불투명**, 아치형 상단 양 모서리 바깥만 크로마로 비워 둥근 윤곽을 준다(그 틈으로 뒤 무대가 살짝 비침).
> **구도 핵심**: 정확히 `333:480`(7:10) 세로, 가운데 세로 이음선 기준 **완전 대칭**. 가운데 이음선에 하트 손잡이 한 쌍 + 붉은 불빛, 상단 정중앙에 뿔. 좌우로 갈라도 양쪽이 거울상이 되도록.

```
Pixel art / dot art of a CUTE but slightly EERIE closed HELL GATE — a pair of heavy GOTHIC doors, front view, NO characters.
The gate is SHUT, the two doors meeting at the exact vertical CENTER seam,
       with a faint warm EMBER-RED glow leaking through the seam (firelight from the underworld behind it).
Shape: tall vertical portrait, aspect ratio exactly 7:10 (≈333:480), filling the frame;
       a pointed GOTHIC ARCH top, perfectly LEFT-RIGHT SYMMETRIC about the center seam (it will be split down the middle).
Material: DARK and heavy — deep burgundy wood with BLACK WROUGHT-IRON gothic bands, bars and rivets; ominous, weighty.
         This is NOT a shiny golden palace gate — most of the gate is DARK (ink-black iron + deep burgundy).
Gold is a MINIMAL accent ONLY: the heart handles and a thin worn-brass edge trim. Do NOT gild the whole frame.
Cute details: a pair of small GOLD HEART-shaped handles at the center seam,
              two small ROUNDED cute DEVIL HORNS at the top-center of the arch, a tiny bat silhouette.
Mood: the gate to a GENTLE underworld — a little spooky yet charming and cozy, lit warmly from BEHIND by embers.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique — deep burgundy and INK-BLACK dominate, only SMALL antique-gold accents, warm ember-red glow at the seam.
Background: FLAT SOLID chroma green (#00ff00) ONLY in the arched top corners outside the gate; the gate body itself is opaque.
```

### 네거티브 (지옥문)

```
no characters, no face, no cat, no people, no text, no watermark, no signature,
no shiny golden gate, no bright royal palace gate, no castle entrance, no fairytale gate, no marble, no white stone,
no full gold frame, no excessive gold, no glossy reflections, no glitter,
no open doors, no gap in the middle, no asymmetry, no off-center seam,
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render,
no gore, no horror, no scary spikes, no skulls on the doors, no clutter.
```

> 톤 팁: **골드를 줄이는 게 핵심** — 손잡이(하트)와 얇은 가장자리 트림만 골드, 나머지는 어두운 철문 + 버건디. 화려하면 성문이 된다.
> **"지옥"은 이음선의 붉은 불빛**이 만든다(안쪽에서 불이 새는 느낌). 뿔은 작고 둥글게(장난기), 무섭거나 뾰족하면 SD 옥자와 안 붙는다.
> 검수 포인트: **좌우 대칭**(반 접어 겹쳐 보기) + 가운데 이음선이 정확히 중앙(x≈166)인지. 어긋나면 슬라이드 시 양쪽 두께가 달라 보인다.

---

## 체키북 장식 (A6 — 컬렉션북 UI) → [asset-checklist.md](./asset-checklist.md) A6

> 은유 = **실물 포토카드 바인더(앤틱 마녀 다이어리)**. 가죽 테두리(다크 무드) + 크림 속지(카드 팝).
> **⚠️ 캐릭터와 워크플로우가 다르다** — 이건 사진 변환(img2img)이 아니라 **텍스트 생성(text2img)** UI 장식이다(실존 인물 고증 불필요). 그래도 ① 마스터 팔레트(~32색) 인덱싱 ② 크로마 그린 누끼는 동일.
> **🔑 작게 뽑지 마라** — 24×24·16×16은 AI가 직접 못 그린다. **크게(예: 512px) 받아 `dotify --size`로 축소**하고, 모양은 **단순·대담**하게(작은 화면에서 읽히게).
> **🔑 미보유 칸 에셋은 0** — empty/locked 칸은 표지 공용 레이어(`frame_cover_bg`+`emblem_wing`)를 코드가 디밍 재활용한다. 여기 참(✦/봉랍)·장식만 새로 그린다.

### 가죽 바인더 프레임 (`book_frame_leather`)

> 카드가 앉는 페이지를 감싸는 **베젤(테두리만)**. 가운데는 뻥 뚫린 창(코드가 속지·그리드를 깐다). 카드 `333×480` 꽉, 가운데 + 바깥 모서리 크로마 그린.

```
Pixel art / dot art of an ANTIQUE LEATHER BINDER / witch's diary COVER seen flat from the front, as a thick
BORDER FRAME ONLY — the entire CENTER is a hollow empty window (cards are placed there later). NO text, NO character.
Frame: a worn dark BURGUNDY LEATHER border hugging all four edges, with embossed corners, a row of fine GOLD STITCHING
       running just inside the edge, and small antique-brass corner caps. Tall vertical portrait, aspect ratio 333:480,
       rounded outer corners.
Center: ONE big empty rectangular hole filling MOST of the frame — FLAT SOLID chroma green (#00ff00), completely EMPTY.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique — deep burgundy leather, antique-gold stitch, ink-black shadow, faint candle warmth.
Background: chroma green (#00ff00) also fills OUTSIDE the rounded corners; ONLY the leather border is opaque.
```

```
[네거티브] no text, no character, no scenery in the center (the center MUST stay flat solid chroma green and empty),
no cards drawn, no shiny modern frame, no full gold frame, no marble, no gradient, no soft anti-aliased edges,
no 3D render, no glossy reflections.
```

### 크림 속지 (`book_page_parchment`)

> 카드가 톡 떠 보이게 받쳐주는 **밝은 종이 바닥**(불투명, 누끼 X). 코드가 가죽 창 안쪽에 깐다.

```
Pixel art / dot art of a blank aged CREAM PARCHMENT page / photo-album insert, seen flat — warm IVORY paper with very
subtle mottling/speckle and a faint darker vignette at the edges, completely EMPTY (cards go on top later).
NO text, NO ruled lines, NO emblem, NO character. Tall vertical rectangle, fully OPAQUE, fills the image edge-to-edge.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading; texture as sparse flat-pixel speckle.
Color mood: warm cream / candle ivory, faint sepia mottling, soft darker edge vignette.
Background: the parchment IS the whole image (opaque, no chroma).
```

```
[네거티브] no text, no ruled notebook lines, no grid lines, no character, no frame border, no holes,
no chroma green, no transparency, no bright pure white, no gradient, no soft anti-aliased edges, no 3D render.
```

### 참 · 작은 장식 (공용 베이스)

> 아래 작은 아이콘들은 **공용 베이스 + 한 줄 추가**로 뽑는다(표정 6종 방식). 전부 크로마 그린 누끼, 크게 받아 축소.

```
[공용 베이스]
Pixel art / dot art ICON — a SINGLE centered object, on a FLAT SOLID chroma green (#00ff00) background, nothing else.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique — deep burgundy, blood red, antique gold, ink black, candle yellow.
Draw it LARGE and BOLD with a simple silhouette (it will be downscaled to a tiny icon — it must read at small size).
```

```
[공용 네거티브] no text, no letters, no numbers, no extra objects, no character, no scenery,
no chroma green on the object itself, no gradient, no soft glow blur, no soft anti-aliased edges,
no 3D render, no glossy reflections, no realistic finish.
```

| 파일명 | 추가 문구(object) | 비고 |
|---|---|---|
| `seal_wax` | `Object: a round WAX SEAL stamp — a blob of dark BURGUNDY / blood-red sealing wax with a thin antique-GOLD rim and a faint embossed mark in the center (a tiny wing), slightly irregular molten edge.` | locked 참 + locked 탭 겸용 (P0) |
| `corner_filigree` | `Object: an ornate ANTIQUE-GOLD FILIGREE corner flourish — an L-shaped baroque scroll / vine ornament for a page corner, symmetric along the diagonal.` | 4모서리 회전 재사용 (P1) |
| `butterfly_deco` | `Object: a small gothic BUTTERFLY, wings spread wide, ink-black wings with antique-gold edge tracing and a hint of violet & pink, tiny body.` | `emblem_butterfly` 축소 재활용도 가능 (P1) |
| `book_watermark_n` | `Object: ONE large ornate monogram letter "N" (blackletter / serif) as a faint EMBOSSED watermark, thin antique-gold outline, low contrast.` | ⚠️ 여기 "N"은 **의도된 모노그램**(공용 네거티브 no text 예외) (P1) |
| `sparkle` | `Object: a clean 4-point SPARKLE / twinkle star, antique-gold with a candle-yellow core.` | empty 참. 코드 `_draw`로 충분 — PNG는 선택 (P1) |
| `candle_deco` | `Object: a small lit CANDLE — ivory candle body, warm candle-yellow teardrop flame, a little melted wax, antique-gold holder base.` | (P2, 여력 시) |
| `ribbon_bookmark` | `Object: a thin vertical RIBBON BOOKMARK hanging straight down, deep burgundy fabric with a forked / notched bottom end and a thin gold edge.` | (P2, 여력 시) |

### 탭 미니 초상 (`portrait_okja` · `portrait_sion`)

> **권장: 생성하지 말고 크롭.** 확정된 `okja_idle.png` / `sioni_idle.png`에서 **얼굴을 정사각으로 크롭** → `dotify --size 24x24`. 라이브 옥자는 마녀룩이라 idle 얼굴이 탭 정체성과 일치하고, 시온이는 idle을 그대로 축소하면 된다(일관성·작업량 둘 다 이득).
> 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
Pixel art / dot art tiny SQUARE PORTRAIT bust (face + shoulders), front view, centered, BIG readable face.
Subject: [ Okja, the chic tsundere hell witch-maid, dark witch hat | Sioni, a VERY CHUBBY round WHITE cat — a BLACK center-parted cap on the head (parted by a white stripe), a tiny BROWN mark on the small pink nose only (no large brown face patch) ].
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique palette. Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

```
[네거티브] no full body, no tiny face, no text, no extra characters, no scenery,
no chroma green on the subject, no gradient, no soft anti-aliased edges, no 3D render.
```

> ⚠️ **공통 검수**: ① 누끼 대상이 순수 크로마 그린에서 깨끗이 분리되는지 ② **작게 축소해도 모양이 읽히는지**(seal/portrait는 24px, butterfly/sparkle는 16px) ③ 마스터 팔레트(~32색) 인덱싱 ④ 가죽 프레임은 **가운데가 순수 크로마 한 덩어리**(코드가 속지·그리드를 깐다)인지.

---

## 선물 아이콘 (A3 — `선물` 팝업 버튼)

> `선물` 버튼 팝업의 **선택지 버튼 좌측 24×24 도트 아이콘**(→ asset_manifest A3 `icon_gift_*`, `data/gifts.json`의 `gift.icon`이 슬롯 id로 가리킴). `ChoicePopup`이 버튼에 얹으며, 슬롯이 없으면 텍스트만 뜨는 graceful fallback이라 **나중에 채워도 안 깨진다**.
> **🔑 규격**: **24×24 투명 누끼**(크로마 그린 → `dotify --chroma 00ff00 --size 24x24`). 위 "참·작은 장식"과 같은 공용 베이스를 쓰되, **버튼 배경이 어두운 버건디+골드 패널**이라 아이콘이 묻히지 않게 **얇은 밝은 외곽선/림**을 둘러 또렷하게 받는다.
> **🔑 색**: 선물은 본래 알록달록(딸기 핑크 등)하므로 dark-antique에 가두지 말고 **아이템 고유색**을 살리되 **마스터 팔레트(~32색) 인덱싱**으로 통일. 매핑은 `data/gifts.json` 순서(1=케이크·2=인형·3=츄르·4=꽃다발).

```
[선물 아이콘 공용 베이스]
Pixel art / dot art ICON — a SINGLE centered object, on a FLAT SOLID chroma green (#00ff00) background, nothing else.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Draw it LARGE and BOLD with a simple, instantly readable silhouette (it will be downscaled to a tiny 24×24 icon).
Give the object a thin clean OUTLINE / light rim so it pops against a DARK burgundy button background.
Use the object's natural cute colors, but keep a small limited palette (it will be indexed to a ~32-color master palette).
```

```
[선물 아이콘 공용 네거티브] no text, no letters, no numbers, no brand logo, no extra objects, no character, no hands, no scenery,
no chroma green on the object itself, no gradient, no soft glow blur, no soft anti-aliased edges,
no 3D render, no glossy reflections, no realistic photo finish.
```

| 파일명 | 선물 | 추가 문구(object) | 비고 |
|---|---|---|---|
| `icon_gift_1` | 딸기 생크림 조각 케이크 | `Object: a slice of STRAWBERRY SHORTCAKE — a triangular wedge with white whipped-cream layers and a glossy RED STRAWBERRY on top, a thin sponge layer, sitting on a tiny plate.` | tier plain |
| `icon_gift_2` | 폭신한 동물 인형 | `Object: a FLUFFY round PLUSH animal doll (teddy/bunny), sitting, big round head, stubby limbs, soft pastel fur, a tiny bow — adorable and huggable.` | tier match |
| `icon_gift_3` | 고양이 츄르 | `Object: a creamy CAT-TREAT squeeze TUBE (churu stick) lying slightly diagonal, a small dab of cream at the open tip, with a tiny PAW-PRINT mark on the wrapper (signals it is for the cat).` | tier sion(시온이용) · 🐾 발바닥 마크 |
| `icon_gift_4` | 꽃다발 | `Object: a small wrapped BOUQUET of flowers — a few rounded blossoms (rose/tulip-like) with green leaves, gathered in a paper wrap tied with a ribbon.` | tier plain |

> ⚠️ **검수 포인트**: ① 순수 크로마 그린에서 깨끗이 누끼되는지 ② **24px로 줄여도 무엇인지 즉시 읽히는지**(버튼에서 라벨 옆 작게 뜬다) ③ **어두운 버건디 버튼 위에서 묻히지 않게 외곽선/림이 있는지** ④ 츄르는 **발바닥 마크로 시온이용임이 드러나는지** ⑤ 마스터 팔레트(~32색) 인덱싱. 저장: `assets/sprites/icon_gift_{1..4}.png`.
> 💡 **음료 아이콘(`icon_drink_1~4`)도 같은 골격** — 이 공용 베이스·규격(24×24)·네거티브 그대로, object만 음료(커피·라떼·딸기우유·허브티 등)로 갈아끼운다(현재 게임 미배선, 후속 트랙).

---

## Phase 3.5 — 메인 디오라마 리프레임 에셋 (ROADMAP A7·A8)

> 2026-06-05 grill-me 합의(→ 메모리 `main-screen-diorama-reframe`). 메인 교감화면을 **카페 디오라마**로 재구성: 중앙 옥자 전신 + **좌우 대칭 엔틱 가구**가 시온이/체키북을 얹는 **받침**이 된다. 우=포션·술병 선반(어깨 높이에 시온이), 좌=엔틱 서랍장/책장(위에 체키북 바인더). 버튼은 나인패치 귀여운 틀로 전면 통일.
> **핵심 분업**: 가구·병·책은 **배경 그림**(A7)에 박고, **시온이·바인더·버튼은 별도 스프라이트**(A8)로 코드가 그 위에 얹는다. 그래서 배경엔 받침이 될 **평평한 선반/상판**을 비워 둬야 한다.

### A7 — 메인 디오라마 배경 v2 (`bg_naraka.png`, 333×480, 누끼 없음)

> 기존 "나라카 지옥 배경"을 **대체**. 차이: 이제 좌우 가구가 단순 장식이 아니라 **스프라이트 받침**이다 — 오른쪽엔 **어깨 높이에 평평한 선반 칸 하나를 비워**(시온이가 앉음), 왼쪽엔 **하중단에 평평한 캐비닛/책장 상판을 비워**(바인더가 놓임) 둔다. 중앙은 옥자 전신이 서므로 여전히 비운다.
> **정확한 y는 그림을 보고 코드(`SIONI_FEET`·바인더 좌표)를 맞춘다** — AI는 대략의 위치만, 받침이 또렷이 평평하면 된다.
> **2x 줌 대비**: 시온이 탭 시 오른쪽 선반이 2배 확대되므로, **오른쪽 선반·병 디테일을 또렷하고 깔끔하게**(확대해도 안 지저분하게).

```
Pixel art interior background of a COZY, CUTE hell-themed maid cafe ("Naraka"), no characters, no cat.
WIDE room filling the FULL frame edge-to-edge, aspect ratio about 7:10 (≈333:480) — NOT a narrow strip, show BOTH side walls.
Back wall across the top, wide warm wooden floor across the bottom.
Mood: cozy and charming, NOT scary — a warm candlelit witch's cafe in a gentle underworld.
LEFT wall: a tall ANTIQUE dark-wood CABINET / BOOKSHELF with stacked old leather books and a few potion jars,
       and ONE clear FLAT EMPTY shelf-top / cabinet surface in the LOWER-MIDDLE area (kept uncluttered — an object will sit there).
RIGHT wall: a tall apothecary SHELF of glowing colored POTION BOTTLES and liquor flasks,
       with ONE clear FLAT EMPTY shelf plank at UPPER-MIDDLE / shoulder height (kept uncluttered — a small pet will sit there).
Both side furniture pieces read as solid LEDGES/PLATFORMS, roughly SYMMETRIC framing on left and right.
Decor: softly glowing candles and small CUTE round flames, a heart-shaped sign high on the back wall,
       tiny cute skulls and little bats, dripping-candle wall sconces, an arched gothic window with faint ember glow.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: dark antique — deep burgundy walls, blood red, antique gold trim, ink black, warm candle-yellow glow;
       the right-wall potion bottles glow in soft jewel tones (still flat, stepped dot shading).
Composition: the CENTER COLUMN and LOWER-CENTER FLOOR are EMPTY (a standing character goes there) —
       plain back wall + clear open floor in the middle, ALL furniture against the side walls,
       with the two clear empty ledges (left lower-middle, right shoulder-height) ready to hold objects.
```

#### 네거티브 (배경 v2)

```
no characters, no people, no cat, no binder, no book held open, no text, no watermark, no signature,
no gradient sky, no soft anti-aliased edges, no realistic photo finish, no 3D render,
no gore, no horror, no scary monsters, no clutter in the center, no furniture in the center,
no narrow tall strip, no corridor framing,
no bottles or books covering the two empty ledges (keep the left lower-middle surface and the right shoulder-height plank clear).
```

> ⚠️ 검수: ① 333폭 꽉 참(좁은 세로 띠 아님) ② **오른쪽 어깨 높이 + 왼쪽 하중단에 평평하게 빈 받침**이 또렷한지 ③ 중앙·하단 중앙이 비어 옥자가 읽히는지 ④ 포근한 캔들 톤(무섭지 않게) ⑤ 마스터 팔레트(~32색) 인덱싱. 저장: `assets/sprites/bg_naraka.png`(기존 덮어쓰기, `cafe.gd` `BG_TEX`와 일치).

### A8-1 — 시온이 60px (받침 위 가독성)

> 디오라마에선 시온이가 발치가 아니라 **선반 어깨 높이**에 앉아 옥자와 한 쌍으로 읽힌다. **그림은 위 "시온이 (펫)" 프롬프트 그대로**, 출력만 `48→60px`. 새로 그릴 필요 없이 **기존 raw(또는 확정 idle)를 `--size 60x60`으로 재출력**하고, `sioni.gd`의 `SPR_SIZE`를 `Vector2(60,60)`으로 올린다(앵커=바닥 중앙은 동일). 4종(idle/snack/play/pet) 모두 60px.

### A8-2 — 나인패치 귀여운 버튼 틀 (`btn_9slice_normal` · `btn_9slice_focused`)

> 액션바·온보딩·팝업 공용. **9-slice라 중앙은 완전 평평**해야 늘려도 안 번진다 — 장식은 **테두리·모서리에만**, 가운데 채움은 단일 톤. 라벨 글자는 코드가 갈무리 폰트로 위에 얹으니 **글자 없이** 빈 틀만. 두 상태: normal(잔잔) / focused(밝게+골드 글로우). 둥근 모서리 바깥은 크로마 그린 누끼.
> **규격 권장**: ~`64×40`, 모서리 반경 ~10px, 9-slice 인셋(margin) 사방 14px. 두 장 모두 **같은 크기·같은 모서리 반경**(상태 스왑 시 안 튀게).

```
Pixel art / dot art of a SINGLE cute rounded-rectangle UI BUTTON PLATE, front view, EMPTY (no text, no icon).
Shape: a horizontal rounded-rectangle plate with soft rounded corners, perfectly symmetric.
Surface: the CENTER fill is ONE FLAT UNIFORM color (so it can be stretched / 9-sliced) —
         all detail lives ONLY on the BORDER and CORNERS: a clean rounded antique-gold outline with a subtle inner bevel,
         tiny gold corner flourishes.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat stepped shading.
Color mood: deep burgundy fill, antique-gold rounded border, ink-black thin outline — to match the cafe UI.
Background: FLAT SOLID chroma green (#00ff00) outside the rounded plate (so the rounded corners cut out cleanly).
```

> **focused 변형 — 한 줄만 추가**: `Variant: brighter / highlighted state — lighter burgundy fill, a GLOWING bright antique-gold border (thicker, with a soft warm gold rim), reads as "selected".`

#### 네거티브 (나인패치 버튼)

```
no text, no letters, no numbers, no icon, no symbol in the center,
no decoration in the CENTER (center must stay a flat uniform fill for 9-slicing),
no multiple buttons, no drop shadow outside the plate, no gradient fill, no soft anti-aliased edges,
no realistic 3D button, no glossy plastic reflection, no chroma green on the plate itself.
```

> ⚠️ 검수: ① **중앙이 단색 평면**인지(여기에 디테일 있으면 9-slice에서 번짐) ② 모서리 반경이 두 상태 동일한지 ③ 둥근 바깥이 깔끔히 누끼됐는지. 인셋(14px)은 Godot `StyleBoxTexture.texture_margin_*`로 설정 → `ui_theme.gd`.

### A8-3 — 체키북 바인더 오브젝트 (`cheki_binder`, 좌측 가구 위 탭 대상)

> 왼쪽 엔틱 캐비닛 상판에 놓여 **탭하면 컬렉션북으로** 들어가는 오브젝트. 실물 포토카드 바인더 은유(→ `collection-book-structure`). 닫힌 가죽 앨범/바인더가 **살짝 비스듬히 세워진** 모습(받침 위에 놓인 게 읽히게). 기존 `book_frame_leather`의 가죽·하트 톤과 한 세트.
> **규격**: ~`48×56`(세로로 약간 큰 책). 누끼=크로마 그린. 앵커는 코드에서 바닥 중앙.

```
Pixel art / dot art of a SINGLE closed cute LEATHER PHOTO-CARD BINDER / album standing slightly tilted, front-3/4 view, NO characters.
Object: a thick closed book / binder with a dark burgundy LEATHER cover, antique-gold corner caps and a gold spine,
        a small GOLD HEART clasp on the front, a tiny butterfly/wing emblem embossed on the cover.
It rests as if placed on a shelf — a small flat base, reads as a standing collectible album.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat stepped shading.
Color mood: deep burgundy leather, antique gold trim, ink-black outline, cream page edges — matches the cheki binder UI.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

#### 네거티브 (바인더)

```
no characters, no cat, no hand, no open book, no readable text, no watermark, no signature,
no stack of many books (ONE single binder), no scenery, no shelf drawn (the shelf is in the background),
no chroma green on the binder, no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render.
```

> ⚠️ 검수: ① **닫힌 한 권**인지(책더미·펼친 책 아님) ② 가죽 버건디+골드 하트 클래스프로 `book_frame_leather`와 톤 일치 ③ 받침에 놓인 듯 바닥이 안정적인지 ④ 누끼 깔끔. 저장: `assets/sprites/cheki_binder.png`.

---

## 후처리 연결 (받은 PNG → 규격 에셋)

```bash
# 옥자 (128×288, 크로마 그린 배경 제거)
tools/.venv/bin/python tools/dotify.py okja_smile_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_smile.png

# 옥자 지뢰계 ★히어로 체키 (금발·갸루 포즈 — 체키 카드용 정적 아트)
tools/.venv/bin/python tools/dotify.py okja_jirai_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_jirai.png

# 체키 뒷면 사진 프레임 (120×180, 가운데 크로마 그린 창만 뚫어 투명 슬롯화)
# ※ preset cheki(120×180) + --chroma 00ff00 → 사진 창이 투명, 양피지 테두리는 불투명 유지
# ※ 로고·워드마크·QR 없음(표지로 이동) — 테두리+붉은 드립만
tools/.venv/bin/python tools/dotify.py frame_standard_raw.png \
  --preset cheki --chroma 00ff00 --out assets/sprites/frame_standard.png

# 지뢰계 테마 프레임 (표준 골격 + 테두리만 지뢰계 데코, 사진 창은 동일하게 크로마 그린)
tools/.venv/bin/python tools/dotify.py frame_jirai_raw.png \
  --preset cheki --chroma 00ff00 --out assets/sprites/frame_jirai.png

# 체키 사진 배경 — 지뢰계 (120×180 불투명, 누끼 X — 누끼 옥자 뒤에 깔리는 의상 종속 레이어)
tools/.venv/bin/python tools/dotify.py bg_cheki_jirai_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_jirai.png

# 체키 앞면 표지 — 파치먼트 배경 (120×180, 불투명 카드, 누끼 없음)
tools/.venv/bin/python tools/dotify.py frame_cover_bg_raw.png \
  --size 120x180 --out assets/sprites/frame_cover_bg.png

# 체키 표지 등급 엠블럼 2종 + 나라카 워드마크 (크로마 그린 누끼 → 표지 위 합성)
# ※ size는 합성 레이어라 자유. 쌍날개·나비는 가로로 넓다. 크로마만 뚫는다.
tools/.venv/bin/python tools/dotify.py emblem_wing_raw.png \
  --size 96x56 --chroma 00ff00 --out assets/sprites/emblem_wing.png
tools/.venv/bin/python tools/dotify.py emblem_butterfly_raw.png \
  --size 88x64 --chroma 00ff00 --out assets/sprites/emblem_butterfly.png
tools/.venv/bin/python tools/dotify.py wordmark_naraka_raw.png \
  --size 96x32 --chroma 00ff00 --out assets/sprites/wordmark_naraka.png

# 시온이 펫 반응 (48×48, preset sioni — 교감화면 기본 흰 고양이)
tools/.venv/bin/python tools/dotify.py sioni_idle_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_idle.png
tools/.venv/bin/python tools/dotify.py sioni_snack_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_snack.png
tools/.venv/bin/python tools/dotify.py sioni_play_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_play.png
tools/.venv/bin/python tools/dotify.py sioni_pet_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_pet.png

# 시온이 체키 사진 (배경 포함 베이크 — 120×180 불투명, 누끼 X·크로마 X, 전신+풍경 2:3 한 장)
tools/.venv/bin/python tools/dotify.py photo_sion_jirai_raw.png \
  --size 120x180 --out assets/sprites/photo_sion_jirai.png
tools/.venv/bin/python tools/dotify.py photo_sion_xmas_raw.png \
  --size 120x180 --out assets/sprites/photo_sion_xmas.png

# ── A4·A5 의상·프레임·배경 확장 (유치원·힙합·집사·크리스마스) ──
# 옥자 의상 3종 (128×288, preset okja — 체키 카드용 정적 아트)
tools/.venv/bin/python tools/dotify.py okja_kinder_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_kinder.png
tools/.venv/bin/python tools/dotify.py okja_hiphop_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_hiphop.png
tools/.venv/bin/python tools/dotify.py okja_butler_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_butler.png
# 옥자 크리스마스 의상 (⚠️ 산타 드레스에 초록 홀리 → 크로마는 마젠타 ff00ff)
tools/.venv/bin/python tools/dotify.py okja_xmas_raw.png \
  --preset okja --chroma ff00ff --out assets/sprites/okja_xmas.png

# 테마 사진 프레임 4종 (preset cheki — 표준 골격 + 테두리 데코만 교체, 사진 창은 크로마로 투명화)
tools/.venv/bin/python tools/dotify.py frame_kinder_raw.png \
  --preset cheki --chroma 00ff00 --out assets/sprites/frame_kinder.png
tools/.venv/bin/python tools/dotify.py frame_hiphop_raw.png \
  --preset cheki --chroma 00ff00 --out assets/sprites/frame_hiphop.png
tools/.venv/bin/python tools/dotify.py frame_butler_raw.png \
  --preset cheki --chroma 00ff00 --out assets/sprites/frame_butler.png
# 크리스마스 프레임 (⚠️ 초록 홀리 데코 → 크로마/사진창 모두 마젠타 ff00ff)
tools/.venv/bin/python tools/dotify.py frame_xmas_raw.png \
  --preset cheki --chroma ff00ff --out assets/sprites/frame_xmas.png

# 체키 사진 배경 4종 (120×180 불투명, 누끼 X — 의상 누끼를 받치는 풍경 레이어)
tools/.venv/bin/python tools/dotify.py bg_cheki_kinder_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_kinder.png
tools/.venv/bin/python tools/dotify.py bg_cheki_hiphop_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_hiphop.png
tools/.venv/bin/python tools/dotify.py bg_cheki_butler_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_butler.png
tools/.venv/bin/python tools/dotify.py bg_cheki_xmas_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_xmas.png

# 나라카 지옥 배경 (333×480, 크로마키 없음 — 화면 전체를 채우는 불투명 배경)
tools/.venv/bin/python tools/dotify.py naraka_bg_raw.png \
  --size 333x480 --out assets/sprites/naraka_bg.png

# 게임기 셸 (흰색 누끼 + LCD 구멍 뚫기 → 635×877 프레임 + shell.gd 상수 출력)
# ※ dotify가 아니라 prep_shell.py. 새 레퍼런스면 먼저 SRC_* 계측값부터 갱신할 것.
tools/.venv/bin/python tools/prep_shell.py \
  --in assets/sprites/_src/damagochi_frame.png --out assets/sprites/shell_frame.png

# 지옥문 (333×480, 아치 모서리만 크로마 그린 제거 → 문 본체 불투명 통짜)
tools/.venv/bin/python tools/dotify.py gate_naraka_raw.png \
  --size 333x480 --chroma 00ff00 --out assets/sprites/gate_naraka.png

# ── 체키북 장식 (A6) ── 크게 받아 dotify로 축소·누끼 (UI 장식: text2img)
# 가죽 바인더 프레임 (가운데 + 바깥 모서리 크로마 그린 → 베젤만 불투명)
tools/.venv/bin/python tools/dotify.py book_frame_leather_raw.png \
  --size 333x480 --chroma 00ff00 --out assets/sprites/book_frame_leather.png
# 크림 속지 (불투명, 누끼 X)
tools/.venv/bin/python tools/dotify.py book_page_parchment_raw.png \
  --size 301x372 --out assets/sprites/book_page_parchment.png
# 탭 미니 초상 (권장: okja_idle/sioni_idle 얼굴 크롭본을 입력으로)
tools/.venv/bin/python tools/dotify.py portrait_okja_raw.png \
  --size 24x24 --chroma 00ff00 --out assets/sprites/portrait_okja.png
tools/.venv/bin/python tools/dotify.py portrait_sion_raw.png \
  --size 24x24 --chroma 00ff00 --out assets/sprites/portrait_sion.png
# 참 (P0 봉랍 / P1 반짝임) + 장식 (P1 코너·나비·워터마크)
tools/.venv/bin/python tools/dotify.py seal_wax_raw.png \
  --size 24x24 --chroma 00ff00 --out assets/sprites/seal_wax.png
tools/.venv/bin/python tools/dotify.py corner_filigree_raw.png \
  --size 32x32 --chroma 00ff00 --out assets/sprites/corner_filigree.png
tools/.venv/bin/python tools/dotify.py butterfly_deco_raw.png \
  --size 16x16 --chroma 00ff00 --out assets/sprites/butterfly_deco.png
tools/.venv/bin/python tools/dotify.py book_watermark_n_raw.png \
  --size 120x120 --chroma 00ff00 --out assets/sprites/book_watermark_n.png
tools/.venv/bin/python tools/dotify.py sparkle_raw.png \
  --size 16x16 --chroma 00ff00 --out assets/sprites/sparkle.png
# (P2, 여력 시) 촛불 · 리본 책갈피
tools/.venv/bin/python tools/dotify.py candle_deco_raw.png \
  --size 16x24 --chroma 00ff00 --out assets/sprites/candle_deco.png
tools/.venv/bin/python tools/dotify.py ribbon_bookmark_raw.png \
  --size 12x40 --chroma 00ff00 --out assets/sprites/ribbon_bookmark.png

# ── Phase 3.5 디오라마 리프레임 (A7·A8) ──
# A7 메인 디오라마 배경 v2 (333×480 불투명, 좌우 가구 받침 — 기존 bg_naraka.png 덮어쓰기)
tools/.venv/bin/python tools/dotify.py bg_naraka_v2_raw.png \
  --size 333x480 --out assets/sprites/bg_naraka.png
# A8-1 시온이 60px (그림 동일, 출력만 48→60 — 기존 raw/idle 재출력 후 sioni.gd SPR_SIZE=60)
tools/.venv/bin/python tools/dotify.py sioni_idle_raw.png \
  --size 60x60 --chroma 00ff00 --out assets/sprites/sioni_idle.png
tools/.venv/bin/python tools/dotify.py sioni_snack_raw.png \
  --size 60x60 --chroma 00ff00 --out assets/sprites/sioni_snack.png
tools/.venv/bin/python tools/dotify.py sioni_play_raw.png \
  --size 60x60 --chroma 00ff00 --out assets/sprites/sioni_play.png
tools/.venv/bin/python tools/dotify.py sioni_pet_raw.png \
  --size 60x60 --chroma 00ff00 --out assets/sprites/sioni_pet.png
# A8-2 나인패치 버튼 틀 normal/focused (둥근 바깥 누끼 → 9-slice는 ui_theme.gd에서 인셋 14px)
tools/.venv/bin/python tools/dotify.py btn_9slice_normal_raw.png \
  --size 64x40 --chroma 00ff00 --out assets/sprites/btn_9slice_normal.png
tools/.venv/bin/python tools/dotify.py btn_9slice_focused_raw.png \
  --size 64x40 --chroma 00ff00 --out assets/sprites/btn_9slice_focused.png
# A8-3 체키북 바인더 오브젝트 (좌측 가구 위 탭 대상)
tools/.venv/bin/python tools/dotify.py cheki_binder_raw.png \
  --size 48x56 --chroma 00ff00 --out assets/sprites/cheki_binder.png
```

> ⚠️ `--preset bg`(270×480)는 셸 교체 이전 값이라 현 LCD `333×480`과 안 맞는다 — 배경은 위처럼 `--size 333x480`로 뽑을 것(또는 `tools/dotify.py` PRESETS의 `bg`를 `(333, 480, False, None)`으로 갱신).

→ 검수 리포트가 ✅ 통과하면 사용, ⚠️ 면 pixilart에서 노이즈/외곽선 수동 정리.

## 반복 루프

1. **(나)** 위 프롬프트 제공 (필요 시 사진별로 미세 조정)
2. **(너)** Gemini에 사진+프롬프트 → 결과 PNG 전달
3. **(나)** `dotify`로 규격화 + 검수 → 통과/미달 판정
4. 미달이면 어디가 어긋났는지 짚고 **프롬프트 수정안** 제시 → 2번 반복
5. 통과 → pixilart 수동 정리 → 에셋 확정

> 팁: 표정 6종은 **첫 1장(idle)을 확정**한 뒤, 그 결과를 레퍼런스로 첨부하며 나머지를 뽑으면 일관성이 크게 오른다.
