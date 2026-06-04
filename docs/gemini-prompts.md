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
> **지뢰계 레퍼 코디**(첨부 사진): 레오파드 무늬 베레모 · 흰 시스루 시폰 블라우스(앞 리본 레이스업) · 검정 레이스 캐미솔 + 가슴 크로스 장식 · 연청 데님 미니 플리츠 · 십자가 목걸이 · 메탈하트/리본 벨트 체인 · **애쉬/라이트 브라운 트윈테일** · **한 손 얼굴 옆 손가락 펼친 시크 제스처** · **검정 통굽 플랫폼 크리퍼 스니커즈(별 장식 + 은색 체인) + 흰 슬라우치 양말**.

```
[Attach THREE images — 1: okja_idle.png (confirmed SD dot, identity lock),
 2: the jirai-kei outfit reference photo, 3: the shoes reference photo]

Keep image 1's character IDENTITY: same face shape, same eyes, same chic tsundere look,
same SD chibi proportions (head:body ≈ 1:3~1:4). RESTYLE her as the jirai-kei coordinate,
matching image 2 for outfit, HAIR and POSE, and image 3 for the shoes:
- Hair: ASH / LIGHT BROWN long TWIN-TAILS (match image 2's hair color — NOT wine-red here).
- Pose: standing, ONE hand raised up beside the face / forehead with fingers spread (chic gesture),
        the other arm relaxed at the side — match image 2 (NOT the clasped-hands idle pose).
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
no witch hat, no wine-red hair (this cut is brown), no original burgundy witch dress
(it is fully replaced by the jirai-kei outfit),
no plain flat shoes, no over-sexualized outfit (keep it cute girly-grunge, age-safe brand).
```

> ⚠️ **검수 포인트**: 체키 카드 안에 들어갈 정적 아트이므로 idle 앵커 일치는 불필요. **얼굴(옥자 정체성) 일관성 + 신발까지 프레임 안에 다 들어왔는지**를 본다. 레오파드/데님/체인은 색이 튀니 후처리 **마스터 팔레트 인덱싱 필수**. 저장: `assets/sprites/okja_jirai.png`.
> 💡 신발 사진 첨부가 안 되면(2장만 지원), `Shoes:` 줄의 텍스트 묘사만으로도 충분하다 — 3번 이미지 참조 문구만 지운다.
> 📌 **나머지 4종 의상(유치원·힙합·집사·크리스마스)도 같은 방식** — 모두 체키 카드용 정적 아트라 포즈·머리색 자유. 이 프롬프트를 베이스로 의상·신발 레퍼런스만 갈아끼우면 된다.

---

## 시온이 (펫)

```
Convert into retro pixel art, a chubby white cat with patches ("Sioni"), Okja's pet.
Small chibi sprite, front view, simple cute shape, sitting (idle).
Style: 8-bit pixel sprite, hard edges, NO anti-aliasing, limited palette.
Background: FLAT SOLID chroma green (#00ff00).
```

### 반응 변형

| 파일명 | 추가 문구 |
|---|---|
| `sioni_idle`  | `sitting calmly, tail curled.` |
| `sioni_treat` | `looking up happily at a treat, mouth open.` |
| `sioni_play`  | `playful pounce pose, paws up.` |
| `sioni_pet`   | `eyes closed, content, being petted.` |

---

## 나라카 지옥 배경 (교감화면 무대)

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

## 후처리 연결 (받은 PNG → 규격 에셋)

```bash
# 옥자 (128×288, 크로마 그린 배경 제거)
tools/.venv/bin/python tools/dotify.py okja_smile_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_smile.png

# 옥자 지뢰계 ★히어로 체키 (브라운·한 손 포즈 — 체키 카드용 정적 아트)
tools/.venv/bin/python tools/dotify.py okja_jirai_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_jirai.png

# 시온이 (48×48)
tools/.venv/bin/python tools/dotify.py sioni_idle_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_idle.png

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
