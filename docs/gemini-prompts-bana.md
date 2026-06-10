# Gemini 도트 변환 프롬프트 — 바나 (뱀파이어 메이드)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**(img2img). 공용 에셋·핵심 원칙·체키 합성 조각은 [공통 파일](./gemini-prompts-common.md) 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))
> **확장 트랙 — 바나 슬라이스(미호 다음).** 확장 트랙 원칙상 **아트가 항상 코드보다 먼저**다(→ 메모리 `character-expansion-plan`). 메인 캐릭터(라이브)이므로 옥자·미호와 동일한 **표정 스왑 SD 라이브**(ADR 0001) 규격.

> **바나 (Bana)**: 뱀파이어 메이드. 반려묘 **코코**(까맣고 마른 고양이 — 프롬프트는 [코코 파일](./gemini-prompts-coco.md)). 시그니처 음료 **블러디 미드나잇**. 로스터 accent색 **퍼플/바이올렛**(실물 의상 톤 반영 — 옥자 버건디·미호 노랑/골드와 겹치지 않음). 인트로 이벤트 = **지뢰계**(미호 선례, `events.gd` `mine`→`jirai`).

> **🔑 레퍼런스 첨부 필수**: 바나 실물 사진을 `assets/sprites/_src/bana_ref.png`(얼굴 선명·메인)에 두고 첨부해 **img2img**로 뽑는다(옥자·미호와 동일 — 텍스트만으론 얼굴이 매번 흔들린다). 보조 레퍼(전신·의상 각도)가 생기면 `bana_ref_b.png`. 표정 6종은 **첫 1장(`bana_idle`)을 확정**한 뒤 그 결과를 레퍼런스로 첨부하며 나머지를 뽑으면 일관성이 크게 오른다.
> **🔑 정체성(고정) — 실물 레퍼 기준**: ① **플래티넘/베이지 블론드**(밝은 금발) 긴 머리, 부드러운 웨이브(양갈래로 살짝 모은 느낌 OK) ② **블랙 + 퍼플 고딕 로리타 메이드룩** — 검정 보디스에 **퍼플 새틴 리본/프릴 + 화이트 레이스 프릴**, 메이드 헤드드레스, **목에 초커(리본·하트 펜던트)** ③ **뱀파이어 표식** — **창백한 피부**, 살짝 보이는 **작은 송곳니**, **루비/와인레드 눈**, 박쥐 모티프 소품(작은 박쥐 헤어핀·박쥐 날개 초커 등 작게) ④ 시그니처 액센트 = **퍼플/바이올렛 + 블러드레드**. 옥자(시크 츤데레)와 대비되는 **요염하지만 애교 있는·도도한 뱀파이어 아가씨** 무드.

> **🔑 SD·셰이딩 락(미호 교훈 그대로 — 두 번 빗나간 함정)**: ① `flat shading` 문구는 **납작·밋밋**을 부르니 쓰지 말고 → **"색마다 2~3톤 도트 셰이딩"**, ② `SLIM`·"늘씬" 과강조는 **머리 작고 다리 긴 일반 등신비(SD 아님)** 를 부르니 쓰지 말고 → **옥자급 SD(머리 ≈ 전체 높이의 1/3, 다리 짧게)** 로 못박는다.
> **🔑 결정적 해법 = 옥자 idle을 앵커로 첨부**: 실물 사진만 img2img하면 **무조건 일반 등신비**로 나온다(머리 작고 다리 김). **반드시 `assets/sprites/okja_idle.png`(확정 SD)를 1번 이미지(비율·도트 스타일 앵커)로, 바나 실물을 2번(얼굴·정체성)으로 첨부**하고 "얼굴·뱀파이어 정체성은 2번에서, 등신비·도트 스타일은 1번(옥자)과 똑같이"라고 지시한다. 텍스트만으론 SD·셰이딩 둘 다 또 빗나간다.
> **⚠️ 단 앵커의 '색'은 가져오지 말 것(버건디 함정)**: 옥자 idle은 **버건디/와인** 의상이라, 앵커로 쓰면 바나 드레스까지 **버건디로 번진다**(실제 발생). 1번에선 **비율·도트 스타일만**, 색은 2번 + 텍스트 기준 — **바나 드레스 = 블랙 + 퍼플/바이올렛(amethyst), 버건디 금지**(블러드레드는 작은 액센트만). 팔레트도 퍼플 램프(`341d4e`·`5b3d7a`·`7a4cae`·`9a6fd0`)를 보강해 진보라가 회보라·버건디로 뭉개지지 않게 했다.

---

## 공통 베이스 (바나 SD) ★라이브 스탠딩용

> 옥자·미호와 동일하게 **SD 치비(머리 ≈ 전체 높이의 1/3, 1:2.5~3)** 로 간다 — 다마고치 LCD에서 표정 6종이 읽히려면 머리를 키워야 한다. 머리 크기·다리 짧음은 옥자 idle 첨부로 강제(위 SD 락 참조).
> **🔑 프레임 충전 = 옥자와 동일 스케일(중요)**: 라이브 스탠딩은 **머리가 상단, 발이 하단에 닿게 프레임을 꽉 채워야** 교감화면에서 옥자와 크기가 맞는다(옥자 idle = 높이 충전 ~96%, 발 바닥여백 0).
> **🔑 충전은 `dotify`가 자동**: `--preset okja`(캐릭터)는 **콘텐츠 bbox 크롭 → 높이 충전 → 하단 정렬**을 자동 적용한다(`FILL_PRESETS`). 여백 많은 원본도 발이 바닥에 붙는다. 끄려면 `--no-fill`.
> **⚠️ 단 폭이 관건**: 충전은 **높이 우선이되 폭이 캔버스(128)를 넘으면 폭 기준으로 제한**(팔·치마 잘림 방지)되어 높이가 덜 찬다. 그래서 **① 스커트/프릴을 양옆으로 과하게 퍼뜨리지 말고 ② 박쥐 날개·소품은 몸 가까이 작게**. dotify가 출력 후 **높이충전·바닥여백을 자동 리포트**한다(`높이충전 ≥90%`, `바닥여백 ≤4px`). ❌ 뜨면 ①②를 손봐 재생성.

```
[Attach: 1 = okja_idle.png — the SD PROPORTION & DOT-STYLE ANCHOR (copy its build), 2 = Bana's real photo — her FACE & identity]

Draw a CUTE SD / CHIBI pixel-art sprite of "Bana", full body, front-facing standing pose.
Take her FACE and IDENTITY from image 2, but COPY ONLY the SUPER-DEFORMED body proportions and dot-art STYLE of image 1 (Okja)
         — do NOT copy image 1's BURGUNDY / WINE colors. Bana's dress is BLACK & PURPLE / violet, NOT red/burgundy like Okja.
Subject: "Bana", a VAMPIRE MAID at a hell-themed maid cafe — elegant, coquettish yet sweet, a touch haughty.
Proportions (MUST MATCH IMAGE 1, the Okja sprite): SUPER-DEFORMED chibi — a BIG ROUND head about ONE THIRD of the
         total height, large expressive eyes, a small compact body and SHORT STUBBY legs. NOT a tall or realistic
         figure, NOT long legs, NOT a normal 5-6-heads-tall girl. Same SD build, NARROW WIDTH and on-screen scale as Okja (clear SIDE MARGINS — the body must NOT touch the left/right edges).
Vampire features (keep EXACT, from image 2): PALE porcelain SKIN, RUBY / wine-RED eyes, tiny cute FANGS just peeking
         when the mouth opens. A small BAT motif accent (a little bat hairpin or a bat-wing charm on the choker) — keep it SMALL.
Hair: long, PLATINUM / BEIGE BLONDE hair with soft waves, loosely gathered (twin-gathered look is fine), with a maid headdress on top.
Outfit: a BLACK & PURPLE gothic-lolita MAID look — a black bodice with clearly PURPLE / VIOLET SATIN ribbons & frills
         (a saturated amethyst purple, NOT burgundy/wine/red) + WHITE LACE frills,
         a maid headdress, and a CHOKER with a ribbon / heart pendant at the neck. Signature accents = PURPLE / violet (blood-red ONLY as a tiny accent).
Style (MATCH IMAGE 1): 8-bit pixel sprite / dot art, limited palette, hard pixel edges, NO anti-aliasing, NO gradients,
         dot-art shading with 2-3 tones per color (highlight, midtone, shadow) — NOT flat single-tone fills.
Color mood: gothic vampire palette — INK BLACK & deep PURPLE / VIOLET dress (amethyst purple, NOT burgundy/wine/red), WHITE lace, platinum-blonde hair, pale skin,
         ruby-red eyes & blood-red accents; keep a NARROW COLUMNAR silhouette — skirt slim and NOT flared, arms & bat wings close to the body, NOT spread to the side edges.
Framing: full body centered, head near the TOP edge and feet near the BOTTOM edge, NOT floating; tall vertical 4:9
         portrait ratio, consistent crop across all expressions.
         Lower body and short legs IDENTICAL across all expressions — only the FACE and ARM pose change.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (바나 공통)

```
no text, no watermark, no signature, no multiple characters, no cropped limbs, no cropped skirt,
no realistic / normal body proportions, no long legs, no adult tall figure, no 5-6-heads-tall girl,
no small head (the head MUST be ~1/3 of the total height like the Okja anchor), no tiny face,
no baby-only infantile style (keep her elegant vampire charm),
no small figure with large empty margins, no floating character above the bottom edge,
no excessive headroom or footroom (head near top, feet on the bottom edge — fill the frame),
no witch hat (that is Okja — Bana is a vampire maid), no fox ears, no cat ears, no animal ears (she is human-shaped),
no dark gothic witch dress identical to Okja (Bana's look is BLACK & PURPLE gothic-lolita MAID), no black hair, no brown hair (hair is PLATINUM BLONDE),
no BURGUNDY / WINE / RED dress, no maroon frills (the dress is PURPLE / violet amethyst — do NOT copy Okja's burgundy from the anchor image; blood-red is a TINY accent only),
no wide flared skirt, no spread arms, no huge spread bat wings — the silhouette must NOT fill the full frame width (keep clear side margins like Okja), no big visible fangs / monster mouth (fangs are tiny and cute),
no flat single-tone coloring, no flat shading (must have highlight+midtone+shadow per color),
no smooth vector / cartoon / anime illustration look, no soft airbrushed or blurred cheeks,
no oversimplified low-detail sprite (it must be as detailed and shaded as the Okja sprite),
no background scenery, no gradient background, no soft anti-aliased edges,
no realistic photo finish, no 3D render, no over-sexualized outfit (keep it cute gothic, age-safe brand).
```

### 표정 6종 — 베이스에 한 줄만 추가

**다리·하체·프레이밍은 고정**하고, **얼굴 표정 + 팔 자세**만 바꾼다(팔도 그림에 박는다 — 리깅 아님). 표정별 사진이 있으면 각각 변환이 더 정확.
> **셰이딩은 6종 전부 베이스 그대로** — 아래 행은 표정·팔만 추가하고, 도트 셰이딩(색마다 2~3톤, flat 금지)·픽셀 규격은 위 공통 베이스를 그대로 따른다. idle만 셰이딩 박고 나머지를 밋밋하게 뽑지 말 것(생성 시 idle 결과를 레퍼로 첨부하면 5종도 톤이 맞는다).

| 파일명 | 추가 문구 |
|---|---|
| `bana_idle`  | `Expression: calm, elegant, mouth closed (a faint cool smile). Arms: both hands clasped together in front (default), like a poised maid.` |
| `bana_smile` | `Expression: bright, charming smile with tiny fangs just showing, eyes gently curved, affectionate. Arms: both hands clasped up near the chest, delighted.` |
| `bana_shy`   | `Expression: shy, blushing on the pale cheeks, eyes averted. Arms: one hand raised, covering the mouth (hiding the little fangs).` |
| `bana_sad`   | `Expression: sulky / pouting, downturned mouth (NEVER crying). Arms: lowered and drooping limply, a little forlorn.` |
| `bana_brew`  | `Expression: focused, playful "brewing". Arms: holding her signature drink "Bloody Midnight" in both hands — a tall dark goblet / glass with a deep BLOOD-RED cocktail, a cherry & a tiny bat pick on top.` |
| `bana_talk`  | `Expression: mouth slightly open talking (a tiny fang peeking), confident-sweet. Arms: one hand raised in a graceful gesture.` |

> ⚠️ **6종 전부 팔 자세가 다르다** (다리·하체·프레이밍은 고정). 전환은 하드컷이라 팔 차이가 커도 OK. 기쁨 "폴짝" 같은 전신 포즈는 별도로 그리지 않고 `bana_smile`을 리워드 순간에 **코드 hop**으로 재사용한다. 슬픔은 **시무룩까지** — 우는 그림 금지(벌 없는 설계).
> 🍷 **`bana_brew` = 블러디 미드나잇 제조 컷 겸용** — 별도 음료 컷을 그리지 않고 이 brew 표정(핏빛 고블릿을 든 손)으로 대체한다(옥자·미호 brew와 동일 원리). 데모는 brew 1장으로 충분.

---

## 바나 탭 미니 초상 (`portrait_bana`)

> 컬렉션북 탭·로스터 선택 화면의 바나 식별 초상(24×24). 레지스트리가 `portrait_%s.png % id`로 경로를 파생하니 파일명은 **`portrait_bana.png`** 고정.
> **권장: 생성하지 말고 크롭** — 확정된 `bana_idle.png`에서 **얼굴(헤드드레스 포함)을 정사각으로 크롭** → `dotify --size 24x24`. 라이브 바나는 기본 메이드룩이라 idle 얼굴이 탭 정체성과 일치한다.
> 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
Pixel art / dot art tiny SQUARE PORTRAIT bust (face + shoulders), front view, centered, BIG readable face.
Subject: "Bana", a cute VAMPIRE maid — PALE skin, RUBY-red eyes, tiny cute FANGS, platinum-blonde wavy hair,
         a maid headdress, a black & PURPLE gothic-lolita collar with WHITE LACE and a choker.
         Clearly a vampire girl (NOT a witch, NOT a fox, NOT a cat).
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use rich dot-art shading — 2-3 tones per color (highlight, midtone, shadow), NOT flat single-tone fills.
       True pixel art, NOT a smooth vector / cartoon look. Match the Okja portrait's shading depth.
Color mood: gothic vampire — black & PURPLE with white lace, platinum hair, pale skin, ruby eyes (shaded, not flat).
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

```
[네거티브] no full body, no tiny face, no text, no extra characters, no scenery,
no witch hat, no fox/cat ears, no black hair (PLATINUM BLONDE), no big monster fangs,
no chroma green on the subject, no gradient, no soft anti-aliased edges, no 3D render.
```

---

## 바나 인트로(지뢰계) 의상 체키 (이벤트 의상 1벌)

> 바나 슬라이스의 **인트로 체키** — 온보딩에서 바나를 고르면 주는 첫 체키(미호 선례). 옥자·미호와 동일하게 **지뢰계 데이** 의상이 인트로 슬롯이다. **체키 카드용 정적 아트** — 교감화면 스킨 아님이라 포즈·헤어 변주 자유(라이브 바나는 메이드룩 고정).
> **🔑 워크플로우(옥자·미호 지뢰계와 동일)**: **① 확정된 `bana_idle.png`(SD 도트 — 얼굴·뱀파이어 정체성·등신비 락) + ② 지뢰계 레퍼런스 사진(의상·헤어·포즈 락)**(+선택 ③ 신발 레퍼)을 첨부하고 "1번 캐릭터를 2번 코디로 다시 그려라". **창백한 피부·루비 눈·작은 송곳니는 의상이 바뀌어도 유지**(바나의 핵심 정체성).
> **🔑 지뢰계 코디 가이드(★실물 레퍼 `bana_jirai_ref.png` 기준 확정)**: 바나만의 톤 = **"다크 그런지 뱀파이어 지뢰계"** — 옥자(핑크 레이스)·미호(레오파드 갸루)·규종이(파스텔 마이멜로디풍)와 구분된다. 실물 코디 = **① 블랙 니트 베레모 + 메탈 아일렛(그로멧 링) 스터드 ② 블랙 디스트레스드/립트(구멍 뚫린) 오버사이즈 그런지 니트 스웨터(긴소매·살짝 오프숄더) ③ 레오파드(치타) 프린트 미니 스커트 ④ 가느다란 실버 체인 네크리스**. 헤어는 **플래티넘 블론드 다운 + 시스루 앞머리**(트윈테일 아님). 메이크업 = **와인/다크로즈 립·스모키**. 포즈는 **한 손을 턱·얼굴 옆으로 들어올린 셀카 무드**(살짝 고개 기울임). **창백한 피부·루비 눈·작은 송곳니는 의상이 바뀌어도 유지**(바나 핵심 정체성 — 실물 눈색은 무시하고 루비로).
> ✅ **지뢰계 레퍼 사진 확보됨** — `assets/sprites/_src/bana_jirai_ref.png`(의상·헤어·포즈 락). 위 코디는 이 사진 기준으로 확정한 것이니 생성 시 반드시 첨부한다.

```
[Attach: 1 = bana_idle.png (confirmed SD dot, identity lock), 2 = bana jirai-day reference photo (outfit + pose lock)]
Keep image 1's character IDENTITY: same face, same VAMPIRE look (PALE skin, RUBY-red eyes, tiny cute FANGS),
same SD chibi proportions (head:body ≈ 1:3~1:4), and KEEP these even in the new outfit.
RESTYLE her into her JIRAI-DAY coordinate (image 2) — a DARK GRUNGE VAMPIRE JIRAI-KEI ("landmine girl") look (cute-gothic, age-safe):
- Hair: long platinum / silver BLONDE with soft waves, worn DOWN with see-through BANGS (NOT twin-tails).
- Hat: a BLACK KNIT BERET with METAL EYELET / grommet ring studs around it, tilted on the head.
- Top: an oversized BLACK DISTRESSED / RIPPED open-knit grunge SWEATER (holey loose knit, long sleeves, slightly off one shoulder).
- Bottom: a LEOPARD / cheetah PRINT mini skirt peeking at the bottom hem.
- Accessories: a thin SILVER CHAIN necklace at the neck (delicate, not chunky). Lips: dark rose / wine; smoky eyes.
- Shoes: chunky platform boots (feet not in the ref — keep them simple).
- Pose (KEEP from image 2): a cute JIRAI SELFIE — head slightly tilted, one hand raised beside the chin / face,
  big ruby eyes, cool-cute confident look.
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use rich dot-art shading — 2-3 tones per color (highlight, midtone, shadow) on hair, pale skin, the black knit
       beret & distressed sweater, the leopard skirt and accessories; NOT flat single-tone fills. True pixel art, NOT a smooth vector / cartoon look.
       Match the Okja sprite's shading depth and pixel crispness.
       Keep her clearly the SAME Bana (pale skin + ruby eyes + tiny fangs intact), dark grunge vampire jirai mood, age-safe.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom,
         tall vertical 4:9 portrait, even margins, a NARROW silhouette well within the frame width (clear side gaps, NOT edge-to-edge).
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (바나 지뢰계 — 공통 네거티브에 더한다)

```
no different face, no extra characters, no cropped feet, no missing fangs, no missing pale skin,
no witch hat, no fox/cat ears, no original maid headdress dress (it is fully replaced by the jirai-day outfit),
no twin-tails (hair is worn DOWN with bangs), no black hair (hair stays PLATINUM / SILVER BLONDE),
no clean / smooth knit (the sweater is DISTRESSED, ripped, holey grunge knit), no beret without the metal eyelet studs,
no purple plaid / check skirt, no metal-heart buckles (this look uses a LEOPARD skirt + studded knit beret + thin silver chain),
no huge spread bat wings, no chunky / oversized necklace (it is a thin delicate chain),
no pink-lace girly blouse identical to Okja (this is a DARK GRUNGE black vampire jirai look),
no flat single-tone coloring, no flat shading, no smooth vector / cartoon / anime look, no soft airbrushed cheeks,
no oversimplified low-detail sprite (match the Okja sprite's shading & detail),
no realistic body proportions, no long thin legs, no adult tall figure, no tiny face,
no over-sexualized outfit (keep it cute jirai-kei, age-safe brand).
```

> ⚠️ **검수 포인트**: 체키 카드 안에 들어갈 정적 아트이므로 idle 앵커 일치는 불필요. **얼굴(바나 정체성) + 창백한 피부·루비 눈·작은 송곳니 유지 + 신발까지 프레임 안에 다 들어왔는지**를 본다. 또 **블랙 니트 베레모(메탈 아일렛)·디스트레스드 그런지 니트·레오파드 스커트·실버 체인·턱 옆 셀카 포즈**가 살았는지 확인. 블랙·레오파드·블론드·메탈은 색이 튀니 후처리 **마스터 팔레트 인덱싱 필수**. 저장: `assets/sprites/bana_jirai.png`.
> 🃏 **체키 합성 레이어**: 바나 지뢰계 체키 = `bana_jirai`(누끼) + **바나 전용 배경 `bg_cheki_bana_jirai`**(아래 신설) + 이벤트 공통 `frame_jirai`(→ [공통 파일](./gemini-prompts-common.md)). **프레임은 이벤트 데이 공통, 배경은 멤버별**(ADR 0003 개정) — 바나 배경도 네온 야경 팔레트는 유지하되(공통 프레임과 짝) 스팟·연출을 바나 의상에 맞춘다.
> 📌 **이후 이벤트 의상(유치원·힙합·집사·크리스마스 등)은 별도 아트 트랙으로 점증** — 5벌 선결 금지. 의상 + 짝 배경(`bg_cheki_bana_{slug}`)을 한 세트로 갈아끼우면 된다.

---

## 바나 지뢰계 체키 사진 배경 (`bg_cheki_bana_jirai`)

> **베이스 = [공통 파일](./gemini-prompts-common.md)의 "체키 사진 배경 — 지뢰계"**(규격 `120×180` 완전 불투명, 누끼 X·크로마 X, 중앙·하단 발치 비움, 도트 보케). **공통 프레임(`frame_jirai`)과 짝이라 네온 야경 팔레트(네이비·블랙 + 네온 핑크/퍼플)는 유지**하되, **바나의 스팟 = 보랏빛 네온 + 박쥐·달이 뜬 고딕 야경 골목**(옥자=시부야 큰길·미호=홍등 야시장과 구분되는 바나만의 현장 — 퍼플 네온이 dominant, 보름달·박쥐 실루엣·고딕 아치 간판).
> **🔑 생성 방식 = `text2img`(레퍼 첨부 금지)**: 이 배경은 인물 없는 순수 풍경이라 **실물 사진을 첨부하지 않고 텍스트만**으로 뽑는다. 일본 거리·겨울·다른 도시 사진을 레퍼로 붙이면 그 구조가 텍스트를 덮어써 **엉뚱한 장면(예: 일본 성하촌 눈거리)** 이 나온다(색 무드만 퍼플로 적용되어 "하늘만 보라"인 채 장면이 빗나감). 레퍼는 떼고 돌릴 것.
> **🔑 하늘 = 짙은 미드나잇 블루, 퍼플은 네온 사인으로** — `Color mood`에서 **하늘은 deep midnight blue/navy**로 잡고 **퍼플/바이올렛은 네온 글로우 액센트**로 분리한다(이전엔 violet dominant라 하늘까지 통째로 보라로 떴다). 바나 정체성 퍼플은 네온·간판·발치 반사로 충분히 살고, 하늘은 차분한 블루라 캐릭터가 더 또렷이 읽힌다. 더 보랏빛으로 가고 싶으면 `deep midnight blue`→`deep blue-violet`로 한 단 올린다.

```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a JIRAI-KEI ("landmine girl") girl's NIGHT street with a GOTHIC VAMPIRE vibe.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a neon-lit night street with a gothic twist at the top and sides — glowing PURPLE and pink NEON SIGNS and gothic-arched shop
      signboards (abstract glyph-like glow, NOT real letters), a big pale FULL MOON, small BAT silhouettes fluttering across the sky,
      tall dark buildings, soft round BOKEH light orbs; a WET sidewalk at the bottom catching purple neon REFLECTIONS.
Depth: detailed glowing signs, the moon and bats along the TOP and the two SIDE edges; the CENTER is a softer, blurrier BOKEH haze of
      purple city lights so a standing character reads clearly; the LOWER-CENTER (character's feet area) stays calmer, just wet-ground reflection.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh done as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: gothic jirai-kei night — the SKY is a deep MIDNIGHT BLUE / navy (not purple), while electric PURPLE & violet glow are the NEON SIGN accents; hot pink accents, pale moon white, a touch of cyan and blood-red.
```

### 네거티브 (바나 지뢰계 배경 — 공통 "지뢰계 배경 네거티브"에 더한다)

> 공통 네거티브(캐릭터·마스코트 없는 순수 풍경·읽히는 글자 금지 등)는 그대로 두고, **일본·전통·겨울 드리프트**(일본 성하촌 눈거리로 빗나간 사례)를 막는 바나 전용 줄을 더한다.

```
no Japanese castle, no pagoda, no temple, no traditional Japanese town, no shrine gate / torii,
no paper lanterns, no wooden old-town shops, no tiled / snow-covered curved roofs,
no snow, no snowfall, no winter scene (this is a non-seasonal night street),
no kanji / hanzi / Japanese signboards, no readable real letters of any language (signs are abstract neon glow only),
no daytime, no bright daytime blue sky (the night sky is a DEEP midnight blue — dark, not bright), no busy/cluttered center blocking the character,
no missing moon, no missing bats (keep the pale FULL MOON + small BAT silhouettes), keep electric PURPLE neon dominant.
```

> ⚠️ **검수 포인트**: ① **고딕 네온 골목**인지(일본 성·탑·눈·초롱으로 새지 않았는지) ② **보름달 + 박쥐 실루엣 + 퍼플 네온 dominant**가 살았는지 ③ 간판이 **읽히는 글자 아닌 추상 네온**인지 ④ 중앙·하단 발치가 비어 캐릭터가 읽히는지 ⑤ 완전 불투명(크로마·투명 0px) ⑥ 마스터 팔레트(~32색) 인덱싱. 저장: `assets/sprites/bg_cheki_bana_jirai.png`.

---

## 후처리 연결 (바나 — 받은 PNG → 규격 에셋)

> 바나 스탠딩은 옥자·미호와 같은 캔버스(`preset okja` = 128×288)를 쓴다. 캐릭터 레지스트리(`data/characters.gd`)가 `bana_*` 경로를 읽는다(코드 배선은 아트 확정 후).

```bash
# 바나 표정 6종 (128×288, 크로마 그린 배경 제거) — idle/smile/shy/sad/brew/talk
tools/.venv/bin/python tools/dotify.py bana_idle_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/bana_idle.png
# (나머지 표정도 파일명만 바꿔 동일하게: bana_smile / bana_shy / bana_sad / bana_brew / bana_talk)

# 바나 인트로 지뢰계 체키 의상 (128×288 — 체키 카드용 정적 아트)
tools/.venv/bin/python tools/dotify.py bana_jirai_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/bana_jirai.png

# 바나 전용 지뢰계 체키 배경 (120×180 완전 불투명 — 누끼 X, 크로마 X)
tools/.venv/bin/python tools/dotify.py bg_cheki_bana_jirai_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_bana_jirai.png

# 바나 탭 미니 초상 (권장: bana_idle 얼굴 크롭본을 입력으로)
tools/.venv/bin/python tools/dotify.py portrait_bana_raw.png \
  --preset portrait --chroma 00ff00 --out assets/sprites/portrait_bana.png
```

> ⚠️ **바나 슬라이스 코드분 대응(아트 확정 후)**: ① 표정 6장 누끼·규격(~128×288)·마스터 팔레트 32색 인덱싱 ② `portrait_bana` 임포트·렌더 → 24×24 ③ 바나 지뢰계 체키 의상 레이어 합성 → `bana_jirai` + **바나 배경 `bg_cheki_bana_jirai`** + 이벤트 공통 `frame_jirai` ④ `data/characters.gd` 레지스트리에 `bana` 메인 항(accent=퍼플, `intro_event="mine"`) + 펫 `coco` 추가 + `data/events.gd`에 `"bana": true`(mine) 플래그 ⑤ 시그니처 음료 "블러디 미드나잇" 배선.
> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
