#!/usr/bin/env python3
"""나라쿠치 콘텐츠 스튜디오 — 대사·선택지·버튼·감정을 브라우저 GUI 로 편집하는 로컬 툴.

data/*.json (ticker·talk·gifts·buttons) 을 읽어 GUI 로 보여주고, 검증 후 그대로 다시 쓴다.
게임(GameData)과 이 툴이 같은 JSON 을 본다 → 단일 출처. (dot_studio.py 와 같은 무의존 패턴)

  - 메인 티커: 캐릭터(옥자·미호…) 선택 → 상황(잠금)×단계(존댓말/반말) 라인 + 단계 컷인 편집
  - 펫 티커: 캐릭터(시온이·규종이…) 선택 → 버튼별 풀(cheki/snack/play/pet/idle) 라인 편집
  - 대화: 메인 선택 → 단계별 토막(질문) + 선택지(label/reply/tier/감정) CRUD
  - 선물: 메인 선택 → 프롬프트 + 선물 항목(label/reply/tier/감정) CRUD
  - 버튼·감정: 옥자 버튼/터치 감정맵 + 시온이 4버튼(라벨·감정·티커풀) — 메인·펫 공유 매핑
  - 캐릭터 목록은 data/characters.gd(Characters.REGISTRY)를 파싱 — 게임과 단일 출처(.gd 추가 시 자동 반영)

감정은 실제 스프라이트(assets/sprites/okja_*.png·sioni_*.png)를 썸네일로 보여준다.
대사 미리보기는 {nick} 을 샘플 닉네임으로 치환해 표시한다.

실행:
  python3 tools/content_studio.py            # 브라우저 자동 오픈(127.0.0.1:8800)
  python3 tools/content_studio.py --port 8900 --no-browser
"""
import argparse
import json
import os
import re
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA_DIR = os.path.join(ROOT, "data")
SPRITES_DIR = os.path.join(ROOT, "assets", "sprites")
AUDIO_DIR = os.path.join(ROOT, "assets", "audio")

FILES = {
    "ticker": "ticker.json",
    "talk": "talk.json",
    "gifts": "gifts.json",
    "buttons": "buttons.json",
    "balance": "balance.json",
    "sound": "sound.json",
}

# 사운드 이벤트 카테고리(검증·UI 그룹 단일 출처 — sound.gd/ADR 0004 와 동기).
SOUND_CATS = ["ui", "interaction", "reward", "transition"]

# 게임 코드와 일치해야 하는 허용값(검증용 단일 출처 — okja.gd / sioni.gd EXPRESSIONS 와 동기).
OKJA_EXPR = ["idle", "smile", "shy", "sad", "brew", "talk"]
SIONI_EXPR = ["idle", "snack", "play", "pet"]
TALK_TIERS = ["good", "plain"]
GIFT_TIERS = ["match", "sion", "plain"]
MAX_CHOICES = 4


def _load_gift_icons():
    """선물 아이콘 슬롯 id 목록 — asset_manifest.json A3 의 icon_gift_* 에서 읽는다(생산 슬롯과 단일 출처).

    실패 시 기본 4종으로 폴백. gifts.json 의 gift.icon 은 이 중 하나(또는 빈 문자열=텍스트만).
    """
    try:
        with open(os.path.join(HERE, "asset_manifest.json"), encoding="utf-8") as f:
            mani = json.load(f)
        ids = [it["id"] for grp in mani.get("groups", []) for it in grp.get("items", [])
               if str(it.get("id", "")).startswith("icon_gift_")]
        if ids:
            return ids
    except Exception:
        pass
    return ["icon_gift_1", "icon_gift_2", "icon_gift_3", "icon_gift_4"]


GIFT_ICONS = _load_gift_icons()


def _list_audio():
    """assets/audio 의 .wav 파일명 목록(정렬) — 사운드 탭 드롭다운 단일 출처."""
    try:
        return sorted(f for f in os.listdir(AUDIO_DIR) if f.endswith(".wav"))
    except OSError:
        return []


# 캐릭터 레지스트리(메인·펫) 단일 출처 — data/characters.gd 의 Characters.REGISTRY 를 파싱한다.
#   게임과 동기: .gd 에 캐릭터를 추가하면 스튜디오 탭(티커·대화·선물)에 자동 반영된다.
#   dialogue = 데이터 키(ticker[dk]·ticker[dk_cutin], talk/gifts 는 dk 하위 섹션 또는 평면 폴백).
_CHAR_RE = re.compile(
    r'"(\w+)":\s*\{\s*"name":\s*"([^"]+)",\s*"kind":\s*(MAIN|PET),'
    r'\s*"dialogue":\s*"(\w+)",\s*"buttons":\s*"(\w+)"'
    r'(?:,\s*"sprite":\s*"(\w+)")?'  # sprite = 라이브 표정 접두어(옵션 — 없으면 디렉토리 탐지 폴백)
)


def _sprite_prefix(key):
    """표정 썸네일 파일 접두어 — {key}_idle.png 우선, 없으면 key 로 시작하는 접두어를 탐색.

    시온이는 id 가 'sion' 이지만 표정 파일은 'sioni_*' 라 직접 매치가 안 된다 → 'sion' 으로 시작하는
    접두어('sioni')를 디렉토리에서 찾아 흡수한다. (게임의 sprite_prefix 와는 별개로 '실재 파일'을 본다.)
    """
    if os.path.isfile(os.path.join(SPRITES_DIR, f"{key}_idle.png")):
        return key
    try:
        for fn in sorted(os.listdir(SPRITES_DIR)):
            if fn.endswith("_idle.png"):
                pre = fn[: -len("_idle.png")]
                if pre.startswith(key):
                    return pre
    except OSError:
        pass
    return key


def load_characters():
    """characters.gd REGISTRY → {"mains":[…], "pets":[…]}. 각 항목 {id,name,dialogue,buttons,sprite}.

    sprite = 표정 썸네일 접두어(_sprite_prefix). 파싱 실패 시 옥자/시온이 기본으로 폴백해 도구가 죽지 않게 한다.
    """
    mains, pets = [], []
    try:
        with open(os.path.join(DATA_DIR, "characters.gd"), encoding="utf-8") as f:
            src = f.read()
        for m in _CHAR_RE.finditer(src):
            cid, name, kind, dialogue, buttons, sprite = m.groups()
            entry = {"id": cid, "name": name, "dialogue": dialogue, "buttons": buttons,
                     "sprite": sprite or _sprite_prefix(dialogue)}  # REGISTRY sprite 우선, 없으면 디렉토리 탐지
            (mains if kind == "MAIN" else pets).append(entry)
    except OSError:
        pass
    if not mains:
        mains = [{"id": "okja", "name": "옥자", "dialogue": "okja", "buttons": "okja", "sprite": "okja"}]
    if not pets:
        pets = [{"id": "sion", "name": "시온이", "dialogue": "sion", "buttons": "sion", "sprite": "sioni"}]
    return {"mains": mains, "pets": pets}


# ── 데이터 입출력 ────────────────────────────────────────────

def load_all():
    db = {}
    for key, fname in FILES.items():
        path = os.path.join(DATA_DIR, fname)
        with open(path, encoding="utf-8") as f:
            db[key] = json.load(f)
    return db


def validate(db):
    """하드 에러(저장 차단) 목록을 반환한다. 빈 문자열 등은 경고로 두고 막지 않는다."""
    errs = []

    chars = load_characters()

    def is_str_list(v):
        return isinstance(v, list) and all(isinstance(x, str) for x in v)

    # talk/gifts 의 캐릭터 섹션 — dk 하위가 있으면 그걸, 없으면 평면 루트(옥자 legacy).
    #   게임 Dialogue._section() 과 동일 규칙(단일 출처).
    def section(d, key):
        return d[key] if isinstance(d, dict) and key in d else d

    # ── 메인 캐릭터(옥자·미호…) — 티커·컷인·대화·선물 (dialogue 키로 일반화) ──
    for c in chars["mains"]:
        dk, nm = c["dialogue"], c["name"]

        # ticker[dk] — 상황×말투 풀
        for sit, pools in db.get("ticker", {}).get(dk, {}).items():
            if sit.startswith("_"):
                continue
            if not isinstance(pools, dict):
                errs.append(f"{nm} 티커 '{sit}' 형식 오류")
                continue
            for stage, lines in pools.items():
                if stage.startswith("_"):
                    continue
                if not is_str_list(lines):
                    errs.append(f"{nm} 티커 '{sit}.{stage}' 는 문자열 배열이어야 함")

        # ticker[dk_cutin] — 단계 상승 컷인(lines[{text,expr}] + reveal + badge)
        for stage, data in db.get("ticker", {}).get(f"{dk}_cutin", {}).items():
            if stage.startswith("_"):
                continue
            if not isinstance(data, dict):
                errs.append(f"{nm} 컷인 '{stage}' 형식 오류")
                continue
            lines = data.get("lines", [])
            if not isinstance(lines, list) or len(lines) == 0:
                errs.append(f"{nm} 컷인 '{stage}' 대사는 최소 1줄이어야 함")
            else:
                for li, ln in enumerate(lines):
                    if not isinstance(ln, dict) or not isinstance(ln.get("text"), str):
                        errs.append(f"{nm} 컷인 {stage}#{li+1} 대사 형식 오류(text 필요)")
                    elif ln.get("expr") not in OKJA_EXPR:
                        errs.append(f"{nm} 컷인 {stage}#{li+1} 감정 값 오류({ln.get('expr')})")

        # talk — 단계(guest/regular)별 토막
        talk = section(db.get("talk", {}), dk)
        for stage in ("guest", "regular"):
            topics = talk.get(stage, [])
            if not isinstance(topics, list):
                errs.append(f"{nm} 대화 '{stage}' 는 토막 배열이어야 함")
                continue
            for ti, topic in enumerate(topics):
                choices = topic.get("choices", [])
                if not isinstance(choices, list) or not (1 <= len(choices) <= MAX_CHOICES):
                    errs.append(f"{nm} 대화 {stage}#{ti+1} 선택지는 1~{MAX_CHOICES}개여야 함")
                    continue
                for ci, ch in enumerate(choices):
                    if ch.get("tier") not in TALK_TIERS:
                        errs.append(f"{nm} 대화 {stage}#{ti+1} 선택지{ci+1} tier 값 오류({ch.get('tier')})")
                    if ch.get("expr") not in OKJA_EXPR:
                        errs.append(f"{nm} 대화 {stage}#{ti+1} 선택지{ci+1} 감정 값 오류({ch.get('expr')})")

        # gifts — 선물 항목
        gifts = section(db.get("gifts", {}), dk)
        for gi, g in enumerate(gifts.get("gifts", [])):
            if g.get("tier") not in GIFT_TIERS:
                errs.append(f"{nm} 선물#{gi+1} tier 값 오류({g.get('tier')})")
            if g.get("expr") not in OKJA_EXPR:
                errs.append(f"{nm} 선물#{gi+1} 감정 값 오류({g.get('expr')})")
            icon = g.get("icon", "")  # 아이콘 슬롯 id(선택) — 빈 문자열은 텍스트만, 허용
            if icon and icon not in GIFT_ICONS:
                errs.append(f"{nm} 선물#{gi+1} 아이콘 '{icon}' 은 허용 슬롯이 아님(asset_manifest icon_gift_*)")
            rep = g.get("reply")  # reply = {guest, regular} 단계별 반응
            if isinstance(rep, dict):
                for st in ("guest", "regular"):
                    if not isinstance(rep.get(st), str):
                        errs.append(f"{nm} 선물#{gi+1} 반응 '{st}' 는 문자열이어야 함")
            elif not isinstance(rep, str):
                errs.append(f"{nm} 선물#{gi+1} 반응 형식 오류(문자열 또는 {{guest,regular}})")

    # ── 펫(시온이·규종이…) — 버튼별 티커 풀 (dialogue 키로 일반화) ──
    pet_keys = {}  # dk → 풀 키 목록(버튼 ticker 참조 검증에 사용)
    for c in chars["pets"]:
        dk, nm = c["dialogue"], c["name"]
        pet = db.get("ticker", {}).get(dk, {})
        keys = [k for k in pet.keys() if not k.startswith("_")]
        pet_keys[dk] = keys
        for k in keys:
            if not is_str_list(pet[k]):
                errs.append(f"{nm} 티커 '{k}' 는 문자열 배열이어야 함")

    # 메인 버튼 감정맵 — buttons[buttons_key].emotion (메인별 전용: 옥자=okja·미호=miho)
    #   버튼 라벨·순서(actions)는 okja 공유·잠금이라 여기선 검증 안 한다(emotion 만 편집 대상).
    for c in chars["mains"]:
        bk, nm = c["buttons"], c["name"]
        em = db.get("buttons", {}).get(bk, {}).get("emotion", {})
        for k in ("cheki", "drink", "touch_cap"):
            if em.get(k) not in OKJA_EXPR:
                errs.append(f"{nm} 버튼 감정 '{k}' 값 오류({em.get(k)})")
        touch = em.get("touch", [])
        if not isinstance(touch, list) or len(touch) == 0:
            errs.append(f"{nm} 터치 감정 풀은 최소 1개여야 함")
        elif any(x not in OKJA_EXPR for x in touch):
            errs.append(f"{nm} 터치 감정 풀에 잘못된 값({touch})")

    # 펫 버튼 4버튼 — buttons[buttons_key].actions (펫별 전용: 시온이=sion·규종이=gyujong)
    #   ticker 참조는 해당 펫 dialogue 풀 키 기준.
    for c in chars["pets"]:
        bk, dk, nm = c["buttons"], c["dialogue"], c["name"]
        keys = pet_keys.get(dk, [])
        for a in db.get("buttons", {}).get(bk, {}).get("actions", []):
            if a.get("emotion") not in SIONI_EXPR:
                errs.append(f"{nm} 버튼 '{a.get('id')}' 감정 값 오류({a.get('emotion')})")
            if a.get("ticker") not in keys:
                errs.append(f"{nm} 버튼 '{a.get('id')}' 티커풀 '{a.get('ticker')}' 가 {nm} 티커에 없음")

    # balance.affinity — tier별(대화/선물) + 액션별 고정 수치 (모두 정수)
    def is_int(v):
        return isinstance(v, int) and not isinstance(v, bool)

    aff = db.get("balance", {}).get("affinity", {})
    for k in ("good", "plain"):
        if not is_int(aff.get("talk", {}).get(k)):
            errs.append(f"밸런스 대화 tier '{k}' 는 정수여야 함")
    for k in ("match", "sion", "plain"):
        if not is_int(aff.get("gift", {}).get(k)):
            errs.append(f"밸런스 선물 tier '{k}' 는 정수여야 함")
    for k in ("drink", "drink_favorite", "cheki", "touch", "touch_session_cap", "sion", "sion_favorite"):
        if not is_int(aff.get(k)):
            errs.append(f"밸런스 '{k}' 는 정수여야 함")

    # sound — 이벤트 바인딩 (→ ADR 0004). 이벤트 키/cat 은 코드 소유(여기선 추가/삭제·키변경 안 함).
    #   file 은 빈 문자열(=cat 기본) 이거나 실재하는 wav 여야 한다. cat 은 허용값.
    snd = db.get("sound", {})
    audio = set(_list_audio())
    defaults = snd.get("defaults", {})
    for cat, fn in defaults.items():
        if fn not in (None, "") and fn not in audio:
            errs.append(f"사운드 기본음 '{cat}' 파일 없음: {fn}")
    for eid, e in snd.get("events", {}).items():
        if eid.startswith("_"):
            continue
        if not isinstance(e, dict):
            errs.append(f"사운드 이벤트 '{eid}' 형식 오류")
            continue
        if e.get("cat") not in SOUND_CATS:
            errs.append(f"사운드 이벤트 '{eid}' 카테고리 오류({e.get('cat')})")
        fn = e.get("file", "")
        if fn not in ("", None) and fn not in audio:
            errs.append(f"사운드 이벤트 '{eid}' 파일 없음: {fn}")
        if not isinstance(e.get("pitch", 1.0), (int, float)) or isinstance(e.get("pitch"), bool):
            errs.append(f"사운드 이벤트 '{eid}' pitch 는 숫자여야 함")

    return errs


def save_all(db):
    for key, fname in FILES.items():
        path = os.path.join(DATA_DIR, fname)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(db[key], f, ensure_ascii=False, indent=2)
            f.write("\n")


# ── HTTP 핸들러 ─────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # 조용히

    def _send(self, code, body, ctype="application/json; charset=utf-8"):
        data = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/" or self.path.startswith("/?"):
            self._send(200, INDEX_HTML, "text/html; charset=utf-8")
        elif self.path == "/api/data":
            payload = {
                "db": load_all(),
                "meta": {
                    "characters": load_characters(),
                    "okjaExpr": OKJA_EXPR,
                    "sioniExpr": SIONI_EXPR,
                    "talkTiers": TALK_TIERS,
                    "giftTiers": GIFT_TIERS,
                    "giftIcons": GIFT_ICONS,
                    "maxChoices": MAX_CHOICES,
                    "audioFiles": _list_audio(),
                    "soundCats": SOUND_CATS,
                },
            }
            self._send(200, json.dumps(payload, ensure_ascii=False))
        elif self.path.startswith("/sprite/"):
            self._serve_sprite(self.path[len("/sprite/"):])
        elif self.path.startswith("/audio/"):
            self._serve_audio(self.path[len("/audio/"):])
        else:
            self._send(404, json.dumps({"error": "not found"}))

    def _serve_sprite(self, name):
        # 경로 traversal 차단 — 영숫자/언더스코어만.
        safe = "".join(c for c in name if c.isalnum() or c == "_")
        path = os.path.join(SPRITES_DIR, safe + ".png")
        if not os.path.isfile(path):
            self._send(404, b"", "image/png")
            return
        with open(path, "rb") as f:
            self._send(200, f.read(), "image/png")

    def _serve_audio(self, name):
        # 경로 traversal 차단 — 영숫자/언더스코어/. 만, .wav 강제.
        safe = "".join(c for c in name if c.isalnum() or c in "_.")
        if not safe.endswith(".wav") or "/" in safe or ".." in safe:
            self._send(404, b"", "audio/wav")
            return
        path = os.path.join(AUDIO_DIR, safe)
        if not os.path.isfile(path):
            self._send(404, b"", "audio/wav")
            return
        with open(path, "rb") as f:
            self._send(200, f.read(), "audio/wav")

    def do_POST(self):
        if self.path != "/api/save":
            self._send(404, json.dumps({"error": "not found"}))
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            db = json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception as e:
            self._send(400, json.dumps({"ok": False, "errors": [f"JSON 파싱 실패: {e}"]}))
            return
        errs = validate(db)
        if errs:
            self._send(400, json.dumps({"ok": False, "errors": errs}, ensure_ascii=False))
            return
        try:
            save_all(db)
        except Exception as e:
            self._send(500, json.dumps({"ok": False, "errors": [f"저장 실패: {e}"]}, ensure_ascii=False))
            return
        self._send(200, json.dumps({"ok": True}))


# ── 프론트엔드 (단일 페이지) ─────────────────────────────────

INDEX_HTML = r"""<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>나라쿠치 콘텐츠 스튜디오</title>
<style>
  :root {
    --bg:#1a1320; --panel:#241a2e; --panel2:#2e2238; --ink:#f3e9f7; --muted:#a892b8;
    --line:#3c2d4a; --accent:#d4607f; --accent2:#7a5cff; --good:#5cc98a; --warn:#e0a85c;
  }
  * { box-sizing:border-box; }
  body { margin:0; font-family:-apple-system,"Apple SD Gothic Neo",system-ui,sans-serif;
    background:var(--bg); color:var(--ink); font-size:14px; }
  header { position:sticky; top:0; z-index:10; background:#160f1c; border-bottom:1px solid var(--line);
    display:flex; align-items:center; gap:12px; padding:10px 16px; }
  header h1 { font-size:15px; margin:0; letter-spacing:.5px; }
  header .spacer { flex:1; }
  .tabs { display:flex; gap:4px; padding:0 12px; background:#160f1c; border-bottom:1px solid var(--line);
    position:sticky; top:43px; z-index:9; }
  .tab { padding:9px 14px; cursor:pointer; color:var(--muted); border-bottom:2px solid transparent; }
  .tab.active { color:var(--ink); border-bottom-color:var(--accent); }
  main { padding:16px; max-width:980px; margin:0 auto; }
  .card { background:var(--panel); border:1px solid var(--line); border-radius:10px; padding:12px 14px;
    margin-bottom:12px; }
  .card > h3 { margin:0 0 10px; font-size:13px; color:var(--ink); display:flex; align-items:center; gap:8px; }
  .lock { font-size:11px; color:var(--muted); border:1px solid var(--line); border-radius:6px; padding:1px 6px; }
  .cols { display:grid; grid-template-columns:1fr 1fr; gap:14px; }
  @media(max-width:720px){ .cols{ grid-template-columns:1fr; } }
  .stage-label { font-size:12px; color:var(--accent); margin-bottom:6px; font-weight:600; }
  .row { display:flex; gap:6px; align-items:flex-start; margin-bottom:6px; }
  input[type=text], textarea, select {
    background:var(--panel2); color:var(--ink); border:1px solid var(--line); border-radius:7px;
    padding:6px 8px; font-size:13px; font-family:inherit; width:100%; }
  textarea { resize:vertical; min-height:34px; }
  input:focus, textarea:focus, select:focus { outline:none; border-color:var(--accent2); }
  .x { flex:0 0 auto; background:transparent; border:1px solid var(--line); color:var(--muted);
    border-radius:7px; width:30px; height:32px; cursor:pointer; font-size:14px; }
  .x:hover { color:#fff; border-color:var(--accent); }
  .add { background:transparent; border:1px dashed var(--line); color:var(--muted); border-radius:7px;
    padding:6px 10px; cursor:pointer; font-size:12px; margin-top:2px; }
  .add:hover { color:var(--ink); border-color:var(--accent2); }
  .add[disabled]{ opacity:.4; cursor:not-allowed; }
  .preview { font-size:12px; color:var(--muted); margin:2px 0 8px 2px; }
  .preview b { color:var(--ink); font-weight:500; }
  button.primary { background:var(--accent); color:#fff; border:none; border-radius:8px;
    padding:8px 16px; cursor:pointer; font-size:13px; font-weight:600; }
  button.primary:hover { filter:brightness(1.1); }
  button.ghost { background:transparent; border:1px solid var(--line); color:var(--muted);
    border-radius:8px; padding:8px 12px; cursor:pointer; font-size:13px; }
  .status { font-size:12px; color:var(--muted); }
  .status.dirty { color:var(--warn); }
  .status.ok { color:var(--good); }
  .status.err { color:var(--accent); }
  .emo { display:flex; gap:4px; flex-wrap:wrap; }
  .emo-chip { border:2px solid transparent; border-radius:8px; padding:2px; cursor:pointer;
    background:#1a1320; display:flex; flex-direction:column; align-items:center; width:46px; }
  .emo-chip img { width:36px; height:46px; object-fit:contain; image-rendering:pixelated; }
  .emo-chip span { font-size:9px; color:var(--muted); margin-top:1px; }
  .emo-chip.sel { border-color:var(--accent); }
  .emo-chip.sel span { color:var(--ink); }
  .choice { background:var(--panel2); border:1px solid var(--line); border-radius:8px; padding:8px;
    margin-bottom:8px; }
  .choice .grid { display:grid; grid-template-columns:1fr 1fr; gap:6px; }
  .field-label { font-size:11px; color:var(--muted); margin:6px 0 3px; }
  .topic { border-left:3px solid var(--accent2); }
  .badge { font-size:11px; color:var(--muted); background:#1a1320; border:1px solid var(--line);
    border-radius:6px; padding:2px 7px; }
  .err-list { background:#3a1620; border:1px solid var(--accent); border-radius:8px; padding:8px 12px;
    margin-bottom:12px; color:#ffd2dd; font-size:12px; white-space:pre-wrap; }
  .nick-input { width:120px; }
  .hint { font-size:11px; color:var(--muted); margin-top:4px; }
  .char-sel { display:flex; gap:6px; flex-wrap:wrap; margin-bottom:14px; }
  .char-chip { padding:6px 16px; border:1px solid var(--line); border-radius:18px; background:var(--panel2);
    color:var(--muted); cursor:pointer; font-size:13px; font-family:inherit; }
  .char-chip:hover { color:var(--ink); border-color:var(--accent2); }
  .char-chip.sel { border-color:var(--accent); color:var(--ink); background:#2e1a26; font-weight:600; }
</style>
</head>
<body>
<header>
  <h1>🩸 나라쿠치 콘텐츠 스튜디오</h1>
  <span class="lock">data/*.json 직접 편집</span>
  <div class="spacer"></div>
  <label class="status">닉네임 미리보기: <input type="text" id="nick" class="nick-input" value="지반계"></label>
  <span id="status" class="status">불러오는 중…</span>
  <button class="ghost" id="reload">새로고침</button>
  <button class="primary" id="save">저장</button>
</header>
<div class="tabs" id="tabs"></div>
<main id="main"></main>

<script>
"use strict";
let DB = null, META = null;
let dirty = false;
let activeTab = "ticker";
let activeMain = "okja";  // 메인 티커/대화/선물 탭이 보여줄 캐릭터(dialogue 키)
let activePet = "sion";   // 펫 티커 탭이 보여줄 캐릭터(dialogue 키)
const TABS = [
  ["ticker", "메인 티커"],
  ["pet", "펫 티커"],
  ["talk", "대화"],
  ["gifts", "선물"],
  ["buttons", "버튼·감정"],
  ["balance", "밸런스"],
  ["sound", "사운드"],
];
const SOUND_CAT_LABEL = {
  ui:"UI · 네비게이션", interaction:"교감 · 액션", reward:"보상 · 마일스톤", transition:"전환",
};
const SITU_LABEL = {
  enter:"입장/첫 방문", neglect:"방치 후 복귀", cheki:"체키 주문", drink:"음료 주문",
  talk:"대화 진입", gift:"선물 진입", touch:"옥자 터치", touch_cap:"터치 상한",
  no_stamina:"기력 소진", cheki_get:"체키 획득", idle:"평소/심심",
};
// 티커 풀 키 = 말투 분기(단계명 아님). guest=존댓말 풀(손님·단골), regular=반말 풀(편해진 사이~).
const STAGE_LABEL = { guest:"존댓말 (손님·단골)", regular:"반말 (편해진 사이~)" };
// 단계 상승 컷인 키 = 도달 단계 직접 매핑(말투 분기 아님).
const CUTIN_LABEL = { regular:"단골 등극 컷인 (존댓말 유지·200)", comfy:"반말 해금 컷인 (존댓말→반말·600)" };

// ── DOM 헬퍼 ──
function el(tag, attrs={}, kids=[]) {
  const n = document.createElement(tag);
  for (const k in attrs) {
    if (k === "class") n.className = attrs[k];
    else if (k === "html") n.innerHTML = attrs[k];
    else if (k.startsWith("on")) n.addEventListener(k.slice(2), attrs[k]);
    else n.setAttribute(k, attrs[k]);
  }
  for (const c of [].concat(kids)) if (c != null) n.append(c.nodeType ? c : document.createTextNode(c));
  return n;
}
function markDirty() { dirty = true; setStatus("저장되지 않은 변경", "dirty"); }
function setStatus(msg, cls) {
  const s = document.getElementById("status");
  s.textContent = msg; s.className = "status " + (cls||"");
}
function nick() { return document.getElementById("nick").value || "손님"; }
function sub(s) { return (s||"").replaceAll("{nick}", nick()); }

// 캐릭터 선택 칩 줄(메인 또는 펫). current·onPick 은 dialogue 키 기준. 1명뿐이면 생략.
function charSelector(chars, current, onPick) {
  if (!chars || chars.length <= 1) return null;
  const wrap = el("div", {class:"char-sel"});
  for (const c of chars) {
    wrap.append(el("button", {class:"char-chip"+(c.dialogue===current?" sel":""),
      onclick:()=>{ onPick(c.dialogue); }}, c.name));
  }
  return wrap;
}
// talk/gifts 의 캐릭터 섹션 — dk 하위가 있으면 그걸, 없으면 평면 루트(옥자 legacy). 게임 Dialogue._section() 과 동일.
function section(db, key) { return (db && Object.prototype.hasOwnProperty.call(db, key)) ? db[key] : db; }
// 활성 캐릭터의 표정 썸네일 접두어(emotionPicker 용). 메인=okja/miho, 펫=sioni/gyujong.
function mainSprite() { return ((META.characters.mains||[]).find(c=>c.dialogue===activeMain)||{}).sprite || "okja"; }
function petSprite() { return ((META.characters.pets||[]).find(c=>c.dialogue===activePet)||{}).sprite || "sioni"; }

// 감정 썸네일 선택기(단일). spritePrefix = 스프라이트 파일 접두어(okja·miho·sioni·gyujong…).
// exprList 미지정 시 메인(okjaExpr) 기본 — 펫은 META.sioniExpr 를 넘긴다.
function emotionPicker(spritePrefix, value, onChange, exprList) {
  const list = exprList || (spritePrefix === "sioni" ? META.sioniExpr : META.okjaExpr);
  const wrap = el("div", {class:"emo"});
  for (const expr of list) {
    const chip = el("div", {class:"emo-chip"+(expr===value?" sel":""), title:expr}, [
      el("img", {src:`/sprite/${spritePrefix}_${expr}`, alt:expr}),
      el("span", {}, expr),
    ]);
    chip.addEventListener("click", () => {
      value = expr;
      wrap.querySelectorAll(".emo-chip").forEach(c => c.classList.remove("sel"));
      chip.classList.add("sel");
      onChange(expr);
    });
    wrap.append(chip);
  }
  return wrap;
}

// 감정 멀티 선택기(터치 풀). 토글, 최소 1개. spritePrefix = 스프라이트 접두어.
function emotionMulti(spritePrefix, arr, exprList) {
  const list = exprList || (spritePrefix === "sioni" ? META.sioniExpr : META.okjaExpr);
  const wrap = el("div", {class:"emo"});
  for (const expr of list) {
    const on = arr.includes(expr);
    const chip = el("div", {class:"emo-chip"+(on?" sel":""), title:expr}, [
      el("img", {src:`/sprite/${spritePrefix}_${expr}`, alt:expr}),
      el("span", {}, expr),
    ]);
    chip.addEventListener("click", () => {
      const i = arr.indexOf(expr);
      if (i >= 0) { if (arr.length > 1) { arr.splice(i,1); chip.classList.remove("sel"); } }
      else { arr.push(expr); chip.classList.add("sel"); }
      markDirty();
    });
    wrap.append(chip);
  }
  return wrap;
}

// 선물 아이콘 썸네일 선택기(단일) — 슬롯 id(META.giftIcons) + "없음"(빈 문자열=텍스트만).
function iconPicker(value, onChange) {
  const wrap = el("div", {class:"emo"});
  const opts = ["", ...(META.giftIcons||[])];
  for (const id of opts) {
    const sel = (id === (value||"")) ? " sel" : "";
    const kids = id
      ? [el("img", {src:`/sprite/${id}`, alt:id}), el("span", {}, id.replace("icon_gift_","#"))]
      : [el("span", {}, "없음")];
    const chip = el("div", {class:"emo-chip"+sel, title:id||"없음"}, kids);
    chip.addEventListener("click", () => {
      value = id;
      wrap.querySelectorAll(".emo-chip").forEach(c => c.classList.remove("sel"));
      chip.classList.add("sel");
      onChange(id);
    });
    wrap.append(chip);
  }
  return wrap;
}

// 라인 한 줄(텍스트 + {nick} 미리보기 + 삭제). arr 에서 idx 제거 가능.
function lineRow(arr, idx, rerender) {
  const val = arr[idx];
  const input = el("input", {type:"text", value:val});
  input.addEventListener("input", () => { arr[idx] = input.value; markDirty(); updatePrev(); });
  const prev = el("div", {class:"preview"});
  function updatePrev() {
    if ((arr[idx]||"").includes("{nick}")) { prev.style.display=""; prev.innerHTML = "▸ <b>"+esc(sub(arr[idx]))+"</b>"; }
    else prev.style.display = "none";
  }
  updatePrev();
  const row = el("div", {}, [
    el("div", {class:"row"}, [
      input,
      el("button", {class:"x", onclick:() => { arr.splice(idx,1); markDirty(); rerender(); }}, "✕"),
    ]),
    prev,
  ]);
  return row;
}
function esc(s){ return (s||"").replace(/[&<>]/g, c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c])); }

// 문자열 배열 풀 편집 블록(라인 목록 + 추가).
function poolBlock(arr, addLabel) {
  const box = el("div");
  function render() {
    box.innerHTML = "";
    arr.forEach((_, i) => box.append(lineRow(arr, i, render)));
    box.append(el("button", {class:"add", onclick:() => { arr.push(""); markDirty(); render(); }}, "+ "+addLabel));
  }
  render();
  return box;
}

// ── 탭: 메인 티커(옥자·미호…) ──
function renderMainTicker() {
  const main = document.getElementById("main");
  const sel = charSelector(META.characters.mains, activeMain, k=>{ activeMain=k; render(); });
  if (sel) main.append(sel);
  const pools_by_sit = DB.ticker[activeMain] || {};
  for (const sit in pools_by_sit) {
    if (sit.startsWith("_")) continue;
    const pools = pools_by_sit[sit];
    const cols = el("div", {class:"cols"});
    for (const stage of ["guest","regular"]) {
      if (!(stage in pools)) continue;
      cols.append(el("div", {}, [
        el("div", {class:"stage-label"}, STAGE_LABEL[stage]||stage),
        poolBlock(pools[stage], "라인 추가"),
      ]));
    }
    main.append(el("div", {class:"card"}, [
      el("h3", {}, [SITU_LABEL[sit]||sit, el("span", {class:"lock"}, "상황: "+sit+" (잠금)")]),
      cols,
    ]));
  }
  renderCutin(activeMain);  // 같은 탭 아래에 단계 상승 컷인(오버레이) 편집
}

// 컷인 대사 한 줄(text + 메인 표정 + {nick} 미리보기 + 삭제). lines 는 [{text,expr}] 객체 배열.
// spritePrefix = 활성 메인 스프라이트 접두어(okja/miho).
function cutinLineRow(lines, idx, rerender, spritePrefix) {
  const ln = lines[idx];
  const input = el("input", {type:"text", value:ln.text||""});
  const prev = el("div", {class:"preview"});
  function updatePrev() {
    if ((ln.text||"").includes("{nick}")) { prev.style.display=""; prev.innerHTML = "▸ <b>"+esc(sub(ln.text))+"</b>"; }
    else prev.style.display = "none";
  }
  input.addEventListener("input", () => { ln.text = input.value; markDirty(); updatePrev(); });
  updatePrev();
  return el("div", {}, [
    el("div", {class:"row"}, [
      input,
      el("button", {class:"x", onclick:() => { lines.splice(idx,1); markDirty(); rerender(); }}, "✕"),
    ]),
    emotionPicker(spritePrefix||"okja", ln.expr, (e) => { ln.expr = e; markDirty(); }),
    prev,
  ]);
}

// 단계 상승 컷인 카드(단골 등극 / 반말 해금). 단계 키는 코드 연동 — 추가/삭제 금지(내용만).
// key = 메인 dialogue 키(옥자=okja → okja_cutin, 미호=miho → miho_cutin).
function renderCutin(key) {
  const main = document.getElementById("main");
  const cut = DB.ticker[key+"_cutin"];
  if (!cut) return;
  const sprite = mainSprite();
  for (const stage of ["regular","comfy"]) {
    if (!(stage in cut)) continue;
    const data = cut[stage];
    if (!Array.isArray(data.lines)) data.lines = [];
    const linesBox = el("div");
    function renderLines() {
      linesBox.innerHTML = "";
      data.lines.forEach((_, i) => linesBox.append(cutinLineRow(data.lines, i, renderLines, sprite)));
      linesBox.append(el("button", {class:"add", onclick:() => {
        data.lines.push({text:"", expr:"talk"}); markDirty(); renderLines();
      }}, "+ 대사 추가"));
    }
    renderLines();
    const revInput = el("input", {type:"text", value:data.reveal||""});
    const revPrev = el("div", {class:"preview"});
    function updateRevPrev() {
      if ((data.reveal||"").includes("{nick}")) { revPrev.style.display=""; revPrev.innerHTML = "▸ <b>"+esc(sub(data.reveal))+"</b>"; }
      else revPrev.style.display = "none";
    }
    revInput.addEventListener("input", () => { data.reveal = revInput.value; markDirty(); updateRevPrev(); });
    updateRevPrev();
    const badgeInput = el("input", {type:"text", value:data.badge||""});
    badgeInput.addEventListener("input", () => { data.badge = badgeInput.value; markDirty(); });
    main.append(el("div", {class:"card"}, [
      el("h3", {}, [CUTIN_LABEL[stage]||stage, el("span", {class:"lock"}, "단계: "+stage+" (잠금)")]),
      el("div", {class:"stage-label"}, "대사 시퀀스 (한 줄씩 진행)"),
      linesBox,
      el("div", {class:"stage-label", style:"margin-top:12px"}, "해금 줄 (마지막 + 배지)"),
      revInput, revPrev,
      el("div", {class:"stage-label", style:"margin-top:12px"}, "골드 배지"),
      badgeInput,
    ]));
  }
}

// ── 탭: 펫 티커(시온이·규종이…) ──
function renderPetTicker() {
  const main = document.getElementById("main");
  const sel = charSelector(META.characters.pets, activePet, k=>{ activePet=k; render(); });
  if (sel) main.append(sel);
  const pet = DB.ticker[activePet] || {};
  const petName = (META.characters.pets.find(c=>c.dialogue===activePet)||{}).name || "펫";
  main.append(el("div", {class:"hint"}, "버튼 id 별 풀 + idle(터치·획득·평소). 버튼탭에서 각 버튼이 어느 풀을 쓰는지 지정합니다."));
  for (const key in pet) {
    if (key.startsWith("_")) continue;
    main.append(el("div", {class:"card"}, [
      el("h3", {}, [key, el("span", {class:"badge"}, petName+" 풀")]),
      poolBlock(pet[key], "라인 추가"),
    ]));
  }
}

// ── 선택지/선물 항목 편집 ──
// opts.replyStages=true 면 reply 를 {guest,regular} 단계별 두 칸으로(선물). 기본은 단일 reply(대화).
function choiceBlock(choice, tiers, onRemove, opts={}) {
  const labelI = el("input", {type:"text", value:choice.label||""});
  labelI.addEventListener("input", ()=>{ choice.label=labelI.value; markDirty(); });

  // 옥자 반응 — 단계별(선물) 또는 단일(대화)
  let replyEls;
  if (opts.replyStages) {
    // 구버전 단일 문자열 → {guest:기존, regular:""} 로 1회 승격
    if (typeof choice.reply !== "object" || choice.reply === null)
      choice.reply = { guest: choice.reply||"", regular: "" };
    replyEls = ["guest","regular"].map(st => {
      const ri = el("input", {type:"text", value:choice.reply[st]||""});
      const rp = el("div", {class:"preview"});
      const up = ()=>{ rp.innerHTML = "▸ 옥자: <b>"+esc(sub(choice.reply[st]))+"</b>"; };
      ri.addEventListener("input", ()=>{ choice.reply[st]=ri.value; markDirty(); up(); });
      up();
      return el("div", {}, [el("div",{class:"field-label"}, "옥자 반응 — "+(STAGE_LABEL[st]||st)), ri, rp]);
    });
  } else {
    const replyI = el("input", {type:"text", value:choice.reply||""});
    const replyPrev = el("div", {class:"preview"});
    const up = ()=>{ replyPrev.innerHTML = "▸ 옥자: <b>"+esc(sub(choice.reply))+"</b>"; };
    replyI.addEventListener("input", ()=>{ choice.reply=replyI.value; markDirty(); up(); });
    up();
    replyEls = [el("div", {class:"field-label"}, "옥자 반응(하단 티커)"), replyI, replyPrev];
  }

  const tierS = el("select", {});
  for (const t of tiers) tierS.append(el("option", {value:t, ...(t===choice.tier?{selected:"selected"}:{})}, t));
  tierS.addEventListener("change", ()=>{ choice.tier=tierS.value; markDirty(); });
  // 선물 전용 아이콘 피커(opts.iconPicker) — 대화 선택지엔 없음.
  const iconEls = opts.iconPicker ? [
    el("div", {class:"field-label", style:"margin-top:8px"}, "선물 아이콘 (버튼 좌측 24×24 · '없음' 가능)"),
    iconPicker(choice.icon, v=>{ choice.icon=v; markDirty(); }),
  ] : [];
  return el("div", {class:"choice"}, [
    el("div", {class:"row"}, [
      el("div", {style:"flex:1"}, [el("div",{class:"field-label"},"선택지 라벨(버튼)"), labelI]),
      el("button", {class:"x", onclick:onRemove}, "✕"),
    ]),
    ...replyEls,
    el("div", {class:"grid"}, [
      el("div", {}, [el("div",{class:"field-label"},"tier (호감도)"), tierS]),
      el("div", {}, [el("div",{class:"field-label"},"선택 후 메인 표정"),
        emotionPicker(opts.sprite||"okja", choice.expr, v=>{ choice.expr=v; markDirty(); })]),
    ]),
    ...iconEls,
  ]);
}

// ── 탭: 대화 ──
function renderTalk() {
  const main = document.getElementById("main");
  const sel = charSelector(META.characters.mains, activeMain, k=>{ activeMain=k; render(); });
  if (sel) main.append(sel);
  const talk = section(DB.talk, activeMain);
  for (const stage of ["guest","regular"]) {
    if (!Array.isArray(talk[stage])) talk[stage] = [];
    const topics = talk[stage];
    const wrap = el("div");
    function render() {
      wrap.innerHTML = "";
      topics.forEach((topic, ti) => {
        const promptI = el("input", {type:"text", value:topic.prompt||""});
        const promptPrev = el("div", {class:"preview"});
        function up(){ promptPrev.style.display=(topic.prompt||"").includes("{nick}")?"":"none";
          promptPrev.innerHTML="▸ <b>"+esc(sub(topic.prompt))+"</b>"; }
        promptI.addEventListener("input", ()=>{ topic.prompt=promptI.value; markDirty(); up(); });
        up();
        const choicesBox = el("div");
        function renderChoices() {
          choicesBox.innerHTML = "";
          topic.choices.forEach((c, ci) => choicesBox.append(
            choiceBlock(c, META.talkTiers, ()=>{ topic.choices.splice(ci,1); markDirty(); renderChoices(); }, {sprite:mainSprite()})));
          const addBtn = el("button", {class:"add", onclick:()=>{
            if (topic.choices.length>=META.maxChoices) return;
            topic.choices.push({label:"",reply:"",tier:"plain",expr:"talk"}); markDirty(); renderChoices();
          }}, "+ 선택지 추가 (최대 "+META.maxChoices+")");
          if (topic.choices.length>=META.maxChoices) addBtn.setAttribute("disabled","");
          choicesBox.append(addBtn);
        }
        renderChoices();
        wrap.append(el("div", {class:"card topic"}, [
          el("h3", {}, ["토막 #"+(ti+1)+" — 옥자 질문",
            el("div",{class:"spacer",style:"flex:1"}),
            el("button", {class:"x", onclick:()=>{ topics.splice(ti,1); markDirty(); render(); }}, "✕")]),
          promptI, promptPrev,
          el("div", {class:"field-label", style:"margin-top:8px"}, "선택지"),
          choicesBox,
        ]));
      });
      wrap.append(el("button", {class:"add", onclick:()=>{
        topics.push({prompt:"", choices:[{label:"",reply:"",tier:"plain",expr:"talk"}]}); markDirty(); render();
      }}, "+ 토막 추가"));
    }
    render();
    main.append(el("div", {}, [
      el("h3", {style:"color:var(--accent);margin:18px 0 8px"}, STAGE_LABEL[stage]||stage),
      wrap,
    ]));
  }
}

// ── 탭: 선물 ──
function renderGifts() {
  const main = document.getElementById("main");
  const sel = charSelector(META.characters.mains, activeMain, k=>{ activeMain=k; render(); });
  if (sel) main.append(sel);
  const g = section(DB.gifts, activeMain);
  if (!g.prompt) g.prompt = {};
  if (!Array.isArray(g.gifts)) g.gifts = [];
  // 프롬프트
  const promptCard = el("div", {class:"card"}, [el("h3",{},"선물 프롬프트 (캐릭터 질문)")]);
  for (const stage of ["guest","regular"]) {
    const i = el("input", {type:"text", value:(g.prompt||{})[stage]||""});
    i.addEventListener("input", ()=>{ g.prompt[stage]=i.value; markDirty(); });
    promptCard.append(el("div", {}, [el("div",{class:"field-label"}, STAGE_LABEL[stage]||stage), i]));
  }
  main.append(promptCard);
  // 선물 목록
  const listCard = el("div", {class:"card"}, [el("h3",{},"선물 항목")]);
  const box = el("div");
  function render() {
    box.innerHTML = "";
    g.gifts.forEach((gift, gi) => box.append(
      choiceBlock(gift, META.giftTiers, ()=>{ g.gifts.splice(gi,1); markDirty(); render(); }, {replyStages:true, iconPicker:true, sprite:mainSprite()})));
    box.append(el("button", {class:"add", onclick:()=>{
      g.gifts.push({label:"",reply:{guest:"",regular:""},tier:"plain",expr:"idle",icon:""}); markDirty(); render();
    }}, "+ 선물 추가"));
  }
  render();
  listCard.append(box);
  main.append(listCard);
}

// ── 탭: 버튼·감정 (메인 감정맵 + 펫 4버튼, 캐릭터별 전용) ──
function renderButtons() {
  const main = document.getElementById("main");
  const b = DB.buttons;

  // ── 메인 버튼 감정(옥자·미호…) — 라벨·순서는 okja.actions 공유(잠금), emotion 만 전용 ──
  const mSel = charSelector(META.characters.mains, activeMain, k=>{ activeMain=k; render(); });
  if (mSel) main.append(mSel);
  const mc = (META.characters.mains||[]).find(c=>c.dialogue===activeMain) || {};
  const mbk = mc.buttons || "okja";
  const sprite = mainSprite();
  const okjaActs = ((b.okja||{}).actions||[]).map(a=>a.id+"("+a.label+")").join("  ·  ");
  if (!b[mbk]) b[mbk] = {};
  const em = b[mbk].emotion || (b[mbk].emotion = {});
  if (!Array.isArray(em.touch)) em.touch = [];
  const mainCard = el("div", {class:"card"}, [
    el("h3", {}, [(mc.name||"메인")+" 버튼 감정 연결", el("span",{class:"lock"},"라벨·순서 okja 공유·잠금")]),
    el("div", {class:"hint", style:"margin-bottom:10px"}, "버튼: "+okjaActs+"  (대화/선물 감정은 각 탭의 선택지에서 편집)"),
  ]);
  const emoRow = (label, key) => el("div", {style:"margin-bottom:12px"}, [
    el("div", {class:"field-label"}, label),
    emotionPicker(sprite, em[key], v=>{ em[key]=v; markDirty(); }),
  ]);
  mainCard.append(emoRow("체키 버튼 → 표정", "cheki"));
  mainCard.append(emoRow("음료 버튼 → 표정 (제조 연출)", "drink"));
  mainCard.append(el("div", {style:"margin-bottom:12px"}, [
    el("div", {class:"field-label"}, "터치 → 무작위 표정 풀 (여러 개 토글, 최소 1)"),
    emotionMulti(sprite, em.touch),
  ]));
  mainCard.append(emoRow("터치 상한 도달 → 표정", "touch_cap"));
  main.append(mainCard);

  // ── 펫 4버튼(시온이·규종이…) — actions 전용(label·emotion·ticker), id·호감도종류 잠금 ──
  const pSel = charSelector(META.characters.pets, activePet, k=>{ activePet=k; render(); });
  if (pSel) main.append(pSel);
  const pc = (META.characters.pets||[]).find(c=>c.dialogue===activePet) || {};
  const pbk = pc.buttons || "sion";
  const psprite = petSprite();
  if (!b[pbk]) b[pbk] = {};
  const petActs = b[pbk].actions || (b[pbk].actions = []);
  const petCard = el("div", {class:"card"}, [
    el("h3", {}, [(pc.name||"펫")+" 4버튼", el("span",{class:"lock"},"id·호감도종류 잠금")]),
  ]);
  const petTickerKeys = Object.keys(DB.ticker[activePet]||{}).filter(k=>!k.startsWith("_"));
  for (const a of petActs) {
    const labelI = el("input", {type:"text", value:a.label||""});
    labelI.addEventListener("input", ()=>{ a.label=labelI.value; markDirty(); });
    const tickerS = el("select", {});
    for (const k of petTickerKeys) tickerS.append(el("option", {value:k, ...(k===a.ticker?{selected:"selected"}:{})}, k));
    tickerS.addEventListener("change", ()=>{ a.ticker=tickerS.value; markDirty(); });
    petCard.append(el("div", {class:"choice"}, [
      el("div", {class:"row"}, [
        el("span", {class:"badge"}, "id: "+a.id),
        el("span", {class:"badge"}, "호감도: "+a.affinity),
      ]),
      el("div", {class:"grid", style:"margin-top:6px"}, [
        el("div", {}, [el("div",{class:"field-label"},"버튼 라벨"), labelI]),
        el("div", {}, [el("div",{class:"field-label"},"티커 풀"), tickerS]),
      ]),
      el("div", {class:"field-label", style:"margin-top:6px"}, "누르면 → 펫 표정"),
      emotionPicker(psprite, a.emotion, v=>{ a.emotion=v; markDirty(); }, META.sioniExpr),
    ]));
  }
  main.append(petCard);
}

// ── 탭: 밸런스 (호감도 수치) ──
// 숫자 한 줄(라벨 + 정수 입력). obj[key] 를 직접 갱신.
function numRow(label, obj, key, hint) {
  const input = el("input", {type:"number", value:(obj[key]??0), min:"0", style:"width:96px;flex:0 0 auto"});
  input.addEventListener("input", () => {
    const v = parseInt(input.value, 10);
    obj[key] = Number.isFinite(v) ? v : 0;
    markDirty();
  });
  return el("div", {class:"row", style:"align-items:center; gap:10px"}, [
    el("div", {style:"flex:1"}, [
      el("div", {style:"font-size:13px;color:var(--ink)"}, label),
      hint ? el("div", {class:"hint", style:"margin-top:0"}, hint) : null,
    ]),
    input,
  ]);
}

function renderBalance() {
  const main = document.getElementById("main");
  const bal = DB.balance || {};
  const aff = bal.affinity;
  if (!aff) { main.append(el("div", {class:"err-list"}, "balance.json 에 affinity 가 없습니다.")); return; }

  main.append(el("div", {class:"card"}, [
    el("h3", {}, ["💬 대화 — tier별 호감도", el("span", {class:"lock"}, "talk")]),
    numRow("좋은 선택 (good ↑↑)", aff.talk, "good"),
    numRow("평범한 선택 (plain ↑)", aff.talk, "plain"),
  ]));

  main.append(el("div", {class:"card"}, [
    el("h3", {}, ["🎁 선물 — tier별 호감도", el("span", {class:"lock"}, "gift")]),
    numRow("맞음 (match ↑↑)", aff.gift, "match"),
    numRow("시온이 간식 (sion ↑↑↑)", aff.gift, "sion"),
    numRow("보통 (plain ↑)", aff.gift, "plain"),
  ]));

  main.append(el("div", {class:"card"}, [
    el("h3", {}, ["🍷🃏👆🐱 액션별 고정 호감도", el("span", {class:"lock"}, "action")]),
    numRow("🍷 음료 주문 (drink)", aff, "drink"),
    numRow("🍷 선호 음료 보너스 (drink_favorite)", aff, "drink_favorite", "※ 아직 게임 미연동(후속)"),
    numRow("🃏 체키 주문 (cheki)", aff, "cheki", "호감도만 — 체키 획득 아님"),
    numRow("👆 터치 1회 (touch)", aff, "touch"),
    numRow("👆 터치 세션 상한 (touch_session_cap)", aff, "touch_session_cap", "세션당 터치로 얻을 수 있는 총량"),
    numRow("🐱 시온이 교감 (sion)", aff, "sion", "간식/놀기/쓰담 각"),
    numRow("🐱 시온이 선호 간식 (sion_favorite)", aff, "sion_favorite", "※ 아직 게임 미연동(후속)"),
  ]));

  main.append(el("div", {class:"hint"},
    "단위는 누적 호감도 포인트. 관계 단계: 단골 200 · 편해진 사이(반말 전환) 600 · 마음 연 사이 2000 (코드 상수). " +
    "대화·선물 선택지는 tier 만 고르고(대화/선물 탭), 실제 수치는 여기서 한 곳에 모은다."));
}

// ── 사운드 (→ ADR 0004) ──
function playClip(file, pitch) {
  if (!file) { setStatus("무음 (바인딩 파일 없음)", ""); return; }
  const a = new Audio("/audio/" + file);
  a.playbackRate = pitch || 1.0;  // 게임 pitch_scale 과 동일하게 속도+음높이 변함
  a.play().catch(()=>setStatus("재생 실패: " + file, "err"));
}

function fileSelect(current, onChange, emptyLabel) {
  const s = el("select", {style:"flex:1; min-width:0"});
  s.append(el("option", {value:""}, emptyLabel || "(카테고리 기본음)"));
  for (const f of (META.audioFiles||[])) {
    const o = el("option", {value:f}, f);
    if (f === current) o.selected = true;
    s.append(o);
  }
  if (!current) s.value = "";
  s.addEventListener("change", ()=>{ onChange(s.value); markDirty(); });
  return s;
}

function gainInput(obj, key) {
  const v = (obj[key] != null) ? obj[key] : 0;
  const i = el("input", {type:"number", value:v, step:"0.5", title:"볼륨(dB)", style:"width:64px;flex:0 0 auto"});
  i.addEventListener("input", ()=>{ const n=parseFloat(i.value); obj[key]= Number.isFinite(n)?n:0; markDirty(); });
  return el("div", {style:"flex:0 0 auto;display:flex;align-items:center;gap:3px"}, [i, el("span",{class:"hint"},"dB")]);
}

function soundRow(id, e, snd) {
  const muted = !!e.mute;
  const resolved = () => e.mute ? "" : (e.file || snd.defaults[e.cat] || "");
  const sel = fileSelect(e.file||"", v=>{ if (v) e.file=v; else delete e.file; });
  sel.disabled = muted;
  const pitch = el("input", {type:"number", value:(e.pitch!=null?e.pitch:1.0), step:"0.05", min:"0.1",
    title:"피치", style:"width:62px;flex:0 0 auto"});
  pitch.disabled = muted;
  pitch.addEventListener("input", ()=>{ const n=parseFloat(pitch.value); e.pitch= Number.isFinite(n)?n:1.0; markDirty(); });
  const play = el("button", {class:"x", title:"미리듣기", onclick:()=>playClip(resolved(), e.pitch||1.0)}, "▶");
  const muteBtn = el("button", {class:"x", title:"음소거 토글",
    style: muted?"color:var(--accent);border-color:var(--accent)":""}, muted?"🔇":"🔊");
  muteBtn.addEventListener("click", ()=>{ e.mute = !e.mute; if(!e.mute) delete e.mute; markDirty(); render(); });
  return el("div", {class:"row", style:"align-items:center;gap:8px"}, [
    el("div", {style:"flex:0 0 128px;font-size:13px"}, e.label||id),
    sel, pitch, play, muteBtn,
  ]);
}

function renderSound() {
  const main = document.getElementById("main");
  const snd = DB.sound || {};
  if (!snd.events) { main.append(el("div",{class:"err-list"},"sound.json 에 events 가 없습니다.")); return; }
  snd.defaults = snd.defaults || {}; snd.gain = snd.gain || {};

  main.append(el("div", {class:"hint", style:"margin-bottom:12px"},
    "이벤트 키·카테고리는 코드 소유(추가/삭제 불가) — 파일·피치·음소거·기본음·볼륨만 조정한다. " +
    "파일을 '(카테고리 기본음)' 으로 두면 그 카테고리 기본 소리가 난다(무음 방지). ▶ 로 들어보며 튜닝."));

  const defCard = el("div", {class:"card"}, [ el("h3", {}, ["🔧 카테고리 기본음 · 볼륨", el("span",{class:"lock"},"defaults")]) ]);
  for (const cat of (META.soundCats||[])) {
    defCard.append(el("div", {class:"row", style:"align-items:center;gap:8px"}, [
      el("div", {style:"flex:0 0 128px;font-size:13px"}, SOUND_CAT_LABEL[cat]||cat),
      fileSelect(snd.defaults[cat]||"", v=>{ snd.defaults[cat]= v||null; }, "(없음=무음)"),
      gainInput(snd.gain, cat),
      el("button", {class:"x", title:"미리듣기", onclick:()=>playClip(snd.defaults[cat], 1.0)}, "▶"),
    ]));
  }
  main.append(defCard);

  for (const cat of (META.soundCats||[])) {
    const ids = Object.keys(snd.events).filter(id=>!id.startsWith("_") && snd.events[id].cat===cat);
    if (!ids.length) continue;
    const card = el("div", {class:"card"}, [ el("h3", {}, [(SOUND_CAT_LABEL[cat]||cat)+" — 이벤트", el("span",{class:"lock"}, cat)]) ]);
    for (const id of ids) card.append(soundRow(id, snd.events[id], snd));
    main.append(card);
  }
}

// ── 탭 전환/렌더 ──
const RENDER = { ticker:renderMainTicker, pet:renderPetTicker, talk:renderTalk, gifts:renderGifts, buttons:renderButtons, balance:renderBalance, sound:renderSound };
function render() {
  document.getElementById("main").innerHTML = "";
  RENDER[activeTab]();
}
function renderTabs() {
  const t = document.getElementById("tabs");
  t.innerHTML = "";
  for (const [id, label] of TABS) {
    t.append(el("div", {class:"tab"+(id===activeTab?" active":""), onclick:()=>{ activeTab=id; renderTabs(); render(); }}, label));
  }
}

// ── 로드/저장 ──
async function load() {
  setStatus("불러오는 중…","");
  const r = await fetch("/api/data");
  const p = await r.json();
  DB = p.db; META = p.meta; dirty = false;
  // 캐릭터 기본 선택(레지스트리 첫 메인·첫 펫) — characters.gd 삽입 순서.
  const mains = (META.characters||{}).mains||[], pets = (META.characters||{}).pets||[];
  if (mains.length && !mains.some(c=>c.dialogue===activeMain)) activeMain = mains[0].dialogue;
  if (pets.length && !pets.some(c=>c.dialogue===activePet)) activePet = pets[0].dialogue;
  setStatus("불러옴 ✓","ok");
  renderTabs(); render();
}
async function save() {
  setStatus("저장 중…","");
  const r = await fetch("/api/save", {method:"POST", headers:{"Content-Type":"application/json"},
    body: JSON.stringify(DB)});
  const p = await r.json();
  if (p.ok) { dirty=false; setStatus("저장됨 ✓ (에디터 F5 로 확인)","ok"); }
  else {
    setStatus("검증 실패 — 저장 안 됨","err");
    const old = document.querySelector(".err-list"); if (old) old.remove();
    document.getElementById("main").prepend(el("div", {class:"err-list"}, "⚠ 저장 차단:\n• "+(p.errors||[]).join("\n• ")));
  }
}
document.getElementById("save").addEventListener("click", save);
document.getElementById("reload").addEventListener("click", ()=>{
  if (dirty && !confirm("저장하지 않은 변경이 사라집니다. 새로고침할까요?")) return;
  load();
});
document.getElementById("nick").addEventListener("input", render);
window.addEventListener("beforeunload", e=>{ if (dirty){ e.preventDefault(); e.returnValue=""; } });
load();
</script>
</body>
</html>
"""


def main():
    ap = argparse.ArgumentParser(description="나라쿠치 콘텐츠 스튜디오")
    ap.add_argument("--port", type=int, default=8800)
    ap.add_argument("--no-browser", action="store_true")
    args = ap.parse_args()

    # 데이터 파일 존재 확인(친절한 에러)
    for fname in FILES.values():
        path = os.path.join(DATA_DIR, fname)
        if not os.path.isfile(path):
            raise SystemExit(f"[오류] 데이터 파일 없음: {path}\n  먼저 리팩터링(JSON 이전)을 끝내세요.")

    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    url = f"http://127.0.0.1:{args.port}/"
    print(f"나라쿠치 콘텐츠 스튜디오 → {url}")
    print("  편집 → 저장 → Godot 에디터 F5 로 반영 확인. (Ctrl+C 종료)")
    if not args.no_browser:
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n종료.")


if __name__ == "__main__":
    main()
