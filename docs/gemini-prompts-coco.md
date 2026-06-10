# Gemini 도트 변환 프롬프트 — 코코 (바나의 까만 고양이)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**(img2img). 공용 에셋·핵심 원칙은 [공통 파일](./gemini-prompts-common.md) 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))
> **확장 트랙 — 바나 슬라이스의 펫 단.** 확장 트랙 원칙상 **아트가 항상 코드보다 먼저**다(→ 메모리 `character-expansion-plan`).

> **코코 (Coco)**: 뱀파이어 메이드 **바나**의 반려묘. 곁의 교감 가능한 펫 + 수집 캐릭터(시온이·규종이와 같은 펫 틀 — 게이지만, 관계단계·기분 없음 → `character-expansion-plan`).
> **🔑 실물 레퍼런스 첨부 필수**: `assets/sprites/_src/coco_ref.png`(코코 실물)를 첨부해 **img2img(사진 변환)** 으로 뽑는다.
> **🔑 정체성(고정) — 실물 레퍼 기준**: 코코는 **얼룩 하나 없는 순수 올블랙(솔리드 블랙) 고양이** — 머리·귀·얼굴·몸·다리·꼬리 **전부 검정**, 흰 얼룩 없음. **노란/황금(amber) 눈**, 작은 **핑크 코**, 흰 수염. ⚠️ **규종이와 명확히 구분** — 규종이는 *까만 바탕+흰 얼룩(턱시도)+초록 눈*인데, **코코는 흰 얼룩이 전혀 없는 올블랙 + 노란 눈**이다. 또 시온이(흰 고양이)와도 반대.
> **🔑 체형 = "까맣고 마른"(고정)**: CONTEXT 설정상 코코는 *마른 고양이*다 — 시온이·규종이의 **통통 동글**과 달리 **날씬하고 우아한** 실루엣(뱀파이어 주인 바나에게 어울리는 시크한 검은 고양이). ⚠️ **단 SD 펫 틀은 유지** — 큰 머리·큰 눈·짧은(가는) 다리의 치비는 그대로 두되 **몸통만 슬림**하게(너무 길쭉·현실적 비례로 빠지지 말 것 — 한 화면에서 다른 펫과 같은 SD 스케일로 읽혀야 한다).
> **🔑 누끼 = 크로마 그린 `#00ff00`(규종이와 다름)**: 코코는 **노란 눈**이라 그린 크로마를 깔아도 눈이 안 뚫린다(규종이는 초록 눈이라 마젠타를 썼다). 표준 그린으로 받고 `dotify --chroma 00ff00`. ⚠️ 단 **순수 올블랙이라 검은 몸이 어두운 배경에 묻히기 쉬우니** 크로마 그린 배경과의 대비를 분명히, 외곽선은 또렷하게.
> **규격**: 펫 라이브 반응 = `96×96`(시온이·규종이와 동일 캔버스). 96px는 AI가 직접 못 그리니 **크게 받아 `dotify --size 96x96`으로 축소** — 동글고 단순한 실루엣으로(작아도 읽히게, 슬림해도 큰 머리·큰 눈은 유지).

---

## 코코 (펫 — 교감화면 반응)

> 바나 곁의 까만 고양이. **교감화면 라이브 펫은 항상 기본 올블랙 고양이**(이벤트 의상은 체키 전용 → 아래 "코코 인트로 체키").
> 시온이·규종이와 **같은 SD 펫 실루엣 스케일**로 가야 한 화면에서 한 쌍처럼 읽힌다 — 큰 머리·큰 눈·짧은 다리의 치비. 단 코코는 **몸통만 슬림**(마른 고양이).

```
[Attach: 1 = assets/sprites/_src/coco_ref.png — Coco's real reference photo, 2 = (optional) assets/sprites/sioni_idle.png — the SD PET SILHOUETTE & dot-style anchor]
Convert the attached cat (image 1) into a CUTE retro pixel art / dot art chibi sprite, front view, sitting. Subject: "Coco", Bana's pet cat.
Take the CAT'S IDENTITY (colour, face) from image 1, but match the SD chibi build and dot style of image 2 (the white pet) — same big head, big eyes, short legs SD scale.
Body: an SD chibi cat with a BIG round head and big eyes, but a SLENDER, SLEEK body (Coco is a THIN, elegant cat — NOT chubby/round like the white pet). Short stubby legs, graceful.
Fur & COLOUR (keep EXACT — a SOLID ALL-BLACK cat, NO markings):
      - the coat is ENTIRELY BLACK everywhere — head, ears, face, body, legs and tail all black. NO white patch, NO blaze, NO tuxedo bib.
      - a small PINK nose, YELLOW / golden (amber) eyes, white whiskers.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, dot-art shading with 2-3 tones (use a dark-grey/charcoal midtone + near-black shadow + a subtle cool highlight so the BLACK body still reads — NOT a flat black blob).
Color mood: a sleek ALL-BLACK cat with a pink nose and glowing YELLOW eyes, against the cafe's dark antique / gothic palette.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

### 네거티브 (코코)

```
no human, no person, no character besides the cat, no clothes (this is the BASE plain cat),
no WHITE patch / no white blaze / no tuxedo bib (Coco is a SOLID ALL-BLACK cat — the OPPOSITE of a tuxedo cat),
no white muzzle, no white chest, no white anywhere on the fur,
no green eyes (the eyes are YELLOW / amber), no chroma green on the cat itself,
no flat solid-black silhouette with no detail (use charcoal midtones + highlights so the black body reads),
no chubby / round ball body (Coco is a SLENDER thin cat — but keep the SD big head & big eyes),
no long realistic body proportions, no text, no watermark, no scenery,
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render.
```

### 반응 4종 — 베이스에 한 줄만 추가 (얼굴·자세만 변경)

| 파일명 | 추가 문구 |
|---|---|
| `coco_idle`  | `Pose: sitting calmly, tail curled elegantly around the feet, content, yellow eyes calm.` |
| `coco_snack` | `Pose: looking UP happily at a treat, mouth open, eager, yellow eyes wide.` |
| `coco_play`  | `Pose: playful pounce, front paws up, ears perked, tail flicked.` |
| `coco_pet`   | `Pose: eyes closed (yellow eyes shut), blissful, head tilted as if being petted.` |

> 팁: idle 1장을 확정한 뒤 그 결과를 레퍼런스로 첨부해 나머지 3종을 뽑으면 올블랙 톤·슬림 체형·노란 눈이 일관된다(시온이·규종이 선례).

---

## 코코 탭 미니 초상 (`portrait_coco`)

> 컬렉션북 탭·로스터 선택 화면의 코코 식별 초상(24×24). 레지스트리가 `portrait_%s.png % id`로 경로를 파생하니 파일명은 **`portrait_coco.png`** 고정.
> **권장: 생성하지 말고 크롭** — 확정된 `coco_idle.png`에서 **얼굴(검은 머리+노란 눈+핑크 코)을 정사각으로, 좌·우·위 여백을 똑같이 두고** 크롭 → `dotify --size 24x24`(초상 슬롯은 "중앙 정렬" 자동 ON). ⚠️ 올블랙이라 작게 줄이면 이목구비가 묻히기 쉬우니 **노란 눈·핑크 코의 대비**를 분명히. 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
[Attach: 확정된 coco_idle.png 또는 assets/sprites/_src/coco_ref.png]
Pixel art / dot art tiny SQUARE PORTRAIT bust (cat FACE + a little shoulder), STRICT FRONT view,
PERFECTLY CENTERED with EQUAL margins on the LEFT, RIGHT and TOP — the face must NOT touch or run off any edge,
leave a small even gap on every side.
Subject: "Coco", Bana's SLENDER SOLID-BLACK cat — the whole face & ears are BLACK,
       big round YELLOW / amber eyes, a small PINK nose, white whiskers. NO white markings anywhere.
       Clearly a CAT (NOT a fox, NOT a human), an all-black cat (NOT a tuxedo, NOT a white cat).
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use 2-3 tones (charcoal midtone + near-black shadow + cool highlight) so the BLACK face reads — NOT a flat black blob.
       Match the Okja/Miho/Sioni/Gyujong portrait shading depth.
Color mood: solid black fur, pink nose, glowing yellow eyes.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

```
[네거티브] no off-center / left-shifted face, no face touching or cropped by ANY edge,
no full body, no tiny face with huge empty margins, no text, no extra characters, no scenery,
no fox ears (this is a CAT), no white markings / no tuxedo bib / no white blaze (Coco is SOLID BLACK),
no green eyes (eyes are YELLOW), no chroma green on the cat,
no flat black blob with no facial detail, no gradient, no soft anti-aliased edges, no 3D render.
```

---

## 코코 인트로(지뢰계) 체키 (베이크 컷 1벌)

> 코코의 **인트로 체키** — 바나를 고르면 받는 인트로 체키 라인의 펫 짝(바나 `intro_event="mine"` = 지뢰계). 펫은 시온이·규종이와 같이 **배경 포함 베이크 사진**으로 굽는다(누끼 3겹 합성 X) — `Events.cheki_photo_path("coco","mine")` = **`photo_coco_jirai.png`**.
> **🔑 규격(시온이·규종이 체키와 동일)**: **카드 풀사이즈 `120×180`(2:3) 완전 불투명**(누끼 X·크로마 X). 고양이 **전신이 잘리지 않게** 화면 안에 두고, 발치(하단 중앙)는 비교적 비워 캐릭터가 읽히게, 풍경 디테일은 위·옆으로 민다.
> **🔑 무드 = 다크 뱀파이어 지뢰계(고딕 야경)**: 코코의 지뢰계 데이 룩은 **블랙·퍼플 박쥐 후드 + 고딕 프릴**의 *다크 뱀파이어 지뢰계* 결 — 옥자(핑크 레이스)·미호(레오파드 갸루)·규종이(파스텔 마이멜로디풍)와 확실히 구분되는 코코/바나만의 톤. **주인 바나의 지뢰계와 같은 보랏빛 네온·박쥐·보름달 고딕 야경**을 배경으로 깔아 한 장으로 어우러진다(바나 `bg_cheki_bana_jirai`와 짝 무드). ⚠️ 톤이 다른 펫들과 구별되는 건 의도.
> **🔑 워크플로우**: 확정된 `coco_idle`(정체성 락) + **`_src/coco_jirai_ref.png`**(박쥐 후드 의상+장면 레퍼, 있으면)를 첨부해 "이 올블랙 고양이에게 이 다크 뱀파이어 코디를 입혀 **이 보랏빛 고딕 야경 앞에서 찍은 한 장**으로". **올블랙·노란 눈은 의상이 바뀌어도 유지.**
> ⚠️ **코코 지뢰계 레퍼 사진 준비 필요** — `assets/sprites/_src/coco_jirai_ref.png`. 없으면 아래 코디 가이드 텍스트만으로 시도하되, 사진을 구하면 일관성이 오른다.
> **지뢰계 코디 가이드(권장)**: ① **블랙/퍼플 박쥐 후드**(끝이 뾰족한 박쥐 날개 귀 — 바깥 블랙/안쪽 퍼플, 옆에 작은 하트·십자가 + 레이스 프릴, 그 안으로 올블랙 얼굴·노란 눈이 보임) ② **퍼플·블랙 프릴 고딕 로리타 드레스**(층층 러플 + 하트·레이스·메탈 하트, 작은 박쥐 프린트 앞치마) ③ 포즈 = **두 앞발 모아 시크하게**, 검은 꼬리는 옆으로. 다크 퍼플·귀엽고 age-safe.

```
[Attach: 1 = coco_idle.png (confirmed cat, identity lock), 2 = _src/coco_jirai_ref.png (dark vampire bat-hood costume + gothic night scene reference, if available)]
ONE baked PHOTO (cheki snapshot): a DARK VAMPIRE JIRAI-KEI costumed SOLID-BLACK cat sitting in front of a PURPLE GOTHIC NIGHT STREET. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's CAT identity: the SAME SLENDER SOLID-BLACK cat with her EXACT look
(entirely BLACK fur everywhere, NO white markings; small pink nose, big YELLOW / amber eyes), same face — peeking out from inside the hood.
Costume — dress it in a BLACK & PURPLE BAT yumekawa / jirai outfit (cute-gothic, age-safe):
- a BLACK / PURPLE BAT HOOD / bonnet with pointed BAT-WING EARS (black outside, purple inside), a small PURPLE BOW, a tiny CROSS or HEART and lace frill at one side, framing the cat's all-black face,
- a frilly PURPLE & BLACK gothic-LOLITA dress — a tiered RUFFLED skirt with hearts, lace and metal-heart trim, a little bat-print apron,
- both front PAWS clasped together in front, chic and sweet; the BLACK TAIL curling out to one side.
  Clearly the SAME all-black cat, just costumed. A cute dark-vampire bat vibe.
Background (baked in): a dreamy PURPLE GOTHIC cute CAFE STREET at night — dark storefronts with PURPLE & pink NEON glow (ABSTRACT glyph-like signs, NOT real letters or brand names),
  a pale FULL MOON, small BAT silhouettes in the sky, round purple paper LANTERNS strung overhead, HEART & bat pennant bunting and string lights across the top, gothic awnings, a dark cobblestone path, a few floating hearts and soft round BOKEH orbs;
  detailed along the TOP and SIDES, a softer blurrier bokeh haze in the CENTER, a calmer dark path in the LOWER-CENTER (feet area).
Composition: the FULL cat (whole body, NOT cropped) sits in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh & lights as clusters of flat stepped pixels. The black cat keeps charcoal midtones + highlights so it reads against the dark scene.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green or magenta anywhere.
Color mood: dark vampire jirai (gothic night) — deep navy/black, electric PURPLE & violet, hot pink accents, pale moon white, blood-red touches; the all-black cat reads via charcoal highlights and its glowing yellow eyes.
```

### 네거티브 (코코 체키 사진)

```
no human, no person, no second character (no Bana in frame), no text, no watermark, no logo, no QR code,
no readable signage, no real words, no brand name,
no DAYLIGHT / pastel-pink scene (this is a PURPLE GOTHIC NIGHT street), no bright sunny background,
no photo frame, no card border, no polaroid edge (frames are separate overlay layers — this pet cheki is a baked photo),
no WHITE markings / no tuxedo bib / no white blaze on the cat (Coco is SOLID BLACK with yellow eyes), no green eyes, no hidden face inside the hood,
no flat black blob cat (keep charcoal highlights so the black cat reads), no cropped cat (the whole body must be inside the frame),
no chroma green, no chroma magenta, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the cat, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① 올블랙 정체성(흰 얼룩 없음·노란 눈)이 **퍼플 박쥐 후드 안에서** 또렷한지(검은 고양이가 어두운 야경에 묻히지 않게 차콜 하이라이트·노란 눈으로 떠 보이는지) ② **`120×180`(2:3) 완전 불투명**(투명·크로마 한 픽셀도 없어야) ③ 고양이 **전신이 안 잘리고** 중앙에 읽히는지(발치 비움), 배경은 **평면 패턴이 아닌 퍼플 고딕 야경 풍경**인지 ④ 간판이 **읽히는 글자·브랜드명이 아닌** 추상 글로우인지 ⑤ 마스터 팔레트(~32색) 인덱싱 — ⚠️ **퍼플·블랙이 다수**라 팔레트에 퍼플 톤이 충분한지 확인(부족하면 인덱싱에서 뭉개짐 → 필요 시 퍼플 1~2색 보강 검토). 저장: `assets/sprites/photo_coco_jirai.png`.
> 🃏 **프레임 짝**: 펫 베이크 컷에도 `cheki_card`가 **이벤트 공통 프레임을 항상 덧씌운다**(`_frame.texture`). 인트로=**일반체키**라 프레임 = `frame_standard`(크라프트/세피아). 단 **나비 승급** 시 `frame_jirai`(네이비·네온 핑크/퍼플)와 짝이 잘 맞는다(퍼플 무드 공유).
> 📌 **이후 이벤트 체키(xmas 등)는 별도 아트 트랙으로 점증** — 펫은 베이크 컷 모델이라 의상+배경을 한 장으로 다시 구우면 된다(시온이 `photo_sion_xmas`·규종이 선례).

---

## 코코 크리스마스 체키 (베이크 컷 1벌)

> 코코의 **크리스마스(xmas) 데이 체키** — `Events.cheki_photo_path("coco","xmas")` = **`photo_coco_xmas.png`**. 펫 베이크 컷 모델이라 의상+배경을 한 장으로 다시 굽는다(지뢰계 선례와 동일). `data/events.gd`의 xmas 행에 `"coco": true` 플래그가 켜져 있어야 컬렉션북 칸이 뜬다(이번 작업에서 켬).
> **🔑 규격(코코 지뢰계 체키와 동일)**: **카드 풀사이즈 `120×180`(2:3) 완전 불투명**(누끼 X·크로마 X). 고양이 **전신이 잘리지 않게** 화면 안에 두고, 발치(하단 중앙)는 비교적 비워 캐릭터가 읽히게, 풍경 디테일은 위·옆으로 민다.
> **🔑 컨셉 = 트리 토퍼 별 / 밤하늘 천사**: 옥자(산타)·시온이(루돌프)와 겹치지 않는 코코만의 크리스마스 아키타입 — **올블랙 몸 = 크리스마스 밤하늘**, **빛나는 노란 눈 = 별빛**이라는 코코의 정체성을 그대로 살린다. 트리 꼭대기의 금색 별 장식(tree-topper)이 된 검은 고양이. 코코의 다크 야경 무드(지뢰계 선례)와도 결이 통한다.
> **🔑 워크플로우**: 확정된 `coco_idle`(정체성 락) + **`_src/coco_xmas_ref.png`**(트리 토퍼 별/천사 의상 레퍼, 있으면)를 첨부해 "이 올블랙 고양이에게 이 별·천사 코디를 입혀 **별 빛나는 크리스마스 밤하늘(트리 꼭대기) 앞에서 찍은 한 장**으로". **올블랙·노란 눈은 의상이 바뀌어도 유지** — 검은 고양이가 어두운 밤하늘에 묻히지 않게 차콜 하이라이트·노란 눈·금색 별빛으로 떠 보이게.

```
[Attach: 1 = coco_idle.png (confirmed cat, identity lock), 2 = _src/coco_xmas_ref.png (tree-topper star / christmas angel costume reference, if available)]
ONE baked PHOTO (cheki snapshot): a CHRISTMAS TREE-TOPPER STAR / starlight-angel costumed SOLID-BLACK cat perched at the top of a giant tree in a STARRY CHRISTMAS NIGHT SKY. Tall vertical portrait, aspect ratio 120:180 (2:3), image filled edge-to-edge.
Keep image 1's CAT identity: the SAME SLENDER SOLID-BLACK cat with her EXACT look
(entirely BLACK fur everywhere, NO white markings; small pink nose, big YELLOW / amber eyes that glow like little stars), same face.
Costume — dress it as a cute TREE-TOPPER STAR / night-sky angel (age-safe):
- a glowing GOLD five-point STAR halo / headpiece framing the head, small GOLD angel wings, a silver-and-gold TINSEL scarf,
- a few golden star sparkles trailing off the black fur, both front paws gently together. Clearly the SAME all-black cat, just costumed; the black body reads like the night sky itself.
Background (baked in): the TOP of a giant CHRISTMAS TREE against a deep STARRY NIGHT SKY — glowing baubles, ornaments and warm string lights along the pine branches just below her, a big soft GOLD STAR glow around her, scattered twinkling STARS and a faint milky-way haze above;
  detailed along the TOP and SIDES, a softer bokeh haze in the CENTER, calm tree-top branches at the bottom.
Composition: the FULL cat (whole body, NOT cropped) sits in the lower-center IN FRONT of the scenery, reading clearly against the blurrier center; even margins.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO smooth gradients, flat shading; bokeh, stars & lights as clusters of flat stepped pixels. The black cat keeps charcoal midtones + highlights so it reads against the dark sky.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green or magenta anywhere.
Color mood: starry christmas night — deep navy & midnight blue, glowing GOLD star light, silver tinsel, pine-green branches with red & gold baubles; the all-black cat reads via charcoal highlights and her glowing yellow eyes.
```

### 네거티브 (코코 크리스마스 체키)

```
no human, no person, no second character (no Bana in frame), no text, no watermark, no logo, no QR code,
no readable signage, no real words, no brand name,
no DAYLIGHT / pastel-pink scene (this is a STARRY NIGHT sky), no bright sunny background, no purple gothic neon street,
no photo frame, no card border, no polaroid edge (frames are separate overlay layers — this pet cheki is a baked photo),
no WHITE markings / no tuxedo bib / no white blaze on the cat (Coco is SOLID BLACK with yellow eyes), no green eyes,
no Santa suit (that is Okja), no reindeer antlers (that is Sion),
no flat black blob cat (keep charcoal highlights so the black cat reads), no cropped cat (the whole body must be inside the frame),
no chroma green, no chroma magenta, no transparency, no empty/hollow area (this layer is FULLY OPAQUE),
no busy/cluttered center blocking the cat, no flat repeating pattern wall (the background is a SCENE),
no gradient, no soft anti-aliased edges, no realistic photo finish, no 3D render, no lens blur photo.
```

> ⚠️ **검수 포인트**: ① 올블랙 정체성(흰 얼룩 없음·노란 눈)이 **밤하늘 별 장식 안에서** 또렷한지(검은 고양이가 밤하늘에 묻히지 않게 차콜 하이라이트·노란 눈·금색 별빛으로 떠 보이는지) ② **`120×180`(2:3) 완전 불투명** ③ 고양이 **전신이 안 잘리고** 중앙에 읽히는지(발치 비움), 배경은 **평면 패턴이 아닌 트리 꼭대기·별 밤하늘 풍경**인지 ④ 마스터 팔레트 인덱싱 — ⚠️ **네이비·금·은(틴셀)** 커버가 충분한지 확인. 저장: `assets/sprites/photo_coco_xmas.png`.
> 🃏 **프레임 짝**: 일반 = `frame_standard`, **나비 승급** 시 `frame_xmas`(눈·리스) — 금·네이비 밤하늘과 톤이 잘 맞는다.

---

## 후처리 연결 (코코 — 받은 PNG → 규격 에셋)

```bash
# 코코 펫 반응 4종 (96×96, 크로마 그린 제거 — 노란 눈이라 그린 안전) — idle/snack/play/pet
tools/.venv/bin/python tools/dotify.py coco_idle_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/coco_idle.png
tools/.venv/bin/python tools/dotify.py coco_snack_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/coco_snack.png
tools/.venv/bin/python tools/dotify.py coco_play_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/coco_play.png
tools/.venv/bin/python tools/dotify.py coco_pet_raw.png \
  --size 96x96 --chroma 00ff00 --out assets/sprites/coco_pet.png

# 코코 인트로 지뢰계 체키 (배경 포함 베이크 — 120×180 불투명, 누끼 X·크로마 X)
tools/.venv/bin/python tools/dotify.py photo_coco_jirai_raw.png \
  --size 120x180 --out assets/sprites/photo_coco_jirai.png

# 코코 크리스마스 체키 (트리 토퍼 별/밤하늘 천사 — 배경 포함 베이크, 120×180 불투명)
tools/.venv/bin/python tools/dotify.py photo_coco_xmas_raw.png \
  --size 120x180 --out assets/sprites/photo_coco_xmas.png

# 코코 탭 미니 초상 (권장: coco_idle 얼굴 크롭본을 입력으로 — 초상 슬롯 중앙 정렬 자동)
tools/.venv/bin/python tools/dotify.py portrait_coco_raw.png \
  --size 24x24 --chroma 00ff00 --out assets/sprites/portrait_coco.png
```

> ⚠️ **바나 슬라이스 펫 코드분 대응(아트 확정 후)**: ① 펫 반응 4컷 누끼·`96×96`·마스터 팔레트 32색 ② `portrait_coco` 임포트·렌더 → 24×24 ③ 인트로 체키 베이크 → `photo_coco_jirai` ④ `data/characters.gd` 레지스트리에 `coco` 펫 항(`kind=PET`, `intro_event="mine"`, accent=퍼플) 추가 + 펫 라이브 스프라이트 경로 배선(`scripts/sioni.gd` 일반화 또는 `coco.gd`) + `data/events.gd`에 `"coco": true`(mine) 플래그.
> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
