# 무협 도트 오픈월드 — 1단계 프로토타입

Godot 4.7 / GDScript. `project.godot`을 Godot에서 열고 F5로 실행.

## 조작
| 동작 | 키보드 | 패드 |
|---|---|---|
| 8방향 이동 | WASD / 방향키 | 왼쪽 스틱 |
| 공격 (3타 콤보) | J / 마우스 왼쪽 | X |
| 경공 (대시, 내공 15) | K / Space / 마우스 오른쪽 | A |
| 운기조식 (가만히 유지: 내공·기혈 회복) | R | Y |
| 도움말 표시 | F1 | |

## 1단계에 들어간 것
- 480x270, 정수 배율, Nearest 필터, 픽셀 스냅
- 8방향 이동 · 방향 공격 · 3타 콤보 (3타째는 범위·넉백 큼) · 공격 후 경공 캔슬
- 경공 무적 시간 + 잔상, 피격 시 무적 깜빡임·넉백, 사망 후 재시작
- 내공: 적중 시 +6, 경공에 소모, 운기조식으로 회복
- 히트스톱 · 화면 흔들림 · 데미지 숫자
- 적 AI 1종(산적): 배회 → 추격 → 예비동작(!) → 베기 → 경직. 쓰러지면 3초 뒤 재등장
- 부드럽게 따라가는 카메라 (맵 경계 제한)

## 구조
```
scripts/
  input_setup.gd   입력 액션 등록 (autoload "Inputs")
  fx.gd            히트스톱/흔들림/데미지 숫자 (autoload "Fx")
  main.gd          테스트 맵 조립
  player.gd        주인공 상태머신
  enemy.gd         산적 AI
  dummy_body.gd    더미 도트 캐릭터 (32x32, 발끝 원점)
  shake_camera.gd  카메라
  ground.gd        임시 바닥 (2단계에서 TileMapLayer로 교체)
  obstacle.gd      나무/바위
  hud.gd           기혈/내공 바
```

## 5단계 에셋 교체 방법
`dummy_body.gd`를 AnimatedSprite2D 기반 노드로 바꾸고, 같은 속성(`facing`, `moving`,
`attack_t`, `flash`, `windup`)을 받아 `"{동작}_{방향}"` 애니메이션을 재생하면 된다.
방향 인덱스: 0=s 1=se 2=e 3=ne 4=n 5=nw 6=w 7=sw (`DIR_NAMES`).
파일명 규칙 `hero_walk_s_01.png` → 애니메이션 `walk_s`.

## 이펙트 (pixelfx)
- `tools/pixelfx/`: [patch-gg/pixelfx](https://github.com/patch-gg/pixelfx) (MIT) 체크아웃. `tools/.gdignore`로 Godot 임포트에서 제외.
- `assets/fx/`: 게임에서 쓰는 스프라이트 시트 (PNG + JSON)
- `scripts/pixel_fx.gd`: 시트를 읽어 한 번 재생하고 지우는 헬퍼 (`PixelFx.spawn(...)`, 가산 합성)

| 사용처 | 이펙트 | 렌더 옵션 |
|---|---|---|
| 1·2타 | `melee/sword-slash` (바라보는 방향으로 회전, 2타는 상하 반전) | 청백 팔레트, radius 24 |
| 3타 | `melee/spin-slash` | 청백 팔레트, radius 30 |
| 적중 | `impacts/hit-spark` (맞은 방향으로 좌우 반전) | height 12 |

다시 뽑기 (tools/pixelfx 에서):
```
node tools/render.mjs melee/sword-slash --sheet --no-actor --opts '{"palette":["#0c1430","#162c5c","#1f4f94","#2f7fcc","#58b4ec","#9bdcff","#d8f4ff","#ffffff"],"radius":24}' --out ../../assets/fx
```
내보내기(export) 시 Export 설정의 "Filters to export non-resource files"에 `*.json`을 추가해야 시트 JSON이 포함된다.
