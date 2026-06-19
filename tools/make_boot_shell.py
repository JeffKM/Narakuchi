#!/usr/bin/env python3
"""부트 로더 셸 생성 — Godot 기본 회색 로고 부트 화면을 시온이 진행반응 로더로 교체한다.

웹 빌드(62MB wasm+pck) 다운로드 동안 보이는 HTML 부트 화면을 브랜드 로더로 바꾼다.
시온이가 진행도에 따라 자다가 → 공손히 기다림 → 앞발 들고 신남 으로 변하고,
진짜 % 도트 바가 실측 다운로드 진행을 보여준다. 인게임 스플래시(지옥문 열림)가 페이로프.

핵심 설계(→ docs/adr/0001):
  - custom_html_shell 템플릿. Godot 가 $GODOT_* 토큰을 치환한다 → 토큰은 그대로 보존.
  - $GODOT_HEAD_INCLUDE 자리 유지 = 오디오 언락 + apple splash 보존(웹 무음 재발 방지).
  - 자산(시온이 3포즈 PNG + 나라쿠치 워드마크 + 갈무리 서브셋 woff2)은 전부 base64 인라인
    → 추가 네트워크 요청 0, 즉시 표시, export 복사 걱정 0.
  - 갈무리는 5.3MB 통째 금지. 로더에 쓰는 글자만 서브셋해 ~수KB woff2 로.

산출:
  - web/index_shell.html  (커밋 대상. export_presets html/custom_html_shell 이 가리킨다)

사용:
  tools/.venv/bin/python tools/make_boot_shell.py
  (의존성: fonttools, brotli — woff2 서브셋용)
"""
import base64
import io
import os

from fontTools.subset import Options, Subsetter
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
GALMURI = os.path.join(ROOT, "assets", "fonts", "Galmuri11.ttf")
OUT = os.path.join(ROOT, "web", "index_shell.html")

# 로더에 실제로 찍히는 글자만 서브셋(카피 + 숫자 + % + 말줄임표 + 공백).
SUBSET_TEXT = "시온이가게문을여는중…0123456789% "

# 진행 단계 임계(JS 와 공유) — 표시 %가 이 값을 넘을 때 시온이 포즈가 바뀐다.
STAGE_T1 = 0.40  # ~여기까지 자다가
STAGE_T2 = 0.80  # ~여기까지 공손히 기다림 → 이후 앞발 들고 신남


def _b64_file(path: str) -> str:
  with open(path, "rb") as f:
    return base64.b64encode(f.read()).decode("ascii")


def _galmuri_subset_woff2_b64() -> str:
  """갈무리11 을 SUBSET_TEXT 글자만 남겨 woff2 로 서브셋 → base64."""
  opt = Options()
  opt.flavor = "woff2"
  opt.desubroutinize = True
  opt.ignore_missing_glyphs = True
  opt.name_IDs = []  # 이름 테이블 비워 더 가볍게
  font = TTFont(GALMURI)
  ss = Subsetter(options=opt)
  ss.populate(text=SUBSET_TEXT)
  ss.subset(font)
  font.flavor = "woff2"
  buf = io.BytesIO()
  font.save(buf)
  return base64.b64encode(buf.getvalue()).decode("ascii")


# HTML 템플릿. @@MARKER@@ 는 base64 로 치환, $GODOT_* 는 Godot 가 export 때 치환(보존).
TEMPLATE = """<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0">
	<title>$GODOT_PROJECT_NAME</title>
	<style>
@font-face {
	font-family: 'GalmuriBoot';
	src: url(data:font/woff2;base64,@@FONT@@) format('woff2');
	font-display: block;
}
html, body, #canvas { margin: 0; padding: 0; border: 0; }
body { background-color: #0d0b12; color: #e8e0ee; overflow: hidden; touch-action: none; }
#canvas { display: block; }
#canvas:focus { outline: none; }

#status {
	position: absolute; inset: 0;
	background-color: #0d0b12;
	display: flex; flex-direction: column;
	justify-content: center; align-items: center;
	z-index: 10;
}
#nk-loader {
	display: flex; flex-direction: column; align-items: center; gap: 18px;
	image-rendering: pixelated;
}
#nk-wordmark { width: 156px; height: auto; image-rendering: pixelated; }
#nk-sioni {
	width: 120px; height: 120px; image-rendering: pixelated;
	animation: nk-float 2.4s ease-in-out infinite;
	will-change: transform;
}
#nk-copy {
	font-family: 'GalmuriBoot', sans-serif; font-size: 13px;
	color: #c9b8d6; letter-spacing: .5px; margin-top: 2px;
}
#nk-bar {
	width: 156px; height: 10px;
	background-color: #241b2e; border: 2px solid #3a2c49;
	image-rendering: pixelated;
}
#nk-bar-fill {
	height: 100%; width: 0%;
	background-image: repeating-linear-gradient(90deg,
		#c4528a 0, #c4528a 8px, #8e2f60 8px, #8e2f60 10px);
}
#nk-pct { font-family: 'GalmuriBoot', monospace; font-size: 11px; color: #8a7a99; }

#status-notice {
	display: none;
	background-color: #5b3943; border: 1px solid #9b3943; border-radius: .5rem;
	color: #e0e0e0; font-family: 'GalmuriBoot', sans-serif;
	margin: 0 2rem; padding: 1rem; text-align: center; line-height: 1.3;
}

@keyframes nk-float { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-7px); } }
@keyframes nk-wake {
	0% { transform: scale(1, .68); } 40% { transform: scale(.9, 1.12); }
	70% { transform: scale(1.04, .96); } 100% { transform: scale(1, 1); }
}
@keyframes nk-jump {
	0% { transform: translateY(0); } 30% { transform: translateY(-16px); }
	55% { transform: translateY(0); } 72% { transform: translateY(-6px); }
	100% { transform: translateY(0); }
}
.nk-wake { animation: nk-wake .5s ease-out !important; }
.nk-jump { animation: nk-jump .55s ease-out !important; }
	</style>
$GODOT_HEAD_INCLUDE
</head>
<body>
	<canvas id="canvas">
		HTML5 canvas appears to be unsupported in the current browser.<br >
		Please try updating or use a different browser.
	</canvas>
	<noscript>
		Your browser does not support JavaScript.
	</noscript>

	<div id="status">
		<div id="nk-loader">
			<img id="nk-wordmark" src="data:image/png;base64,@@WORDMARK@@" alt="나라쿠치">
			<img id="nk-sioni" src="data:image/png;base64,@@SIONI_SLEEP@@" alt="">
			<div id="nk-copy">시온이가 가게 문을 여는 중…</div>
			<div id="nk-bar"><div id="nk-bar-fill"></div></div>
			<div id="nk-pct">0%</div>
		</div>
		<div id="status-notice"></div>
	</div>

	<script src="$GODOT_URL"></script>
	<script>
const GODOT_CONFIG = $GODOT_CONFIG;
const GODOT_THREADS_ENABLED = $GODOT_THREADS_ENABLED;
const engine = new Engine(GODOT_CONFIG);

(function () {
	// ── 시온이 진행반응 로더 ────────────────────────────────
	const overlay = document.getElementById('status');
	const notice = document.getElementById('status-notice');
	const loaderEl = document.getElementById('nk-loader');
	const sioni = document.getElementById('nk-sioni');
	const barFill = document.getElementById('nk-bar-fill');
	const pctEl = document.getElementById('nk-pct');

	// 단계별 시온이 포즈(base64 인라인). 0:자다가 1:공손히 기다림 2:앞발 들고 신남.
	const POSE = [
		'data:image/png;base64,@@SIONI_SLEEP@@',
		'data:image/png;base64,@@SIONI_IDLE@@',
		'data:image/png;base64,@@SIONI_PLAY@@',
	];
	const T1 = @@STAGE_T1@@, T2 = @@STAGE_T2@@;  // 단계 임계(make_boot_shell.py 단일 출처)
	const MIN_MS = 600;   // 최소 표시(캐시 즉시로드에서도 3단계가 보이게)
	const FADE_MS = 300;  // 페이드아웃 → 인게임 스플래시로 이음새 없이

	let initializing = true;
	let target = 0;     // 실측 다운로드 진행 0..1
	let shown = 0;      // 화면 표시 진행 0..1 (실측을 ease 로 추적)
	let booted = false; // startGame 완료
	let stage = -1;
	let finished = false;
	let startTs = null;

	function setStage(s) {
		if (s === stage) return;
		const prev = stage;
		stage = s;
		sioni.src = POSE[s];
		// 전환 비트: 자다가→기다림은 기지개(wake), 그 외(→신남)는 점프.
		sioni.classList.remove('nk-wake', 'nk-jump');
		void sioni.offsetWidth;  // reflow 강제 → 애니 재시작
		if (prev !== -1) {
			sioni.classList.add(s === 1 ? 'nk-wake' : 'nk-jump');
		}
	}
	// 전환 비트가 끝나면 클래스를 떼 둥실(nk-float) 로 복귀.
	sioni.addEventListener('animationend', function () {
		sioni.classList.remove('nk-wake', 'nk-jump');
	});

	function tick(ts) {
		if (startTs === null) startTs = ts;
		const goal = booted ? 1 : target;
		shown += (goal - shown) * 0.10;       // 부드러운 추적
		if (goal - shown < 0.004) shown = goal;
		const pc = Math.max(0, Math.min(1, shown));
		setStage(pc < T1 ? 0 : pc < T2 ? 1 : 2);
		barFill.style.width = (pc * 100).toFixed(1) + '%';
		pctEl.textContent = Math.round(pc * 100) + '%';
		if (booted && shown >= 0.999 && (ts - startTs) >= MIN_MS) { finish(); return; }
		requestAnimationFrame(tick);
	}

	function finish() {
		if (finished || !initializing) return;
		finished = true;
		overlay.style.transition = 'opacity ' + FADE_MS + 'ms ease';
		overlay.style.opacity = '0';
		setTimeout(function () { overlay.remove(); initializing = false; }, FADE_MS);
	}

	function displayFailureNotice(err) {
		console.error(err);
		const msg = (err instanceof Error) ? err.message
			: (typeof err === 'string') ? err : 'An unknown error occurred.';
		if (loaderEl) loaderEl.style.display = 'none';
		while (notice.lastChild) notice.removeChild(notice.lastChild);
		msg.split('\\n').forEach(function (line) {
			notice.appendChild(document.createTextNode(line));
			notice.appendChild(document.createElement('br'));
		});
		notice.style.display = 'block';
		overlay.style.visibility = 'visible';
		initializing = false;
	}

	const missing = Engine.getMissingFeatures({ threads: GODOT_THREADS_ENABLED });

	if (missing.length !== 0) {
		if (GODOT_CONFIG['serviceWorker'] && GODOT_CONFIG['ensureCrossOriginIsolationHeaders'] && 'serviceWorker' in navigator) {
			let swReg;
			try {
				swReg = navigator.serviceWorker.getRegistration();
			} catch (err) {
				swReg = Promise.reject(new Error('Service worker registration failed.'));
			}
			// 서비스워커 설치로 해결될 여지 → 설치 후 새로고침.
			Promise.race([
				swReg.then((registration) => {
					if (registration != null) {
						return Promise.reject(new Error('Service worker already exists.'));
					}
					return registration;
				}).then(() => engine.installServiceWorker()),
				new Promise((resolve) => { setTimeout(() => resolve(), 2000); }),
			]).then(() => {
				window.location.reload();
			}).catch((err) => {
				console.error('Error while registering service worker:', err);
			});
		} else {
			const missingMsg = 'Error\\nThe following features required to run Godot projects on the Web are missing:\\n';
			displayFailureNotice(missingMsg + missing.join('\\n'));
		}
	} else {
		overlay.style.visibility = 'visible';
		requestAnimationFrame(tick);
		engine.startGame({
			'onProgress': function (current, total) {
				if (current > 0 && total > 0) target = current / total;
			},
		}).then(function () { booted = true; }, displayFailureNotice);
	}
}());
	</script>
</body>
</html>
"""


def main() -> None:
  os.makedirs(os.path.dirname(OUT), exist_ok=True)
  html = (TEMPLATE
          .replace("@@FONT@@", _galmuri_subset_woff2_b64())
          .replace("@@WORDMARK@@", _b64_file(os.path.join(SPR, "wordmark_naraka.png")))
          .replace("@@SIONI_SLEEP@@", _b64_file(os.path.join(SPR, "sioni_sleep.png")))
          .replace("@@SIONI_IDLE@@", _b64_file(os.path.join(SPR, "sioni_idle.png")))
          .replace("@@SIONI_PLAY@@", _b64_file(os.path.join(SPR, "sioni_play.png")))
          .replace("@@STAGE_T1@@", str(STAGE_T1))
          .replace("@@STAGE_T2@@", str(STAGE_T2)))
  with open(OUT, "w", encoding="utf-8") as f:
    f.write(html)
  kb = len(html.encode("utf-8")) / 1024
  print("✅ 부트 로더 셸: %s (%.1f KB)" % (os.path.relpath(OUT, ROOT), kb))
  print("   export_presets html/custom_html_shell=\"res://web/index_shell.html\" 확인 필요")


if __name__ == "__main__":
  main()
