# Gemini 도트 변환 프롬프트 — 선아 (멜의 갈색 푸들)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물/일러스트 → AI 도트화**(img2img). 공용 에셋·핵심 원칙은 [공통 파일](./gemini-prompts-common.md) 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))
> **확장 트랙 — 멜 슬라이스의 펫 단(2마리 중 1).** 짝꿍 수아는 [수아 파일](./gemini-prompts-sua.md). 확장 트랙 원칙상 **아트가 항상 코드보다 먼저**다(→ 메모리 `character-expansion-plan`).

> **선아 (Suna)**: 강시 메이드 **멜**의 반려견 — **갈색(카라멜) 푸들**. 곁의 교감 가능한 펫 + 수집 캐릭터(시온이·규종이·코코와 같은 펫 틀 — 게이지만, 관계단계·기분 없음 → `character-expansion-plan`).
> **🔑 레퍼런스 첨부 필수**: `assets/sprites/_src/suna_ref.png`(선아 레퍼)를 첨부해 **img2img** 로 뽑는다. (레퍼가 이미 귀여운 일러스트 톤이라 도트화가 수월하다.)
> **🔑 정체성(고정) — 레퍼 기준**: 선아는 **카라멜/골든 브라운 곱슬 푸들** — 머리·귀·몸 전체가 **복슬복슬한 갈색 곱슬털**(특히 **둥근 곱슬 머리뭉치**가 시그니처), 큰 **둥근 갈색 눈**, 작은 **갈색/짙은 코**. ⚠️ **수아(베이지 장모 닥스훈트, 늘어진 긴 귀·긴 몸통)와 명확히 구분** — 선아는 *둥근 곱슬 푸들*이다.
> **🔑 체형 = "동글 복슬 SD 펫"**: 시온이·규종이의 **통통 동글 SD 틀**을 따른다(코코만 슬림 예외 — 선아는 슬림 아님). 큰 머리·큰 눈·짧은 다리의 치비 + **푸들 특유의 곱슬 볼륨**(머리뭉치·다리 끝 퐁퐁).
> **🔑 누끼 = 크로마 그린 `#00ff00`**: 갈색 털이라 그린 크로마가 안전(눈·털 안 뚫림). `dotify --chroma 00ff00`.
> **규격**: 펫 라이브 반응 = `96×96`(시온이·규종이·코코와 동일 캔버스). 96px는 AI가 직접 못 그리니 **크게 받아 `dotify --size 96x96`으로 축소** — 동글고 단순한 실루엣으로(작아도 읽히게, 곱슬 볼륨·큰 눈 유지).

---

## 선아 (펫 — 교감화면 반응)

> 멜 곁의 갈색 푸들. **교감화면 라이브 펫은 항상 기본 갈색 푸들**(이벤트 의상은 체키 전용 → 아래 "선아 인트로 체키").
> 시온이·규종이·코코와 **같은 SD 펫 실루엣 스케일**로 가야 한 화면에서 한 쌍처럼 읽힌다 — 큰 머리·큰 눈·짧은 다리의 치비.

```
[Attach: 1 = assets/sprites/_src/suna_ref.png — Suna's reference, 2 = (optional) assets/sprites/sioni_idle.png — the SD PET SILHOUETTE & dot-style anchor]
Convert the attached dog (image 1) into a CUTE retro pixel art / dot art chibi sprite, front view, sitting. Subject: "Suna", Mel's pet dog.
Take the DOG'S IDENTITY (colour, breed, face) from image 1, but match the SD chibi build and dot style of image 2 (the white cat pet) — same big head, big eyes, short legs SD scale.
Body: an SD chibi POODLE with a BIG round head and big eyes, short stubby legs. KEEP the poodle's fluffy CURLY volume — a round CURLY top-knot of fur on the head and little fluffy poofs at the legs/tail.
Fur & COLOUR (keep EXACT — a CARAMEL / golden-BROWN curly poodle):
      - the coat is fluffy CURLY CARAMEL / golden-brown everywhere — head, ears, body and legs all warm brown curls.
      - big round BROWN eyes, a small DARK-brown nose.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, dot-art shading with 2-3 tones (a warm brown midtone + darker brown shadow + a light cream highlight on the curls so the fluffy texture reads — NOT a flat brown blob).
Color mood: a fluffy caramel-brown curly poodle with big brown eyes, against the cafe's warm antique palette.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

### 네거티브 (선아)

```
no human, no person, no character besides the dog, no clothes (this is the BASE plain dog),
no LONG body / no short legs dachshund shape (that is Sua — Suna is a ROUND curly POODLE),
no long droopy hound ears (poodle ears are part of the curly fluff), no straight smooth fur (the fur is CURLY & fluffy),
no white / cream coat (Suna is CARAMEL / golden-BROWN), no cat (this is a DOG),
no chroma green on the dog itself, no flat single-brown silhouette with no detail (use highlights so the curls read),
no long realistic body proportions, no text, no watermark, no scenery,
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render.
```

### 반응 4종 — 베이스에 한 줄만 추가 (얼굴·자세만 변경)

| 파일명 | 추가 문구 |
|---|---|
| `suna_idle`  | `Pose: sitting calmly, content, big brown eyes calm, a small happy mouth.` |
| `suna_snack` | `Pose: looking UP happily at a treat, mouth open, eager, eyes wide, maybe a paw lifted.` |
| `suna_play`  | `Pose: playful bouncy stance, front paws up, ears/curls perked, tongue out happily.` |
| `suna_pet`   | `Pose: eyes closed (happy squint), blissful, head tilted up as if being petted.` |

> 팁: idle 1장을 확정한 뒤 그 결과를 레퍼런스로 첨부해 나머지 3종을 뽑으면 카라멜 곱슬 톤·큰 눈이 일관된다(시온이·규종이·코코 선례).

---

## 선아 탭 미니 초상 (`portrait_suna`)

> 컬렉션북 탭·로스터 선택 화면의 선아 식별 초상(24×24). 레지스트리가 `portrait_%s.png % id`로 경로를 파생하니 파일명은 **`portrait_suna.png`** 고정.
> **권장: 생성하지 말고 크롭** — 확정된 `suna_idle.png`에서 **얼굴(곱슬 머리뭉치 포함)을 정사각으로, 좌·우·위 여백을 똑같이 두고** 크롭 → `dotify --size 24x24`(초상 슬롯은 "중앙 정렬" 자동 ON). 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
[Attach: 확정된 suna_idle.png 또는 assets/sprites/_src/suna_ref.png]
Pixel art / dot art tiny SQUARE PORTRAIT bust (dog FACE + a little shoulder), STRICT FRONT view,
PERFECTLY CENTERED with EQUAL margins on the LEFT, RIGHT and TOP — the face must NOT touch or run off any edge,
leave a small even gap on every side.
Subject: "Suna", Mel's CARAMEL / golden-BROWN curly POODLE — a round CURLY fluff head,
       big round BROWN eyes, a small dark nose. Clearly a fluffy POODLE (NOT a dachshund, NOT a cat, NOT a fox).
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use 2-3 tones (warm brown midtone + darker shadow + cream highlight) so the curls read — NOT a flat brown blob.
       Match the Sioni/Gyujong/Coco portrait shading depth.
Color mood: caramel-brown curly fur, big brown eyes, dark nose.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

```
[네거티브] no off-center / left-shifted face, no face touching or cropped by ANY edge,
no full body, no tiny face with huge empty margins, no text, no extra characters, no scenery,
no dachshund long ears/body (this is a POODLE), no straight fur (CURLY), no white/cream coat (CARAMEL BROWN),
no cat, no fox, no chroma green on the dog, no flat brown blob with no detail, no gradient, no soft anti-aliased edges, no 3D render.
```

---

## 선아 인트로(지뢰계) 체키 (베이크 컷 1벌)

> 선아의 **인트로 체키** — 멜을 고르면 받는 인트로 체키 라인의 펫 짝(멜 `intro_event="mine"` = 지뢰계). 펫은 시온이·규종이·코코와 같이 **배경 포함 베이크 사진**으로 굽는다(누끼 3겹 합성 X) — `Events.cheki_photo_path("suna","mine")` = **`photo_suna_jirai.png`**.
> **🔑 규격(코코 체키와 동일)**: **카드 풀사이즈 `120×180`(2:3) 완전 불투명**(누끼 X·크로마 X). 강아지 **전신이 잘리지 않게** 화면 안에 두고, 발치(하단 중앙)는 비교적 비워 캐릭터가 읽히게, 풍경 디테일은 위·옆으로 민다.
> **🔑 무드 = 동양/차이나 강시 지뢰계(청록 야경)**: 선아의 지뢰계 데이 룩은 **블루·틸 부적/차이나 모티프**의 *오리엔탈 지뢰계* 결 — 옥자(핑크)·미호(레오파드)·바나/코코(다크 퍼플)와 구분되는 멜/선아만의 톤. **주인 멜의 지뢰계와 같은 청록/시안 네온·옥빛 등롱 동양 야경**을 배경으로 깔아 한 장으로 어우러진다(멜 `bg_cheki_mel_jirai`와 짝 무드).
> **🔑 워크플로우**: 확정된 `suna_idle`(정체성 락) + **`_src/suna_jirai_ref.png`**(부적 후드 의상+장면 레퍼, 있으면)를 첨부해 "이 갈색 푸들에게 이 동양 강시 코디를 입혀 **이 청록 동양 야경 앞에서 찍은 한 장**으로". **카라멜 곱슬·갈색 눈은 의상이 바뀌어도 유지.**
> ⚠️ **선아 지뢰계 레퍼 사진 준비 필요** — `assets/sprites/_src/suna_jirai_ref.png`. 없으면 아래 코디 가이드 텍스트만으로 시도.
> **지뢰계 코디 가이드(권장)**: ① **블루/틸 부적 후드/보닛**(작은 부적(符)·매듭·홍실 + 레이스 프릴, 그 안으로 갈색 곱슬 얼굴·갈색 눈이 보임) ② **틸·블루 프릴 차이나 미니 케이프/드레스**(만다린 칼라·매듭 단추 + 동전·하트 트림, 작은 부적 프린트) ③ 포즈 = **두 앞발 모아 귀엽게**, 곱슬 꼬리는 옆으로. 청록·귀엽고 age-safe.

```
[Attach: 1 = suna_idle.png (confirmed dog, identity lock), 2 = _src/suna_jirai_ref.png (oriental talisman costume + teal night scene reference, if available)]
ONE baked PHOTO (cheki snapshot): an ORIENTAL JIANGSHI JIRAI-KEI costumed CARAMEL-BROWN curly POODLE sitting in front of a TEAL CHINATOWN NIGHT STREET. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's DOG identity: the SAME fluffy CARAMEL / golden-BROWN curly poodle with her EXACT look
(curly brown fur everywhere, round curly top-knot; big BROWN eyes, small dark nose), same face — peeking out from inside the hood.
Costume — dress her in a BLUE & TEAL oriental-talisman yumekawa / jirai outfit (cute, age-safe):
- a BLUE / TEAL HOOD / bonnet with cute TALISMAN (fu charm) tags, Chinese KNOTS and a small RED-string charm, lace frill at one side, framing the dog's curly brown face,
- a frilly TEAL & BLUE china-motif cape/dress — a mandarin collar with frog buttons, coin & heart trim, a little talisman-print apron,
- both front PAWS clasped together in front, chic and sweet; the curly TAIL curling out to one side.
  Clearly the SAME caramel poodle, just costumed. A cute oriental jiangshi vibe.
Background (baked in): a dreamy TEAL CHINATOWN cute CAFE STREET at night — dark storefronts with TEAL & cyan NEON glow (ABSTRACT glyph-like signs, NOT real letters or brand names),
  rows of round JADE-GREEN & red paper LANTERNS strung overhead, a pale FULL MOON, hanging RED-string charms, HEART pennant bunting and string lights across the top, oriental awnings, a dark cobblestone path, a few floating hearts and soft round BOKEH orbs;
  detailed along the TOP and SIDES, a softer blurrier bokeh haze in the CENTER, a calmer dark path in the LOWER-CENTER (feet area).
Composition: the FULL dog (whole body, NOT cropped) sits in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & lights as clusters of flat stepped pixels. The brown poodle keeps warm highlights so the curly texture reads against the dark scene.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green or magenta anywhere.
Color mood: oriental jirai (chinatown night) — deep navy/black, electric TEAL & cyan, hot pink & jade-green accents, pale moon white, orange & red touches; the caramel poodle reads via warm highlights and her big brown eyes.
```

### 네거티브 (선아 체키 사진)

```
no human, no person, no second character (no Mel in frame), no text, no watermark, no logo, no QR code,
no readable signage, no real words, no brand name,
no DAYLIGHT / pastel-pink scene (this is a TEAL CHINATOWN NIGHT street), no bright sunny background,
no photo frame, no card border, no polaroid edge (frames are separate overlay layers — this pet cheki is a baked photo),
no dachshund long body/ears (Suna is a curly POODLE), no straight fur, no white/cream coat (CARAMEL BROWN), no cat, no hidden face inside the hood,
no flat brown blob dog (keep warm highlights so the curls read), no cropped dog (the whole body must be inside the frame),
no chroma green, no chroma magenta, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the dog, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① 카라멜 곱슬 정체성(둥근 곱슬·갈색 눈)이 **틸 부적 후드 안에서** 또렷한지 ② **`120×180`(2:3) 완전 불투명**(투명·크로마 한 픽셀도 없어야) ③ 강아지 **전신이 안 잘리고** 중앙에 읽히는지(발치 비움), 배경은 **평면 패턴이 아닌 청록 동양 야경 풍경**인지 ④ 간판이 **읽히는 글자·브랜드명이 아닌** 추상 글로우인지 ⑤ 마스터 팔레트 인덱싱 — ⚠️ **블루·틸이 다수**라 팔레트에 청록 톤이 충분한지 확인. 저장: `assets/sprites/photo_suna_jirai.png`.
> 🃏 **프레임 짝**: 펫 베이크 컷에도 `cheki_card`가 **이벤트 공통 프레임을 항상 덧씌운다**(`_frame.texture`). 인트로=**일반체키**라 프레임 = `frame_standard`(크라프트/세피아). 나비 승급 시 `frame_jirai`(네이비·네온)와도 짝이 맞는다.
> 📌 **이후 이벤트 체키(xmas 등)는 별도 아트 트랙으로 점증** — 펫은 베이크 컷 모델이라 의상+배경을 한 장으로 다시 구우면 된다.

---

## 선아 크리스마스 체키 (베이크 컷 1벌)

> 선아의 **크리스마스(xmas) 데이 체키** — `Events.cheki_photo_path("suna","xmas")` = **`photo_suna_xmas.png`**. 펫 베이크 컷 모델이라 의상+배경을 한 장으로 다시 굽는다(지뢰계 선례와 동일). `data/events.gd`의 xmas 행에 `"suna": true` 플래그가 켜져 있어야 컬렉션북 칸이 뜬다(이번 작업에서 켬).
> **🔑 규격(선아 지뢰계 체키와 동일)**: **카드 풀사이즈 `120×180`(2:3) 완전 불투명**(누끼 X·크로마 X). 강아지 **전신이 잘리지 않게** 화면 안에 두고, 발치(하단 중앙)는 비교적 비워 캐릭터가 읽히게, 풍경 디테일은 위·옆으로 민다.
> **🔑 컨셉 = 진저브레드 쿠키(Gingerbread)**: 옥자(산타)·시온이(루돌프)와 겹치지 않는 선아만의 크리스마스 아키타입 — **카라멜/갈색 곱슬털 = 쿠키 반죽**이라는 선아의 정체성을 그대로 살린다. 곱슬 가장자리에 흰 아이싱을 두른 해맑은 진저브레드 강아지. 짝꿍 수아(캔디케인)와 달콤한 한 쌍.
> **🔑 워크플로우**: 확정된 `suna_idle`(정체성 락) + **`_src/suna_xmas_ref.png`**(진저브레드 의상 레퍼, 있으면)를 첨부해 "이 갈색 푸들을 진저브레드 쿠키처럼 꾸며 **이 진저브레드 하우스 베이커리 앞에서 찍은 한 장**으로". **카라멜 곱슬·갈색 눈은 의상이 바뀌어도 유지.**

```
[Attach: 1 = suna_idle.png (confirmed dog, identity lock), 2 = _src/suna_xmas_ref.png (gingerbread-cookie costume reference, if available)]
ONE baked PHOTO (cheki snapshot): a GINGERBREAD-COOKIE costumed CARAMEL-BROWN curly POODLE standing in front of a cozy GINGERBREAD-HOUSE BAKERY. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's DOG identity: the SAME fluffy CARAMEL / golden-BROWN curly poodle with her EXACT look
(curly brown fur everywhere, round curly top-knot; big BROWN eyes, small dark nose), same face — the warm brown curls read like gingerbread dough.
Costume — decorate her as a cute GINGERBREAD COOKIE (age-safe, sweet):
- WHITE icing ZIGZAG trim piped along the edges of her curls (ears, chest, legs), round RED & GREEN gumdrop buttons down the front, little icing-heart cheeks,
- a tiny SANTA HAT or an icing BOW on the head, a happy tongue peeking out. Clearly the SAME caramel poodle, just decorated like a cookie.
Background (baked in): a cozy GINGERBREAD-HOUSE BAKERY / candy village — a candy-roof gingerbread house with white-icing eaves, PEPPERMINT-stick posts, shelves of cookies and a warm OVEN glow, gently floating powdered-sugar snow and string lights;
  detailed along the TOP and SIDES, a softer bokeh haze in the CENTER, a calm bakery floor at the bottom.
Composition: the FULL dog (whole body, NOT cropped) stands in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & lights as clusters of flat stepped pixels. The brown poodle keeps warm highlights so the curly texture reads.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green or magenta anywhere.
Color mood: warm gingerbread bakery — toasty cookie BROWN, white icing, red & green gumdrops, caramel and cream, warm oven amber.
```

### 네거티브 (선아 크리스마스 체키)

```
no human, no person, no second character (no Mel in frame), no text, no watermark, no logo, no QR code,
no readable signage, no real words, no brand name,
no NIGHT neon street, no teal chinatown scene (this is a warm GINGERBREAD BAKERY), no pastel-pink scene,
no photo frame, no card border, no polaroid edge (frames are separate overlay layers — this pet cheki is a baked photo),
no dachshund long body/ears (Suna is a curly POODLE), no straight fur, no white/cream coat (CARAMEL BROWN), no cat,
no Santa suit (that is Okja), no reindeer antlers (that is Sion),
no flat brown blob dog (keep warm highlights so the curls read), no cropped dog (the whole body must be inside the frame),
no chroma green, no chroma magenta, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the dog, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① 카라멜 곱슬 정체성(둥근 곱슬·갈색 눈)이 **아이싱 장식 아래에서** 또렷한지(곱슬 푸들이지 닥스훈트로 빠지지 않게) ② **`120×180`(2:3) 완전 불투명** ③ 강아지 **전신이 안 잘리고** 중앙에 읽히는지(발치 비움), 배경은 **평면 패턴이 아닌 진저브레드 베이커리 풍경**인지 ④ 마스터 팔레트 인덱싱 — ⚠️ **따뜻한 갈색·캐러멜·아이싱 흰색·빨강/초록 검드롭** 커버가 충분한지 확인. 저장: `assets/sprites/photo_suna_xmas.png`.
> 🃏 **프레임 짝**: 일반 = `frame_standard`, **나비 승급** 시 `frame_xmas`(눈·리스) — 따뜻한 쿠키 갈색·빨강/초록과 톤이 잘 맞는다.

---

## 후처리 연결 (선아 — 받은 PNG → 규격 에셋)

```bash
# 선아 펫 반응 4종 (96×96, 크로마 그린 제거 — 갈색이라 그린 안전) — idle/snack/play/pet
tools/.venv/bin/python tools/dotify.py suna_idle_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/suna_idle.png
tools/.venv/bin/python tools/dotify.py suna_snack_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/suna_snack.png
tools/.venv/bin/python tools/dotify.py suna_play_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/suna_play.png
tools/.venv/bin/python tools/dotify.py suna_pet_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/suna_pet.png

# 선아 인트로 지뢰계 체키 (배경 포함 베이크 — 120×180 불투명, 누끼 X·크로마 X)
tools/.venv/bin/python tools/dotify.py photo_suna_jirai_raw.png \
  --size 120x180 --out assets/sprites/photo_suna_jirai.png

# 선아 크리스마스 체키 (진저브레드 쿠키 — 배경 포함 베이크, 120×180 불투명)
tools/.venv/bin/python tools/dotify.py photo_suna_xmas_raw.png \
  --size 120x180 --out assets/sprites/photo_suna_xmas.png

# 선아 탭 미니 초상 (권장: suna_idle 얼굴 크롭본을 입력으로 — 초상 슬롯 중앙 정렬 자동)
tools/.venv/bin/python tools/dotify.py portrait_suna_raw.png \
  --size 24x24 --chroma 00ff00 --out assets/sprites/portrait_suna.png
```

> ⚠️ **멜 슬라이스 펫 코드분 대응(아트 확정 후)**: ① 펫 반응 4컷 누끼·`96×96`·마스터 팔레트 ② `portrait_suna` 임포트·렌더 → 24×24 ③ 인트로 체키 베이크 → `photo_suna_jirai` ④ `data/characters.gd` 레지스트리에 `suna` 펫 항(`kind=PET`, `intro_event="mine"`, accent=TEAL) + `data/balance.gd` `GAUGE_SUNA` + `data/events.gd` `"suna": true`(mine). 펫 라이브 스프라이트 경로는 제네릭(`Sioni.set_prefix`)이라 코드 무수정 — 데이터만 추가.
> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
