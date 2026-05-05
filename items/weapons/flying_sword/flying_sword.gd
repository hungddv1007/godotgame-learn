extends Area3D
class_name FlyingSword

## === CONFIGURATION ===
@export var fly_speed: float = 50.0 # Tốc độ bay (m/s)
@export var lifetime: float = 5.0 # Thời gian sống tối đa (giây)
@export var hover_time: float = 0.2 # Thời gian lơ lửng trước khi phóng
@export var spawn_time: float = 0.15 # Thời gian hiện ra (scale 0 → 1)

## === STATE ===
enum Phase { SPAWN, HOVER, LAUNCH }
var current_phase: Phase = Phase.SPAWN
var damage_data: DamageData
var aim_target: Vector3 = Vector3.ZERO
var fly_direction: Vector3 = Vector3.FORWARD # Hướng bay thực tế (tính tại launch)
var hit_entities: Array[Node] = []
var owner_node: Node = null # Người sở hữu (player) để không tự đánh bản thân
var is_destroyed: bool = false
var on_hit_effects: Array = [] # Hiệu ứng áp dụng khi trúng đích

func _ready():
	# Bắt đầu ở scale rất nhỏ (không dùng ZERO vì Jolt Physics không chấp nhận singular transform)
	scale = Vector3.ONE * 0.01
	
	# Chỉ kết nối area_entered — phát hiện Hurtbox (Area vs Area)
	# KHÔNG dùng body_entered — tránh kiếm chạm mặt đất trước khi trúng mục tiêu
	area_entered.connect(_on_area_entered)
	
	# Bắt đầu vòng đời
	_start_spawn_phase()

## Thiết lập dữ liệu sát thương, mục tiêu, và hiệu ứng khi trúng
func setup(p_damage_data: DamageData, p_aim_target: Vector3, p_owner: Node, p_effects: Array = []) -> void:
	damage_data = p_damage_data
	aim_target = p_aim_target
	owner_node = p_owner
	on_hit_effects = p_effects

## === GIAI ĐOẠN 1: SPAWN - Hiện ra từ từ ===
func _start_spawn_phase():
	current_phase = Phase.SPAWN
	
	# Tween scale từ 0.01 lên 1
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, spawn_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(_start_hover_phase)

## === GIAI ĐOẠN 2: HOVER - Lơ lửng tại chỗ ===
func _start_hover_phase():
	current_phase = Phase.HOVER
	
	# Đợi hover_time rồi chuyển sang Launch
	var timer = get_tree().create_timer(hover_time)
	timer.timeout.connect(_start_launch_phase)

## === GIAI ĐOẠN 3: LAUNCH - Phóng về phía trước ===
func _start_launch_phase():
	current_phase = Phase.LAUNCH
	
	# Cập nhật aim_target lần cuối từ player trước khi phóng
	if owner_node and owner_node.has_method("get_aim_target"):
		aim_target = owner_node.get_aim_target()
	
	# === VECTOR TARGETING ===
	if aim_target != Vector3.ZERO and global_position.distance_to(aim_target) > 0.1:
		fly_direction = (aim_target - global_position).normalized()
		look_at(global_position + fly_direction, Vector3.UP)
	else:
		fly_direction = -global_transform.basis.z.normalized()
	
	# Bật va chạm
	set_deferred("monitoring", true)
	
	# Timer tự hủy
	var death_timer = get_tree().create_timer(lifetime)
	death_timer.timeout.connect(_on_lifetime_expired)

func _physics_process(delta: float):
	if current_phase == Phase.SPAWN or current_phase == Phase.HOVER:
		# === REAL-TIME TRACKING ===
		# Liên tục xoay mũi kiếm theo hồng tâm của player trong lúc lơ lửng
		if owner_node and owner_node.has_method("get_aim_target"):
			var current_target = owner_node.get_aim_target()
			if global_position.distance_to(current_target) > 0.1:
				look_at(current_target, Vector3.UP)
	elif current_phase == Phase.LAUNCH:
		# Di chuyển theo fly_direction đã tính (cố định tại thời điểm launch)
		global_position += fly_direction * fly_speed * delta

## === XỬ LÝ VA CHẠM ===
## Xử lý area_entered cho Hurtbox (Area vs Area)
func _on_area_entered(area: Area3D):
	if is_destroyed:
		return
	if area is Hurtbox:
		var target = area.owner
		# Không tự đánh bản thân
		if target == owner_node:
			return
		# Không đánh trúng cùng mục tiêu 2 lần
		if hit_entities.has(target):
			return
		hit_entities.append(target)
		
		# Truyền sát thương
		if damage_data:
			area.receive_damage(damage_data)
		
		# Áp dụng hiệu ứng on-hit (cháy, độc, v.v.)
		if area.stats_manager and on_hit_effects.size() > 0:
			for effect in on_hit_effects:
				area.stats_manager.apply_status_effect(effect)
		
		# Thanh kiếm tự hủy sau khi trúng mục tiêu
		_destroy()

func _on_lifetime_expired():
	_destroy()

func _destroy():
	if is_destroyed or not is_inside_tree():
		return
	is_destroyed = true
	# Tắt va chạm — PHẢI dùng set_deferred vì có thể đang trong signal callback
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	# Hiệu ứng biến mất nhanh
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.1)
	tween.tween_callback(queue_free)
