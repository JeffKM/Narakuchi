# 효과음 8종 — Suno 프롬프트 (T18 사운드 자리 채우기)

`Sfx` 오토로드(`scripts/systems/sfx.gd`)가 찾는 8개 큐를 Suno로 만들기 위한 프롬프트 모음.
완성하면 **정확한 파일명**으로 `assets/audio/`에 넣으면 코드 수정 없이 자동 발화한다. (매핑·규격은 [`assets/audio/README.md`](../assets/audio/README.md))

## ⚠️ Suno로 SFX 만들 때 주의

- Suno는 **곡(수십 초~분)** 단위라 한 발(one-shot) 효과음엔 거칠다. **생성 후 앞부분 0.1~2초만 잘라내** 쓴다(Audacity/온라인 트리머).
- 모두 같은 음색 가족이 되도록 **공통 스타일 토큰을 앞에 붙여** 생성한다 → 게임 사운드 통일감.
- **Instrumental(가사 없음)** 로. 가사칸은 비우거나 `[instrumental]`.
- 트림 후: **모노 · 16-bit PCM WAV · 피크 −6dB 정도로 노멀라이즈** → 아래 파일명으로 저장.
- Godot은 `assets/audio/*.wav`를 자동 임포트(루프 **off**가 기본 = SFX에 맞음). 길면 무겁고 겹침이 부자연스러우니 **짧게** 자른다.
- Suno가 영 안 맞으면 대안: **jsfxr / bfxr / ChipTone**(브라우저 8비트 SFX 생성기)로 같은 의도를 뽑아도 됨.

## 공통 스타일 토큰 (각 프롬프트 앞에 붙이기)

```
8-bit chiptune, NES 2A03 style, square and triangle wave, retro video game sound effect, instrumental, no vocals, mono, clean crisp attack, lo-fi
```

---

## 1. `sfx_order.wav` — 주문 (체키/음료 주문 · 딸랑)

> 목표: 가게 종처럼 산뜻한 "딸랑/딩-동" 2음 — 주문 확정의 경쾌한 신호. **~0.6초**

```
8-bit chiptune, NES 2A03 style, square wave, instrumental, no vocals, mono, crisp:
short cheerful shop counter bell, bright two-note ding-dong, snappy square wave blip, friendly café order confirm, very short, clean
```

## 2. `sfx_cheki_get.wav` — 오늘의 체키 획득 (언박싱 · 팡!)

> 목표: 아이템 GET 팡파레 — 상승 아르페지오가 밝은 코드로 터짐. **감정 피크, 가장 중요.** **~1.2초**

```
8-bit chiptune, NES 2A03 style, square and triangle wave, instrumental, no vocals, mono:
triumphant item-get fanfare, ascending major arpeggio resolving into a bright sparkling chord, celebratory reward jingle, joyful, short sparkle tail
```

## 3. `sfx_butterfly.wav` — 나비 승급 (반짝 상승)

> 목표: 진화/승급의 영롱한 반짝임 — 빠른 상승 아르페지오 + 트윙클 잔향. **~1.8초**

```
8-bit chiptune, NES 2A03 style, bell-like square leads, instrumental, no vocals, mono:
magical evolution shimmer, fast ascending twinkling arpeggio, glittering chiptune sparkles rising upward, enchanting transformation, ethereal glittering tail
```

## 4. `sfx_flip.wav` — 카드 뒤집기 (촤락)

> 목표: 카드가 휙 도는 짧은 휘리릭 — 살짝 내려가는 블립 + 부드러운 노이즈 스윕. **~0.3초**

```
8-bit chiptune, NES 2A03 style, square wave with noise channel, instrumental, no vocals, mono:
quick card flip whoosh, short downward pitch blip with a soft noise sweep, snappy paper turn, very short
```

## 5. `sfx_tap.wav` — UI 선택 (틱)

> 목표: 메뉴 커서/버튼 한 번 — 아주 짧은 단음 클릭. **~0.1초** (제일 짧게)

```
8-bit chiptune, NES 2A03 style, single square wave, instrumental, no vocals, mono:
tiny UI select blip, one very short crisp menu cursor click, retro game button, ultra short
```

## 6. `sfx_gauge_full.wav` — 호감도 게이지 가득 (차오름 완료)

> 목표: 상승 스윕이 깔끔한 차임으로 안착 — "다 찼다!"의 만족스러운 해결. **~0.9초**

```
8-bit chiptune, NES 2A03 style, square wave portamento, instrumental, no vocals, mono:
rising power-up sweep filling to completion, ascending glide landing on a clean satisfying chime, gauge full confirm, warm resolve
```

## 7. `sfx_book.wav` — 체키북 열기 (책장)

> 목표: 책/메뉴가 스르륵 열림 — 부드러운 페이지 노이즈 + 낮고 따뜻한 톤. **~0.6초**

```
8-bit chiptune, NES 2A03 style, noise channel plus low triangle wave, instrumental, no vocals, mono:
gentle book open sound, soft page-turn noise with a low warm chiptune thump, cozy menu open, short
```

## 8. `sfx_shutter.wav` — 공유 이미지 저장 (찰칵)

> 목표: 레트로 카메라 셔터 — 빠른 노이즈 클릭 2번(열림-닫힘). **~0.4초**

```
8-bit chiptune, NES 2A03 style, noise channel percussive, instrumental, no vocals, mono:
retro camera shutter snap, two quick percussive clicks open then close, photographic 8-bit shutter, short and snappy
```

---

## 완성 체크리스트

- [ ] 8개 모두 트림 → 모노 16-bit WAV → 위 파일명으로 `assets/audio/`에 저장
- [ ] 길이 과하지 않게(특히 `tap`/`flip`은 0.1~0.3초)
- [ ] 음량 8개 균형 맞춤(`tap`이 `cheki_get`보다 크지 않게)
- [ ] Godot 에디터에서 임포트 확인(루프 off) → 인게임에서 주문/획득/나비/플립/탭/게이지/책/공유 들어보기
- [ ] 필요 시 `SFX` 버스 음량으로 일괄 조절
