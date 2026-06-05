# 나라쿠치 (Narakuchi)

나라카 컨셉(메이드)카페 팬게임. **Godot 4** 기반, 도트 그래픽의 가벼운 **데일리 교감 + 체키(포토카드) 수집** 게임.

매일 나라카에 들러 사장 **옥자**(지옥의 마녀)와 교감하며 친해지고, 이벤트 데이 의상의 **체키**를 모은다. 웹(HTML5/PWA) 모바일 세로.

## 실행

```bash
# Godot 4 에디터로 열기
godot project.godot
```

- 메인 씬: `scenes/Main.tscn` (현재 부트 플레이스홀더 — 270×480 확인용)
- 웹 빌드: 에디터에서 `Web` export preset 구성 후 `Project > Export`

## 문서

| 파일 | 내용 |
|---|---|
| [CLAUDE.md](./CLAUDE.md) | 개발 가이드 (엔진·구조·규칙) |
| [PRD.md](./PRD.md) | 게임 명세 + 수치 밸런스(§4.5) + 이벤트(§9.1) |
| [ROADMAP.md](./ROADMAP.md) | 1주 7일 개발 계획 |
| [CONTEXT.md](./CONTEXT.md) | 도메인 용어집 |
| [docs/script-okja.md](./docs/script-okja.md) | 옥자 대사 스크립트 |
| [docs/adr/](./docs/adr/) | 핵심 결정 기록 (도트 규격 · 체키 모델) |

## 폴더 구조

```
project.godot
scenes/        씬 (셸·온보딩·교감·컬렉션북·공유)
scripts/       GDScript
  systems/     호감도·스태미나·체키·저장·출석
data/          이벤트/체키/대사/밸런스 상수
assets/
  sprites/     옥자 표정·시온이·체키 카드·프레임·게임기 셸
  fonts/       갈무리
```
