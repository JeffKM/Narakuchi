#!/usr/bin/env python3
"""나라카찌 도트 스튜디오 — dotify 파이프라인을 브라우저 GUI로 다루는 로컬 툴.

pixelartvillage 스타일의 인터랙티브 워크플로:
  이미지 드롭 → 프리셋/크로마키/임계값 슬라이더 조정 → 실시간 nearest 미리보기
  → 규격 검수 리포트 확인 → assets/ 로 바로 저장.

규격 로직은 전부 dotify.dotify_image() 한 곳에서 재사용한다(단일 소스).
추가 의존성 없음 — 파이썬 표준 라이브러리 http.server + pillow/numpy(이미 설치됨).

실행:
  tools/.venv/bin/python tools/dot_studio.py          # 브라우저 자동 오픈
  tools/.venv/bin/python tools/dot_studio.py --port 8800 --no-browser
"""
import argparse
import base64
import io
import json
import os
import shutil
import subprocess
import sys
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import numpy as np
from PIL import Image

import dotify  # 같은 폴더의 파이프라인 모듈

ROOT = dotify.ROOT  # 프로젝트 루트 (저장 경로 가드용)
HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(HERE, "asset_manifest.json")  # 체크리스트 → 생산 슬롯 정의
PAL_DIR = os.path.join(ROOT, "assets", "palettes")
PALETTE_GPL = os.path.join(PAL_DIR, "narakatchi.gpl")
PALETTE_STRIP = os.path.join(PAL_DIR, "narakatchi_strip.png")
PALETTE_GRID = os.path.join(PAL_DIR, "narakatchi_grid.png")
GRID_COLS, GRID_CELL = 8, 48  # 미리보기 grid: 8열 · 48px 셀(행우선)


def load_palette_hexes():
  """팔레트 .hex를 '#rrggbb' 리스트로 (스와치 표시용)."""
  with open(dotify.PALETTE_HEX) as f:
    return ["#" + ln.strip().lstrip("#") for ln in f if ln.strip()]


def data_url_to_image(data_url):
  """'data:image/png;base64,....' → PIL Image."""
  _, b64 = data_url.split(",", 1)
  return Image.open(io.BytesIO(base64.b64decode(b64)))


def image_to_data_url(im):
  """PIL Image → PNG data URL."""
  buf = io.BytesIO()
  im.save(buf, "PNG")
  return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def hex_to_rgb(s):
  s = s.lstrip("#")
  return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def parse_palette(hexes):
  """['#rrggbb', ...] → (N,3) float 배열. 빈/None이면 None(파일 팔레트 사용)."""
  if not hexes:
    return None
  return np.array([hex_to_rgb(h) for h in hexes], dtype=np.float32)


def existing_gpl_names():
  """현재 .gpl에서 'rrggbb' → 이름 매핑(저장 시 이름 보존용)."""
  names = {}
  if not os.path.exists(PALETTE_GPL):
    return names
  with open(PALETTE_GPL) as f:
    for ln in f:
      parts = ln.split()
      if len(parts) >= 3 and parts[0].isdigit():
        r, g, b = (int(parts[i]) for i in range(3))
        name = parts[3] if len(parts) > 3 else ""
        names["%02x%02x%02x" % (r, g, b)] = name
  return names


def regen_palette_images(rgbs):
  """편집한 팔레트로 미리보기 PNG(strip·grid) 재생성. rgbs=[(r,g,b), ...]."""
  n = len(rgbs)
  # strip: 색당 1px 열 (N×1)
  strip = np.array(rgbs, dtype=np.uint8).reshape(1, n, 3)
  Image.fromarray(strip, "RGB").save(PALETTE_STRIP)
  # grid: 8열 · 48px 셀 · 행우선, 남는 셀은 INK(첫 색)로 채움
  rows = (n + GRID_COLS - 1) // GRID_COLS
  grid = np.empty((rows, GRID_COLS, 3), dtype=np.uint8)
  grid[:] = rgbs[0]
  for i, c in enumerate(rgbs):
    grid[i // GRID_COLS, i % GRID_COLS] = c
  big = np.repeat(np.repeat(grid, GRID_CELL, axis=0), GRID_CELL, axis=1)
  Image.fromarray(big, "RGB").save(PALETTE_GRID)


def save_palette(hexes):
  """편집한 팔레트를 .hex(파이프라인 원본) + .gpl(이름 보존) + 미리보기 PNG로 동시 저장."""
  clean = [h.lstrip("#").lower() for h in hexes if h.strip()]
  if not clean:
    raise ValueError("팔레트가 비어 있습니다.")
  rgbs = [hex_to_rgb(h) for h in clean]
  with open(dotify.PALETTE_HEX, "w") as f:
    f.write("\n".join(clean) + "\n")

  names = existing_gpl_names()
  lines = ["GIMP Palette", "Name: Narakatchi Master 32", "Columns: 8", "#"]
  for i, h in enumerate(clean):
    r, g, b = rgbs[i]
    name = names.get(h) or f"COLOR_{i + 1:02d}"  # 색 동일 시 기존 이름 보존
    lines.append(f"{r:3d} {g:3d} {b:3d}\t{name}")
  with open(PALETTE_GPL, "w") as f:
    f.write("\n".join(lines) + "\n")

  regen_palette_images(rgbs)
  return len(clean)


def thumb_data_url(path, box=44):
  """완성 에셋 썸네일(nearest 축소) data URL — 체크리스트 슬롯 미리보기용."""
  im = Image.open(path).convert("RGBA")
  w, h = im.size
  s = min(box / w, box / h, 1.0)
  if s < 1.0:
    im = im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.NEAREST)
  return image_to_data_url(im)


def assets_status():
  """매니페스트 + 각 슬롯의 규격 표기·완료 여부·썸네일을 합쳐 반환."""
  with open(MANIFEST, encoding="utf-8") as f:
    m = json.load(f)
  for g in m["groups"]:
    for it in g["items"]:
      if it.get("tool"):
        # GUI 파이프라인 비대상 — 전용 툴로 생성하는 에셋(예: 셸 = prep_shell.py)
        w, h = it["size"]
        it["spec"] = f"{it['tool']} · {w}×{h}"
      elif it.get("preset"):
        w, h, _, _ = dotify.PRESETS[it["preset"]]
        it["spec"] = f"{it['preset']} · {w}×{h}"
      else:
        w, h = it["size"]
        it["spec"] = f"{w}×{h}"
      full = os.path.join(ROOT, it["path"])
      it["exists"] = os.path.exists(full)
      it["thumb"] = thumb_data_url(full) if it["exists"] else None
  return m


def resolve_spec(params):
  """요청 파라미터 → (폭, 높이, 투명, lcd). 프리셋 또는 커스텀 사이즈."""
  preset = params.get("preset")
  if preset and preset != "custom":
    return dotify.PRESETS[preset]
  w = int(params.get("width", 120))
  h = int(params.get("height", 180))
  return w, h, bool(params.get("transparent", True)), None


def process(params):
  """업로드 이미지를 규격 도트로 변환 + 검수. {result, dims, audit} 반환."""
  im = data_url_to_image(params["image"])
  tw, th, transparent, lcd = resolve_spec(params)

  chroma = None
  if params.get("chroma_on"):
    chroma = hex_to_rgb(params.get("chroma", "#00ff00"))
  alpha_thr = int(params.get("alpha_thr", 128))
  chroma_tol = int(params.get("chroma_tol", 48))
  apply_palette = bool(params.get("apply_palette", True))
  pal = parse_palette(params.get("palette"))  # 스튜디오에서 편집한 팔레트(없으면 파일)

  out = dotify.dotify_image(
    im, tw, th, transparent or chroma is not None, lcd,
    alpha_thr=alpha_thr, chroma=chroma, chroma_tol=chroma_tol,
    apply_palette=apply_palette, palette=pal,
  )
  ok, lines = dotify.audit(out, tw, th, pal if pal is not None else dotify.load_palette(), lcd)
  return {
    "result": image_to_data_url(out),
    "dims": [tw, th],
    "audit": {"ok": ok, "lines": [ln.strip() for ln in lines]},
    "_image": out,  # /save 재사용용 (HTTP 응답에서는 핸들러가 제거)
  }


# GUI에서 직접 실행을 허용하는 전용 생성 툴(화이트리스트) — 임의 명령 실행 차단
TOOL_SCRIPTS = {
  "prep_shell.py": os.path.join(HERE, "prep_shell.py"),
}
# prep_shell.py 가 변환하는 셸 레퍼런스(원본) — GUI에 올린 이미지를 여기에 채택한다
SHELL_REF = os.path.join(ROOT, "assets", "sprites", "_src", "damagochi_frame.png")


def run_tool(name, image=None):
  """전용 생성 툴(셸 = prep_shell.py)을 서브프로세스로 돌려 에셋을 만든다.

  dotify 파이프라인으로는 못 만드는 에셋(흰 배경 누끼·LCD 정밀 펀칭)을 GUI에서
  한 번에 생성하는 통로. `image`(data URL)가 오면 **그 이미지를 셸 레퍼런스(_src)로
  채택**한 뒤 변환한다 — GUI에 올린 이미지가 그대로 셸 소스가 된다(이전 레퍼런스는
  `.prev.png`로 백업). 없으면 기존 _src 를 변환. 화이트리스트 밖 이름은 거부.

  ⚠️ prep_shell 계측값은 1760×2432 다마고치 레이아웃 기준 — 같은 구도·치수의
  레퍼런스를 넣어야 LCD 구멍·버튼이 정합한다.
  """
  script = TOOL_SCRIPTS.get(name)
  if not script:
    raise ValueError(f"허용되지 않은 툴: {name}")
  adopted = False
  if image:
    img = data_url_to_image(image)
    os.makedirs(os.path.dirname(SHELL_REF), exist_ok=True)
    if os.path.exists(SHELL_REF):
      shutil.copy2(SHELL_REF, SHELL_REF + ".prev.png")  # 직전 레퍼런스 롤링 백업
    img.save(SHELL_REF)
    adopted = True
  proc = subprocess.run(
    [sys.executable, script], capture_output=True, text=True, cwd=ROOT, timeout=120,
  )
  out = (proc.stdout or "") + (proc.stderr or "")
  if adopted:
    out = f"[올린 이미지를 셸 레퍼런스(_src)로 채택 · 직전본 .prev.png 백업]\n" + out
  return {"ok": proc.returncode == 0, "tool": name, "adopted_ref": adopted, "output": out.strip()}


def safe_save_path(rel):
  """프로젝트 루트 안쪽 .png 경로만 허용(경로 탈출 차단)."""
  rel = rel.strip().lstrip("/")
  if not rel.lower().endswith(".png"):
    rel += ".png"
  full = os.path.normpath(os.path.join(ROOT, rel))
  if not full.startswith(ROOT + os.sep):
    raise ValueError("프로젝트 폴더 밖에는 저장할 수 없습니다.")
  return full


class Handler(BaseHTTPRequestHandler):
  last_image = None  # 마지막 변환 결과(PIL) — /save 가 이걸 디스크에 씀

  def log_message(self, *a):  # 콘솔 잡음 억제
    pass

  def _json(self, obj, status=200):
    body = json.dumps(obj).encode()
    self.send_response(status)
    self.send_header("Content-Type", "application/json; charset=utf-8")
    self.send_header("Content-Length", str(len(body)))
    self.end_headers()
    self.wfile.write(body)

  def _read_json(self):
    n = int(self.headers.get("Content-Length", 0))
    return json.loads(self.rfile.read(n) or b"{}")

  def do_GET(self):
    if self.path == "/assets":
      self._json(assets_status())
      return
    if self.path not in ("/", "/index.html"):
      self._json({"error": "not found"}, 404)
      return
    html = PAGE.replace("__PALETTE__", json.dumps(load_palette_hexes()))
    body = html.encode("utf-8")
    self.send_response(200)
    self.send_header("Content-Type", "text/html; charset=utf-8")
    self.send_header("Content-Length", str(len(body)))
    self.end_headers()
    self.wfile.write(body)

  def do_POST(self):
    try:
      params = self._read_json()
      if self.path == "/process":
        out = process(params)
        Handler.last_image = out.pop("_image")
        self._json(out)
      elif self.path == "/save":
        if Handler.last_image is None:
          self._json({"error": "먼저 이미지를 변환하세요."}, 400)
          return
        path = safe_save_path(params.get("path", ""))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        Handler.last_image.save(path, "PNG")
        self._json({"ok": True, "path": os.path.relpath(path, ROOT)})
      elif self.path == "/save_palette":
        n = save_palette(params.get("palette", []))
        self._json({"ok": True, "count": n})
      elif self.path == "/run_tool":
        self._json(run_tool(params.get("tool", ""), params.get("image")))
      else:
        self._json({"error": "not found"}, 404)
    except Exception as e:  # GUI 단일 사용자 — 에러를 그대로 패널에 노출
      self._json({"error": f"{type(e).__name__}: {e}"}, 500)


# ── 프론트엔드(단일 HTML) ───────────────────────────────────────────────
PAGE = r"""<!DOCTYPE html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>나라카찌 도트 스튜디오</title>
<style>
  :root { --bg:#161420; --panel:#221d2e; --line:#3a2f4a; --txt:#f4f2f7; --muted:#9a96a3;
          --accent:#ff6fae; --ok:#3fd47a; --bad:#ff6f6f; }
  * { box-sizing:border-box; }
  body { margin:0; font:14px/1.5 -apple-system,'Apple SD Gothic Neo',sans-serif;
         background:var(--bg); color:var(--txt); }
  header { padding:12px 20px; border-bottom:1px solid var(--line); display:flex;
           align-items:baseline; gap:12px; }
  header h1 { font-size:16px; margin:0; }
  header span { color:var(--muted); font-size:12px; }
  .wrap { display:grid; grid-template-columns:258px 290px 1fr; height:calc(100vh - 51px); }
  .panel { padding:16px 20px; border-right:1px solid var(--line); overflow-y:auto; }
  /* 체크리스트 열 */
  .checklist-col { border-right:1px solid var(--line); overflow-y:auto; padding:14px 14px 30px; }
  .cl-head label { display:block; font-size:12px; color:var(--muted); text-transform:uppercase;
    letter-spacing:.5px; margin-bottom:6px; }
  .cl-head .prog { font-size:13px; } .cl-head .prog b { color:var(--accent); font-size:15px; }
  .bar { height:6px; background:var(--bg); border-radius:3px; overflow:hidden; margin-top:6px; }
  .bar i { display:block; height:100%; width:0; background:var(--accent); transition:width .3s; }
  .grp-title { font-size:11px; color:var(--muted); text-transform:uppercase; letter-spacing:.5px;
    margin:16px 0 6px; display:flex; justify-content:space-between; }
  .slot { display:flex; align-items:center; gap:8px; padding:5px 7px; border-radius:7px;
    cursor:pointer; border:1px solid transparent; }
  .slot:hover { background:var(--panel); }
  .slot.sel { border-color:var(--accent); background:var(--panel); }
  .slot .dot { width:13px; text-align:center; color:var(--muted); font-size:12px; flex:0 0 auto; }
  .slot.done .dot { color:var(--ok); }
  .slot .thumb { width:26px; height:26px; flex:0 0 auto; object-fit:contain;
    image-rendering:pixelated; border-radius:4px; }
  .slot .thumb.ph { border:1px dashed var(--line); box-sizing:border-box; }
  .slot-label { flex:1; min-width:0; font-size:12px; color:var(--muted);
    display:flex; flex-direction:column; line-height:1.25; }
  .slot.done .slot-label { color:var(--txt); }
  .slot-label small { color:var(--muted); opacity:.65; font-size:10px;
    overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .stage { padding:20px; display:flex; flex-direction:column; gap:16px; overflow-y:auto; }
  .grp { margin-bottom:18px; }
  .grp > label { display:block; font-size:12px; color:var(--muted); margin-bottom:6px;
                 text-transform:uppercase; letter-spacing:.5px; }
  select, input[type=text], input[type=number] { width:100%; background:var(--bg);
    color:var(--txt); border:1px solid var(--line); border-radius:6px; padding:7px 9px; }
  .row { display:flex; gap:8px; }
  .row > * { flex:1; }
  .chk { display:flex; align-items:center; gap:8px; cursor:pointer; }
  .chk input { width:auto; }
  input[type=range] { width:100%; accent-color:var(--accent); }
  .val { float:right; color:var(--accent); font-variant-numeric:tabular-nums; }
  #drop { border:2px dashed var(--line); border-radius:10px; padding:22px 12px;
          text-align:center; color:var(--muted); cursor:pointer; transition:.15s; }
  #drop.hot { border-color:var(--accent); color:var(--txt); }
  button { width:100%; background:var(--accent); color:#161420; border:0; font-weight:700;
           padding:10px; border-radius:8px; cursor:pointer; }
  button.ghost { background:transparent; color:var(--muted); border:1px solid var(--line);
                 font-weight:500; }
  .previews { display:flex; gap:24px; flex-wrap:wrap; align-items:flex-start; }
  .card { display:flex; flex-direction:column; gap:6px; }
  .card h3 { margin:0; font-size:12px; color:var(--muted); font-weight:500; }
  .checker { background:
      conic-gradient(#2b2733 25%, #221d2e 0 50%, #2b2733 0 75%, #221d2e 0) 0 0/16px 16px;
      border:1px solid var(--line); border-radius:6px; }
  .checker img { display:block; image-rendering:pixelated; }
  #audit { background:var(--panel); border:1px solid var(--line); border-radius:8px;
           padding:12px 14px; white-space:pre-wrap; font-family:ui-monospace,monospace;
           font-size:13px; max-width:520px; }
  #verdict { font-weight:700; margin-top:8px; }
  .ok { color:var(--ok); } .bad { color:var(--bad); }
  .swatches { display:grid; grid-template-columns:repeat(8,1fr); gap:4px; }
  .sw { position:relative; }
  .sw input[type=color] { width:100%; aspect-ratio:1; padding:0; border:1px solid var(--line);
    border-radius:4px; background:none; cursor:pointer; }
  .sw input[type=color]::-webkit-color-swatch-wrapper { padding:0; }
  .sw input[type=color]::-webkit-color-swatch { border:0; border-radius:3px; }
  .sw .rm { position:absolute; top:-5px; right:-5px; width:15px; height:15px; line-height:13px;
    padding:0; border-radius:50%; background:var(--bad); color:#fff; font-size:11px; border:0;
    cursor:pointer; opacity:0; transition:.1s; }
  .sw:hover .rm { opacity:1; }
  #msg, #palMsg { color:var(--muted); font-size:12px; min-height:16px; }
  .hidden { display:none; }
</style></head>
<body>
<header><h1>🎨 나라카찌 도트 스튜디오</h1>
  <span>규격은 dotify 파이프라인이 강제 · 결과는 assets/ 에 저장</span></header>
<div class="wrap">
  <div class="checklist-col">
    <div class="cl-head">
      <label>에셋 체크리스트</label>
      <div class="prog"><b id="progress">0 / 0</b> 완료</div>
      <div class="bar"><i id="progressBar"></i></div>
    </div>
    <div id="checklist"></div>
  </div>
  <div class="panel">
    <div class="grp">
      <label>1. 원본 이미지</label>
      <div id="drop">여기로 드래그<br>또는 클릭해서 선택</div>
      <input type="file" id="file" accept="image/*" class="hidden">
    </div>

    <div class="grp">
      <label>2. 규격 프리셋</label>
      <select id="preset">
        <option value="okja">okja — 옥자 스탠딩 128×288</option>
        <option value="sioni">sioni — 시온이 48×48</option>
        <option value="cheki" selected>cheki — 체키/프레임 아트 120×180</option>
        <option value="bg">bg — 배경 333×480 (불투명)</option>
        <option value="custom">custom — 직접 입력</option>
      </select>
      <div id="customSize" class="row hidden" style="margin-top:8px">
        <input type="number" id="width" value="120" min="1"> ×
        <input type="number" id="height" value="180" min="1">
      </div>
      <label class="chk hidden" id="customTrans" style="margin-top:8px">
        <input type="checkbox" id="transparent" checked> 투명 배경</label>
    </div>

    <div class="grp">
      <label>3. 크로마키 배경 제거</label>
      <label class="chk"><input type="checkbox" id="chroma_on"> 단색 배경 제거</label>
      <div id="chromaOpts" class="hidden" style="margin-top:8px">
        <div class="row" style="align-items:center">
          <input type="color" id="chroma" value="#00ff00" style="flex:0 0 40px;height:34px;padding:2px">
          <input type="text" id="chroma_hex" value="#00ff00">
        </div>
        <label style="margin-top:8px">허용 오차 <span class="val" id="ctolv">48</span>
          <input type="range" id="chroma_tol" min="0" max="160" value="48"></label>
      </div>
    </div>

    <div class="grp">
      <label>4. 미세 조정</label>
      <label>알파 임계값 <span class="val" id="athrv">128</span>
        <input type="range" id="alpha_thr" min="0" max="255" value="128"></label>
      <label class="chk" style="margin-top:8px">
        <input type="checkbox" id="apply_palette" checked> 32색 팔레트 적용</label>
      <label style="margin-top:10px">미리보기 배율 <span class="val" id="scalev">3×</span>
        <input type="range" id="scale" min="1" max="6" value="3"></label>
    </div>

    <div class="grp">
      <label>5. 저장</label>
      <input type="text" id="savePath" placeholder="assets/sprites/okja_idle.png">
      <button id="saveBtn" style="margin-top:8px">assets/ 에 저장</button>
      <button id="toolBtn" class="hidden" style="margin-top:8px">🛠 <span id="toolName"></span> 실행</button>
      <div id="msg" style="margin-top:6px"></div>
    </div>

    <div class="grp">
      <label>마스터 팔레트 <span id="palCount" style="color:var(--accent)"></span></label>
      <div class="swatches" id="swatches"></div>
      <div class="row" style="margin-top:8px">
        <button class="ghost" id="addColor">+ 색 추가</button>
        <button class="ghost" id="resetPal">되돌리기</button>
      </div>
      <button id="savePal" style="margin-top:6px">팔레트 저장 (.hex · .gpl)</button>
      <div id="palMsg" style="margin-top:6px"></div>
    </div>
  </div>

  <div class="stage">
    <div class="previews">
      <div class="card"><h3>원본</h3>
        <div class="checker"><img id="origImg" alt=""></div></div>
      <div class="card"><h3>결과 (nearest 확대)</h3>
        <div class="checker"><img id="outImg" alt=""></div></div>
    </div>
    <div>
      <h3 style="color:var(--muted);font-size:12px;margin:0 0 6px">검수 리포트</h3>
      <div id="audit">이미지를 올리면 검수 결과가 표시됩니다.</div>
      <div id="verdict"></div>
    </div>
  </div>
</div>

<script>
const PALETTE = __PALETTE__;
const $ = id => document.getElementById(id);
let origDataUrl = null, timer = null;
let palette = [...PALETTE];  // 편집 가능한 작업 팔레트
let manifest = null, selectedId = null;

// ── 에셋 체크리스트 ──────────────────────────────────────────────
async function loadAssets() {
  try {
    manifest = await (await fetch('/assets')).json();
    renderChecklist();
  } catch (e) { $('checklist').textContent = '⚠ 매니페스트 로드 실패: ' + e; }
}
function allItems() { return manifest.groups.flatMap(g => g.items); }
function findItem(id) { return allItems().find(i => i.id === id); }
function renderChecklist() {
  const items = allItems(), done = items.filter(i => i.exists).length;
  $('progress').textContent = `${done} / ${items.length}`;
  $('progressBar').style.width = (items.length ? done / items.length * 100 : 0) + '%';
  $('checklist').innerHTML = manifest.groups.map(g => {
    const gd = g.items.filter(i => i.exists).length;
    return `<div class="grp-title"><span>${g.title}</span><span>${gd}/${g.items.length}</span></div>` +
      g.items.map(i => `
        <div class="slot ${i.exists ? 'done' : ''} ${i.id === selectedId ? 'sel' : ''}" data-id="${i.id}">
          <span class="dot">${i.exists ? '✓' : '▢'}</span>
          ${i.thumb ? `<img class="thumb" src="${i.thumb}">` : '<span class="thumb ph"></span>'}
          <span class="slot-label">${i.label}<small>${i.spec}</small></span>
        </div>`).join('');
  }).join('');
  $('checklist').querySelectorAll('.slot').forEach(el =>
    el.onclick = () => selectSlot(el.dataset.id));
}
function selectSlot(id) {
  const it = findItem(id);
  if (!it) return;
  selectedId = id;
  if (it.preset) {
    $('preset').value = it.preset;
  } else {
    $('preset').value = 'custom';
    $('width').value = it.size[0]; $('height').value = it.size[1];
    $('transparent').checked = it.transparent !== false;
  }
  $('savePath').value = it.path;
  syncUI(); renderChecklist();
  render();
  // 전용 툴 슬롯(예: 셸 = prep_shell.py)은 dotify 변환·저장 대신 툴 실행 버튼을 노출
  if (it.tool) {
    $('saveBtn').classList.add('hidden');
    $('toolBtn').classList.remove('hidden');
    $('toolName').textContent = it.tool;
    $('msg').innerHTML = `🛠 <b>${it.label}</b> — 이미지를 올리고 <code>${it.tool}</code> 실행을 누르면 <b>그 이미지를 셸 레퍼런스로 채택</b>해 변환합니다. (이미지 없이 누르면 기존 레퍼런스 변환 · 1760×2432 다마고치 구도 권장)`;
  } else {
    $('saveBtn').classList.remove('hidden');
    $('toolBtn').classList.add('hidden');
    $('msg').innerHTML = `🎯 <b>${it.label}</b> 선택 — 이미지를 올리고 저장하면 이 칸이 채워집니다.`;
  }
}

// 편집 가능한 팔레트 스와치
function renderSwatches() {
  $('palCount').textContent = `(${palette.length}색)`;
  $('swatches').innerHTML = palette.map((c, i) => `
    <div class="sw"><input type="color" value="${c}" data-i="${i}" title="${c}">
      <button class="rm" data-i="${i}" title="삭제">×</button></div>`).join('');
  $('swatches').querySelectorAll('input[type=color]').forEach(inp => {
    inp.oninput = () => { palette[+inp.dataset.i] = inp.value; inp.title = inp.value; render(); };
  });
  $('swatches').querySelectorAll('.rm').forEach(b => {
    b.onclick = () => { palette.splice(+b.dataset.i, 1); renderSwatches(); render(); };
  });
}
$('addColor').onclick = () => { palette.push('#ffffff'); renderSwatches(); render(); };
$('resetPal').onclick = () => { palette = [...PALETTE]; renderSwatches(); render();
  $('palMsg').textContent = '파일 팔레트로 되돌렸습니다(저장 전).'; };
$('savePal').onclick = async () => {
  $('palMsg').textContent = '저장 중…';
  const res = await fetch('/save_palette', { method:'POST',
    headers:{'Content-Type':'application/json'}, body: JSON.stringify({ palette }) });
  const d = await res.json();
  $('palMsg').innerHTML = d.error ? '⚠ ' + d.error
    : `<span class="ok">✅ 팔레트 저장됨 (${d.count}색) → .hex · .gpl</span>`;
};
renderSwatches();

// 파일 드롭/선택
const drop = $('drop'), file = $('file');
drop.onclick = () => file.click();
['dragover','dragenter'].forEach(e => drop.addEventListener(e, ev => { ev.preventDefault(); drop.classList.add('hot'); }));
['dragleave','drop'].forEach(e => drop.addEventListener(e, ev => { ev.preventDefault(); drop.classList.remove('hot'); }));
drop.addEventListener('drop', ev => loadFile(ev.dataTransfer.files[0]));
file.onchange = () => loadFile(file.files[0]);
function loadFile(f) {
  if (!f) return;
  const r = new FileReader();
  r.onload = () => { origDataUrl = r.result; $('origImg').src = origDataUrl;
    drop.innerHTML = f.name; render(); };
  r.readAsDataURL(f);
}

// 컨트롤 동기화
function syncUI() {
  $('customSize').classList.toggle('hidden', $('preset').value !== 'custom');
  $('customTrans').classList.toggle('hidden', $('preset').value !== 'custom');
  $('chromaOpts').classList.toggle('hidden', !$('chroma_on').checked);
  $('ctolv').textContent = $('chroma_tol').value;
  $('athrv').textContent = $('alpha_thr').value;
  $('scalev').textContent = $('scale').value + '×';
  $('outImg').style.width = '';
}
// 색상 ↔ hex 텍스트 동기화
$('chroma').oninput = () => { $('chroma_hex').value = $('chroma').value; render(); };
$('chroma_hex').oninput = () => { if (/^#?[0-9a-fA-F]{6}$/.test($('chroma_hex').value)) {
  $('chroma').value = $('chroma_hex').value.startsWith('#') ? $('chroma_hex').value : '#'+$('chroma_hex').value; render(); } };

['preset','width','height','transparent','chroma_on','chroma_tol','alpha_thr','apply_palette','scale']
  .forEach(id => $(id).addEventListener('input', () => { syncUI(); render(); }));

function params() {
  return {
    image: origDataUrl, preset: $('preset').value,
    width: +$('width').value, height: +$('height').value,
    transparent: $('transparent').checked,
    chroma_on: $('chroma_on').checked, chroma: $('chroma_hex').value,
    chroma_tol: +$('chroma_tol').value, alpha_thr: +$('alpha_thr').value,
    apply_palette: $('apply_palette').checked, palette: palette,
  };
}

// 디바운스 변환 요청
function render() {
  if (!origDataUrl) return;
  clearTimeout(timer);
  timer = setTimeout(async () => {
    try {
      const res = await fetch('/process', { method:'POST',
        headers:{'Content-Type':'application/json'}, body: JSON.stringify(params()) });
      const d = await res.json();
      if (d.error) { $('audit').textContent = '⚠ ' + d.error; return; }
      const out = $('outImg');
      out.onload = () => { out.style.width = (d.dims[0] * +$('scale').value) + 'px'; };
      out.src = d.result;
      $('audit').textContent = d.audit.lines.join('\n');
      const v = $('verdict');
      v.textContent = d.audit.ok ? '✅ 규격 통과 — 그대로 사용 가능'
                                 : '⚠️ 일부 항목 미달 — 조정하거나 수동 정리 필요';
      v.className = d.audit.ok ? 'ok' : 'bad';
    } catch (e) { $('audit').textContent = '⚠ ' + e; }
  }, 220);
}

// 저장
$('saveBtn').onclick = async () => {
  const path = $('savePath').value.trim();
  if (!path) { $('msg').textContent = '저장 경로를 입력하세요.'; return; }
  $('msg').textContent = '저장 중…';
  const res = await fetch('/save', { method:'POST',
    headers:{'Content-Type':'application/json'}, body: JSON.stringify({ path }) });
  const d = await res.json();
  if (d.error) { $('msg').innerHTML = '⚠ ' + d.error; return; }
  $('msg').innerHTML = '<span class="ok">✅ 저장됨 → ' + d.path + '</span>';
  loadAssets();  // 방금 채운 슬롯 상태/썸네일 갱신
};

// 전용 툴(prep_shell.py 등) 실행 — 서버가 서브프로세스로 돌려 에셋을 직접 생성
$('toolBtn').onclick = async () => {
  const it = findItem(selectedId);
  if (!it || !it.tool) return;
  $('toolBtn').disabled = true;
  // 올린 원본 이미지가 있으면 셸 레퍼런스로 채택해 변환(없으면 기존 _src 변환)
  const usingUpload = !!origDataUrl;
  $('msg').innerHTML = `🛠 <code>${it.tool}</code> 실행 중…` +
    (usingUpload ? ' (올린 이미지를 레퍼런스로 채택)' : ' (기존 레퍼런스 변환)');
  try {
    const res = await fetch('/run_tool', { method:'POST',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ tool: it.tool, image: origDataUrl || null }) });
    const d = await res.json();
    const log = d.output ? `<pre style="white-space:pre-wrap;margin:6px 0 0;font-size:11px;color:var(--muted)">${d.output.replace(/</g,'&lt;')}</pre>` : '';
    $('msg').innerHTML = (d.error || !d.ok)
      ? `⚠ ${d.error || d.tool + ' 실패'}` + log
      : `<span class="ok">✅ ${d.tool} 완료 → ${it.path}</span>` + log;
    if (d.ok) loadAssets();  // 생성된 슬롯 썸네일·완료 표시 갱신
  } finally { $('toolBtn').disabled = false; }
};

// 프리셋별 저장 경로 자동 제안
const SUGGEST = { okja:'assets/sprites/okja_idle.png', sioni:'assets/sprites/sioni_idle.png',
  cheki:'assets/sprites/cheki_art.png', bg:'assets/sprites/bg_naraka.png',
  custom:'assets/sprites/asset.png' };
$('preset').addEventListener('change', () => {
  $('savePath').value = SUGGEST[$('preset').value];
  $('saveBtn').classList.remove('hidden');  // 프리셋 수동 변경 = 일반 변환·저장 모드 복귀
  $('toolBtn').classList.add('hidden');
});
$('savePath').value = SUGGEST['cheki'];

syncUI();
loadAssets();
</script>
</body></html>"""


def main():
  ap = argparse.ArgumentParser(description="나라카찌 도트 스튜디오 (로컬 웹 GUI)")
  ap.add_argument("--port", type=int, default=8765)
  ap.add_argument("--no-browser", action="store_true", help="브라우저 자동 오픈 안 함")
  args = ap.parse_args()

  url = f"http://127.0.0.1:{args.port}/"
  srv = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
  print(f"🎨 도트 스튜디오 실행 중 → {url}")
  print("   종료: Ctrl+C")
  if not args.no_browser:
    threading.Timer(0.6, lambda: webbrowser.open(url)).start()
  try:
    srv.serve_forever()
  except KeyboardInterrupt:
    print("\n종료합니다.")
    srv.shutdown()


if __name__ == "__main__":
  main()
