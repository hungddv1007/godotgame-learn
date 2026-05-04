extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var spring_arm = $SpringArm3D
@onready var visual_pivot = $VisualPivot
@onready var stats_manager = $StatsManager
@onready var camera: Camera3D = $SpringArm3D/Camera3D

@export var mouse_sensitivity = 0.003

var idle_time = 0.0
var combat_timer = 0.0
var is_in_combat = false
var turn_speed = 10.0

# === GATE OF BABYLON SYSTEM ===
var flying_sword_scene = preload("res://items/weapons/flying_sword/flying_sword.tscn")
var attack_cooldown_timer: float = 0.0 # Bộ đếm ngược giữa các lần bắn
var last_sword_offset: Vector2 = Vector2.ZERO # Vết vị trí kiếm cuối cùng (thuật toán rải đều)
const MIN_SWORD_DISTANCE: float = 1.5 # Khoảng cách tối thiểu giữa các thanh kiếm
const SPAWN_BEHIND_DISTANCE: float = 1.5 # Khoảng cách sau lưng
const MAX_SPAWN_ATTEMPTS: int = 10 # Số lần thử random tối đa

func _ready():
	spring_arm.top_level = true
	spring_arm.add_excluded_object(self.get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Pre-warm: Instantiate rồi free ngay 1 thanh kiếm ẩn để Godot compile shader trước
	# Tránh hiện tượng "đơ" (stutter) khi click lần đầu tiên
	# Phải call_deferred vì scene tree đang bận setup children trong _ready()
	_prewarm_flying_sword.call_deferred()

func _prewarm_flying_sword():
	var dummy = flying_sword_scene.instantiate()
	dummy.set_physics_process(false)
	dummy.set_process(false)
	dummy.set_deferred("monitoring", false)
	dummy.set_deferred("monitorable", false)
	get_tree().current_scene.add_child(dummy)
	dummy.global_position = Vector3(0, -999, 0)
	dummy.scale = Vector3.ONE
	# Đợi 2 frame để GPU render xong rồi xóa
	get_tree().process_frame.connect(func():
		get_tree().process_frame.connect(func():
			if is_instance_valid(dummy):
				dummy.queue_free()
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)

# === BUG FIX #1: Dùng _input thay vì _unhandled_input ===
# CanvasLayer (PlayerHUD) ăn hết mouse event trước khi tới _unhandled_input.
# _input luôn nhận event trước tất cả UI nodes.
func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(60))
		get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Update SpringArm3D position
	var target_pos = global_position + Vector3(0, 1.5, 0) + spring_arm.global_transform.basis.x * 0.5
	spring_arm.global_position = spring_arm.global_position.lerp(target_pos, 20.0 * delta)

	# === ATTACK SPEED COOLDOWN ===
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	# === COMBAT STATE & FIRE SWORD ===
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		is_in_combat = true
		combat_timer = 0.0
		
		# Giữ chuột trái → Bắn liên tục theo Attack Speed
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and attack_cooldown_timer <= 0:
			fire_sword()
			
	elif is_in_combat:
		combat_timer += delta
		if combat_timer >= 0.5:
			is_in_combat = false

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1
		
	input_dir = input_dir.normalized()
	
	# Free-look logic
	if input_dir == Vector2.ZERO:
		idle_time += delta
	else:
		idle_time = 0.0
	
	# Direction based on spring_arm
	var direction = (spring_arm.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# Flatten the direction to the XZ plane to prevent flying up/down based on camera pitch
	direction.y = 0
	direction = direction.normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Rotation Logic
	if is_in_combat:
		# Xoay cực nhanh khi ngắm/dùng kỹ năng để nhân vật theo kịp hồng tâm
		visual_pivot.global_rotation.y = lerp_angle(visual_pivot.global_rotation.y, spring_arm.rotation.y, turn_speed * 3.0 * delta)
	elif direction != Vector3.ZERO:
		var target_angle = atan2(-direction.x, -direction.z)
		visual_pivot.global_rotation.y = lerp_angle(visual_pivot.global_rotation.y, target_angle, turn_speed * delta)
	elif direction == Vector3.ZERO and idle_time >= 0.5:
		pass # Allow free-look

	move_and_slide()

# =========================================================
#  MODULE 1: TÂM NGẮM & NHẮM BẮN TPS
# =========================================================

## Bắn Raycast từ Camera xuyên qua giữa màn hình → trả về tọa độ mục tiêu
func get_aim_target() -> Vector3:
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().size / 2.0
	
	# Tạo ray từ camera xuyên qua tâm màn hình
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)
	var ray_end = ray_origin + ray_direction * 1000.0
	
	# Dùng PhysicsDirectSpaceState3D để raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self.get_rid()] # Loại trừ chính người chơi
	query.collision_mask = 0xFFFFFFFF # Tất cả layer
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Tia trúng vật thể/mặt đất → trả về điểm va chạm
		return result.position
	else:
		# Không trúng gì → trả về điểm cực xa theo hướng camera
		return ray_origin + ray_direction * 1000.0

# =========================================================
#  MODULE 3: PHÓNG KIẾM (FIRE SWORD)
# =========================================================

func fire_sword():
	# Tính cooldown dựa trên Attack Speed
	var atk_speed = stats_manager.get_stat("attack_speed")
	attack_cooldown_timer = 1.0 / atk_speed
	
	# Lấy mục tiêu ngắm
	var aim_target = get_aim_target()
	
	# Tạo DamageData động từ StatsManager
	var current_atk = stats_manager.get_stat("attack_damage")
	var damage = DamageData.new()
	damage.amount = current_atk
	damage.damage_type = DamageData.DamageType.PHYSICAL
	
	# Tính vị trí spawn sau lưng người chơi
	var spawn_pos = _calculate_spawn_position()
	
	# Instantiate thanh kiếm bay
	var sword = flying_sword_scene.instantiate()
	get_tree().current_scene.add_child(sword)
	sword.global_position = spawn_pos
	sword.setup(damage, aim_target, self)

# =========================================================
#  MODULE 4: THUẬT TOÁN SINH KIẾM SAU LƯNG
# =========================================================

func _calculate_spawn_position() -> Vector3:
	# Random một Vector2(x, y) trên mặt phẳng sau lưng
	var new_offset = _get_spread_offset()
	last_sword_offset = new_offset
	
	# Chuyển đổi Vector2 sang hệ tọa độ 3D cục bộ sau lưng player
	# Trục X: sang ngang (local X)
	# Trục Y: lên trên (world Y)
	# Trục Z: lùi về sau (local +Z = behind)
	var player_basis = visual_pivot.global_transform.basis
	var behind_dir = player_basis.z.normalized() # +Z = phía sau
	var right_dir = player_basis.x.normalized()  # +X = phải
	
	var spawn_pos = global_position
	spawn_pos += behind_dir * SPAWN_BEHIND_DISTANCE  # Dịch lùi sau lưng
	spawn_pos += right_dir * new_offset.x             # Dịch ngang
	spawn_pos += Vector3.UP * (new_offset.y + 1.0)    # Dịch lên (offset + chiều cao cơ bản)
	
	return spawn_pos

## Thuật toán rải đều: đảm bảo mỗi thanh kiếm không spawn quá gần thanh trước
func _get_spread_offset() -> Vector2:
	var new_offset: Vector2
	var attempts = 0
	
	while attempts < MAX_SPAWN_ATTEMPTS:
		new_offset = Vector2(
			randf_range(-2.0, 2.0),  # X: trái/phải
			randf_range(0.5, 2.5)    # Y: cao/thấp
		)
		
		# Nếu là thanh kiếm đầu tiên (offset = ZERO) thì chấp nhận luôn
		if last_sword_offset == Vector2.ZERO:
			break
		
		# Kiểm tra khoảng cách với vị trí thanh kiếm cuối
		if new_offset.distance_to(last_sword_offset) >= MIN_SWORD_DISTANCE:
			break
		
		# Quá gần → đảo ngược dấu để đẩy sang góc khác
		if attempts > MAX_SPAWN_ATTEMPTS / 2.0:
			new_offset.x *= -1.0
		if attempts > MAX_SPAWN_ATTEMPTS * 3.0 / 4.0:
			new_offset.y = 3.0 - new_offset.y # Đảo trục Y
		
		attempts += 1
	
	return new_offset
