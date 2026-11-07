extends AnimatedSprite2D
## pixelfx 스프라이트 시트(PNG + Aseprite식 JSON)를 한 번 재생하고 사라지는 이펙트.
## 시트는 tools/pixelfx 에서 `node tools/render.mjs <id> --sheet --out assets/fx` 로 뽑는다.
## 노드 원점 = `anchor`(시트 프레임 안의 픽셀 좌표). 회전·뒤집기는 이 점을 중심으로 일어난다.

const FX_ROOT := "res://assets/fx/"

static var _cache := {}
static var _add_mat: CanvasItemMaterial


static func _add_material() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat


## id 예) "melee/sword-slash" → res://assets/fx/melee/sword-slash/sword-slash.{png,json}
static func load_sheet(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var name := id.get_file()
	var base := FX_ROOT + id + "/" + name
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
	var meta: Dictionary = json.meta.pixelfx
	var tex: Texture2D = load(base + ".png")
	var fw: int = meta.frameSize[0]
	var fh: int = meta.frameSize[1]
	var cols: int = meta.columns
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("play")
	frames.set_animation_loop("play", meta.loop)
	frames.set_animation_speed("play", meta.fps)
	for i in int(meta.frames):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2((i % cols) * fw, (i / cols) * fh, fw, fh)
		frames.add_frame("play", at)
	var info := {"frames": frames, "pivot": Vector2(meta.pivot[0], meta.pivot[1]), "meta": meta}
	_cache[id] = info
	return info


## 이펙트를 parent 아래 pos에 만든다.
## anchor: 프레임 안에서 pos에 올 픽셀 (기본 = 시트의 pivot)
## mirror_x / mirror_y: anchor 기준 좌우·상하 반전
static func spawn(parent: Node, id: String, pos: Vector2, rot := 0.0, anchor := Vector2(-1, -1),
		mirror_x := false, mirror_y := false, speed := 1.0) -> AnimatedSprite2D:
	var info := load_sheet(id)
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = info.frames
	fx.centered = false
	fx.offset = -(info.pivot if anchor.x < 0 else anchor)
	fx.position = pos
	fx.rotation = rot
	fx.scale = Vector2(-1 if mirror_x else 1, -1 if mirror_y else 1)
	fx.speed_scale = speed
	fx.z_index = 5
	# 시트에 구워진 빛(어두운 반투명 테두리)이 밝은 풀밭에서 그림자처럼 보이지 않게 가산 합성
	fx.material = _add_material()
	parent.add_child(fx)
	fx.play("play")
	fx.animation_finished.connect(fx.queue_free)
	return fx
