# Gemini 도트 변환 프롬프트 — 수아 (멜의 베이지 닥스훈트)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물/일러스트 → AI 도트화**(img2img). 공용 에셋·핵심 원칙은 [공통 파일](./gemini-prompts-common.md) 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))
> **확장 트랙 — 멜 슬라이스의 펫 단(2마리 중 1).** 짝꿍 선아는 [선아 파일](./gemini-prompts-suna.md). **수아는 선아 미러** — 구조·후처리·체키 무드는 [선아 파일](./gemini-prompts-suna.md)과 동일하고, **견종/색만 다르다**(이 문서는 그 차이만 정리). 확장 트랙 원칙상 **아트가 항상 코드보다 먼저**다(→ 메모리 `character-expansion-plan`).

> **수아 (Sua)**: 강시 메이드 **멜**의 반려견 — **베이지(크림) 장모 닥스훈트**. 곁의 교감 가능한 펫 + 수집 캐릭터(펫 틀 — 게이지만, 관계단계·기분 없음).
> **🔑 레퍼런스 첨부 필수**: `assets/sprites/_src/sua_ref.png`(수아 레퍼)를 첨부해 **img2img** 로 뽑는다.
> **🔑 정체성(고정) — 레퍼 기준**: 수아는 **크림/베이지 장모(長毛) 닥스훈트** — **늘어진 긴 귀**(부드러운 장모), **길쭉한 몸통과 짧은 다리**(닥스훈트 실루엣), 큰 **둥근 눈**, **검은 코**, 부드러운 크림 베이지 털. ⚠️ **선아(갈색 곱슬 푸들, 둥근 곱슬 머리뭉치)와 명확히 구분** — 수아는 *긴 귀·긴 몸·매끈 장모 닥스훈트*다.
> **🔑 체형 = "동글 SD 펫" 틀 + 닥스훈트 힌트**: 시온이·규종이의 **통통 동글 SD 틀**을 기본으로(큰 머리·큰 눈·짧은 다리 치비) **닥스훈트의 긴 귀와 살짝 긴 몸통**만 더한다. ⚠️ **단 SD 스케일 유지** — 현실 닥스훈트처럼 *과하게 길쭉·낮게* 빠지지 말 것(한 화면에서 다른 펫과 같은 SD 스케일로 읽혀야 한다 — 코코 슬림 교훈과 같은 주의: 견종 특징은 *힌트*만, SD 틀이 우선).
> **🔑 누끼 = 크로마 그린 `#00ff00`**: 베이지/크림 털이라 그린 크로마가 안전. `dotify --chroma 00ff00`.
> **규격**: 펫 라이브 반응 = `96×96`(다른 펫과 동일 캔버스). 크게 받아 `dotify --size 96x96`으로 축소.

---

## 수아 (펫 — 교감화면 반응)

> 멜 곁의 베이지 닥스훈트. **교감화면 라이브 펫은 항상 기본 베이지 닥스훈트**(이벤트 의상은 체키 전용 → 아래 "수아 인트로 체키").

```
[Attach: 1 = assets/sprites/_src/sua_ref.png — Sua's reference, 2 = (optional) assets/sprites/sioni_idle.png — the SD PET SILHOUETTE & dot-style anchor]
Convert the attached dog (image 1) into a CUTE retro pixel art / dot art chibi sprite, front view, sitting. Subject: "Sua", Mel's pet dog.
Take the DOG'S IDENTITY (colour, breed, face) from image 1, but match the SD chibi build and dot style of image 2 (the white cat pet) — same big head, big eyes, short legs SD scale.
Body: an SD chibi long-haired DACHSHUND with a BIG round head and big eyes, short stubby legs. Add the dachshund hints — soft LONG DROOPY EARS and a slightly LONG body — but keep the SD chibi scale (NOT an exaggerated low-slung sausage shape).
Fur & COLOUR (keep EXACT — a CREAM / BEIGE long-haired dachshund):
      - a soft CREAM / pale-BEIGE long coat everywhere — head, the long droopy ears, body and legs all cream-beige.
      - big round dark eyes, a small BLACK nose.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, dot-art shading with 2-3 tones (a beige midtone + soft tan shadow + a cream highlight so the long fur reads — NOT a flat beige blob).
Color mood: a soft cream-beige long-haired dachshund with big eyes and a black nose, against the cafe's warm antique palette.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

### 네거티브 (수아)

```
no human, no person, no character besides the dog, no clothes (this is the BASE plain dog),
no curly fur / no round curly top-knot poodle shape (that is Suna — Sua is a smooth LONG-HAIRED DACHSHUND),
no caramel / golden-brown coat (Sua is CREAM / BEIGE), no cat (this is a DOG),
no exaggerated extra-long low sausage body (keep the SD chibi scale, dachshund hint only),
no chroma green on the dog itself, no flat single-beige silhouette with no detail (use highlights so the long fur reads),
no long realistic body proportions, no text, no watermark, no scenery,
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render.
```

### 반응 4종 — 베이스에 한 줄만 추가 (얼굴·자세만 변경)

| 파일명 | 추가 문구 |
|---|---|
| `sua_idle`  | `Pose: sitting calmly, content, big eyes calm, long ears resting, a small happy mouth.` |
| `sua_snack` | `Pose: looking UP happily at a treat, mouth open, eager, eyes wide, long ears perked.` |
| `sua_play`  | `Pose: playful bouncy stance, front paws up, long ears flopping, tongue out happily.` |
| `sua_pet`   | `Pose: eyes closed (happy squint), blissful, head tilted up as if being petted.` |

> 팁: idle 1장을 확정한 뒤 그 결과를 레퍼런스로 첨부해 나머지 3종을 뽑으면 베이지 장모 톤·긴 귀·큰 눈이 일관된다.

---

## 수아 탭 미니 초상 (`portrait_sua`)

> 파일명 **`portrait_sua.png`** 고정. **권장: `sua_idle.png`에서 얼굴(긴 귀 일부 포함) 정사각 크롭** → `dotify --size 24x24`. 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
[Attach: 확정된 sua_idle.png 또는 assets/sprites/_src/sua_ref.png]
Pixel art / dot art tiny SQUARE PORTRAIT bust (dog FACE + a little shoulder), STRICT FRONT view,
PERFECTLY CENTERED with EQUAL margins on the LEFT, RIGHT and TOP — the face must NOT touch or run off any edge.
Subject: "Sua", Mel's CREAM / BEIGE LONG-HAIRED DACHSHUND — soft long droopy ears framing the face,
       big round dark eyes, a small black nose. Clearly a long-haired DACHSHUND (NOT a poodle, NOT a cat).
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use 2-3 tones (beige midtone + tan shadow + cream highlight) so the long fur reads — NOT a flat beige blob.
       Match the Sioni/Gyujong/Coco portrait shading depth.
Color mood: cream-beige long fur, big dark eyes, black nose.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

```
[네거티브] no off-center / left-shifted face, no face touching or cropped by ANY edge,
no full body, no tiny face with huge empty margins, no text, no extra characters, no scenery,
no curly poodle fluff (this is a smooth long-haired DACHSHUND with long droopy ears), no caramel-brown coat (CREAM BEIGE),
no cat, no fox, no chroma green on the dog, no flat beige blob with no detail, no gradient, no soft anti-aliased edges, no 3D render.
```

---

## 수아 인트로(지뢰계) 체키 (베이크 컷 1벌)

> 수아의 **인트로 체키** — 멜 인트로 체키 라인의 펫 짝. `Events.cheki_photo_path("sua","mine")` = **`photo_sua_jirai.png`**.
> **🔑 규격·무드·배경은 [선아 체키](./gemini-prompts-suna.md#선아-인트로지뢰계-체키-베이크-컷-1벌)와 동일** — **`120×180`(2:3) 완전 불투명**, **청록/시안 동양 차이나타운 야경**(멜 `bg_cheki_mel_jirai`와 짝 무드), 동양 강시 부적/매듭 지뢰계 코디. **차이는 주인공이 크림 베이지 닥스훈트(긴 귀)** 라는 점뿐.
> **🔑 워크플로우**: 확정된 `sua_idle`(정체성 락) + **`_src/sua_jirai_ref.png`**(있으면)를 첨부해 "이 베이지 닥스훈트에게 이 동양 강시 코디를 입혀 이 청록 동양 야경 앞에서 찍은 한 장으로". **크림 베이지·긴 귀·검은 코는 의상이 바뀌어도 유지.**
> ⚠️ **수아 지뢰계 레퍼 사진 준비 필요** — `assets/sprites/_src/sua_jirai_ref.png`. 없으면 코디 가이드 텍스트만으로.

```
[Attach: 1 = sua_idle.png (confirmed dog, identity lock), 2 = _src/sua_jirai_ref.png (oriental talisman costume + teal night scene reference, if available)]
ONE baked PHOTO (cheki snapshot): an ORIENTAL JIANGSHI JIRAI-KEI costumed CREAM-BEIGE LONG-HAIRED DACHSHUND sitting in front of a TEAL CHINATOWN NIGHT STREET. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's DOG identity: the SAME soft CREAM / BEIGE long-haired dachshund with her EXACT look
(cream-beige long fur, long droopy ears, big dark eyes, small black nose), same face — peeking out from inside the hood, long ears showing.
Costume — dress her in a BLUE & TEAL oriental-talisman yumekawa / jirai outfit (cute, age-safe):
- a BLUE / TEAL HOOD / bonnet with cute TALISMAN (fu charm) tags, Chinese KNOTS and a small RED-string charm, lace frill at one side, framing the dog's cream face and long ears,
- a frilly TEAL & BLUE china-motif cape/dress — a mandarin collar with frog buttons, coin & heart trim, a little talisman-print apron,
- both front PAWS clasped together in front, chic and sweet.
  Clearly the SAME cream dachshund, just costumed. A cute oriental jiangshi vibe.
Background (baked in): a dreamy TEAL CHINATOWN cute CAFE STREET at night — dark storefronts with TEAL & cyan NEON glow (ABSTRACT glyph-like signs, NOT real letters or brand names),
  rows of round JADE-GREEN & red paper LANTERNS strung overhead, a pale FULL MOON, hanging RED-string charms, HEART pennant bunting and string lights across the top, oriental awnings, a dark cobblestone path, soft round BOKEH orbs;
  detailed along the TOP and SIDES, a softer blurrier bokeh haze in the CENTER, a calmer dark path in the LOWER-CENTER (feet area).
Composition: the FULL dog (whole body, NOT cropped) sits in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & lights as clusters of flat stepped pixels. The cream dachshund keeps soft highlights so the long fur reads against the dark scene.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green or magenta anywhere.
Color mood: oriental jirai (chinatown night) — deep navy/black, electric TEAL & cyan, hot pink & jade-green accents, pale moon white, orange & red touches; the cream dachshund reads via soft highlights and her big dark eyes.
```

### 네거티브 (수아 체키 사진)

```
no human, no person, no second character (no Mel in frame), no text, no watermark, no logo, no QR code,
no readable signage, no real words, no brand name,
no DAYLIGHT / pastel-pink scene (this is a TEAL CHINATOWN NIGHT street), no bright sunny background,
no photo frame, no card border, no polaroid edge (frames are separate overlay layers — this pet cheki is a baked photo),
no curly poodle fluff (Sua is a smooth long-haired DACHSHUND), no caramel-brown coat (CREAM BEIGE), no cat, no hidden face inside the hood,
no exaggerated extra-long sausage body (keep SD chibi scale), no flat beige blob dog (keep soft highlights), no cropped dog (whole body inside the frame),
no chroma green, no chroma magenta, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the dog, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: 선아 체키와 동일하되 ① **크림 베이지·긴 귀 닥스훈트 정체성**(곱슬 푸들로 빠지지 않게)이 틸 부적 후드 안에서 또렷한지 ② `120×180` 완전 불투명 ③ 전신 안 잘림·중앙 읽힘 ④ 추상 글로우 간판 ⑤ 청록·블루 팔레트 충분. 저장: `assets/sprites/photo_sua_jirai.png`.
> 🃏 프레임 짝은 선아와 동일(인트로=`frame_standard`).

---

## 수아 크리스마스 체키 (베이크 컷 1벌)

> 수아의 **크리스마스(xmas) 데이 체키** — `Events.cheki_photo_path("sua","xmas")` = **`photo_sua_xmas.png`**. 펫 베이크 컷 모델이라 의상+배경을 한 장으로 다시 굽는다(지뢰계 선례와 동일). `data/events.gd`의 xmas 행에 `"sua": true` 플래그가 켜져 있어야 컬렉션북 칸이 뜬다(이번 작업에서 켬).
> **🔑 규격(수아 지뢰계 체키와 동일)**: **카드 풀사이즈 `120×180`(2:3) 완전 불투명**(누끼 X·크로마 X). 강아지 **전신이 잘리지 않게** 화면 안에 두고, 발치(하단 중앙)는 비교적 비워 캐릭터가 읽히게, 풍경 디테일은 위·옆으로 민다.
> **🔑 컨셉 = 캔디케인(Candy cane)**: 옥자(산타)·시온이(루돌프)와 겹치지 않는 수아만의 크리스마스 아키타입 — **길쭉한 닥스훈트 몸통 = 캔디케인 줄무늬**라는 수아의 정체성을 그대로 살린다. 빨강·흰 사선 줄무늬가 긴 몸을 감는 페퍼민트 강아지. 짝꿍 선아(진저브레드)와 달콤한 한 쌍.
> **🔑 워크플로우**: 확정된 `sua_idle`(정체성 락) + **`_src/sua_xmas_ref.png`**(캔디케인 의상 레퍼, 있으면)를 첨부해 "이 베이지 닥스훈트에게 캔디케인 줄무늬 코디를 입혀 **이 페퍼민트 캔디 가게 앞에서 찍은 한 장**으로". **크림 베이지·긴 귀·검은 코는 의상이 바뀌어도 유지.**

```
[Attach: 1 = sua_idle.png (confirmed dog, identity lock), 2 = _src/sua_xmas_ref.png (candy-cane costume reference, if available)]
ONE baked PHOTO (cheki snapshot): a CANDY-CANE costumed CREAM-BEIGE LONG-HAIRED DACHSHUND standing in front of a cheery PEPPERMINT CANDY SHOP. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's DOG identity: the SAME soft CREAM / BEIGE long-haired dachshund with her EXACT look
(cream-beige long fur, long droopy ears, big dark eyes, small black nose), same face and long ears showing — her LONG body is perfect for candy-cane stripes.
Costume — dress her as a cute CANDY CANE (age-safe, sweet):
- a RED & WHITE diagonally STRIPED knit sweater / wrap running the length of her long body (candy-cane stripes), a peppermint-swirl charm,
- a small GREEN HOLLY & red-berry collar, a RED BOW on each long ear. Clearly the SAME cream dachshund, just costumed; her long body reads as a candy cane.
Background (baked in): a cheery PEPPERMINT CANDY SHOP — candy-cane pillars, red-and-white striped awnings, glass jars of sweets, a peppermint-swirl wall, twinkling cellophane sparkle and warm string lights;
  detailed along the TOP and SIDES, a softer bokeh haze in the CENTER, a calm shop floor at the bottom.
Composition: the FULL dog (whole body, NOT cropped) stands in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & lights as clusters of flat stepped pixels. The cream dachshund keeps soft highlights so the long fur reads.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green or magenta anywhere.
Color mood: peppermint candy shop — candy RED & white stripes, mint-green accents, the cream-beige dachshund popping in the middle, warm shop light.
```

### 네거티브 (수아 크리스마스 체키)

```
no human, no person, no second character (no Mel in frame), no text, no watermark, no logo, no QR code,
no readable signage, no real words, no brand name,
no NIGHT neon street, no teal chinatown scene (this is a bright PEPPERMINT CANDY SHOP), no pastel-pink gloom,
no photo frame, no card border, no polaroid edge (frames are separate overlay layers — this pet cheki is a baked photo),
no curly poodle fluff (Sua is a smooth long-haired DACHSHUND), no caramel-brown coat (CREAM BEIGE), no cat,
no Santa suit (that is Okja), no reindeer antlers (that is Sion),
no exaggerated extra-long sausage body (keep SD chibi scale), no flat beige blob dog (keep soft highlights), no cropped dog (whole body inside the frame),
no chroma green, no chroma magenta, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the dog, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① 크림 베이지·긴 귀 닥스훈트 정체성(곱슬 푸들로 빠지지 않게)이 **캔디케인 줄무늬 안에서** 또렷한지 ② **`120×180`(2:3) 완전 불투명** ③ 강아지 **전신이 안 잘리고** 중앙에 읽히는지(발치 비움), 배경은 **평면 패턴이 아닌 페퍼민트 캔디 가게 풍경**인지 ④ 마스터 팔레트 인덱싱 — ⚠️ **캔디 빨강·흰색·민트 그린·베이지** 커버가 충분한지 확인. 저장: `assets/sprites/photo_sua_xmas.png`.
> 🃏 **프레임 짝**: 일반 = `frame_standard`, **나비 승급** 시 `frame_xmas`(눈·리스) — 캔디 빨강·민트와 톤이 잘 맞는다.

---

## 후처리 연결 (수아 — 받은 PNG → 규격 에셋)

```bash
# 수아 펫 반응 4종 (96×96, 크로마 그린 제거 — 베이지라 그린 안전) — idle/snack/play/pet
tools/.venv/bin/python tools/dotify.py sua_idle_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/sua_idle.png
tools/.venv/bin/python tools/dotify.py sua_snack_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/sua_snack.png
tools/.venv/bin/python tools/dotify.py sua_play_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/sua_play.png
tools/.venv/bin/python tools/dotify.py sua_pet_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/sua_pet.png

# 수아 인트로 지뢰계 체키 (배경 포함 베이크 — 120×180 불투명, 누끼 X·크로마 X)
tools/.venv/bin/python tools/dotify.py photo_sua_jirai_raw.png \
  --size 120x180 --out assets/sprites/photo_sua_jirai.png

# 수아 크리스마스 체키 (캔디케인 — 배경 포함 베이크, 120×180 불투명)
tools/.venv/bin/python tools/dotify.py photo_sua_xmas_raw.png \
  --size 120x180 --out assets/sprites/photo_sua_xmas.png

# 수아 탭 미니 초상 (권장: sua_idle 얼굴 크롭본을 입력으로 — 초상 슬롯 중앙 정렬 자동)
tools/.venv/bin/python tools/dotify.py portrait_sua_raw.png \
  --size 24x24 --chroma 00ff00 --out assets/sprites/portrait_sua.png
```

> ⚠️ **멜 슬라이스 펫 코드분 대응(아트 확정 후)**: 선아와 동일 — `data/characters.gd` `sua` 펫 항(`kind=PET`, `intro_event="mine"`, accent=TEAL) + `data/balance.gd` `GAUGE_SUA` + `data/events.gd` `"sua": true`(mine). 펫 라이브 경로는 제네릭이라 데이터만 추가.
> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
