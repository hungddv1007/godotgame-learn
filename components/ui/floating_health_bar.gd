extends Sprite3D
class_name FloatingHealthBar

var viewport: SubViewport
var progress_bar: ProgressBar

func _ready():
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	transparent = true
	
	# Tạo SubViewport linh động để không cần thiết lập file tscn rườm rà
	viewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.size = Vector2(250, 30)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	
	# Tạo thanh Progress Bar
	progress_bar = ProgressBar.new()
	progress_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	progress_bar.show_percentage = false
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_bg.corner_radius_top_left = 15
	style_bg.corner_radius_bottom_right = 15
	style_bg.corner_radius_bottom_left = 15
	style_bg.corner_radius_top_right = 15
	
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	style_fg.corner_radius_top_left = 15
	style_fg.corner_radius_bottom_right = 15
	style_fg.corner_radius_bottom_left = 15
	style_fg.corner_radius_top_right = 15
	
	progress_bar.add_theme_stylebox_override("background", style_bg)
	progress_bar.add_theme_stylebox_override("fill", style_fg)
	viewport.add_child(progress_bar)
	
	# Gắn viewport texture vào Sprite3D
	texture = viewport.get_texture()

func update_health(current: float, max_hp: float):
	if progress_bar:
		progress_bar.max_value = max_hp
		progress_bar.value = current
