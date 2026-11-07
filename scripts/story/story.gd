extends Node
## 초반 퀘스트 "한 시진" (Q0~Q5) 진행. 상호작용·지역 진입·전투 결과를 받아 대화와 퀘스트를 바꾼다.
## 주인공은 서진의 기억이 없다: 옥분이 이름을 말해 주기 전까지 "여인"으로 부른다.
##
## 시진 시계(각): Q0 0 → Q1 수락 1 → 술 전달 2 → 수련 끝 5 → 골목 파악 7 → 황가 일당 8(유시)

const Techniques := preload("res://scripts/combat/techniques.gd")

var main                          # main.gd
var _busy := false                # 이벤트(대화) 진행 중이면 다른 이벤트를 받지 않는다
var _dummy = null
var _dummy_hits := 0
var _fight: Array = []
var _fight_active := false


func _region() -> Node:
	return main.region


func _player() -> Node:
	return main.player


func say(lines: Array) -> int:
	return await main.dialogue.play(lines)


func sys(text: String) -> void:
	await say([{"text": text, "sys": true}])


func okbun_name() -> String:
	return "옥분" if Game.flag("know_okbun") else "여인"


# ───────────── 시작 ─────────────

func start_new_game() -> void:
	_busy = true
	Game.set_quest("q0", "주위를 살펴보자", 0)
	await say([
		{"text": "…낯선 천장.", "thought": true},
		{"text": "짚 냄새. 나무 벽. 내 방이 아니다.", "thought": true},
	])
	_busy = false


# ───────────── 지역 진입 ─────────────

## 지역을 짓자마자(페이드 인 전에) 부른다: 퀘스트에 따라 NPC를 숨기거나 보인다.
func apply_presence(region: Node) -> void:
	var yeop = region.npc("yeop")
	if yeop:
		yeop.set_present(Game.flag("q5"))


## 지역에 들어와 화면이 밝아진 뒤 부른다: 퀘스트 이벤트.
func on_region_entered(region: Node) -> void:
	_dummy = null
	match region.region_id:
		"inn":
			if Game.quest == "q0" and Game.flag("q0_bowl") and not Game.flag("q1_called"):
				Game.set_flag("q1_called")
				_busy = true
				await say([{"who": okbun_name(), "text": "서진아! 일어났으면 이리 좀 와 보렴."}])
				Game.set_objective("객잔의 여인에게 말을 걸자")
				_busy = false
		"dojo":
			if Game.quest == "q2" and not Game.flag("q2_done"):
				_spawn_dummy()
		"alley":
			if Game.quest == "q3" and not Game.flag("q3_arrived"):
				Game.set_flag("q3_arrived")
				_busy = true
				await say([
					{"text": "여기다. 컷에서 본 돌다리 기둥.", "thought": true},
					{"text": "해 질 녘에 서진은… 아니, 나는 여기서 쓰러진다.", "thought": true},
				])
				Game.set_objective("골목 안쪽까지 지형을 살펴 두자")
				_busy = false
			elif Game.quest == "q4" and not _fight_active:
				# 자동 세이브에서 돌아왔을 때: 대화 없이 바로 다시 싸운다
				_start_fight(true)
		"village":
			if Game.quest == "q5" and not Game.flag("q5_village"):
				Game.set_flag("q5_village")
				Game.set_objective("게시판 옆의 노인에게 말을 걸자")


func _physics_process(_delta: float) -> void:
	if _busy or main == null or main.region == null or main.transitioning:
		return
	# Q3: 골목 안쪽까지 들어가면 지형 파악 완료 → 황가 일당 등장
	if Game.quest == "q3" and main.region.region_id == "alley" and Game.flag("q3_arrived"):
		var cell: Vector2i = main.region.world_to_cell(_player().global_position)
		if cell.x >= main.region.consts.get("SCOUT_X", 18):
			_scouted()


# ───────────── 상호작용 ─────────────

func on_interact(id: String) -> void:
	if _busy:
		return
	_busy = true
	match id:
		"bowl": await _talk_bowl()
		"okbun": await _talk_okbun()
		"ma": await _talk_ma()
		"yeop": await _talk_yeop()
		"notice_board": await _look_board()
		"training_post": await say([{"text": "낡은 목인장. 칼자국이 빼곡하다.", "thought": true}])
		"well": await say([{"text": "깊은 우물. 물이 차다.", "thought": true}])
		_: pass
	_busy = false


func _talk_bowl() -> void:
	if Game.flag("q0_bowl"):
		await say([{"text": "물에 비친 얼굴. 아직도 낯설다.", "thought": true}])
		return
	Game.set_flag("q0_bowl")
	await say([
		{"text": "물그릇에 얼굴이 비친다.", "thought": true},
		{"text": "…누구야, 이거.", "thought": true},
		{"text": "열댓 살쯤 된 소년. 내 얼굴이 아니다.", "thought": true},
		{"text": "잠깐. 이 얼굴, 본 적 있어. 아까 그 웹툰…", "thought": true},
		{"text": "1화 마지막 컷. 다리 밑 골목에서 쓰러져 있던 그 애. 한서진.", "thought": true},
	])
	Game.memory_unlocked = true
	Game.changed.emit()
	await sys("기억 속 컷이 떠올랐다.  (Tab → 기억)")
	await say([
		{"text": "컷 속 하늘은 해 질 녘이었어. 창밖 해를 보면… 한 시진쯤 남았다.", "thought": true},
		{"text": "그 전에 뭐라도 해야 해. 일단 밖으로 나가 보자.", "thought": true},
	])
	Game.set_objective("밖으로 나가 보자")


func _talk_okbun() -> void:
	match Game.quest:
		"q0":
			if not Game.flag("q0_bowl"):
				await say([{"who": okbun_name(), "text": "얼굴이 왜 그러니? 뒷방에 물 떠다 놨다. 세수라도 하고 오렴."}])
				return
			await _quest1()
		"q1":
			await say([{"who": "옥분", "text": "술은 마 사범님께 갖다 드렸니? 무관은 큰길 따라 동쪽이야."}])
		"q2":
			await say([{"who": "옥분", "text": "마 사범님이 너한테 목검을 쥐여 주셨다고? 별일이구나."}])
		"q3", "q4":
			await say([{"who": "옥분", "text": "해 지기 전엔 들어오너라. 요즘 황가 녀석들이 설쳐."}])
		_:
			await say([{"who": "옥분", "text": "무사해서 다행이다. …오늘따라 네가 좀 커 보이는구나."}])


func _quest1() -> void:
	var c := await say([
		{"who": okbun_name(), "text": "어, 너 오늘 왜 이렇게 말이 없니? 어디 아프냐?"},
		{"text": "이게 나인가… 아니, 서진이구나.", "thought": true},
		{"text": "이 사람이 누군지 모른다. 어떻게 대답하지?", "thought": true, "choices": ["아, 아니에요. 괜찮아요.", "…누구세요?"]},
	])
	if c == 1:
		await say([
			{"who": okbun_name(), "text": "얘가 잠이 덜 깼나. 옥분 아줌마도 못 알아보고."},
			{"who": "옥분", "text": "열이라도 있는 거 아니야? 이리 와 봐."},
		])
	else:
		await say([
			{"who": okbun_name(), "text": "괜찮긴. 말투도 영 딴사람 같은데."},
			{"who": okbun_name(), "text": "이 옥분 아줌마 눈은 못 속여. 무슨 일 있으면 말하렴."},
		])
	Game.set_flag("know_okbun")
	await say([
		{"text": "옥분. 이 객잔의 주인이고, 서진을 거둬 키운 사람… 인 것 같다.", "thought": true},
		{"who": "옥분", "text": "그래도 심부름은 해야지. 이 술 한 병, 무관의 마 사범님께 갖다 드리렴."},
		{"who": "옥분", "text": "무관은 큰길 따라 동쪽이야. 다녀와서 저녁 준비 돕고."},
	])
	Game.add_item("wine")
	await sys("술 한 병을 받았다.")
	Game.set_quest("q1", "무관의 마 사범에게 술을 전하자", 1)


func _talk_ma() -> void:
	match Game.quest:
		"q0", "":
			await say([{"who": "마 사범", "text": "서진이 아니냐. 무관엔 무슨 일로?"}])
		"q1":
			await _quest2_start()
		"q2":
			if Game.flag("q2_learned"):
				await say([{"who": "마 사범", "text": "형을 떠올려라. 목인장에 일섬을 써 보거라."}])
			else:
				await say([{"who": "마 사범", "text": "기본부터다. 목인장을 세 번 베어 보거라. (F)"}])
		_:
			await say([{"who": "마 사범", "text": "오늘 배운 형을 잊지 마라. 몸이 따라오지 않으면 머리라도 기억해야 한다."}])


func _quest2_start() -> void:
	Game.remove_item("wine")
	await say([
		{"who": "마 사범", "text": "옥분이 보냈구나. 고맙다고 전해라."},
		{"who": "마 사범", "text": "…그런데 서진아. 오늘은 눈빛이 다르구나."},
		{"text": "들켰나? 아니, 이건 기회다. 싸우는 법을 배워야 해.", "thought": true},
		{"text": "…사범님. 저한테 칼 쓰는 법 좀 가르쳐 주세요. 지금, 당장요.", "choices": ["오늘 해 지기 전에 꼭 배워야 해요.", "그냥… 궁금해서요."]},
		{"who": "마 사범", "text": "허. 늘 도망만 다니던 녀석이."},
		{"who": "마 사범", "text": "좋다. 시간이 없다니 급하게 가르치마. 받아라, 연습용 목검이다."},
	])
	Game.add_item("wooden_sword")
	_player().weapon_id = "wooden_sword"
	await sys("연습용 목검을 받았다.")
	Game.set_quest("q2", "목인장을 세 번 베자 (F)", 2)
	_dummy_hits = 0
	_spawn_dummy()


func _spawn_dummy() -> void:
	if _dummy and is_instance_valid(_dummy):
		return
	_dummy = _region().spawn_enemy("dummy", Vector2i(11, 7))
	_dummy.hit_taken.connect(_on_dummy_hit)


func _on_dummy_hit(_e, _amount: float, poise_dmg: float) -> void:
	if Game.quest != "q2" or _busy:
		return
	if not Game.flag("q2_learned"):
		_dummy_hits += 1
		Game.set_objective("목인장을 세 번 베자 (F)  %d/3" % mini(_dummy_hits, 3))
		if _dummy_hits >= 3:
			_teach_ilseom()
	elif poise_dmg >= Techniques.TECHNIQUES.ilseom.poise:
		_q2_done()


func _teach_ilseom() -> void:
	_busy = true
	await say([
		{"who": "마 사범", "text": "손목이 굳었다만, 칼끝은 제법 곧구나."},
		{"who": "마 사범", "text": "이제 초식 하나를 보여 주마. 일섬(一閃)이다."},
		{"who": "마 사범", "text": "먼저 기수식을 잡는다. 숨을 고르고, 몸을 낮췄다가 — 솟구치며 벤다."},
		{"text": "보인다. 동작이 '형'으로 머릿속에 그대로 박힌다.", "thought": true},
	])
	_player().learn_technique("ilseom")
	Game.set_flag("q2_learned")
	await sys("초식 [일섬]을 익혔다.  커맨드는 무공 메뉴(Tab)에서 확인할 수 있다.")
	Game.set_objective("무공 메뉴(Tab)에서 일섬의 형을 보고, 목인장에 써 보자")
	_busy = false


func _q2_done() -> void:
	_busy = true
	Game.set_flag("q2_done")
	await say([
		{"who": "마 사범", "text": "…!"},
		{"who": "마 사범", "text": "한 번 보고 형을 그대로 따라 하다니. 너, 정말 서진이 맞느냐?"},
		{"text": "에이, 별거 아니에요.", "choices": ["에이, 별거 아니에요."]},
		{"text": "…방금 그 말, 내가 하려던 말이 아니었는데.", "thought": true},
		{"who": "마 사범", "text": "몸이 버티지 못하면 형도 소용없다. 내공이 바닥나면 숨을 고르거라. (R 유지: 운기조식)"},
	])
	Game.set_quest("q3", "기억 속 컷의 장소를 찾자  (Tab → 기억)", 5)
	await say([
		{"text": "그 컷… 돌다리 기둥 아래 골목. 마을 동쪽에 돌다리가 있었지.", "thought": true},
	])
	_busy = false


func _scouted() -> void:
	_busy = true
	Game.set_quest("q3", "골목을 살펴 두자", 7)
	await say([
		{"text": "상자, 술통, 무너진 담. 숨을 곳은 있다.", "thought": true},
		{"text": "내려오는 계단은 하나뿐. 놈들도 저기로 오겠지.", "thought": true},
	])
	await get_tree().create_timer(0.6).timeout
	await say([
		{"who": "???", "text": "어이, 서진이! 거기 숨어 있었냐?"},
	])
	Game.set_quest("q4", "황가 일당에게서 살아남자", 8)
	_spawn_trio()
	await say([
		{"who": "황가", "text": "이달 보호비. 옥분이네 객잔 몫까지 오늘 받아 가야겠다."},
		{"text": "온다. 1화 마지막 장면이.", "thought": true, "choices": ["…돈 없어요.", "에이, 별거 아니에요."]},
		{"who": "황가", "text": "이 자식이 오늘따라 눈을 똑바로 뜨네? 끌고 가!"},
	])
	# 자동 세이브: 싸움 직전. 죽으면 여기서 다시 시작한다.
	Game.set_flag("q4_autosave")
	main.autosave()
	_begin_fight()
	_busy = false


func _spawn_trio() -> void:
	_clear_trio()
	var spawns: Dictionary = _region().consts.get("SPAWNS", {})
	for key in ["hwang", "thug_a", "thug_b"]:
		var kind := "hwang" if key == "hwang" else "thug"
		var e = _region().spawn_enemy(kind, spawns.get(key, Vector2i(5, 8)))
		e.died.connect(_on_trio_died)
		_fight.append(e)


func _clear_trio() -> void:
	for e in _fight:
		if is_instance_valid(e):
			e.queue_free()
	_fight.clear()


func _start_fight(from_autosave: bool) -> void:
	_spawn_trio()
	if from_autosave:
		Fx.popup_text(_player().global_position, "다시 한 번", Color("d8f4ff"))
	_begin_fight()


func _begin_fight() -> void:
	_fight_active = true
	_player().auto_respawn = false
	_region().set_exits_enabled(false)
	for e in _fight:
		if is_instance_valid(e):
			e.detect_range = 400.0
			e.lose_range = 600.0


func _on_trio_died(_e) -> void:
	if not _fight_active:
		return
	for e in _fight:
		if is_instance_valid(e) and e.state != e.State.DEAD:
			return
	_win_fight()


func _win_fight() -> void:
	_fight_active = false
	_busy = true
	await get_tree().create_timer(0.8).timeout
	_player().auto_respawn = true
	_region().set_exits_enabled(true)
	Game.set_flag("q4_won")
	await say([
		{"text": "…살았다?", "thought": true},
		{"text": "해가 넘어간다. 유시(酉時). 원작에서 서진이 숨을 거둔 시각.", "thought": true},
		{"text": "그런데 나는, 아직 서 있다.", "thought": true},
	])
	await main.cutscene.play_not_in_original()
	Game.set_flag("q5")
	Game.set_quest("q5", "마을로 돌아가자", 8)
	_busy = false


## 플레이어가 죽었을 때 (main이 연결). Q4 싸움 중이면 1화 엔딩 컷 → 뒤로가기 → 자동 세이브.
func on_player_died() -> void:
	if not _fight_active:
		return
	_busy = true
	_fight_active = false
	await get_tree().create_timer(1.0).timeout
	await main.cutscene.play_death()
	_clear_trio()
	await main.load_game(Game.AUTOSAVE_PATH, true)
	_busy = false


func _talk_yeop() -> void:
	if Game.quest == "q5":
		await say([
			{"who": "노인", "text": "허허. 살아남았구먼."},
			{"who": "노인", "text": "원래라면 오늘 해 질 녘, 그 골목에서 끝났을 아이가."},
			{"text": "…이 노인, 뭘 아는 거지?", "thought": true},
			{"text": "노인의 귀에 하얀 끈 같은 게 걸려 있다. …이어폰? 설마.", "thought": true},
			{"who": "엽 노인", "text": "나는 엽가라고 하네. 떠도는 늙은이지."},
			{"who": "엽 노인", "text": "이야기가 어긋났어. 이제부터는 아무도 모르는 길이야. 자네도, 나도."},
			{"who": "엽 노인", "text": "살고 싶으면 강해져야 하네. 일거리는 저 게시판에 붙여 두지."},
		])
		Game.set_quest("done", "엽 노인의 첫 의뢰를 받자  (다음 지역은 준비 중)", 8)
		await sys("초반 「한 시진」 완료.  다음 지역은 1차 버전(M6)에서 열린다.")
	else:
		await say([{"who": "엽 노인", "text": "게시판을 보게. 강호는 넓어."}])


func _look_board() -> void:
	if Game.quest == "done":
		await say([{"text": "새 종이: 「죽림 너머 산적 출몰. 길 안내 겸 호위 구함 — 엽」 (준비 중)", "thought": true}])
	else:
		await say([{"text": "낡은 종이 몇 장. 사람 찾기, 짐 나르기… 의뢰 게시판인가 보다.", "thought": true}])
