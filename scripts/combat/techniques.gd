extends RefCounted
## 초식·무기 데이터.
## 초식 커맨드 = 기수식(Shift 유지) 중의 방향 입력 + 공격(F).
## 방향 토큰은 화면 기준 절대 방향: "U" 위, "D" 아래, "L" 왼쪽, "R" 오른쪽. (대각선 입력은 무시)
## 초식은 익혀야(player.known_techniques) 쓸 수 있다. 커맨드는 HUD에 띄우지 않고,
## 무공 메뉴(M4)의 목록에서 보고 외워서 쓴다. 초식이 나가는 방향은 기수식에 들어가기 전에 보던 방향.

const TECHNIQUES := {
	"ilseom": {
		"name": "일섬",
		"desc": "자세를 낮췄다가 보던 방향으로 단숨에 파고들며 벤다.",
		"command": ["D", "U"],    # ↓ ↑ + F
		"qi": 20.0,
		"dmg": 26.0,          # 무기 배율 적용 전
		"poise": 60.0,        # 기세 피해
		"knock": 150.0,
		"windup": 0.10,       # 자세를 낮추는 시간
		"dash_dist": 56.0,    # 돌진 거리 (px)
		"dash_time": 0.11,
		"width": 12.0,        # 돌진 경로의 판정 폭 (반폭)
		"recovery": 0.30,     # 돌진 뒤 빈틈
		"fx": "melee/thrust",
	},
}

const WEAPONS := {
	"wooden_sword": {"name": "연습용 목검", "dmg": 1.0, "reach": 0.0},
	"fist": {"name": "맨손", "dmg": 0.6, "reach": -6.0},
}

const TOKEN_TIMEOUT := 0.8   # 방향 입력 사이 허용 시간
const MAX_TOKENS := 4


const TOKEN_ARROW := {"U": "↑", "D": "↓", "L": "←", "R": "→"}


## 입력 토큰 끝부분과 맞는 초식 id (known 안에서만). 긴 커맨드부터 본다. 없으면 "".
static func match_command(tokens: Array, known: Array) -> String:
	var best := ""
	var best_len := 0
	for id in known:
		if not TECHNIQUES.has(id):
			continue
		var cmd: Array = TECHNIQUES[id].command
		if cmd.size() > tokens.size() or cmd.size() <= best_len:
			continue
		if tokens.slice(tokens.size() - cmd.size()) == cmd:
			best = id
			best_len = cmd.size()
	return best
