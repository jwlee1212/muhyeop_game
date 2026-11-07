# 무협 도트 오픈월드 (가제)

탑다운 도트 무협 RPG. 무협 웹툰 1화만 본 주인공이 1화에서 죽는 소년 한서진의 몸에 빙의해, 죽기 한 시진 전부터 죽음을 피하고 원작 밖의 강호를 떠돈다.
Godot 4.7 / GDScript. 실행 파일: `~/Applications/Godot.app/Contents/MacOS/Godot`
이야기·설정·NPC·초반 퀘스트: [docs/STORY.md](docs/STORY.md). (원래 기획서의 멸문·본문파 줄거리는 폐기)

## 기획 핵심
- 480x270 (정수 배율), 캐릭터 32x32, 타일 16x16, 팔레트 16~32색, 8방향 이동·공격
- 전투: 방향 공격, 회피(경공), **기세**(적 게이지를 깎으면 경직)
- **기수식**: Q를 누르고 있는 동안 자세 → 화면 기준 절대 방향(↑↓←→) + J로 초식 발동 (첫 초식: 일섬 `↓↑+J`). 초식은 배워야 쓰고, 커맨드는 무공 메뉴에서 보고 외운다 (전투 HUD에 커맨드 목록을 띄우지 않는다)
- 내공: 적중 시 충전 → 경공·초식에 소모 → 운기조식으로 회복
- 시진 시계: 실시간이 아니라 **퀘스트 진행에 맞춰** 넘어간다
- 재시도: 황가 일당 전투 직전 자동 세이브 → 죽으면 "뒤로가기"로 전투 직전부터
- 서진의 원래 기억은 없다 (대사 쓸 때 주의: 주인공은 주변 인물의 이름·관계를 모른다)
- 첫 무대: 돌다리 마을 (객잔·헛간·무관·돌다리·다리 밑 뒷골목)

## 개발 단계
| 단계 | 목표 | 상태 |
|---|---|---|
| 1 | 움직임과 손맛: 8방향 이동·공격·피격(더미 도트) + 카메라 | 완료 (+ pixelfx 베기 이펙트) |
| 2 | 돌다리 마을: 타일맵 + 실내 + 지역 전환 + 길찾기 적 | 완료 |
| 3 | 기수식과 기세: Q 커맨드·일섬·기세·황가 일당 3인 전투 | 완료 |
| 4 | 한 시진: 대화·퀘스트·시진 시계·자동 세이브·Q0~Q5 | 다음 |
| 5 | SpriteCook 에셋(8방향 캐릭터, 타일셋) + ElevenLabs 사운드 | |
| 6 | 1차 버전: Q5 이후 지역 2곳·보스 2·배포 빌드 | |

단계별 세부 작업과 완료 조건은 [docs/MILESTONES.md](docs/MILESTONES.md) (M1~M6 = 위 1~6단계). 단계를 끝내면 이 표와 그 문서의 체크박스·상태를 함께 갱신한다.

## 구조
```
scenes/main.tscn        Main 노드 하나 (main.gd가 게임을 코드로 조립)
scripts/
  input_setup.gd        입력 액션 등록 (autoload "Inputs")
  fx.gd                 hitstop / shake / damage_number (autoload "Fx")
  main.gd               게임 루트: REGIONS 목록, change_region(id, entry), 페이드, HUD
  player.gd             주인공 상태머신 (MOVE ATTACK DASH HURT MEDITATE DEAD STANCE TECHNIQUE), frozen, place_at(), 기수식 토큰
  enemy.gd              적 AI. KINDS(thug, hwang)·ATTACKS(slash slam stomp charge) 표, 기세, region.find_path로 추격
  combat/techniques.gd  초식(TECHNIQUES)·무기(WEAPONS) 데이터, match_command()
  combat/telegraph.gd   적 공격 예고 (region.ground_fx에 붙음)
  dummy_body.gd         더미 도트 몸체 (5단계에서 AnimatedSprite2D로 교체)
  pixel_fx.gd           pixelfx 스프라이트 시트 재생
  shake_camera.gd / obstacle.gd(나무·바위) / hud.gd(바·지역 이름·기수식 입력·보스 바)
  world/tiles.gd        지도 글자 ↔ 타일 대응표(LEGEND), TileSet 생성
  world/region_grid.gd  글자 격자 + 그리기 명령 (rect, building, set_c)
  world/region.gd       지역 빌더: 타일맵·출구·진입 지점·NPC·적·AStarGrid2D·카메라 경계
  world/npc.gd          NPC 자리 표시 (옥분 okbun, 마 사범 ma, 엽 노인 yeop)
  regions/*.gd          지역 정의: shed(시작) inn village dojo alley
  dev/gen_placeholder_tiles.gd  임시 타일셋 PNG 생성기
assets/tiles/           placeholder_tiles.png (16x16, 8열 아틀라스)
assets/fx/              pixelfx에서 뽑은 시트 (PNG + JSON)
tools/pixelfx/          patch-gg/pixelfx git 서브모듈 (tools/.gdignore로 Godot 임포트 제외)
                        새로 받을 때: git clone --recurse-submodules / git submodule update --init
.claude/skills/pixelfx  pixelfx 스킬
```

## 코드 규칙
- **`class_name` 쓰지 않는다.** 다른 스크립트는 `const X := preload("res://scripts/x.gd")`로 불러 타입으로도 쓴다.
- **타입이 있는 수학 함수**를 쓴다: `lerpf maxf clampf roundf absf maxi`. 일반 `lerp/max/round`는 Variant를 돌려줘 `:=` 추론이 실패한다.
- 입력 액션은 `input_setup.gd`에서 코드로 추가한다 (project.godot에 직렬화하지 않음). 현재: move_*, attack(J), dash(K/Space), stance(Q, 패드 LB), meditate(R), debug_toggle(F1).
- **방향 인덱스**: 0=s 1=se 2=e 3=ne 4=n 5=nw 6=w 7=sw (`dummy_body.gd`의 `DIRS8`, `DIR_NAMES`). 벡터 → 인덱스는 `player.gd`의 `dir_index()`.
- **원점 = 발끝** (y정렬용). 몸 중심/타격 기준점은 `HIT_CENTER = (0, -10)`.
- 충돌 레이어: 1 = 월드(벽·장애물), 2 = 플레이어, 4 = 적. 플레이어 mask 1, 적 mask 1|4.
- 캐릭터·오브젝트는 y_sort가 켜진 `world` 노드 아래에 둔다. `world`는 그룹 `fx_layer`.
- 몸체 교체 인터페이스: `facing`, `moving`, `attack_t`(0..1, -1=공격 아님), `flash`, `windup`, `draw_trail`, `stance`, `stunned`, `poise_ratio`(-1=숨김). 이것만 맞추면 player/enemy는 그대로 쓴다.
- 적 피격: `take_hit(피해, 방향, 넉백, 기세피해)`. 새 공격을 만들면 기세 피해도 정한다.
- 기수식 토큰은 화면 기준 "U" "D" "L" "R" (`player.dir_token()`, 대각선은 무시). 초식이 나가는 방향은 기수식 전에 보던 방향. 새 초식은 `TECHNIQUES`에 추가하고 `player.learn_technique(id)`로 익힌다 (`known_techniques`).
- 적 종류 추가: `enemy.gd`의 `KINDS`/`ATTACKS`, 지도 글자는 `tiles.gd`의 `ENEMY_CHARS`.
- 주석과 UI 문자열은 한국어.

## 지역(맵) 만들기
- 지역 하나 = `scripts/regions/<id>.gd` + `main.gd`의 `REGIONS`에 등록.
- 상수: `NAME`(화면 표시), `FLOOR`(소품·표시 글자 밑 기본 바닥), `EXITS`(`{"1": {"to", "entry", "floor"}}`).
- 지도: 작은 실내는 `const MAP := [글자 줄...]`, 큰 바깥은 `static func make_grid() -> Grid`에서 `rect`/`building`/`set_c`로 그린다.
- 글자 표는 `scripts/world/tiles.gd` 맨 위 주석과 `LEGEND`. 표시 글자: `1~9` 출구, `a c d e f g` 진입 지점, `O M Y` NPC, `E` 황가 패거리, `H` 황가, `T` 나무.
- 진입 지점은 출구 칸과 겹치지 않게 한 칸 떨어뜨린다 (겹치면 들어오자마자 다시 나간다).
- 타일 그림을 바꾸려면 `dev/gen_placeholder_tiles.gd`를 고치고 `$G --headless --path . --script res://scripts/dev/gen_placeholder_tiles.gd` 후 `--import`. M5에서는 같은 아틀라스 좌표로 SpriteCook 타일셋을 그려 PNG만 교체한다.

## 에셋 규칙
- 파일명: `대상_동작_방향_번호` (예: `hero_walk_s_01.png`) → 애니메이션 이름 `walk_s`
- 텍스처 필터 Nearest (프로젝트 기본값), 픽셀 스냅 켜짐
- 실제 게임·캐릭터를 베끼지 않는다

## pixelfx 이펙트
- 현재 사용: 1·2타 `melee/sword-slash`(radius 24), 3타 `melee/spin-slash`(radius 30), 적중 `impacts/hit-spark`(height 12), 일섬 `melee/thrust`(reach 56, 청백), 기세 붕괴 `impacts/crit-hit`(height 12), 황가 내려찍기·발구르기 `impacts/heavy-landing`(흙먼지 팔레트). 베기 2종은 청백 팔레트 `["#0c1430","#162c5c","#1f4f94","#2f7fcc","#58b4ec","#9bdcff","#d8f4ff","#ffffff"]`.
- 다시 뽑기 (tools/pixelfx 에서): `node tools/render.mjs <id> --sheet --no-actor --opts '<JSON>' --out ../../assets/fx` 후 `contact.png`는 지운다.
- 재생: `PixelFx.spawn(parent, id, pos, rot, anchor, mirror_x, mirror_y, speed)`. `anchor`는 프레임 안에서 `pos`에 올 픽셀(회전 중심). 궤적 중심은 이펙트 소스의 `cx, cy` + 시트 pivot으로 구한다.
- pixelfx 이펙트는 대부분 옆에서 본 시점이고 크다. 탑다운에 쓸 때는 radius/size 옵션으로 줄이고 회전·반전으로 맞춘다.
- 시트 JSON은 리소스가 아니므로 내보내기 설정의 non-resource 필터에 `*.json`을 넣어야 한다.

## 검증 방법
```bash
G=~/Applications/Godot.app/Contents/MacOS/Godot
$G --headless --path . --import          # 새 에셋 임포트 + 스크립트 파싱
$G --headless --path . --quit-after 300  # 실행 오류 확인
```
- **자동 입력 테스트**: `_autotest/autoplay.gd`(Input.action_press로 조작)를 만들고 프로젝트 루트에 `override.cfg`로 autoload 등록 → 실행 → **끝나면 둘 다 삭제**. 프로젝트에 남기지 않는다.
- **화면 확인**: `$G --path . --write-movie <scratch>/f.png --fixed-fps 30 --quit-after N`으로 프레임 녹화. 창이 가려지면 모든 프레임이 같게 찍힐 수 있으니, 그럴 때는 프레임 해시를 비교하고 헤드리스 로그로 대신 확인한다.
- 녹화 프레임·임시 파일은 프로젝트 밖(스크래치 폴더)에 둔다.
- 자동 테스트 실행은 출력을 파일로 받고(`> log 2>&1`) `--quit-after N`으로 상한을 둔다. 파이프로 받으면 버퍼에 막히고, 테스트 스크립트가 오류로 멈추면 Godot가 끝나지 않는다.
- 창 모드 캡처는 `await RenderingServer.frame_post_draw` 후 `get_viewport().get_texture().get_image().save_png()`.

