extends Label3D
class_name FloatingText

func _ready():
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	font_size = 42
	outline_size = 12
	outline_render_priority = 0
	render_priority = 10
	
	var tween = create_tween()
	var up_offset = Vector3(0, 1.0, 0)
	
	# Nhảy nhẹ lên trên trong 1 giây
	tween.tween_property(self, "position", position + up_offset, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Mờ dần đi
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_callback(queue_free)

func setup(amount: float, is_critical: bool = false):
	text = str(snapped(amount, 0.1))
	if is_critical:
		modulate = Color.GOLD
		pixel_size = 0.015 # Text bự hơn khi chí mạng
		text = text + "!"
	else:
		modulate = Color.WHITE
		pixel_size = 0.01
