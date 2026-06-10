# Gemini 도트 변환 프롬프트 — 미호 (구미호 메이드)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**(img2img). 공용 에셋·핵심 원칙·체키 합성 조각은 [공통 파일](./gemini-prompts-common.md) 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))
> **추적 이슈 [#1](https://github.com/JeffKM/Narakuchi/issues/1)** — 미호 슬라이스 첫 단(아트 선행). **확장 트랙 원칙상 아트가 항상 코드보다 먼저**다(→ 메모리 `character-expansion-plan`).

> **미호 (Miho)**: 구미호 메이드. 반려묘 **규종이**(별 슬라이스 #6 — 프롬프트는 [규종이 파일](./gemini-prompts-gyujong.md)). 시그니처 음료 **미호 스파클링**. 로스터 accent색 **노랑/골드**(→ ROADMAP T21 — 실물 레퍼 반영해 기존 핑크에서 변경). 옥자와 같은 **표정 스왑 SD 라이브**(ADR 0001) 규격.

> **🔑 레퍼런스 첨부 필수**: 미호 실물 사진을 `assets/sprites/_src/miho_ref.png`(얼굴 선명·메인)에 두고 첨부해 **img2img**로 뽑는다(옥자·시온이와 동일 — 텍스트만으론 얼굴이 매번 흔들린다). 보조: `miho_ref_b.png`(전신·의상 각도), `miho_ref_chibi.png`(목표 SD 스타일 참고용 — img2img 입력 아님, 백·노랑 구미호+흰 꼬리+한복풍 룩의 도착점). 표정 6종은 **첫 1장(`miho_idle`)을 확정**한 뒤 그 결과를 레퍼런스로 첨부하며 나머지를 뽑으면 일관성이 크게 오른다.
> **🔑 정체성(고정) — 실물 레퍼 기준**: ① **흰 여우 귀(안쪽 핑크)** + **크고 복슬복슬한 흰 여우 꼬리**(가독성 위해 1~3개로 압축, "구미호"의 다꼬리는 암시만) ② **여우 분장** — 양 볼 **수염 자국** + 눈밑 **붉은 아이메이크업** + 주홍 립 ③ **긴 검은 생머리** ④ **백·노랑 한국 전통 구미호룩** — 흰 한복풍 저고리(부드러운 프릴) + 노란 치마, 시그니처 액센트는 **노랑/골드** ⑤ 가끔 **파란 도깨비불(귀신불)** 이펙트로 구미호 분위기 ⑥ 시크한 옥자와 대비되는 **포근·애교 + 영리한 여우** 무드.

> **🔑 SD·셰이딩 락(생성 교훈 — 두 번 빗나감)**: 미호는 ① `flat shading` 문구 탓에 **납작·밋밋**, ② `SLIM` 과강조 탓에 **머리 작고 다리 긴 일반 등신비(SD 아님)** 로 나왔다. 수정: ① `flat shading` 제거 → **"색마다 2~3톤 도트 셰이딩"**, ② `SLIM` 제거 → **옥자급 SD(머리 ≈ 전체 높이의 1/3, 다리 짧게)** 로 못박음.
> **🔑 결정적 해법 = 옥자 idle을 앵커로 첨부**: 실물 사진만 img2img하면 **무조건 일반 등신비**로 나온다(머리 작고 다리 김). **반드시 `assets/sprites/okja_idle.png`(확정 SD)를 1번 이미지(비율·도트 스타일 앵커)로, 미호 실물을 2번(얼굴·정체성)으로 첨부**하고 "얼굴·여우 정체성은 2번에서, 등신비·도트 스타일은 1번(옥자)과 똑같이"라고 지시한다. 텍스트만으론 SD·셰이딩 둘 다 또 빗나간다.

---

## 공통 베이스 (미호 SD) ★라이브 스탠딩용

> 옥자와 동일하게 **SD 치비(머리 ≈ 전체 높이의 1/3, 1:2.5~3)** 로 간다 — 다마고치 LCD에서 표정 6종이 읽히려면 머리를 키워야 한다(→ 옥자 SD 근거). 여우 귀·꼬리는 SD에서 실루엣 포인트가 되니 **또렷하고 크게**. **머리 크기·다리 짧음은 옥자 idle 첨부로 강제**(위 SD 락 참조).
> **🔑 프레임 충전 = 옥자와 동일 스케일(중요)**: 라이브 스탠딩은 **머리가 상단, 발이 하단에 닿게 프레임을 꽉 채워야** 교감화면에서 옥자와 크기가 맞는다(옥자 idle = 높이 충전 ~96%, 발 바닥여백 0).
> **🔑 충전은 이제 `dotify`가 자동(2026-06-07)**: `--preset okja`(캐릭터)는 **콘텐츠 bbox 크롭 → 높이 충전 → 하단 정렬**을 자동 적용한다(`FILL_PRESETS`). 여백 많은 원본을 넣어도 발이 바닥에 붙는다 — 레퍼를 꽉 크롭할 부담이 줄었다. 끄려면 `--no-fill`.
> **⚠️ 단 폭이 관건**: 충전은 **높이 우선이되 폭이 캔버스(128)를 넘으면 폭 기준으로 제한**(팔·꼬리 잘림 방지)되어 **높이가 덜 찬다.** SD라 머리는 커도 되지만(옥자도 SD인데 96% 충전), **여우 꼬리·도깨비불이 양옆으로 퍼지면 폭을 먹어** 높이가 손해다. 그래서 **① 꼬리는 몸 옆/뒤로 모아 실루엣을 좁게 ② 도깨비불은 몸 가까이 작게**. (예: idle에 도깨비불이 양옆으로 들어가 폭 제한 → 70%, 꼬리 펼쳐짐 → 85%.)
> **🔑 검수**: dotify가 출력 후 **높이충전·바닥여백을 자동 리포트**한다(`높이충전 ≥90%`, `바닥여백 ≤4px`). ❌ 뜨면 위 ①②를 손봐 재생성.

```
[Attach: 1 = okja_idle.png — the SD PROPORTION & DOT-STYLE ANCHOR (copy its build), 2 = Miho's real photo — her FACE & identity]

Draw a CUTE SD / CHIBI pixel-art sprite of "Miho", full body, front-facing standing pose.
Take her FACE and IDENTITY from image 2, but COPY the SUPER-DEFORMED body proportions and dot-art style of image 1 (Okja).
Subject: "Miho", a nine-tailed fox (gumiho) MAID at a hell-themed maid cafe — clever, warm and affectionate, a little teasing.
Proportions (MUST MATCH IMAGE 1, the Okja sprite): SUPER-DEFORMED chibi — a BIG ROUND head about ONE THIRD of the
         total height, large expressive eyes, a small compact body and SHORT STUBBY legs. NOT a tall or realistic
         figure, NOT long legs, NOT a normal 5-6-heads-tall girl. Same SD build and on-screen scale as Okja.
Fox features (keep EXACT, from image 2): pointed WHITE FOX EARS with PINK inner on top of the head, and ONE big FLUFFY
         WHITE FOX TAIL (or a few, 1-3) — a gumiho fox-girl. The ears & tail are a clear silhouette point.
Fox face makeup (keep): subtle WHISKER marks on both cheeks, a soft RED / blush accent under the eyes, vermilion lips.
Hair: long, straight, BLACK hair.
Outfit: a Korean traditional gumiho look — a WHITE hanbok-style top (jeogori) with soft white frills
         + a YELLOW skirt, a small maid headpiece tucked between the fox ears (a cafe touch).
Style (MATCH IMAGE 1): 8-bit pixel sprite / dot art, limited palette, hard pixel edges, NO anti-aliasing, NO gradients,
         dot-art shading with 2-3 tones per color (highlight, midtone, shadow) — NOT flat single-tone fills.
Color mood: bright fox-spirit palette — clean WHITE top, warm YELLOW / gold skirt & accents, black hair,
         vermilion lip accent; optional faint blue will-o'-wisp (dokkaebi-bul) spirit flames — keep them SMALL and
         CLOSE to her body (NOT spread out wide to the sides — a narrow silhouette).
Framing: full body centered, head near the TOP edge and feet near the BOTTOM edge, NOT floating; tall vertical 4:9
         portrait ratio, consistent crop across all expressions.
         Lower body and short legs IDENTICAL across all expressions — only the FACE and ARM pose change.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (미호 공통)

```
no text, no watermark, no signature, no multiple characters, no cropped limbs, no cropped tail,
no realistic / normal body proportions, no long legs, no adult tall figure, no 5-6-heads-tall girl,
no small head (the head MUST be ~1/3 of the total height like the Okja anchor), no tiny face,
no baby-only infantile style (keep her cute fox-spirit charm),
no small figure with large empty margins, no floating character above the bottom edge,
no excessive headroom or footroom (head near top, feet on the bottom edge — fill the frame),
no human ears alongside the fox ears (fox ears only), no cat ears (these are FOX ears),
no witch hat (that is Okja — Miho is a gumiho fox), no missing fox ears, no missing tail,
no dark gothic maid dress (her look is a WHITE & YELLOW gumiho), no pink-dominant outfit, no blonde hair (hair is BLACK),
no flat single-tone coloring, no flat shading (must have highlight+midtone+shadow per color),
no smooth vector / cartoon / anime illustration look, no soft airbrushed or blurred cheeks,
no oversimplified low-detail sprite (it must be as detailed and shaded as the Okja sprite),
no background scenery, no gradient background, no soft anti-aliased edges,
no realistic photo finish, no 3D render.
```

### 표정 6종 — 베이스에 한 줄만 추가

**다리·하체·프레이밍·여우 귀/꼬리는 고정**하고, **얼굴 표정 + 팔 자세**만 바꾼다(팔도 그림에 박는다 — 리깅 아님). 꼬리는 감정에 살짝 반응해도 되지만(기쁨=바짝 섬, 시무룩=축 처짐) 위치·개수는 유지. 표정별 사진이 있으면 각각 변환이 더 정확.
> **셰이딩은 6종 전부 베이스 그대로** — 아래 행은 표정·팔만 추가하고, 도트 셰이딩(색마다 2~3톤, flat 금지)·픽셀 규격은 위 공통 베이스를 그대로 따른다. idle만 셰이딩 박고 나머지를 밋밋하게 뽑지 말 것(생성 시 idle 결과를 레퍼로 첨부하면 5종도 톤이 맞는다).

| 파일명 | 추가 문구 |
|---|---|
| `miho_idle`  | `Expression: calm, gentle, mouth closed. Arms: both hands clasped together in front (default). Tail relaxed. NO spirit flames (idle is calm — keep silhouette narrow).` |
| `miho_smile` | `Expression: bright warm smile, eyes gently curved, affectionate. Arms: both hands clasped up near the chest, delighted. Tail perked up happily, faint blue spirit flames around.` |
| `miho_shy`   | `Expression: shy, blushing cheeks (over the red under-eye accent), eyes averted, one fox ear drooping. Arms: one hand raised, covering the mouth.` |
| `miho_sad`   | `Expression: sulky / pouting, downturned mouth, ears lowered (NEVER crying). Arms: lowered and drooping limply. Tail drooping.` |
| `miho_brew`  | `Expression: focused, cheerful "brewing". Arms: holding a sparkling GOLDEN-YELLOW fizzy drink ("Miho Sparkling") in both hands — a tall glass with bubbles, a citrus / gold hue.` |
| `miho_talk`  | `Expression: mouth slightly open, talking warmly. Arms: one hand raised in a gentle gesture.` |

> ⚠️ **6종 전부 팔 자세가 다르다** (다리·하체·프레이밍·여우 귀·꼬리는 고정). 전환은 하드컷이라 팔 차이가 커도 OK. 기쁨 "폴짝" 같은 전신 포즈는 별도로 그리지 않고 `miho_smile`을 리워드 순간에 **코드 hop**으로 재사용한다. 슬픔은 **귀·꼬리 처짐 시무룩까지** — 우는 그림 금지(벌 없는 설계).
> 💧 **`miho_brew` = 미호 스파클링 제조 컷 겸용** — 이슈 #1의 "스파클링 제조 컷"은 별도로 그리지 않고 이 brew 표정(핑크 탄산음료를 든 손)으로 대체한다(옥자 brew와 동일 원리). 음료 연출 강조가 필요하면 brew를 음료 클로즈업으로 한 장 더 뽑되, **데모는 brew 1장으로 충분**.

---

## 미호 탭 미니 초상 (`portrait_miho`)

> 컬렉션북 탭·로스터 선택 화면의 미호 식별 초상. **권장: 생성하지 말고 크롭** — 확정된 `miho_idle.png`에서 **얼굴(여우 귀 포함)을 정사각으로 크롭** → `dotify --size 24x24`. 라이브 미호는 기본 메이드룩이라 idle 얼굴이 탭 정체성과 일치한다.
> 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
Pixel art / dot art tiny SQUARE PORTRAIT bust (face + shoulders), front view, centered, BIG readable face.
Subject: "Miho", a cute nine-tailed FOX gumiho — pointed WHITE FOX EARS (pink inner) on top of the head,
         long black hair, subtle fox whisker makeup with a soft RED under-eye accent, vermilion lips,
         a small maid headpiece, white hanbok-style top with YELLOW / gold accents.
         Clearly a fox spirit (NOT a cat, NOT a witch).
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use rich dot-art shading — 2-3 tones per color (highlight, midtone, shadow), NOT flat single-tone fills.
       True pixel art, NOT a smooth vector / cartoon look. Match the Okja portrait's shading depth.
Color mood: bright WHITE & YELLOW gumiho palette (shaded, not flat), black hair.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

```
[네거티브] no full body, no tiny face, no text, no extra characters, no scenery,
no cat ears (FOX ears), no witch hat, no blonde hair (BLACK hair), no pink-dominant outfit,
no chroma green on the subject, no gradient, no soft anti-aliased edges, no 3D render.
```

---

## 미호 인트로(지뢰계) 의상 체키 (이벤트 의상 1벌)

> 미호 슬라이스의 **인트로 체키** — 온보딩에서 미호를 고르면 주는 첫 체키(→ 이슈 #5, `character-expansion-plan`). 옥자와 동일하게 **지뢰계 데이** 의상이 인트로 슬롯이다. **체키 카드용 정적 아트** — 교감화면 스킨 아님이라 포즈·머리색 자유(라이브 미호는 메이드룩 고정).
> **🔑 워크플로우(옥자 지뢰계와 동일)**: **① 확정된 `miho_idle.png`(SD 도트 — 얼굴·여우 귀/꼬리·정체성·등신비 락) + ② 지뢰계 레퍼런스 사진(의상·머리색·포즈 락)**(+선택 ③ 신발 레퍼)을 첨부하고 "1번 캐릭터를 2번 코디로 다시 그려라". **여우 귀·꼬리는 의상이 바뀌어도 유지**(미호의 핵심 정체성).
> **지뢰계 코디 가이드(실물 레퍼 기준 — `_src/miho_jirai_ref.png`)**: 미호의 지뢰계 데이 룩은 **레오파드 스트릿 갸루** 무드(옥자의 핑크 레이스 지뢰계와 결이 다름). 핵심 = **화이트 오버사이즈 티(레오파드+레드 그래픽, 한쪽 오프숄더) + 레오파드 미니스커트**. **노란 네일·노란 스크런치**가 미호 노랑/골드 시그니처와 자연스레 맞물린다. 머리는 **샴페인/애시 블론드 생머리+일자뱅**(트윈테일 X), 머리 위엔 **검은 리본 달린 둥근/하트 선글라스를 얹음**(안 씀 — 여우 귀는 그 사이로 보이게). 포즈는 **핑거건/V 갸루 셀카**. **여우 귀·꼬리·여우 분장은 유지**(미호 핵심 정체성).

```
[Attach: 1 = miho_idle.png (confirmed SD dot, identity lock), 2 = miho jirai-day reference photo (outfit + pose lock)]
Keep image 1's character IDENTITY: same face, same warm gumiho fox look (WHITE fox ears, whisker makeup,
red under-eye accent), same SD chibi proportions (head:body ≈ 1:3~1:4),
and KEEP her WHITE FOX EARS and big FLUFFY WHITE FOX TAIL (these stay even in the new outfit).
RESTYLE her into her JIRAI-DAY coordinate (image 2) — a LEOPARD-print street GYARU look (cool, sassy, age-safe):
- Hair: long, straight, CHAMPAGNE / ASH-BLONDE (beige blonde) with blunt straight BANGS, worn DOWN (NOT twin-tails).
- Headwear: round / heart-shaped SUNGLASSES with a small black ribbon, pushed UP and resting ON TOP of the head
  (not over the eyes) — placed so the WHITE FOX EARS still show.
- Top: an OVERSIZED WHITE short-sleeve T-SHIRT with a LEOPARD / cheetah-print graphic and RED accents on the front,
  worn OFF-SHOULDER on one side (a thin black camisole strap peeking).
- Bottom: a LEOPARD-print mini skirt with a black waistband.
- Nails: long YELLOW / lime nails. Accessories: a YELLOW wrist scrunchie + a wristwatch, a few rings
  (the yellow nails & band tie into Miho's gold/yellow signature). Lips: red / vermilion.
- Shoes: chunky platform sneakers or boots (feet not in the ref — keep them simple).
- Pose (KEEP from image 2): a sassy GYARU SELFIE — head slightly tilted, one (or both) hand(s) raised beside the face
  making a finger-gun / V sign near the eye, big eyes, cool-cute confident look.
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use rich dot-art shading — 2-3 tones per color (highlight, midtone, shadow) on hair, skin, leopard print,
       skirt and tail; NOT flat single-tone fills. True pixel art, NOT a smooth vector / cartoon look.
       Match the Okja sprite's shading depth and pixel crispness.
       Keep her clearly the SAME Miho (fox ears + tail intact), leopard street-gyaru mood, age-safe.
Framing: FULL body centered (head to shoes all visible, tail not cropped), big head near top, feet near bottom,
         tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (미호 지뢰계 — 공통 네거티브에 더한다)

```
no different face, no extra characters, no cropped feet, no cropped or hidden tail, no missing fox ears,
no cat ears, no witch hat, no original maid dress (it is fully replaced by the jirai-day outfit),
no twin-tails (hair worn DOWN), no beret/cap (sunglasses rest on top of the head instead),
no sunglasses over the eyes (they sit on top of the head), no pink lace girly blouse (this is a leopard street look),
no flat single-tone coloring, no flat shading, no smooth vector / cartoon / anime look, no soft airbrushed cheeks,
no oversimplified low-detail sprite (match the Okja sprite's shading & detail),
no realistic body proportions, no long thin legs, no adult tall figure, no tiny face,
no over-sexualized outfit (keep it cute street-gyaru, age-safe brand).
```

> ⚠️ **검수 포인트**: 체키 카드 안에 들어갈 정적 아트이므로 idle 앵커 일치는 불필요. **얼굴(미호 정체성) + 여우 귀·꼬리 유지 + 신발까지 프레임 안에 다 들어왔는지**를 본다. 또 **레오파드 무늬·블론드 생머리+일자뱅·머리 위 선글라스(얹음)·오프숄더·핑거건 갸루 포즈**가 살았는지 확인. 레오파드·레드 그래픽·옐로 네일은 색이 튀니 후처리 **마스터 팔레트 인덱싱 필수**. 저장: `assets/sprites/miho_jirai.png`.
> 🃏 **체키 합성 레이어**: 미호 지뢰계 체키 = `miho_jirai`(누끼) + **미호 전용 배경 `bg_cheki_miho_jirai`**(아래 신설) + 이벤트 공통 `frame_jirai`(→ [공통 파일](./gemini-prompts-common.md)). **프레임은 이벤트 데이 공통, 배경은 멤버별**(ADR 0003 개정 2026-06-07) — 미호 배경도 네온 야경 팔레트는 유지하되(공통 프레임과 짝) 스팟·연출을 미호 의상에 맞춘다.
> 📌 **이후 이벤트 의상(유치원·힙합·집사·크리스마스 등)은 별도 아트 트랙으로 점증** — 5벌 선결 금지(시온이 선례, → `character-expansion-plan` 슬라이스 DoD). 의상 + 짝 배경(`bg_cheki_miho_{slug}`)을 한 세트로 갈아끼우면 된다.

---

## 미호 지뢰계 체키 사진 배경 (`bg_cheki_miho_jirai`)

> **베이스 = [공통 파일](./gemini-prompts-common.md)의 "체키 사진 배경 — 지뢰계"**(규격 `120×180` 완전 불투명, 누끼 X·크로마 X, 중앙·하단 발치 비움, 도트 보케). **미호의 스팟 = 붉은 홍등(랜턴) 야시장 골목** — 옥자(시부야 큰길)와 확실히 구분되는 미호만의 현장.
> ⚠️ **팔레트 예외(의식적)**: 이벤트 공통 `frame_jirai`는 네온 핑크·퍼플인데, 이 배경은 **따뜻한 붉은 홍등 톤**이라 ADR 0003의 "프레임-배경 팔레트 통일"에서 **의도적으로 벗어난다**(소유자 결정 2026-06-07). 붉은 글로우 + 네온 핑크 프레임이 같은 "밤거리 발광" 계열이라 합성은 성립하되, 정확히 한 세트는 아님을 감안한다.

```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a night MARKET ALLEY strung with glowing RED LANTERNS.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a narrow shopping alley at night — rows of round RED LANTERNS strung overhead, small lit shop fronts and signboards on both sides
      (abstract glyph-like glow, NOT real letters), warm red-amber glow everywhere; soft round BOKEH light orbs in the air.
Depth: dense lanterns and shop signs along the TOP and the two SIDE edges; the CENTER is a softer, blurrier BOKEH haze of red light
      receding down the alley so a standing character reads clearly; the LOWER-CENTER (character's feet area) stays calmer, just a glossy street catching red reflections.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh done as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: warm festival night — deep navy/black sky, glowing lantern RED, warm amber/gold, with a touch of pink to bridge toward the jirai frame.
```

> 네거티브는 [공통 파일](./gemini-prompts-common.md)의 "지뢰계 배경 네거티브" 그대로(특히 **캐릭터·마스코트 없는 순수 풍경** — 의상 누끼가 위에 올라간다). 저장: `assets/sprites/bg_cheki_miho_jirai.png`.

---

## 미호 유치원 의상 체키 (`miho_kinder`)

> **유치원 데이** — 옥자와 한 세트(전원 같은 원아복 코디). **체키 카드용 정적 아트**(포즈·헤어 변주 자유). **여우 귀·꼬리는 의상이 바뀌어도 유지**(미호 핵심 정체성).
> **🔑 코디 가이드(실물 레퍼 확정 — `_src/miho_kinder_ref.png`)**: 머스타드/옐로 **와이드브림 버킷햇** + 흰 **피터팬 라운드 카라**의 **핑크 퍼프소매 원피스**(앞 리본 단추) + 가슴 **빨강 명찰** + 사선으로 멘 **노란 크로스백**(작은 곰 인형 + 빨강 리본 매달림) + 빨강 **하트 귀걸이** + 허리 은색 나비 장식. 헤어는 **긴 생머리 다운**(양손으로 머리 잡은 포즈). 멜·바나와 같은 유치원 세트지만 미호는 **핑크 원피스 + 노란 백 + 곰 인형**으로 구분.

```
[Attach: 1 = miho_idle.png (confirmed SD dot, identity lock), 2 = _src/miho_kinder_ref.png (kindergarten outfit + pose lock)]
Keep image 1's character IDENTITY: same face, same warm gumiho fox look (WHITE fox ears, whisker makeup, red under-eye accent),
keep Miho's OWN hair color from image 1, same SD chibi proportions (head:body ≈ 1:3~1:4),
and KEEP her WHITE FOX EARS and big FLUFFY WHITE FOX TAIL (these stay even in the new outfit).
RESTYLE her into the KINDERGARTEN-DAY coordinate from image 2 — a cute preschool-pupil look (childlike, age-safe):
- Hair: long straight hair worn DOWN with a straight fringe, soft and childlike.
- Headwear: a MUSTARD / golden-YELLOW wide-brim BUCKET HAT, placed so the WHITE FOX EARS still show.
- Top: a PINK long-puff-sleeve smock DRESS with a big WHITE rounded PETER-PAN COLLAR and small RIBBON-bow buttons down the front.
- Badge: a small RED / pink rounded NAME TAG on the chest.
- Bag: a YELLOW cross-body messenger BAG worn diagonally, with a little BEAR plush and a RED ribbon dangling from it.
- Accessories: RED heart-shaped EARRINGS; a small silver butterfly clasp at the waist.
- Pose (KEEP from image 2): both hands lightly holding her own long hair strands beside her face, calm cute look.
- Shoes: WHITE knee socks and small WHITE shoes.
- Expression: calm, slightly pouty-cute innocent face.
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients,
       rich 2-3 tone dot shading (highlight/midtone/shadow) on hair, skin, pink dress and tail; NOT flat single-tone.
       Keep her clearly the SAME Miho (fox ears + tail intact), just dressed as a sweet kindergartener.
Framing: FULL body centered (head to shoes all visible, tail not cropped), big head near top, feet near bottom,
         tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no different face, no missing fox ears, no cropped or hidden tail, no cat ears, no witch hat (it's a yellow bucket hat), no maid outfit (fully replaced by the pink kindergarten dress), no over-mature outfit (keep it childlike & age-safe), no sunglasses, no cropped feet, no flat single-tone coloring.`

> 🃏 **체키 합성 레이어**: 미호 유치원 체키 = `miho_kinder`(누끼) + **미호 전용 배경 `bg_cheki_miho_kinder`**(아래) + 이벤트 공통 `frame_kinder`(→ [공통 파일](./gemini-prompts-common.md)). 저장: `assets/sprites/miho_kinder.png`.

---

## 미호 유치원 체키 사진 배경 (`bg_cheki_miho_kinder`)

> **베이스 = [공통 파일](./gemini-prompts-common.md)의 "체키 사진 배경"**(규격 `120×180` 완전 불투명, 누끼 X·크로마 X, 중앙·하단 발치 비움, 도트 보케). **유치원 데이 공통 톤 = 크레용·무지개·파스텔 유치원**(옥자 배경과 한 세트). **미호의 스팟 = 블록·미끄럼틀이 있는 놀이방 코너**(살짝의 변주만 — 같은 유치원).

```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a bright cheerful KINDERGARTEN PLAYROOM corner.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a sunny preschool play corner — pastel walls with a big crayon-drawn RAINBOW, fluffy clouds and a yellow sun, colorful
      building BLOCKS, a small SLIDE and toy shelves along the sides, paper bunting / flags strung overhead, soft round BOKEH light orbs.
Depth: rainbow, bunting and shelves along the TOP and the two SIDE edges; the CENTER is a softer, blurrier pastel haze so a standing
      character reads clearly; the LOWER-CENTER (character's feet area) stays calmer — a soft play-mat floor.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: warm bright nursery — cream walls, pastel rainbow (red-orange-yellow-green-blue-purple), sky blue, sunny yellow, candy pink.
```

> 네거티브는 [공통 파일](./gemini-prompts-common.md)의 배경 네거티브 그대로(특히 **캐릭터·마스코트 없는 순수 풍경**). 저장: `assets/sprites/bg_cheki_miho_kinder.png`.

---

## 후처리 연결 (미호 — 받은 PNG → 규격 에셋)

> 미호 스탠딩은 옥자와 같은 캔버스(`preset okja` = 128×288)를 쓴다. 캐릭터 레지스트리(#2)가 `miho_*` 경로를 읽는다.

```bash
# 미호 표정 6종 (128×288, 크로마 그린 배경 제거) — idle/smile/shy/sad/brew/talk
tools/.venv/bin/python tools/dotify.py miho_idle_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/miho_idle.png
# (나머지 표정도 파일명만 바꿔 동일하게: miho_smile / miho_shy / miho_sad / miho_brew / miho_talk)

# 미호 인트로 지뢰계 체키 의상 (128×288 — 체키 카드용 정적 아트, 여우 귀·꼬리 유지)
tools/.venv/bin/python tools/dotify.py miho_jirai_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/miho_jirai.png

# 미호 전용 지뢰계 체키 배경 (120×180 완전 불투명 — 누끼 X, 크로마 X)
tools/.venv/bin/python tools/dotify.py bg_cheki_miho_jirai_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_miho_jirai.png

# 미호 유치원 체키 의상 (128×288 — 체키 카드용 정적 아트, 여우 귀·꼬리 유지)
tools/.venv/bin/python tools/dotify.py miho_kinder_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/miho_kinder.png
# 미호 전용 유치원 체키 배경 (120×180 완전 불투명 — 누끼 X, 크로마 X)
tools/.venv/bin/python tools/dotify.py bg_cheki_miho_kinder_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_miho_kinder.png

# 미호 탭 미니 초상 (권장: miho_idle 얼굴 크롭본을 입력으로)
tools/.venv/bin/python tools/dotify.py portrait_miho_raw.png \
  --preset portrait --chroma 00ff00 --out assets/sprites/portrait_miho.png
```

> ⚠️ **이슈 #1 Acceptance criteria 대응**: ① 표정 6장 누끼·규격(~128×288)·마스터 팔레트 32색 인덱싱 → 위 6종 명령 + dotify 검수 리포트 ② `portrait_miho` 임포트·렌더 → 24×24 ③ 미호 지뢰계 체키 의상 레이어 합성 → `miho_jirai` + **미호 배경 `bg_cheki_miho_jirai`** + 이벤트 공통 `frame_jirai` ④ 팔레트 벗어난 픽셀 0 → dotify 인덱싱 통과.
> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
