extends RefCounted
## 객잔 뒷방(헛간). 게임 시작 지점 a (짚 침상 옆). Q0 "낯선 몸"의 무대, 물그릇 p.

const NAME := "객잔 뒷방"
const FLOOR := "_"
const EXITS := {
	"1": {"to": "inn", "entry": "c", "floor": "D"},
}
const MAP := [
	"IIIIIIIIIIIIII",
	"I_kk___xx_bb_I",
	"I_kk_________I",
	"I_a_______x__I",
	"I____p_______I",
	"I_________x__I",
	"I__________c_I",
	"IIIIIIIIIII1II",
]
