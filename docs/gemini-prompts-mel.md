# Gemini 도트 변환 프롬프트 — 멜 (강시 메이드)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**(img2img). 공용 에셋·핵심 원칙·체키 합성 조각은 [공통 파일](./gemini-prompts-common.md) 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))
> **확장 트랙 — 멜 슬라이스(최후 메인).** 확장 트랙 원칙상 **아트가 항상 코드보다 먼저**다(→ 메모리 `character-expansion-plan`). 메인 캐릭터(라이브)이므로 옥자·미호·바나와 동일한 **표정 스왑 SD 라이브**(ADR 0001) 규격. 펫은 **2마리**(선아=[갈색 푸들](./gemini-prompts-suna.md)·수아=[베이지 닥스훈트](./gemini-prompts-sua.md)).

> **멜 (Mel)**: **강시 메이드**(중국 강시 컨셉). 반려견 **선아**(갈색 푸들)·**수아**(베이지 장모 닥스훈트). 시그니처 음료 **청운 에이드**(맑은 청록빛 한 잔). 로스터 accent색 **청록/틸(TEAL)**(실물 의상 톤 반영 — 옥자 버건디·미호 노랑/골드·바나 퍼플과 겹치지 않음). 인트로 이벤트 = **지뢰계**(선례, `events.gd` `mine`→`jirai`).

> **🔑 레퍼런스 첨부 필수**: 멜 실물 사진을 `assets/sprites/_src/mel_ref.png`(얼굴 선명·강시 관복 풀샷)에 두고 첨부해 **img2img**로 뽑는다(옥자·미호·바나와 동일 — 텍스트만으론 얼굴이 매번 흔들린다). 보조 레퍼(전신·의상 각도)가 생기면 `mel_ref_b.png`. 표정 6종은 **첫 1장(`mel_idle`)을 확정**한 뒤 그 결과를 레퍼런스로 첨부하며 나머지를 뽑으면 일관성이 크게 오른다.
> **🔑 정체성(고정) — 실물 레퍼 기준**: ① **흑발(짙은 검정~다크브라운)**, **일자 앞머리(블런트/처피 뱅)** + 옆으로 살짝 흐른 머리 ② **블루·틸 비단 청나라(淸) 관복(官服)룩** — 꽃 자카드 무늬가 든 **블루 비단 상의**, **청록/민트 그라데이션 소매 트림 + 오렌지 안감/연단**, 안쪽 **레드** 포인트, **만다린(차이나) 칼라 + 매듭 단추(프로그)** ③ **강시 관모(冠帽)** — 블루 비단에 꽃무늬, **빨간 비즈 술/장식 끈**이 옆으로 늘어짐 ④ **강시 메이크업 표식** — **양 볼에 작고 동그란 빨간 점(2~3개)**, **빨간 입술·빨간 손톱**, 살짝 **창백한(쿨톤) 피부** ⑤ 시그니처 액센트 = **틸/청록 + 블루 + 오렌지·레드 포인트**. 옥자(시크 츤데레)와 대비되는 **단정하고 새초롬한·동양적 강시 아가씨** 무드(귀엽고 age-safe — 좀비·공포 연출 금지).

> **🔑 SD·셰이딩 락(미호·바나 교훈 그대로 — 두 번 빗나간 함정)**: ① `flat shading` 문구는 **납작·밋밋**을 부르니 쓰지 말고 → **"색마다 2~3톤 도트 셰이딩"**, ② `SLIM`·"늘씬" 과강조는 **머리 작고 다리 긴 일반 등신비(SD 아님)** 를 부르니 쓰지 말고 → **옥자급 SD(머리 ≈ 전체 높이의 1/3, 다리 짧게)** 로 못박는다.
> **🔑 결정적 해법 = 옥자 idle을 앵커로 첨부**: 실물 사진만 img2img하면 **무조건 일반 등신비**로 나온다(머리 작고 다리 김). **반드시 `assets/sprites/okja_idle.png`(확정 SD)를 1번 이미지(비율·도트 스타일 앵커)로, 멜 실물을 2번(얼굴·정체성)으로 첨부**하고 "얼굴·강시 정체성은 2번에서, 등신비·도트 스타일은 1번(옥자)과 똑같이"라고 지시한다. 텍스트만으론 SD·셰이딩 둘 다 또 빗나간다.
> **🔑 색 락 — 틸 3톤·블루 채도(첫 idle 탁함 교훈)**: 멜은 청록/블루가 의상 대부분이라 **셰이딩이 부족하면 소매·치마가 탁해진다**(첫 idle 실패). 반드시 ① **틸/청록 소매·치마는 3톤 램프**(다크 `2f7d72` → **미드 `4fa69b`**(45색 보강) → 라이트 민트 `6fd0c4`)로 둥근 볼륨을 주고 ② **블루 비단 그림자는 채도 있는 딥블루**(`1e3563`/`13223f`)로 — **회색/차콜로 빠지지 않게**. flat 단색 틸·무채색 그림자 금지. (마스터 팔레트는 청록 미드톤 보강 완료 → `narakuchi.hex` 45색.)

---

## 공통 베이스 (멜 SD) ★라이브 스탠딩용

> 옥자·미호·바나와 동일하게 **SD 치비(머리 ≈ 전체 높이의 1/3, 1:2.5~3)** 로 간다 — 다마고치 LCD에서 표정 6종이 읽히려면 머리를 키워야 한다. 머리 크기·다리 짧음은 옥자 idle 첨부로 강제(위 SD 락 참조).
> **🔑 프레임 충전 = 옥자와 동일 스케일(중요)**: 라이브 스탠딩은 **머리가 상단, 발이 하단에 닿게 프레임을 꽉 채워야** 교감화면에서 옥자와 크기가 맞는다(옥자 idle = 높이 충전 ~96%, 발 바닥여백 0).
> **🔑 충전은 `dotify`가 자동**: `--preset okja`(캐릭터)는 **콘텐츠 bbox 크롭 → 높이 충전 → 하단 정렬**을 자동 적용한다(`FILL_PRESETS`). 여백 많은 원본도 발이 바닥에 붙는다. 끄려면 `--no-fill`.
> **⚠️ 단 폭이 관건**: 충전은 **높이 우선이되 폭이 캔버스(128)를 넘으면 폭 기준으로 제한**(소매·관복 자락 잘림 방지)되어 높이가 덜 찬다. 강시 관복은 **소매가 넓어** 폭이 쉽게 초과된다 → **① 넓은 소매를 양옆으로 과하게 펼치지 말고 몸 가까이 늘어뜨리고 ② 양팔 강시 포즈(앞으로 수평 뻗기)는 idle이 아니라 `talk` 한 컷에만** 절제한다. dotify가 출력 후 **높이충전·바닥여백을 자동 리포트**한다(`높이충전 ≥90%`, `바닥여백 ≤4px`). ❌ 뜨면 ①②를 손봐 재생성.

```
[Attach: 1 = okja_idle.png — the SD PROPORTION & DOT-STYLE ANCHOR (copy its build), 2 = Mel's real photo (_src/mel_ref.png) — her FACE & identity]

Draw a CUTE SD / CHIBI pixel-art sprite of "Mel", full body, front-facing standing pose.
Take her FACE and IDENTITY from image 2, but COPY the SUPER-DEFORMED body proportions and dot-art style of image 1 (Okja).
Subject: "Mel", a JIANGSHI (Chinese hopping-vampire) MAID at a hell-themed maid cafe — neat, demure yet a little prim, oriental and cute (NOT scary, NOT a rotting zombie — age-safe, adorable).
Proportions (MUST MATCH IMAGE 1, the Okja sprite): SUPER-DEFORMED chibi — a BIG ROUND head about ONE THIRD of the
         total height, large expressive eyes, a small compact body and SHORT STUBBY legs. NOT a tall or realistic
         figure, NOT long legs, NOT a normal 5-6-heads-tall girl. Same SD build, NARROW WIDTH and on-screen scale as Okja (clear SIDE MARGINS — the body and wide sleeves must NOT touch the left/right edges).
Jiangshi features (keep EXACT, from image 2): faintly PALE cool-toned skin, small round RED dots on both CHEEKS (2-3 each, the
         classic jiangshi blush makeup), RED lips and RED nails. A cute oriental hopping-vampire look — friendly, never frightening.
Hair: DARK (near-black / dark-brown) hair with a straight BLUNT fringe (choppy bangs), framing the face.
Outfit: a BLUE & TEAL silk CHINESE QING-style court ROBE (官服) maid look — a BLUE silk top with floral brocade pattern,
         TEAL / mint gradient SLEEVE & hem trim with ORANGE lining/piping and RED inner accents, a MANDARIN (stand) collar
         with knotted frog buttons. On the head a BLUE silk JIANGSHI court HAT / bonnet with a floral motif and RED beaded
         tassels hanging at one side. Signature accents = TEAL / blue + orange & red.
Style (MATCH IMAGE 1): 8-bit pixel sprite / dot art, limited palette, hard pixel edges, NO anti-aliasing, NO gradients,
         dot-art shading with 2-3 tones per color (highlight, midtone, shadow) — NOT flat single-tone fills.
Color mood: oriental jiangshi palette — BLUE & TEAL silk robe with orange & red trim, dark hair, faintly pale skin,
         red cheeks/lips; keep a NARROW COLUMNAR silhouette — wide sleeves draped CLOSE to the body, NOT spread to the side edges.
Framing: full body centered, head near the TOP edge and feet near the BOTTOM edge, NOT floating; tall vertical 4:9
         portrait ratio, consistent crop across all expressions.
         Lower body and short legs IDENTICAL across all expressions — only the FACE and ARM pose change.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (멜 공통)

```
no text, no watermark, no signature, no multiple characters, no cropped limbs, no cropped robe / sleeves,
no realistic / normal body proportions, no long legs, no adult tall figure, no 5-6-heads-tall girl,
no small head (the head MUST be ~1/3 of the total height like the Okja anchor), no tiny face,
no baby-only infantile style (keep her demure oriental charm),
no small figure with large empty margins, no floating character above the bottom edge,
no excessive headroom or footroom (head near top, feet on the bottom edge — fill the frame),
no witch hat (that is Okja — Mel wears a BLUE jiangshi court hat), no fox ears, no cat ears, no animal ears (she is human-shaped),
no maid headdress identical to Bana, no gothic-lolita dress (Mel's look is a BLUE & TEAL Chinese court robe),
no blonde hair, no platinum hair (hair is DARK near-black with a blunt fringe),
no scary zombie / rotting / corpse / horror look, no green skin, no fangs, no blood,
no wide spread sleeves / no T-pose arms, no flared silhouette filling the full frame width (keep clear side margins like Okja),
no missing red cheek dots (the 2-3 red cheek dots MUST stay), no missing red lips,
no flat single-tone coloring, no flat shading (must have highlight+midtone+shadow per color),
no smooth vector / cartoon / anime illustration look, no soft airbrushed or blurred cheeks,
no oversimplified low-detail sprite (it must be as detailed and shaded as the Okja sprite),
no background scenery, no gradient background, no soft anti-aliased edges,
no realistic photo finish, no 3D render, no over-sexualized outfit (keep it cute & age-safe brand).
```

### 표정 6종 — 베이스에 한 줄만 추가

**다리·하체·프레이밍은 고정**하고, **얼굴 표정 + 팔 자세**만 바꾼다(팔도 그림에 박는다 — 리깅 아님). 표정별 사진이 있으면 각각 변환이 더 정확.
> **셰이딩은 6종 전부 베이스 그대로** — 아래 행은 표정·팔만 추가하고, 도트 셰이딩(색마다 2~3톤, flat 금지)·픽셀 규격은 위 공통 베이스를 그대로 따른다. idle만 셰이딩 박고 나머지를 밋밋하게 뽑지 말 것(생성 시 idle 결과를 레퍼로 첨부하면 5종도 톤이 맞는다).
> **볼 빨간 점·빨간 입술은 6종 전부 유지**(강시 정체성 — 표정이 바뀌어도 사라지면 안 됨).

| 파일명 | 추가 문구 |
|---|---|
| `mel_idle`  | `Expression: calm, demure, mouth closed (a faint quiet smile). Arms: both hands gathered together in front inside the wide sleeves (a neat oriental gongshou pose), sleeves draped close to the body.` |
| `mel_smile` | `Expression: bright, sweet smile, eyes gently curved, cheerful. Arms: both hands clasped up near the chest, delighted, sleeves close.` |
| `mel_shy`   | `Expression: shy, blushing (red cheek dots stand out), eyes averted. Arms: one wide sleeve raised to half-cover the mouth, bashful.` |
| `mel_sad`   | `Expression: sulky / pouting, downturned mouth (NEVER crying). Arms: lowered and drooping limply inside the sleeves, a little forlorn.` |
| `mel_brew`  | `Expression: focused, gentle "brewing". Arms: holding her signature drink "Cheongun Ade" in both hands — a tall clear glass of a sparkling CLEAR TEAL / sky-blue ADE (cloudy-blue soda with a soft cream foam like a blue cloud) and a mint sprig on top.` |
| `mel_talk`  | `Expression: mouth slightly open talking, demure-confident. Arms: ONE arm extended forward in a playful JIANGSHI gesture (a single stiff-arm reaching out, fingers loosely together), the other arm tucked in the sleeve. Keep the arm CLOSE-ISH, not a full wide T-pose.` |

> ⚠️ **6종 전부 팔 자세가 다르다** (다리·하체·프레이밍은 고정). 전환은 하드컷이라 팔 차이가 커도 OK. 기쁨 "폴짝" 같은 전신 포즈는 별도로 그리지 않고 `mel_smile`을 리워드 순간에 **코드 hop**으로 재사용한다(강시 점프와 의미가 겹쳐 더 잘 어울린다). 슬픔은 **시무룩까지** — 우는 그림 금지(벌 없는 설계).
> 🥤 **`mel_brew` = 청운 에이드 제조 컷 겸용** — 별도 음료 컷을 그리지 않고 이 brew 표정(청록 음료 잔을 든 손)으로 대체한다(옥자·미호·바나 brew와 동일 원리). 데모는 brew 1장으로 충분.
> ⚠️ **`mel_talk`의 강시 포즈는 "한 팔만, 몸 가까이"** — 양팔 수평 T자로 펴면 넓은 소매 때문에 폭이 캔버스를 넘어 충전이 깨진다(공통 베이스 ⚠️ 참조). 강시다움은 한 팔 stiff-arm으로 충분히 산다.

---

## 멜 탭 미니 초상 (`portrait_mel`)

> 컬렉션북 탭·로스터 선택 화면의 멜 식별 초상(24×24). 레지스트리가 `portrait_%s.png % id`로 경로를 파생하니 파일명은 **`portrait_mel.png`** 고정.
> **권장: 생성하지 말고 크롭** — 확정된 `mel_idle.png`에서 **얼굴(관모 포함)을 정사각으로 크롭** → `dotify --size 24x24`. 라이브 멜은 기본 강시 관복이라 idle 얼굴이 탭 정체성과 일치한다. ⚠️ 작게 줄여도 **볼 빨간 점·블루 관모**가 멜 식별 포인트이니 대비를 분명히.
> 크롭 소스가 마땅치 않을 때만 아래로 생성:

```
Pixel art / dot art tiny SQUARE PORTRAIT bust (face + shoulders), front view, centered, BIG readable face.
Subject: "Mel", a cute JIANGSHI (Chinese hopping-vampire) maid — faintly PALE skin, small round RED DOTS on both cheeks,
         RED lips, DARK hair with a straight blunt fringe, a BLUE silk jiangshi court HAT with a floral motif and a RED beaded tassel,
         a BLUE & TEAL mandarin-collar court robe with orange trim.
         Clearly an oriental jiangshi girl (NOT a witch, NOT a fox, NOT a vampire-maid). Cute and friendly, NOT scary.
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use rich dot-art shading — 2-3 tones per color (highlight, midtone, shadow), NOT flat single-tone fills.
       True pixel art, NOT a smooth vector / cartoon look. Match the Okja portrait's shading depth.
Color mood: oriental jiangshi — BLUE & TEAL silk with orange/red trim, dark hair, pale skin, red cheek dots (shaded, not flat).
Background: FLAT SOLID chroma green (#00ff00), nothing else.
```

```
[네거티브] no full body, no tiny face, no text, no extra characters, no scenery,
no witch hat, no fox/cat ears, no blonde hair (DARK hair), no missing red cheek dots, no scary zombie look, no fangs, no green skin,
no chroma green on the subject, no gradient, no soft anti-aliased edges, no 3D render.
```

---

## 멜 인트로(지뢰계) 의상 체키 (이벤트 의상 1벌)

> 멜 슬라이스의 **인트로 체키** — 온보딩에서 멜을 고르면 주는 첫 체키(선례). 옥자·미호·바나와 동일하게 **지뢰계 데이** 의상이 인트로 슬롯이다. **체키 카드용 정적 아트** — 교감화면 스킨 아님이라 포즈·헤어 변주 자유(라이브 멜은 강시 관복 고정).
> **🔑 워크플로우(옥자·미호·바나 지뢰계와 동일)**: **① 확정된 `mel_idle.png`(SD 도트 — 얼굴·등신비 락) + ② 지뢰계 레퍼런스 사진 `_src/mel_jirai_ref.png`(의상·헤어·포즈 락)**(+선택 ③ 신발 레퍼)을 첨부하고 "1번 캐릭터를 2번 코디로 다시 그려라". **이 의상은 블론드 헤어라 다크 헤어 락은 풀리고, Mel 식별 마커는 「창백한 피부 · 볼 빨간 점 · 빨간 입술」 3개만 의상이 바뀌어도 유지**(강시 메이크업 표식이 곧 정체성).
> **🔑 지뢰계 코디 가이드(실물 레퍼 확정 — 블랙 고딕 + 레드 레오파드)**: 실물 레퍼 기준 멜의 지뢰계 = **블랙 고딕 갸루룩**. 옥자(핑크 레이스)·바나(퍼플 고딕)와 구분되는 포인트는 **실버 십자가·천사 날개·케루빔 그래픽 프린트**. 미호(레오파드 갸루)와 톤이 일부 겹치나(레드 레오파드 스커트) 사용자 확정 코디다.
> - **헤어**: **블론드/플래티넘**(레퍼 그대로), 일자 앞머리 + 사이드로 흐른 긴 머리, 정수리에 작은 헤어핀/장식.
> - **상의**: **블랙 오프숄더 반팔 톱**, 네크라인 안쪽으로 **레드 레이어**가 살짝 비침, 가슴 중앙에 **실버/회색 십자가 + 천사 날개 + 작은 케루빔(천사)** 도안 프린트, 밑단 **레이스 트림**.
> - **하의**: **레드/블랙 레오파드 프릴 티어드 미니스커트**(레이스 + **베이지/탠 벨트형 트림** 디테일).
> - **액세서리**: **초커** + 레이어드 **십자가 목걸이**, **블랙 네일(끝만 레드 팁)**, 손목 밴드.
> - **포즈(레퍼 유지)**: **한 손을 얼굴 옆/귀 옆으로 올린 쿨큐트 셀카**(고개 살짝 기울임, 큰 눈). 핑거하트/V로 변주 가능.
> - **유지**: 창백한 피부 · 볼 빨간 점 · 빨간 입술(블론드여도 이 3개는 멜 식별 — 강시 표식).
> ✅ **지뢰계 레퍼 확정**: `assets/sprites/_src/mel_jirai_ref.png` 첨부.

```
[Attach: 1 = mel_idle.png (confirmed SD dot, face & proportion lock), 2 = mel jirai-day reference photo (_src/mel_jirai_ref.png — outfit + hair + pose lock)]
Keep image 1's FACE and Mel's identity MAKEUP MARKS: faintly PALE cool-toned skin, small round RED dots on both cheeks, RED lips,
same SD chibi proportions (head:body ≈ 1:3~1:4) — KEEP these even though the hair and outfit change.
RESTYLE her into her JIRAI-DAY coordinate from image 2 — a BLACK GOTHIC JIRAI-KEI ("landmine girl") gal look (cute, age-safe):
- Hair: BLONDE / PLATINUM hair (image 2), a straight blunt fringe with long side-swept hair, small hair clips on top.
- Top: a BLACK off-shoulder short-sleeve top, a RED inner layer peeking at the neckline, with a big SILVER/grey
  graphic print on the chest — a CROSS with ANGEL WINGS and tiny cherubs — and LACE trim at the hem.
- Bottom: a RED & BLACK LEOPARD-print ruffled TIERED mini skirt with lace and a BEIGE/TAN belt-like trim band.
- Accessories: a CHOKER, layered CROSS necklaces, BLACK nails with RED tips, a wrist band.
- Shoes: chunky platform shoes (feet not in the ref — keep them simple, black).
- Pose (KEEP from image 2): a cool-cute JIRAI SELFIE — head slightly tilted, ONE hand raised beside the face / ear,
  big eyes, confident cool-cute look. (finger-heart / V near the eye is an OK variation.)
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients.
       Use rich dot-art shading — 2-3 tones per color (highlight, midtone, shadow) on the blonde hair, pale skin, black top,
       red leopard skirt and the silver cross graphic; NOT flat single-tone fills. True pixel art, NOT a smooth vector / cartoon look.
       Match the Okja sprite's shading depth and pixel crispness.
       Keep her clearly the SAME Mel (pale skin + red cheek dots + red lips intact), cute gothic jirai mood, age-safe.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom,
         tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (멜 지뢰계 — 공통 네거티브에 더한다)

```
no different face, no extra characters, no cropped feet, no missing red cheek dots, no missing red lips, no missing pale skin,
no witch hat, no fox/cat ears, no original jiangshi court robe & hat (it is fully replaced by the jirai-day outfit),
no dark / black hair (for THIS outfit the hair is BLONDE / platinum per the reference), no scary zombie / rotting / horror look, no green skin, no fangs, no blood,
no pink-lace girly blouse identical to Okja, no full purple gothic-lolita dress identical to Bana (this is a BLACK off-shoulder top + RED leopard skirt with a silver cross-and-wings graphic),
no blue / teal qipao or china-motif robe (that was the old guess — the real coordinate is BLACK GOTHIC + RED LEOPARD),
no flat single-tone coloring, no flat shading, no smooth vector / cartoon / anime look, no soft airbrushed cheeks,
no oversimplified low-detail sprite (match the Okja sprite's shading & detail),
no realistic body proportions, no long thin legs, no adult tall figure, no tiny face,
no over-sexualized outfit (keep it cute jirai-kei, age-safe brand).
```

> ⚠️ **검수 포인트**: 체키 카드 안에 들어갈 정적 아트이므로 idle 앵커 일치는 불필요. **얼굴 + 창백 피부·볼 빨간 점·빨간 입술 유지(블론드여도 이 3개로 멜 식별) + 신발까지 프레임 안에 다 들어왔는지**를 본다. 또 **블랙 오프숄더 + 실버 십자가·날개 그래픽 + 레드 레오파드 프릴 스커트 + 한 손 셀카 포즈**가 살았는지 확인. 후처리 **마스터 팔레트 인덱싱 필수** — 블랙·레드·블론드·레오파드가 모두 기존 32~45색 램프로 충분히 표현되는지 확인(레오파드 패턴은 다크/탠 2~3톤이면 충분).
> 🃏 **체키 합성 레이어**: 멜 지뢰계 체키 = `mel_jirai`(누끼) + **멜 전용 배경 `bg_cheki_mel_jirai`** + 이벤트 공통 `frame_jirai`(→ [공통 파일](./gemini-prompts-common.md)). **프레임은 이벤트 데이 공통, 배경은 멤버별**(ADR 0003 개정).
> ⚠️ **배경 짝 재검토 필요**: 기존 `bg_cheki_mel_jirai`는 **청록/시안 차이나타운 야경**(옛 차이나 코디 짝)으로 만들어졌다. 의상이 **블랙 고딕 + 레드 레오파드**로 확정되며 톤이 어긋난다 → 아래 배경 섹션을 **블랙/레드 고딕 네온 야경**으로 다시 뽑을지 검토(현행 유지도 가능하나 의상과 색 충돌).
> 📌 **이후 이벤트 의상(유치원·힙합·집사·크리스마스 등)은 별도 아트 트랙으로 점증** — 5벌 선결 금지. 의상 + 짝 배경(`bg_cheki_mel_{slug}`)을 한 세트로 갈아끼우면 된다.

---

## 멜 지뢰계 체키 사진 배경 (`bg_cheki_mel_jirai`)

> **베이스 = [공통 파일](./gemini-prompts-common.md)의 "체키 사진 배경 — 지뢰계"**(규격 `120×180` 완전 불투명, 누끼 X·크로마 X, 중앙·하단 발치 비움, 도트 보케). **공통 프레임(`frame_jirai`)과 짝이라 네온 야경 팔레트(네이비·블랙 + 네온 핑크/퍼플)는 유지**하되, **멜의 스팟 = 블랙/레드 고딕 무드의 네온 야경**(의상이 블랙 고딕 + 레드 레오파드로 확정 — 옛 청록 차이나타운 안이 폐기됨). 옥자=시부야 큰길·미호=홍등 야시장·바나=퍼플 고딕과 구분되게 **레드/마젠타 네온 + 십자가·고딕 모티프 글로우 간판, 다크 도시**로.

```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a JIRAI-KEI ("landmine girl") girl's NIGHT street with a DARK GOTHIC vibe.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a neon-lit night street with a dark gothic twist at the top and sides — glowing RED, MAGENTA and hot-pink NEON SIGNS and
      abstract glyph-like glow signboards (NOT real letters), gothic CROSS-shaped neon motifs, a big pale FULL MOON behind dark spires,
      tall dark buildings, soft round BOKEH light orbs; a WET asphalt path at the bottom catching red & magenta neon REFLECTIONS.
Depth: detailed glowing signs, cross motifs and the moon along the TOP and the two SIDE edges; the CENTER is a softer, blurrier BOKEH haze of
      red/magenta city lights so a standing character reads clearly; the LOWER-CENTER (character's feet area) stays calmer, just wet-ground reflection.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh done as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: gothic jirai-kei night — deep navy/black sky, electric RED & magenta dominant, hot pink & purple accents, pale moon white, a touch of cold blue.
```

> 네거티브는 [공통 파일](./gemini-prompts-common.md)의 "지뢰계 배경 네거티브" 그대로(특히 **캐릭터·마스코트 없는 순수 풍경** — 의상 누끼가 위에 올라간다). 저장: `assets/sprites/bg_cheki_mel_jirai.png`.

---

## 멜 유치원 의상 체키 (`mel_kinder`)

> **유치원 데이** — 옥자와 한 세트(전원 같은 원아복 코디). **체키 카드용 정적 아트**(포즈·헤어 변주 자유). **창백한 피부·볼 빨간 점·빨간 입술 3개는 의상이 바뀌어도 유지**(멜 강시 식별 표식 = 핵심 정체성).
> **🔑 코디 가이드(실물 레퍼 확정 — `_src/mel_kinder_ref.png`)**: 머스타드/옐로 **와이드브림 버킷햇**(흰 꽃 클립) + 흰 **피터팬 라운드 카라**의 **하늘색(라이트 블루) 퍼프소매 원피스**(앞 단추) + 가슴 **빨강 명찰** + 사선으로 멘 **노란 크로스백** + **다크 낮은 트윈테일**(노란 리본/스크런치) + 흰 무릎양말 + 손목시계. 무릎 꿇은 포즈, 한 손 모자챙. 미호·바나와 같은 유치원 세트지만 멜은 **하늘색 원피스**로 구분 + 멜다움으로 이마 **작은 노란 부적 스티커**(귀엽게·무섭지 않게).

```
[Attach: 1 = mel_idle.png (confirmed SD dot, face & proportion lock), 2 = _src/mel_kinder_ref.png (kindergarten outfit + pose lock)]
Keep image 1's FACE and Mel's identity MAKEUP MARKS: faintly PALE cool-toned skin, small round RED dots on both cheeks, RED lips,
same SD chibi proportions (head:body ≈ 1:3~1:4) — KEEP these even though the outfit changes.
RESTYLE her into the KINDERGARTEN-DAY coordinate from image 2 — a cute preschool-pupil look (childlike, age-safe):
- Hair: dark hair in low TWIN-TAILS tied with YELLOW ribbons / scrunchies, straight fringe.
- Headwear: a MUSTARD / golden-YELLOW wide-brim BUCKET HAT with a tiny white flower clip; add a small cute YELLOW TALISMAN (paper charm) sticker on the forehead as a playful jiangshi nod.
- Top: a LIGHT-BLUE (sky blue) long-puff-sleeve smock DRESS with a big WHITE rounded PETER-PAN COLLAR and a button placket.
- Badge: a small RED rounded NAME TAG on the chest.
- Bag: a YELLOW cross-body messenger BAG worn diagonally.
- Accessories: a small wristwatch.
- Pose (KEEP from image 2): kneeling / sitting on her knees, ONE hand lightly touching the hat brim, calm cute look.
- Shoes: WHITE knee socks and small WHITE shoes.
- Expression: calm innocent face.
Style: polished 8-bit pixel sprite / dot art, hard CHUNKY pixel edges, NO anti-aliasing, NO gradients,
       rich 2-3 tone dot shading (highlight/midtone/shadow) on hair, pale skin and the light-blue dress; NOT flat single-tone.
       Keep her clearly the SAME Mel (pale skin + red cheek dots + red lips intact), just dressed as a sweet kindergartener.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom,
         tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no different face, no missing red cheek dots, no missing red lips, no missing pale skin, no fox/cat ears, no witch hat (it's a yellow bucket hat), no jiangshi court robe & hat (fully replaced by the light-blue kindergarten dress), no scary zombie / horror look, no green skin, no over-mature outfit (keep it childlike & age-safe), no cropped feet, no flat single-tone coloring.`

> 🃏 **체키 합성 레이어**: 멜 유치원 체키 = `mel_kinder`(누끼) + **멜 전용 배경 `bg_cheki_mel_kinder`**(아래) + 이벤트 공통 `frame_kinder`(→ [공통 파일](./gemini-prompts-common.md)). 저장: `assets/sprites/mel_kinder.png`.

---

## 멜 유치원 체키 사진 배경 (`bg_cheki_mel_kinder`)

> **베이스 = [공통 파일](./gemini-prompts-common.md)의 "체키 사진 배경"**(규격 `120×180` 완전 불투명, 누끼 X·크로마 X, 중앙·하단 발치 비움, 도트 보케). **유치원 데이 공통 톤 = 크레용·무지개·파스텔 유치원**(옥자 배경과 한 세트). **멜의 스팟 = 악기·실로폰이 있는 음악놀이 코너**(살짝의 변주만 — 같은 유치원).

```
Pixel art / dot art BACKGROUND scenery for a photo (cheki) snapshot — a bright cheerful KINDERGARTEN MUSIC corner.
NO character, NO frame, NO border, NO text in any readable language. A real LOCATION backdrop that fills the WHOLE image edge-to-edge
(a cut-out character will be composited standing IN FRONT of it later), tall vertical portrait, aspect ratio 120:180 (2:3).
Scene: a sunny preschool music corner — pastel walls with a big crayon-drawn RAINBOW, fluffy clouds and a yellow sun, a colorful
      XYLOPHONE, little drums and tambourines on shelves along the sides, paper bunting / flags strung overhead, soft round BOKEH light orbs.
Depth: rainbow, bunting and shelves along the TOP and the two SIDE edges; the CENTER is a softer, blurrier pastel haze so a standing
      character reads clearly; the LOWER-CENTER (character's feet area) stays calmer — a soft play-mat floor.
Style: 8-bit pixel sprite / dot art, hard pixel edges, chunky pixels, NO anti-aliasing, NO smooth gradients, flat shading; bokeh as clusters of flat pixel dots.
FULLY OPAQUE — solid fill everywhere, NO transparency, NO chroma green anywhere.
Color mood: warm bright nursery — cream walls, pastel rainbow (red-orange-yellow-green-blue-purple), sky blue, sunny yellow, candy pink.
```

> 네거티브는 [공통 파일](./gemini-prompts-common.md)의 배경 네거티브 그대로(특히 **캐릭터·마스코트 없는 순수 풍경**). 저장: `assets/sprites/bg_cheki_mel_kinder.png`.

---

## 색 보정 재생성 (raw 없이 색만 개선 — 정체성·포즈 유지)

> 첫 `mel_idle` 의 청록 소매·치마가 탁했고(틸 미드톤 부재) **raw(인덱싱 전 풀컬러)가 없을 때**의 복구 루트. 빈손 재생성은 정체성·구도를 잃으니, **확정된 `mel_idle.png` 자체를 레퍼로 첨부**해 얼굴·포즈·의상·구도는 그대로 두고 **셰이딩만 풍부하게** 다시 받는다. 받은 raw 를 보강된 45색 팔레트로 `dotify` 재인덱싱.

```
[Attach: 1 = assets/sprites/okja_idle.png (SD 비율·도트 스타일 앵커), 2 = assets/sprites/mel_idle.png (멜 정체성·포즈·의상·구도 락)]
Redraw this SD chibi pixel-art character (image 2, "Mel" the jiangshi maid). Keep her IDENTITY, POSE, OUTFIT and
COMPOSITION EXACTLY the same as image 2 — same face, dark blunt-fringe hair, RED cheek dots, RED lips, the BLUE
jiangshi court hat with a RED bead tassel, the BLUE & TEAL silk court robe, and the same standing pose (hands
gathered in the wide sleeves). Match the SD proportions / dot style of image 1.
The ONLY change: enrich the DOT-ART SHADING so the colors are NOT muddy:
- The TEAL / turquoise SLEEVE CUFFS and the LOWER SKIRT must use a FULL 3-TONE teal ramp — a DARK teal shadow,
  a MID teal, and a LIGHT mint highlight — NOT a single flat dark-teal fill. Give the cuffs and skirt clear rounded volume.
- The BLUE silk robe must keep SATURATED deep-blue shadows (NOT desaturated grey / charcoal shadows).
- Keep the arms and skirt readable with light coming from the upper-left.
Keep HARD pixel edges, NO anti-aliasing, NO gradients, limited palette. Same tall 4:9 vertical framing, feet at the bottom.
Background: FLAT SOLID chroma green (#00ff00), no scenery.
```

```
[네거티브] no different face, no pose change, no outfit change, no hat change, no missing red cheek dots,
no FLAT single-tone teal sleeves/skirt, no grey / desaturated / muddy shadows, no muddy colors,
no anti-aliasing, no gradient, no realistic / tall body proportions, no background scenery.
```

> 받은 raw(`mel_idle_raw.png`)를 **보강 45색**으로 재인덱싱 → `dotify ... --preset okja --chroma 00ff00`(아래). 결과의 청록 3톤·블루 채도를 검수한 뒤, **표정 5종(smile/shy/sad/brew/talk)도 이 새 idle 을 레퍼로** 같은 셰이딩으로 다시 받는다(현재는 idle 복사 placeholder).

---

## 후처리 연결 (멜 — 받은 PNG → 규격 에셋)

> 멜 스탠딩은 옥자·미호·바나와 같은 캔버스(`preset okja` = 128×288)를 쓴다. 캐릭터 레지스트리(`data/characters.gd`)가 `mel_*` 경로를 읽는다(코드 배선은 아트 확정 후).
> ⚠️ **크로마 주의**: 멜 의상은 블루/틸이라 크로마 그린 `#00ff00`과 충돌하지 않는다(그린 ≠ 블루/틸). 단 **`mel_brew`의 청운 에이드는 시안/하늘색 쪽으로** 뽑아 순수 그린과 멀게 한다(청록이 그린에 너무 붙으면 음료가 크로마로 뚫린다 → 그때만 `--chroma ff00ff` 마젠타로 대체).

```bash
# 멜 표정 6종 (128×288, 크로마 그린 배경 제거) — idle/smile/shy/sad/brew/talk
tools/.venv/bin/python tools/dotify.py mel_idle_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/mel_idle.png
# (나머지 표정도 파일명만 바꿔 동일하게: mel_smile / mel_shy / mel_sad / mel_brew / mel_talk)
# ⚠️ mel_brew 가 청록 음료라 그린에 뚫리면: --chroma ff00ff (마젠타 배경으로 재생성 후)

# 멜 인트로 지뢰계 체키 의상 (128×288 — 체키 카드용 정적 아트)
tools/.venv/bin/python tools/dotify.py mel_jirai_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/mel_jirai.png

# 멜 전용 지뢰계 체키 배경 (120×180 완전 불투명 — 누끼 X, 크로마 X)
tools/.venv/bin/python tools/dotify.py bg_cheki_mel_jirai_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_mel_jirai.png

# 멜 유치원 체키 의상 (128×288 — 체키 카드용 정적 아트, 볼 빨간 점·빨간 입술·창백 피부 유지)
tools/.venv/bin/python tools/dotify.py mel_kinder_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/mel_kinder.png
# 멜 전용 유치원 체키 배경 (120×180 완전 불투명 — 누끼 X, 크로마 X)
tools/.venv/bin/python tools/dotify.py bg_cheki_mel_kinder_raw.png \
  --size 120x180 --out assets/sprites/bg_cheki_mel_kinder.png

# 멜 탭 미니 초상 (권장: mel_idle 얼굴 크롭본을 입력으로)
tools/.venv/bin/python tools/dotify.py portrait_mel_raw.png \
  --preset portrait --chroma 00ff00 --out assets/sprites/portrait_mel.png
```

> ⚠️ **멜 슬라이스 코드분 대응(아트 확정 후)**: ① 표정 6장 누끼·규격(~128×288)·마스터 팔레트 인덱싱 ② `portrait_mel` 임포트·렌더 → 24×24 ③ 멜 지뢰계 체키 의상 레이어 합성 → `mel_jirai` + **멜 배경 `bg_cheki_mel_jirai`** + 이벤트 공통 `frame_jirai` ④ `data/characters.gd` 레지스트리에 `mel` 메인 항(accent=TEAL, `intro_event="mine"`) + 펫 `suna`·`sua` 추가 + `data/events.gd`에 `"mel": true`·`"suna": true`·`"sua": true`(mine) 플래그 ⑤ 시그니처 음료 "청운 에이드" 배선 ⑥ `data/balance.gd` `GAUGE_MEL`·`GAUGE_SUNA`·`GAUGE_SUA` ⑦ `collection_book.gd` TABS 멜(메인)·선아·수아(펫) + `ExpansionSlide` 예고 목록에서 제외 ⑧ `docs/script-mel.md` 톤 가이드 + `ticker.json`/`talk.json`/`gifts.json` 멜 보이스.
> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
