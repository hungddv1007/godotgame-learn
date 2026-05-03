extends StaticBody3D

@onready var stats_manager = $StatsManager
var debug_print_timer = 0.0
var base_color: Color
var previous_hp: float = 0.0
var was_full: bool = true

func _ready():
	stats_manager.health_changed.connect(_on_health_changed)
	stats_manager.died.connect(_on_died)
	
	# Khởi tạo chỉ số cho hình nộm
	stats_manager.add_modifier("max_hp", StatsManager.ModifierType.FLAT, 900.0) # Tổng 1000 HP
	stats_manager.add_modifier("armor", StatsManager.ModifierType.FLAT, 50.0)
	stats_manager.current_hp = stats_manager.get_stat("max_hp")
	previous_hp = stats_manager.current_hp
	
	$FloatingHealthBar.update_health(stats_manager.current_hp, stats_manager.get_stat("max_hp"))
	
	# Lưu màu gốc
	var body_material = $BodyMesh.mesh.surface_get_material(0)
	if body_material:
		base_color = body_material.albedo_color

func _process(delta):
	if debug_print_timer > 0:
		debug_print_timer -= delta
		
	var current = stats_manager.current_hp
	var max_hp = stats_manager.get_stat("max_hp")
	
	if current < max_hp:
		was_full = false
		if debug_print_timer <= 0:
			print("Đang hồi máu... HP: ", snapped(current, 0.1), "/", max_hp)
			debug_print_timer = 0.5
	elif not was_full and current >= max_hp:
		print("Dummy HP đã hồi đầy: ", max_hp, "/", max_hp)
		was_full = true

func _on_health_changed(current, max_hp):
	$FloatingHealthBar.update_health(current, max_hp)
	
	# Chỉ xử lý chớp đỏ và in log ngay lập tức nếu thực sự mất máu
	if current < previous_hp:
		print("Dummy bị chém! HP còn: ", snapped(current, 0.1), "/", max_hp)
		debug_print_timer = 0.5 # Reset timer để không bị trùng log hồi máu ngay sau đó
		
		var body_material = $BodyMesh.mesh.surface_get_material(0)
		var head_material = $HeadMesh.mesh.surface_get_material(0)
		
		var tween = create_tween()
		if body_material:
			body_material.albedo_color = Color.RED
			tween.tween_property(body_material, "albedo_color", base_color, 0.15)
		
		if head_material:
			var head_base_color = Color(0.8, 0.4, 0.1, 1) # Màu gốc của đầu
			head_material.albedo_color = Color.RED
			# Dùng parallel để chạy chung hiệu ứng mờ cho đầu
			tween.parallel().tween_property(head_material, "albedo_color", head_base_color, 0.15)
			
	previous_hp = current

func _on_died():
	print("Dummy đã bị tiêu diệt!")
	queue_free()
