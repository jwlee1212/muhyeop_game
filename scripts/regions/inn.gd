extends RefCounted
## 객잔. 옥분(O)이 있다. 위쪽 문 1 → 헛간, 아래쪽 문 2 → 마을.

const NAME := "객잔"
const FLOOR := "_"
const EXITS := {
	"1": {"to": "shed", "entry": "c", "floor": "D"},
	"2": {"to": "village", "entry": "c", "floor": "D"},
}
const MAP := [
	"IIII1IIIIIIIIIIIIIII",
	"I___c______xxbb____I",
	"I__________________I",
	"I_t__t__t____ttt___I",
	"I_________________OI",
	"I_t__t__t__________I",
	"I__________________I",
	"I_t__t__t____a_____I",
	"IIIIIIIIIIIII2IIIIII",
]
