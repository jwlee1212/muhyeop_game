extends RefCounted
## 무관. 마 사범(M)이 있다. Q2 "급조 수련"의 무대.

const NAME := "무관"
const FLOOR := "_"
const EXITS := {
	"1": {"to": "village", "entry": "d", "floor": "D"},
}
const MAP := [
	"IIIIIIIIIIIIIIIIIIIIII",
	"I_vvvv______vvvv_____I",
	"I____________________I",
	"I__u____u____u____u__I",
	"I____________________I",
	"I_________M__________I",
	"I____________________I",
	"I__u____u____u____u__I",
	"I____________________I",
	"I__________a_________I",
	"IIIIIIIIIII1IIIIIIIIII",
]
