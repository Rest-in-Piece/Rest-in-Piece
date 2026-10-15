extends Button

var _tween_visual: Tween


func _ready() -> void:
	mouse_entered.connect(_animar.bind(true))
	mouse_exited.connect(_animar.bind(false))
	focus_entered.connect(_animar.bind(true))
	focus_exited.connect(_animar.bind(false))
	resized.connect(func(): pivot_offset = size / 2.0)
	pivot_offset = size / 2.0


func _animar(ativo: bool) -> void:
	if disabled:
		return
	if _tween_visual != null and _tween_visual.is_valid():
		_tween_visual.kill()
	_tween_visual = create_tween()
	_tween_visual.tween_property(self, "scale", Vector2(1.015, 1.015) if ativo else Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
