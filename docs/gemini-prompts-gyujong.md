# Gemini 도트 변환 프롬프트 — 규종이 (미호의 까만 고양이)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**(img2img). 공용 에셋·핵심 원칙은 [공통 파일](./gemini-prompts-common.md) 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))
> **추적 이슈 [#6](https://github.com/JeffKM/Narakuchi/issues/6)** — 펫 규종이 슬라이스(미호 슬라이스의 마지막 단). **확장 트랙 원칙상 아트가 항상 코드보다 먼저**다(→ 메모리 `character-expansion-plan`). 슬라이스 #6 코드 배선이 이 에셋을 기다린다(ROADMAP T33+ · 표 #6 "⛔ 규종이 아트 대기").

> **규종이**: 구미호 메이드 **미호**의 반려묘. 곁의 교감 가능한 펫 + 수집 캐릭터(시온이와 같은 펫 틀 — 게이지만, 관계단계·기분 없음 → `character-expansion-plan`).
> **🔑 실물 레퍼런스 첨부 필수**: `assets/sprites/_src/gyujong_ref.png`(규종이 실물)를 첨부해 **img2img(사진 변환)** 으로 뽑는다 — **흰 얼룩의 위치(눈·코 사이 블레이즈)** 가 정체성이라 텍스트만으론 매번 흔들린다.
> **🔑 얼룩(고정) — 시온이의 거울상**: 시온이가 *흰 바탕+검은 두건*이라면 **규종이는 그 반대 = 까만 바탕(턱시도)+흰 얼룩**이다. 바탕·머리·귀·등·꼬리는 **검정이 메인**, 흰색은 ① **주둥이·턱·가슴(턱받이)** 과 ② **두 눈 사이에서 콧대를 타고 이마로 올라가는 흰 줄(블레이즈)** 에만(= "눈·코 사이 흰 얼룩"). **작은 핑크 코 · 초록 눈 · 흰 수염.** ⚠️ 시온이(흰 고양이)와 헷갈리지 않게 **"까만 고양이"** 임을 못박는다.
> **🔑 누끼 = 크로마 마젠타 `#ff00ff`(중요·시온이와 다름)**: 규종이는 **초록 눈**이라 크로마 그린(`#00ff00`)을 깔면 눈동자가 함께 뚫린다. 그래서 배경 크로마를 **마젠타**로 받고 `dotify --chroma ff00ff`로 분리한다(크리스마스 프레임이 초록 홀리 때문에 마젠타 쓰는 것과 같은 원리). 규종이 몸엔 마젠타·핫핑크 금지.
> **규격**: 펫 라이브 반응 = `96×96`(시온이 `sioni_*`와 동일 캔버스 — 현재 `scripts/sioni.gd` `SPR_SIZE=96×96`). 96px는 AI가 직접 못 그리니 **크게 받아 `dotify --size 96x96`으로 축소** — 동글고 단순한 실루엣으로(작아도 읽히게).

---

## 규종이 (펫 — 교감화면 반응)

> 미호 곁의 까만 고양이. **교감화면 라이브 펫은 항상 기본 까만 고양이**(이벤트 의상은 체키 전용 → 아래 "규종이 인트로 체키").
> 시온이와 **같은 동글동글 SD 펫 실루엣**으로 가야 한 화면에서 한 쌍처럼 읽힌다 — 통통하고 둥근 몸, 짧은 다리, 큰 눈.

```
[Attach: 1 = assets/sprites/_src/gyujong_ref.png — Gyujong's real reference photo, 2 = (optional) assets/sprites/sioni_idle.png — the chubby-round PET SILHOUETTE & dot-style anchor]
Convert the attached cat (image 1) into a CUTE retro pixel art / dot art chibi sprite, front view, sitting. Subject: "Gyujong", Miho's pet cat.
Take the CAT'S IDENTITY (markings, face) from image 1, but match the CHUBBY-ROUND chibi build and dot style of image 2 (the white pet).
Body: CHUBBY and ROUND — a plump, cozy ball-shaped body with short stubby legs, big round eyes, small nose, friendly.
Fur & MARKINGS (keep EXACT — this is a TUXEDO cat, the MIRROR of the white pet):
      - base coat is MOSTLY BLACK. Black covers the HEAD, EARS, BACK and TAIL.
      - WHITE appears ONLY as: (a) the MUZZLE / CHIN / CHEST bib, and (b) a WHITE BLAZE that runs UP BETWEEN THE TWO EYES,
        over the bridge of the nose, toward the forehead (the "white mark between eyes and nose"). Roughly symmetric.
      - a small PINK nose, GREEN eyes, white whiskers.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
Color mood: a BLACK cat with white muzzle + a white center blaze, pink nose, GREEN eyes, against the cafe's dark antique palette.
Background: FLAT SOLID chroma MAGENTA (#ff00ff), nothing else. (Magenta, NOT green — the cat has GREEN eyes that must not be keyed out.)
```

### 네거티브 (규종이)

```
no human, no person, no character besides the cat, no clothes (this is the BASE plain cat),
no MOSTLY-WHITE cat (Gyujong is a BLACK / tuxedo cat — white is ONLY the muzzle/chest + a center blaze),
no black cap / black hood over a white head (that is the OTHER pet — Gyujong is the inverse),
no white over the whole face, no missing white blaze between the eyes,
no chroma magenta on the cat, no pink/magenta fur, no green background (the eyes are green — background is MAGENTA),
no slim / thin / long-legged cat, no text, no watermark, no scenery,
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render.
```

### 반응 4종 — 베이스에 한 줄만 추가 (얼굴·자세만 변경)

| 파일명 | 추가 문구 |
|---|---|
| `gyujong_idle`  | `Pose: sitting calmly, tail curled around the feet, content.` |
| `gyujong_snack` | `Pose: looking UP happily at a treat, mouth open, eager.` |
| `gyujong_play`  | `Pose: playful pounce, front paws up, ears perked.` |
| `gyujong_pet`   | `Pose: eyes closed, blissful, head tilted as if being petted.` |

> 팁: idle 1장을 확정한 뒤 그 결과를 레퍼런스로 첨부해 나머지 3종을 뽑으면 흰 얼룩·체형이 일관된다(시온이 선례).

---

## 규종이 탭 미니 초상 (`portrait_gyujong`)

> 컬렉션북 탭·로스터 선택 화면의 규종이 식별 초상(24×24). 레지스트리가 `portrait_%s.png % id`로 경로를 파생하니 파일명은 **`portrait_gyujong.png`** 고정.
> **권장: 생성하지 말고 크롭** — 확정된 `gyujong_idle.png`에서 **얼굴(검은 머리+흰 블레이즈+코)을 정사각으로, 좌·우·위 여백을 똑같이 두고** 크롭 → `dotify --size 24x24`(초상 슬롯은 "중앙 정렬" 자동 ON). 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
[Attach: 확정된 gyujong_idle.png 또는 assets/sprites/_src/gyujong_ref.png]
Pixel art / dot art tiny SQUARE PORTRAIT bust (cat FACE + a little shoulder), STRICT FRONT view,
PERFECTLY CENTERED with EQUAL margins on the LEFT, RIGHT and TOP — the face must NOT touch or run off any edge,
leave a small even gap on every side.
Subject: "Gyujong", Miho's chubby BLACK / tuxedo cat — base coat MOSTLY BLACK (black head, ears),
       big round GREEN eyes, small PINK nose.
Markings (keep EXACT): WHITE only on the MUZZLE / CHIN and as a WHITE BLAZE running UP BETWEEN THE EYES over the nose
       bridge to the forehead, roughly SYMMETRIC. Clearly a CAT (NOT a fox, NOT a human), the MIRROR of the white pet.
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use 2-3 tones per color (highlight, midtone, shadow), NOT flat single-tone fills. Match the Okja/Miho/Sioni portrait shading depth.
Color mood: black fur with a white muzzle + center blaze, pink nose, green eyes.
Background: FLAT SOLID chroma MAGENTA (#ff00ff), nothing else. (Magenta, NOT green — the eyes are green.)
```

```
[네거티브] no off-center / left-shifted face, no face touching or cropped by ANY edge,
no full body, no tiny face with huge empty margins, no text, no extra characters, no scenery,
no fox ears (this is a CAT), no mostly-white head (Gyujong is a BLACK cat — white is only muzzle + center blaze),
no chroma magenta on the cat, no green background (green eyes — key is MAGENTA),
no gradient, no soft anti-aliased edges, no 3D render.
```

---

## 규종이 인트로(지뢰계) 체키 (베이크 컷 1벌)

> 규종이 슬라이스의 **인트로 체키** — 미호를 고르면 받는 인트로 체키 라인의 펫 짝(미호 `intro_event="mine"` = 지뢰계). 펫은 시온이와 같이 **배경 포함 베이크 사진**으로 굽는다(누끼 3겹 합성 X) — `Events.cheki_photo_path("gyujong","mine")` = **`photo_gyujong_jirai.png`**.
> **🔑 규격(시온이 체키와 동일)**: **카드 풀사이즈 `120×180`(2:3) 완전 불투명**(누끼 X·크로마 X). 고양이 **전신이 잘리지 않게** 화면 안에 두고, 발치(하단 중앙)는 비교적 비워 캐릭터가 읽히게, 풍경 디테일은 위·옆으로 민다.
> **🔑 무드 = 파스텔 핑크 "마이멜로디풍" 지뢰계(유메카와)**: 규종이의 지뢰계 데이 룩은 **핑크 바니 후드 + 프릴 로리타 드레스**의 *꿈꾸는 듯 귀여운(yumekawa)* 결 — 옥자(핑크 레이스)·미호(레오파드 갸루)·시온이(쿠로미 블랙)와 확실히 구분되는 규종이만의 톤. **배경도 같은 무드의 파스텔 핑크 카페 거리**라 의상과 한 장으로 어우러진다. ⚠️ 미호(붉은 홍등)·옥자/시온이(네온 밤거리)와 **톤이 다른 건 의도**(소유자 결정 2026-06-08) — 규종이는 낮·파스텔.
> **🔑 IP 회피(쿠로미 선례와 동일)**: 산리오 **마이멜로디를 직접 베끼지 말고** 그 *분위기*만 — **일반 핑크 토끼** 실루엣·후드로(특정 캐릭터 재현 X), 간판은 **읽히는 브랜드명 없이 추상 글로우**로. 데모 브랜드 안전.
> **🔑 워크플로우**: 확정된 `gyujong_idle`(정체성 락) + **`_src/gyujong_jirai_ref.png`**(핑크 마이멜로디 의상+장면 레퍼)를 첨부해 "이 까만 고양이에게 이 핑크 바니 코디를 입혀 **이 파스텔 핑크 카페 거리 앞에서 찍은 한 장**으로". **흰 얼룩(블레이즈)·초록 눈은 의상이 바뀌어도 유지.**
> **지뢰계 코디 가이드(레퍼 기준 — `_src/gyujong_jirai_ref.png`)**: ① **핑크 바니 후드**(길게 늘어진 토끼 귀 — 바깥 핑크/안쪽 크림, 옆에 작은 리본·하트 + 레이스 프릴, 그 안으로 까만 얼굴·흰 주둥이·초록 눈이 보임) ② **프릴 핑크 로리타/유메카와 드레스**(층층 러플 스커트 + 하트·레이스·리본, 하트 프린트 앞치마) ③ 포즈 = **두 앞발 모아 수줍게**(레퍼처럼), 까만 꼬리는 옆으로. 파스텔 핑크·귀엽고 age-safe.

```
[Attach: 1 = gyujong_idle.png (confirmed cat, identity lock), 2 = _src/gyujong_jirai_ref.png (pink bunny-hood costume + pastel cafe scene reference)]
ONE baked PHOTO (cheki snapshot): a PINK "dreamy-cute" (yumekawa) JIRAI-KEI costumed BLACK cat sitting in front of a PASTEL-PINK CUTE CAFE STREET. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's CAT identity: the SAME CHUBBY round BLACK / tuxedo cat with her EXACT markings
(mostly BLACK head/ears/back/tail; WHITE only on the muzzle/chest and a WHITE BLAZE up between the eyes; small pink nose, GREEN eyes), same face — peeking out from inside the hood.
Costume — dress it in a PINK BUNNY yumekawa / jirai outfit (cute-gothic, age-safe):
- a soft PINK BUNNY HOOD / bonnet with LONG DROOPY BUNNY EARS (pink outside, cream inside), a small PINK BOW or HEART and lace frill at one side, framing the cat's tuxedo face,
- a frilly PINK LOLITA dress — a tiered RUFFLED skirt with hearts, lace and ribbon trim, a little heart-print apron,
- both front PAWS clasped together in front, shy and sweet; the BLACK TAIL curling out to one side.
  Clearly the SAME cat, just costumed. A cute pink BUNNY vibe — NOT a copy of any trademark character.
Background (baked in): a dreamy PASTEL-PINK cute CAFE STREET / shopping arcade in soft daylight — pink storefronts (a cafe and a sweet shop, with ABSTRACT glyph-like signs, NOT real letters or brand names),
  round PINK BUNNY-FACE paper LANTERNS strung overhead, HEART-shaped pennant bunting and string lights across the top, candy-pink awnings, a pastel pink cobblestone path, a few floating hearts and soft round BOKEH orbs;
  detailed along the TOP and SIDES, a softer blurrier bokeh haze in the CENTER, a calmer pink path in the LOWER-CENTER (feet area).
Composition: the FULL cat (whole body, NOT cropped) sits in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & lights as clusters of flat stepped pixels.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green or magenta anywhere.
Color mood: dreamy pastel pink (yumekawa jirai), soft daylight — candy pink, rose, blush, cream, white lace, with mint & lavender accents and a touch of gold; the black-and-white tuxedo cat pops against the pink.
```

### 네거티브 (규종이 체키 사진)

```
no human, no person, no second character (no Miho in frame), no text, no watermark, no logo, no QR code,
no readable signage, no real words, no brand name, no exact Sanrio / My Melody character copy (generic pink BUNNY vibe only),
no NIGHT scene, no dark navy/black background, no red lanterns (this is a PASTEL PINK daylight street),
no photo frame, no card border, no polaroid edge (frames are separate overlay layers — this pet cheki is a baked photo),
no mostly-white cat (Gyujong is BLACK / tuxedo with a white blaze + green eyes), no missing white blaze, no hidden face inside the hood,
no cropped cat (the whole body must be inside the frame),
no chroma green, no chroma magenta, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the cat, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① 까만 턱시도 정체성(흰 블레이즈·초록 눈)이 **핑크 후드 안에서** 또렷한지 ② **`120×180`(2:3) 완전 불투명**(투명·크로마 한 픽셀도 없어야) ③ 고양이 **전신이 안 잘리고** 중앙에 읽히는지(발치 비움), 배경은 **평면 패턴이 아닌 파스텔 핑크 카페 거리 풍경**인지 ④ 간판이 **읽히는 글자·브랜드명이 아닌** 추상 글로우, 바니 마스코트/랜턴이 **일반 핑크 토끼**(산리오 직카피 X)인지 ⑤ 마스터 팔레트(~32색) 인덱싱 — ⚠️ **파스텔 핑크가 다수**라 팔레트에 핑크 톤이 충분한지 확인(부족하면 인덱싱에서 뭉개짐 → 필요 시 핑크 1~2색 보강 검토). 저장: `assets/sprites/photo_gyujong_jirai.png`.
> 🃏 **프레임 짝(중요)**: 펫 베이크 컷에도 `cheki_card`가 **이벤트 공통 프레임을 항상 덧씌운다**(`_frame.texture`). 인트로=**일반체키**라 프레임 = `frame_standard`(크라프트/세피아) → 따뜻한 톤이라 핑크와 무난. 단 **나비 승급** 시 `frame_jirai`(네이비·네온 핑크/퍼플)와는 톤이 부딪치니, 핑크 무드 유지하려면 **핑크 프레임 변주(`frame_jirai` 핑크판)** 를 후속으로 검토(이 체키 프롬프트 범위 밖).
> 📌 **이후 이벤트 체키(xmas 등)는 별도 아트 트랙으로 점증** — 펫은 베이크 컷 모델이라 의상+배경을 한 장으로 다시 구우면 된다(시온이 `photo_sion_xmas` 선례).

---

## 규종이 크리스마스 체키 (베이크 컷 1벌)

> 규종이의 **크리스마스(xmas) 데이 체키** — `Events.cheki_photo_path("gyujong","xmas")` = **`photo_gyujong_xmas.png`**. 펫 베이크 컷 모델이라 의상+배경을 한 장으로 다시 굽는다(지뢰계 선례와 동일 파이프라인). `data/events.gd`의 xmas 행에 `"gyujong": true` 플래그가 켜져 있어야 컬렉션북에 칸이 뜬다(이번 작업에서 켬).
> **🔑 규격(시온이·규종이 지뢰계 체키와 동일)**: **카드 풀사이즈 `120×180`(2:3) 완전 불투명**(누끼 X·크로마 X). 고양이 **전신이 잘리지 않게** 화면 안에 두고, 발치(하단 중앙)는 비교적 비워 캐릭터가 읽히게, 풍경 디테일은 위·옆으로 민다.
> **🔑 컨셉 = 호두까기 인형 병정(Nutcracker soldier)**: 옥자(산타)·시온이(루돌프)와 겹치지 않는 규종이만의 크리스마스 아키타입 — **도도·격식 있는 턱시도 고양이**라 병정 제복(빨강·금)이 흑백 정체성과 자연스럽게 맞는다. 빳빳한 차렷 포즈로 나무 장난감 병정 같은 격식.
> **🔑 워크플로우**: 확정된 `gyujong_idle`(정체성 락) + **`_src/gyujong_xmas_ref.png`**(호두까기 병정 의상 레퍼, 있으면)를 첨부해 "이 까만 고양이에게 이 병정 코디를 입혀 **이 크리스마스 장난감 가게 쇼윈도 앞에서 찍은 한 장**으로". **흰 얼룩(블레이즈)·초록 눈은 의상이 바뀌어도 유지.**

```
[Attach: 1 = gyujong_idle.png (confirmed cat, identity lock), 2 = _src/gyujong_xmas_ref.png (nutcracker-soldier costume reference, if available)]
ONE baked PHOTO (cheki snapshot): a NUTCRACKER-SOLDIER costumed BLACK / tuxedo cat standing at attention in front of a CHRISTMAS TOY-SHOP WINDOW. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's CAT identity: the SAME CHUBBY round BLACK / tuxedo cat with her EXACT markings
(mostly BLACK head/ears/back/tail; WHITE only on the muzzle/chest and a WHITE BLAZE up between the eyes; small pink nose, GREEN eyes), same face — peeking out from under the tall hat.
Costume — dress it as a cute NUTCRACKER SOLDIER (toy-soldier charm, age-safe):
- a tall BLACK & GOLD shako / busby hat with a small WHITE feather plume and a gold chin strap,
- a bright RED soldier jacket with GOLD epaulettes, a double row of GOLD buttons and gold brandenburg cord trim, a small navy/white collar,
- tiny white-gloved front paws, a STIFF at-attention pose like a wooden toy. Clearly the SAME tuxedo cat, just costumed.
Background (baked in): a cozy CHRISTMAS TOY-SHOP WINDOW / little stage — rows of wooden NUTCRACKER dolls, wind-up toys and stacked wrapped PRESENTS, a gold STAR garland and warm string lights, a glowing display-case;
  detailed along the TOP and SIDES, a softer bokeh haze in the CENTER, a calm toy-shelf floor at the bottom.
Composition: the FULL cat (whole body, NOT cropped) stands in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & lights as clusters of flat stepped pixels.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green or magenta anywhere.
Color mood: festive nutcracker — soldier RED & GOLD, navy accents, warm amber display light, pine green and a white feather; the black-and-white tuxedo cat pops in the middle.
```

### 네거티브 (규종이 크리스마스 체키)

```
no human, no person, no second character (no Miho in frame), no text, no watermark, no logo, no QR code,
no readable signage, no real words, no brand name,
no NEON night street, no pastel-pink scene (this is a warm CHRISTMAS TOY-SHOP window),
no photo frame, no card border, no polaroid edge (frames are separate overlay layers — this pet cheki is a baked photo),
no mostly-white cat (Gyujong is BLACK / tuxedo with a white blaze + green eyes), no missing white blaze, no hidden face under the hat,
no Santa suit (that is Okja), no reindeer antlers (that is Sion), no cropped cat (the whole body must be inside the frame),
no chroma green, no chroma magenta, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the cat, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① 까만 턱시도 정체성(흰 블레이즈·초록 눈)이 **병정 모자/제복 안에서** 또렷한지 ② **`120×180`(2:3) 완전 불투명**(투명·크로마 한 픽셀도 없어야) ③ 고양이 **전신이 안 잘리고** 중앙에 읽히는지(발치 비움), 배경은 **평면 패턴이 아닌 장난감 가게 쇼윈도 풍경**인지 ④ 간판이 **읽히는 글자·브랜드명이 아닌** 추상 글로우인지 ⑤ 마스터 팔레트 인덱싱 — ⚠️ **빨강·금·네이비·파인그린** 커버가 충분한지 확인(부족하면 인덱싱에서 뭉개짐 → 필요 시 보강 검토). 저장: `assets/sprites/photo_gyujong_xmas.png`.
> 🃏 **프레임 짝**: 펫 베이크 컷에도 `cheki_card`가 이벤트 공통 프레임을 덧씌운다. 일반 = `frame_standard`(크라프트/세피아), **나비 승급** 시 `frame_xmas`(눈·리스) — 병정 빨강·금과 톤이 잘 맞는다.

---

## 후처리 연결 (규종이 — 받은 PNG → 규격 에셋)

```bash
# 규종이 펫 반응 4종 (96×96, 크로마 마젠타 제거 — 초록 눈 보호) — idle/snack/play/pet
tools/.venv/bin/python tools/dotify.py gyujong_idle_raw.png \
  --size 96x96 --chroma ff00ff --out assets/sprites/gyujong_idle.png
tools/.venv/bin/python tools/dotify.py gyujong_snack_raw.png \
  --size 96x96 --chroma ff00ff --out assets/sprites/gyujong_snack.png
tools/.venv/bin/python tools/dotify.py gyujong_play_raw.png \
  --size 96x96 --chroma ff00ff --out assets/sprites/gyujong_play.png
tools/.venv/bin/python tools/dotify.py gyujong_pet_raw.png \
  --size 96x96 --chroma ff00ff --out assets/sprites/gyujong_pet.png

# 규종이 인트로 지뢰계 체키 (배경 포함 베이크 — 120×180 불투명, 누끼 X·크로마 X)
tools/.venv/bin/python tools/dotify.py photo_gyujong_jirai_raw.png \
  --size 120x180 --out assets/sprites/photo_gyujong_jirai.png

# 규종이 크리스마스 체키 (호두까기 병정 — 배경 포함 베이크, 120×180 불투명)
tools/.venv/bin/python tools/dotify.py photo_gyujong_xmas_raw.png \
  --size 120x180 --out assets/sprites/photo_gyujong_xmas.png

# 규종이 탭 미니 초상 (권장: gyujong_idle 얼굴 크롭본을 입력으로 — 초상 슬롯 중앙 정렬 자동)
tools/.venv/bin/python tools/dotify.py portrait_gyujong_raw.png \
  --size 24x24 --chroma ff00ff --out assets/sprites/portrait_gyujong.png
```

> ⚠️ **슬라이스 #6 코드분 대응(아트 확정 후)**: ① 펫 반응 4컷 누끼·`96×96`·마스터 팔레트 32색 → 위 4종 명령 + dotify 검수 ② `portrait_gyujong` 임포트·렌더 → 24×24 ③ 인트로 체키 베이크 → `photo_gyujong_jirai` ④ `data/characters.gd` 레지스트리에 `gyujong` 펫 항(`kind=PET`, `intro_event="mine"`, accent) 추가 + 펫 라이브 스프라이트 경로(`scripts/sioni.gd` 하드코딩 일반화 또는 `gyujong.gd`) 배선.
> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
