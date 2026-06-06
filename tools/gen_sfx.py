#!/usr/bin/env python3
"""나라쿠치 효과음 8종 생성기 (T18 사운드 자리 채우기) — ChipTone 풍 칩튠 합성.

표준 라이브러리만 사용(wave/struct/math/random). square/triangle/noise + 엔벨로프로
NES 풍 8비트 SFX 8종을 assets/audio/sfx_*.wav 로 떨군다(모노 16-bit). 파라미터를 조정해
재생성 가능. 마음에 안 드는 큐는 ChipTone/jsfxr 결과물로 같은 파일명에 덮어쓰면 됨.

  python3 tools/gen_sfx.py

큐: order·cheki_get·butterfly·flip·tap·gauge_full·book·shutter (→ docs/audio-sfx-prompts.md)
"""
import math
import os
import random
import struct
import wave

SR = 44100  # 샘플레이트

# 재현 가능하게(노이즈 큐가 매번 동일하도록)
random.seed(1116)


# ── 파형 ─────────────────────────────────────────────────
def wave_sample(phase: float, kind: str, duty: float = 0.5) -> float:
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < duty else -1.0
    if kind == "tri":
        return 4.0 * abs(p - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "sine":
        return math.sin(2.0 * math.pi * p)
    return 0.0


def env_ar(i: int, n: int, attack: float, release: float) -> float:
    """선형 attack/release 엔벨로프(클릭 방지). 가운데는 1.0 유지."""
    a = int(attack * SR)
    r = int(release * SR)
    if i < a:
        return i / max(1, a)
    if i > n - r:
        return max(0.0, (n - i) / max(1, r))
    return 1.0


# ── 제너레이터 ───────────────────────────────────────────
def tone(freq, dur, kind="square", vol=0.6, duty=0.5,
         attack=0.004, release=0.03, decay_exp=0.0,
         vib_rate=0.0, vib_depth=0.0):
    """단음. decay_exp>0 이면 지수 감쇠(동전·반짝 톤). vib_* 로 비브라토."""
    n = int(dur * SR)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = freq
        if vib_rate > 0.0:
            f = freq * (1.0 + vib_depth * math.sin(2.0 * math.pi * vib_rate * t))
        phase += f / SR
        s = wave_sample(phase, kind, duty)
        a = env_ar(i, n, attack, release)
        if decay_exp > 0.0:
            a *= math.exp(-decay_exp * t)
        out[i] = s * vol * a
    return out


def sweep(f0, f1, dur, kind="square", vol=0.6, duty=0.5,
          attack=0.004, release=0.04, expo=True):
    """피치 스윕(포르타멘토). expo=True 면 지수 보간(자연스러운 상승/하강)."""
    n = int(dur * SR)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        x = i / max(1, n - 1)
        f = (f0 * (f1 / f0) ** x) if expo else (f0 + (f1 - f0) * x)
        phase += f / SR
        out[i] = wave_sample(phase, kind, duty) * vol * env_ar(i, n, attack, release)
    return out


def noise(dur, vol=0.5, attack=0.002, release=0.05, lp=0.0, decay_exp=0.0):
    """화이트 노이즈. lp(0~1) 원폴 로우패스로 'fff' 결로 부드럽게. decay_exp 로 감쇠."""
    n = int(dur * SR)
    out = [0.0] * n
    y = 0.0
    for i in range(n):
        x = random.uniform(-1.0, 1.0)
        if lp > 0.0:
            y += lp * (x - y)
            s = y
        else:
            s = x
        a = env_ar(i, n, attack, release)
        if decay_exp > 0.0:
            a *= math.exp(-decay_exp * (i / SR))
        out[i] = s * vol * a
    return out


# ── 합성 헬퍼 ────────────────────────────────────────────
def cat(*bufs):
    out = []
    for b in bufs:
        out.extend(b)
    return out


def mix(*bufs):
    n = max(len(b) for b in bufs)
    out = [0.0] * n
    for b in bufs:
        for i, v in enumerate(b):
            out[i] += v
    return out


def silence(dur):
    return [0.0] * int(dur * SR)


def midi(n):
    return 440.0 * 2.0 ** ((n - 69) / 12.0)


# 음이름 → MIDI (필요 음만)
N = {
    "C4": 60, "E4": 64, "G4": 67,
    "C5": 72, "E5": 76, "G5": 79, "A5": 81,
    "C6": 84, "E6": 88, "G6": 91,
    "C7": 96, "E7": 100, "G7": 103,
    "E3": 52, "A3": 57,
}


def f(name):
    return midi(N[name])


# ── 큐 정의 ──────────────────────────────────────────────
def cue_order():
    # 딸랑 — 산뜻한 2음(딩-동). triangle 종소리 + square 살짝.
    a = mix(tone(f("G5"), 0.10, "tri", 0.7, decay_exp=10),
            tone(f("G5"), 0.10, "square", 0.18, duty=0.5, decay_exp=12))
    b = mix(tone(f("C6"), 0.20, "tri", 0.8, decay_exp=7),
            tone(f("C6"), 0.20, "square", 0.2, duty=0.5, decay_exp=9))
    return cat(a, b)


def cue_cheki_get():
    # 획득 팡파레 — 상승 아르페지오 → 밝은 코드 → 반짝 꼬리. (감정 피크)
    arp = []
    for nm in ["C5", "E5", "G5", "C6"]:
        arp = cat(arp, tone(f(nm), 0.075, "square", 0.6, duty=0.5, release=0.02))
    chord = mix(tone(f("C6"), 0.5, "square", 0.42, duty=0.5, decay_exp=3.0),
                tone(f("E6"), 0.5, "square", 0.34, duty=0.25, decay_exp=3.0),
                tone(f("G6"), 0.5, "tri", 0.5, decay_exp=3.0))
    sparkle = cat(tone(f("C7"), 0.05, "square", 0.3, duty=0.25, decay_exp=20),
                  tone(f("E7"), 0.07, "square", 0.28, duty=0.25, decay_exp=18))
    return cat(arp, mix(chord, cat(silence(0.18), sparkle)))


def cue_butterfly():
    # 나비 승급 — 빠른 2옥타브 상승 아르페지오 + 비브라토 잔향 + 트윙클.
    arp = []
    for nm in ["C5", "E5", "G5", "C6", "E6", "G6", "C7"]:
        arp = cat(arp, tone(f(nm), 0.06, "square", 0.5, duty=0.25, release=0.015))
    shimmer = tone(f("C7"), 0.6, "tri", 0.55, decay_exp=2.2, vib_rate=14, vib_depth=0.02)
    twinkle = cat(silence(0.1), tone(f("G7"), 0.05, "square", 0.22, duty=0.12, decay_exp=22),
                  silence(0.12), tone(f("E7"), 0.05, "square", 0.2, duty=0.12, decay_exp=22))
    return cat(arp, mix(shimmer, twinkle))


def cue_flip():
    # 카드 뒤집기 — 빠른 하강 블립 + 부드러운 노이즈 스윕.
    blip = sweep(1300, 420, 0.16, "square", 0.5, duty=0.4, release=0.03)
    swsh = noise(0.14, 0.28, lp=0.06, decay_exp=18, release=0.04)
    return mix(blip, swsh)


def cue_tap():
    # UI 틱 — 아주 짧은 단음 클릭.
    return tone(f("C6"), 0.05, "square", 0.5, duty=0.5, attack=0.002, release=0.02, decay_exp=16)


def cue_gauge_full():
    # 게이지 가득 — 상승 스윕 → 깔끔한 차임 안착.
    up = sweep(330, 880, 0.42, "square", 0.42, duty=0.5, release=0.02)
    chime = mix(tone(f("C6"), 0.34, "tri", 0.7, decay_exp=4.5),
                tone(f("G6"), 0.34, "tri", 0.4, decay_exp=4.5))
    return cat(up, chime)


def cue_book():
    # 체키북 열기 — 낮은 삼각파 텀프 + 부드러운 페이지 노이즈.
    thump = tone(f("A3"), 0.16, "tri", 0.6, attack=0.003, release=0.06, decay_exp=8)
    page = noise(0.4, 0.26, lp=0.04, attack=0.02, release=0.12, decay_exp=4)
    return mix(thump, page)


def cue_shutter():
    # 공유 저장 — 셔터 찰칵(열림-닫힘 노이즈 클릭 2발 + 미세 금속 클릭).
    click1 = mix(noise(0.05, 0.5, lp=0.25, release=0.02, decay_exp=30),
                 tone(2200, 0.03, "square", 0.2, duty=0.5, decay_exp=40))
    click2 = mix(noise(0.07, 0.55, lp=0.22, release=0.03, decay_exp=24),
                 tone(1800, 0.04, "square", 0.22, duty=0.5, decay_exp=35))
    return cat(click1, silence(0.05), click2)


CUES = {
    "order": (cue_order, 0.72),
    "cheki_get": (cue_cheki_get, 0.85),
    "butterfly": (cue_butterfly, 0.80),
    "flip": (cue_flip, 0.62),
    "tap": (cue_tap, 0.55),
    "gauge_full": (cue_gauge_full, 0.78),
    "book": (cue_book, 0.62),
    "shutter": (cue_shutter, 0.70),
}


# ── 정규화 + 기록 ────────────────────────────────────────
def normalize(buf, peak):
    m = max((abs(s) for s in buf), default=0.0)
    if m <= 0.0:
        return buf
    g = peak / m
    return [s * g for s in buf]


def write_wav(path, buf):
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in buf:
            v = int(max(-1.0, min(1.0, s)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(bytes(frames))


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.join(os.path.dirname(here), "assets", "audio")
    os.makedirs(out_dir, exist_ok=True)
    for key, (gen, peak) in CUES.items():
        buf = normalize(gen(), peak)
        path = os.path.join(out_dir, "sfx_%s.wav" % key)
        write_wav(path, buf)
        print("✅ %-12s %5.2fs  peak=%.2f  → %s" % (key, len(buf) / SR, peak, os.path.relpath(path)))


if __name__ == "__main__":
    main()
