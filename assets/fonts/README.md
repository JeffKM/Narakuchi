# 갈무리 폰트 설치 안내

나라카찌는 한글 도트 폰트 **갈무리(Galmuri)**를 사용한다 (→ ../../docs/adr/0001-dot-art-spec.md).

## 1) 내려받기

- 공식: https://galmuri.quiple.dev (또는 https://github.com/quiple/galmuri )
- **라이선스: SIL Open Font License 1.1** — 상업적 사용·임베드·배포 자유. (저작자: 길형진/quiple)

받아서 이 폴더(`assets/fonts/`)에 아래 파일을 넣는다:

```
assets/fonts/Galmuri11.ttf   (본문/타이틀 기본)
assets/fonts/Galmuri9.ttf    (작은 글씨, 선택)
```

> 파일명이 위와 정확히 같아야 `scripts/systems/fonts.gd`가 자동으로 잡는다. 다르면 `fonts.gd`의 경로 상수를 수정.

## 2) Godot 임포트 설정 (픽셀 크리스프)

`.ttf`를 넣으면 Godot이 자동 임포트한다. 도트가 또렷하려면 파일 선택 후 **Import 탭**에서:

- **Antialiasing: Disabled (None)**
- **Hinting: None**
- **Subpixel Positioning: Disabled**
- 적용 후 **Reimport**

> 코드(`fonts.gd`)에서도 런타임에 위 설정을 강제하지만, Import 탭에서도 맞춰두면 에디터 미리보기까지 또렷하다.

## 3) 크기 규칙

- 갈무리11은 **11px 네이티브**. 크기는 **11의 정수배(11·22·33)**로 쓰고, 프로젝트 전역 **Nearest 필터**(이미 설정됨)와 함께 써야 픽셀이 안 뭉갠다.
- 상수: `Fonts.SIZE_TITLE(22)` / `SIZE_BODY(11)` / `SIZE_SMALL(9)`.

## 적용 확인

폰트를 넣고 `scenes/Main.tscn`을 실행하면 타이틀이 영문 `NARAKATCHI` → 한글 **`나라카찌`**로 바뀐다. (폰트가 없으면 영문 폴백)
