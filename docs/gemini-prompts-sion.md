# Gemini 도트 변환 프롬프트 — 시온이

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**(img2img). 공용 에셋·핵심 원칙은 [공통 파일](./gemini-prompts-common.md) 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))

> **시온이**: 옥자의 흰 얼룩 고양이. 곁의 교감 가능한 펫 + 수집 캐릭터.

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

### A8-1 — 시온이 60px (디오라마 받침 위 가독성)

> 디오라마(Phase 3.5)에선 시온이가 발치가 아니라 **선반 어깨 높이**에 앉아 옥자와 한 쌍으로 읽힌다. **그림은 위 프롬프트 그대로**, 출력만 `48→60px`. 새로 그릴 필요 없이 **기존 raw(또는 확정 idle)를 `--size 60x60`으로 재출력**하고, `sioni.gd`의 `SPR_SIZE`를 `Vector2(60,60)`으로 올린다(앵커=바닥 중앙은 동일). 4종(idle/snack/play/pet) 모두 60px.

### 시온이 탭 미니 초상 (`portrait_sion`)

> 컬렉션북 탭·로스터 선택 화면의 시온이 식별 초상(24×24). **권장: 생성하지 말고 크롭** — 확정된 `sioni_idle.png`에서 **얼굴(검은 두건+흰 가르마+코)을 정사각으로, 좌·우·위 여백을 똑같이 두고** 크롭 → `dotify --size 24x24`.
> ⚠️ **왼쪽 잘림 원인 = 얼굴이 정중앙이 아니라 왼쪽으로 치우친 채 크롭/생성됨.** 재작업 시 **정면·정중앙·사방 균등 여백**(얼굴이 어느 가장자리에도 닿지 않게)을 반드시 못 박는다. 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
[Attach: 확정된 sioni_idle.png 또는 assets/sprites/_src/sion_ref.png]
Pixel art / dot art tiny SQUARE PORTRAIT bust (cat FACE + a little shoulder), STRICT FRONT view,
PERFECTLY CENTERED with EQUAL margins on the LEFT, RIGHT and TOP — the face must NOT touch or run off any edge,
leave a small even gap on every side.
Subject: "Sioni", Okja's VERY ROUND chubby cat — base coat MOSTLY WHITE, big round eyes, small PINK nose.
Markings (keep EXACT): a BLACK cap over the top of the head and ears, SPLIT down the middle by a WHITE
         center blaze (center hair-parting "gareuma"), roughly SYMMETRIC. ONE tiny BROWN mark on the pink nose ONLY.
         Clearly a CAT (NOT a fox, NOT a human).
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use 2-3 tones per color (highlight, midtone, shadow), NOT flat single-tone fills. Match the Okja/Miho portrait shading depth.
Color mood: white fur with BLACK center-parted head markings, pink nose, tiny brown nose mark.
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

```
[네거티브] no off-center / left-shifted face, no face touching or cropped by ANY edge,
no full body, no tiny face with huge empty margins, no text, no extra characters, no scenery,
no fox ears (this is a CAT), no witch hat, no large brown face patch (brown is ONLY a tiny nose mark),
no all-white head (keep the BLACK center-parted cap), no chroma green on the cat,
no gradient, no soft anti-aliased edges, no 3D render.
```

---

## 시온이 생애단계 (펫 육성 — D0 · 16컷)

> 설계 단일 출처: **[ADR 0005](./adr/0005-pet-raising-growth-axis.md)**(펫 육성 = 분기형 진화) · 아트 스펙: **[art-spec-pet-growth.md](./art-spec-pet-growth.md)** · 도트 규격: **[ADR 0001](./adr/0001-dot-art-spec.md)**.
> 같은 **아기** → (간식/놀기 밸런스) → **성체 3분기**(마른/보통/뚱뚱). 중간 **유년**은 단일(분기 미노출).
> **신규 = 16컷**: 아기4 + 유년4 + 마른4 + 통통4. **보통(=캐논)은 기존 `sioni_*` 4컷 재사용 → 0**(이미 통통-귀여운 배포 그림을 대표로 승격, 양 끝 *더 마름*·*더 통통*만 신규).
> **🔑 정체성 락**: 모든 단계가 위 베이스와 **같은 흰 얼룩 고양이** — 바탕 흰색, **검은 가르마 두건**(가운데 흰 줄로 갈린 대칭 검은 캡 + 꼬리/몸 검정), **작은 핑크 코에 갈색 점 하나**(갈색은 코에만). 차이는 **체형/체급뿐**(얼굴·무늬·색 공유). 확정된 `sioni_idle.png`를 첨부해 단계마다 일관시킨다.
> **규격**: `96×96`(매니페스트 size 96 + `fill:true` · 구 preset `sioni`는 48px 레거시 — 생애단계는 96px), **NEAREST·마스터 팔레트·발밑(하단 중앙) 피벗**. 아기는 캔버스 안에서 *작게*(여백 큼), 자랄수록 더 채운다. 크로마 그린 `#00ff00` 배경.

### 단계별 체형 수식어 (베이스에 한 줄 — 같은 고양이, 체급만 변경)

| 단계 | 파일 접두어 | 추가 문구(체형) |
|---|---|---|
| 아기 (baby) | `sioni_baby_*` | `Life stage: a TINY KITTEN — small, soft and extra-round (a little "꼬물이" puffball), short stubby legs, oversized round head & eyes, baby proportions. Occupies the LOWER-CENTER of the canvas leaving generous empty margin around (it is small).` |
| 유년 (child) | `sioni_child_*` | `Life stage: a YOUNG cat (adolescent) — bigger than the kitten but not yet a full adult, slightly slimmer middle form, lanky-cute, growing into the body. Fills more of the canvas than the baby, still some margin.` |
| 성체 마른 (thin) | `sioni_thin_*` | `Life stage: a SLENDER ADULT — noticeably LEANER and SLIMMER than the canon cat, sleek and athletic silhouette, slim waist and longer legs, still clearly the SAME white cat. Fills the canvas like an adult.` |
| 성체 통통 (fat) | `sioni_fat_*` | `Life stage: a VERY ROUND, EXTRA-CHUBBY ADULT — even FATTER and rounder than the canon cat, a big plump ball-shaped body, the legs nearly hidden under the round belly, maximally pudgy & cozy. Same white cat. Fills the canvas like a large adult.` |
| 성체 보통 (normal=**캐논**) | — | **신규 생성 없음** — 기존 `sioni_idle/snack/play/pet.png` 재사용(코드에서 `stage=normal` → 접두어 없는 레거시 파일로 alias). |

### 반응 4종 — 위 [반응 4종 표](#반응-4종--베이스에-한-줄만-추가-얼굴자세만-변경)와 동일 (얼굴·자세만 변경)

각 단계 × 반응 4종 = 16컷. 포즈 문구는 베이스 반응 표를 그대로 재사용한다:

- `*_idle` → `Pose: sitting calmly, tail curled around the feet, content.`
- `*_snack` → `Pose: looking UP happily at a treat, mouth open, eager.`
- `*_play` → `Pose: playful pounce, front paws up, ears perked.`
- `*_pet` → `Pose: eyes closed, blissful, head tilted as if being petted.`

> **조립법**: `[베이스 시온이 프롬프트]` + `[단계별 체형 수식어 한 줄]` + `[반응 포즈 한 줄]`. **팁**: 단계마다 그 단계의 `idle` 1장을 먼저 확정(정체성+체형 락)한 뒤, 그 결과를 레퍼런스로 첨부해 나머지 3종(snack/play/pet)을 뽑으면 체형·얼룩이 흔들리지 않는다.

### 네거티브 (생애단계 — 베이스 네거티브에 더함)

```
no costume / no clothes (life-stage sprites are the PLAIN base cat — costumes are cheki-only),
keep it the SAME white cat with the BLACK center-parted head cap + tiny brown nose mark (markings must NOT change between stages — ONLY the body size/build changes),
for baby: no adult proportions, no slim athletic build; for thin: no fat round body (it must be LEANER than canon);
for fat: no slim/normal build (it must be ROUNDER/FATTER than canon),
no full-canvas baby (the kitten is SMALL with margin), no fox, no human,
no text, no watermark, no scenery, no chroma green on the cat, no gradient, no soft anti-aliased edges, no 3D render.
```

### 후처리 (생애단계 16컷 — 받은 PNG → 96×96 누끼 · 단계별 크기)

> **🔑 크기 위계는 픽셀에 굽는다(런타임 scale 아님)** — 같은 96×96 캔버스 안에서 단계별 `--fill-scale`로 **콘텐츠를 작게/크게 채우고 발은 바닥에 정렬**한다(발밑 피벗 = 솟아오르는 성장감). 렌더는 `sioni.gd` scale 1.0 그대로(프로젝트 관례: 물리 크기는 PNG에, 코드는 native). D1 진화 엔진은 prefix만 스왑하면 즉시 크기가 바뀐다.
> **단계별 비율**(콘텐츠 높이 ÷ 96): **아기 50% · 유년 68% · 성체(마름·통통) 82%(=캐논과 동일 "지금 크기")**. `--fill-scale` 값 = 목표비율 ÷ 0.96(머리여백).
> **🔑 발밑 여백 `--foot-margin 10`(필수)** — 시온이는 디오라마 받침에 앉아 **발이 캔버스 바닥이 아니라 row 86(발여백 10px)**에 온다(캐논 `sioni_idle` 과 동일, `cafe.gd SIONI_PAD_BOTTOM=11`·그림자 정합). 이걸 빼면 단계들이 캐논보다 10px 아래로 내려가 **그림자와 어긋난다**. **도트 스튜디오**에선 A16 슬롯 선택 시 "부분 충전"·"발밑 여백" 슬라이더가 자동 세팅된다(별도 입력 불필요).

```bash
# 단계별 fill_scale (아기 작게 → 성체 캐논 크기) + 발밑 여백 10(캐논 발 높이 정합).
declare -A FS=( [baby]=0.52 [child]=0.70 [thin]=0.86 [fat]=0.86 )
for st in baby child thin fat; do
  for r in idle snack play pet; do
    tools/.venv/bin/python tools/dotify.py sioni_${st}_${r}_raw.png \
      --size 96x96 --chroma 00ff00 --fill --fill-scale ${FS[$st]} --foot-margin 10 \
      --out assets/sprites/sioni_${st}_${r}.png
  done
done
# 보통(normal=캐논)은 기존 sioni_idle/snack/play/pet.png 재사용 → 생성 없음(이미 ~82%·발여백 10)
```

> ⚠️ raw 가 아니라 **이미 구운 96×96 누끼(투명 PNG)에서 다시 크기·발높이만 조절**할 땐 `--chroma` 대신 `--transparent` 를 쓴다(`--size 96x96 --transparent --fill --fill-scale … --foot-margin 10`). 크로마를 빼면 투명 영역이 불투명 처리돼 "100% 충전"으로 잘못 측정된다.
> **산출/검수(art-spec §5)**: `assets/sprites/`에 16컷 → 임포트(`godot --headless --import`) 후 `tools/audit_sweep.py`(팔레트·96×96·알파 — 부분충전은 충전율 기대치를 비율만큼 낮춰 통과)·`tools/verify_cheki_art.gd`(펫 순회) → 디오라마 ×1/×2 또렷. **도트 스튜디오** 체크리스트 그룹 **A16**에 `96×96 · 충전 N%`로 슬롯이 떠 진행률로 추적된다.

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

## 후처리 연결 (시온이 — 받은 PNG → 규격 에셋)

```bash
# 시온이 펫 반응 (48×48, preset sioni — 교감화면 기본 흰 고양이)
tools/.venv/bin/python tools/dotify.py sioni_idle_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_idle.png
tools/.venv/bin/python tools/dotify.py sioni_snack_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_snack.png
tools/.venv/bin/python tools/dotify.py sioni_play_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_play.png
tools/.venv/bin/python tools/dotify.py sioni_pet_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_pet.png

# A8-1 시온이 60px (그림 동일, 출력만 48→60 — 기존 raw/idle 재출력 후 sioni.gd SPR_SIZE=60)
tools/.venv/bin/python tools/dotify.py sioni_idle_raw.png \
  --size 60x60 --chroma 00ff00 --out assets/sprites/sioni_idle.png
tools/.venv/bin/python tools/dotify.py sioni_snack_raw.png \
  --size 60x60 --chroma 00ff00 --out assets/sprites/sioni_snack.png
tools/.venv/bin/python tools/dotify.py sioni_play_raw.png \
  --size 60x60 --chroma 00ff00 --out assets/sprites/sioni_play.png
tools/.venv/bin/python tools/dotify.py sioni_pet_raw.png \
  --size 60x60 --chroma 00ff00 --out assets/sprites/sioni_pet.png

# 시온이 체키 사진 (배경 포함 베이크 — 120×180 불투명, 누끼 X·크로마 X, 전신+풍경 2:3 한 장)
tools/.venv/bin/python tools/dotify.py photo_sion_jirai_raw.png \
  --size 120x180 --out assets/sprites/photo_sion_jirai.png
tools/.venv/bin/python tools/dotify.py photo_sion_xmas_raw.png \
  --size 120x180 --out assets/sprites/photo_sion_xmas.png

# 탭 미니 초상 (→ 위 "시온이 탭 미니 초상" 섹션)
# preset portrait = 24×24 + 콘텐츠 크롭 후 사방 균등 여백 '중앙 정렬'(좌우 잘림/여백0 방지).
# 도트 스튜디오에선 초상 슬롯이 "중앙 정렬"을 자동 ON 한다(별도 플래그 불필요).
tools/.venv/bin/python tools/dotify.py portrait_sion_raw.png \
  --preset portrait --chroma 00ff00 --out assets/sprites/portrait_sion.png
```

> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
