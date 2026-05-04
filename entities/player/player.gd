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
signal weapon_changed(weapon_data) # Signal thông báo UI khi đổi vũ khí

var attack_cooldown_timer: float = 0.0
var last_sword_offset: Vector2 = Vector2.ZERO
const MIN_SWORD_DISTANCE: float = 1.5
const SPAWN_BEHIND_DISTANCE: float = 1.5
const MAX_SPAWN_ATTEMPTS: int = 10

# Hệ thống đa vũ khí — dữ liệu vũ khí hiện tại
var current_weapon = null # WeaponData Resource hiện tại
var _weapon_definitions: Dictionary = {} # Lưu cache {name: WeaponData}

# Preload tất cả loại kiếm
var _normal_sword_scene = preload("res://items/weapons/flying_sword/flying_sword.tscn")
var _fire_sword_scene = preload("res://items/weapons/flying_sword/fire_sword.tscn")
var _poison_sword_scene = preload("res://items/weapons/flying_sword/poison_sword.tscn")
var _dot_script = preload("res://data/effects/dot_effect.gd")
var _weapon_data_script = preload("res://items/weapons/weapon_data.gd")

func _ready():
	spring_arm.top_level = true
	spring_arm.add_excluded_object(self.get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Khởi tạo bộ vũ khí
	_init_weapons()
	
	# Pre-warm tất cả loại kiếm
	_prewarm_flying_sword.call_deferred()

func _init_weapons():
	# === PHI KIẾM THƯỜNG ===
	var normal = _weapon_data_script.new()
	normal.weapon_name = "Phi Kiếm"
	normal.weapon_scene = _normal_sword_scene
	normal.weapon_color = Color(0.85, 0.85, 0.92, 1)
	normal.description = "Thanh kiếm bay tiêu chuẩn"
	_weapon_definitions["normal"] = normal
	
	# === PHI KIẾM LỬA ===
	var fire = _weapon_data_script.new()
	fire.weapon_name = "Kiếm Lửa"
	fire.weapon_scene = _fire_sword_scene
	fire.weapon_color = Color(1.0, 0.4, 0.1, 1)
	fire.description = "Thiêu đốt mục tiêu"
	# Tạo hiệu ứng cháy
	var burn_effect = _dot_script.new()
	burn_effect.effect_name = "Bỏng Lửa"
	burn_effect.effect_id = "weapon_burn"
	burn_effect.duration = 5.0
	burn_effect.damage_per_second = 8.0
	burn_effect.stackable = true
	burn_effect.max_stacks = 3
	burn_effect.tags_to_apply.assign(["burning"])
	fire.on_hit_effects = [burn_effect]
	_weapon_definitions["fire"] = fire
	
	# === PHI KIẾM ĐỘC ===
	var poison = _weapon_data_script.new()
	poison.weapon_name = "Kiếm Độc"
	poison.weapon_scene = _poison_sword_scene
	poison.weapon_color = Color(0.3, 0.85, 0.2, 1)
	poison.description = "Nhiễm độc mục tiêu"
	# Tạo hiệu ứng độc
	var poison_effect = _dot_script.new()
	poison_effect.effect_name = "Trúng Độc"
	poison_effect.effect_id = "weapon_poison"
	poison_effect.duration = 8.0
	poison_effect.damage_per_second = 4.0
	poison_effect.stackable = true
	poison_effect.max_stacks = 5
	poison_effect.tags_to_apply.assign(["poisoned"])
	poison.on_hit_effects = [poison_effect]
	_weapon_definitions["poison"] = poison
	
	# Mặc định dùng phi kiếm thường
	equip_weapon("normal")

## Đổi vũ khí — được gọi từ WeaponZone hoặc phím tắt
func equip_weapon(weapon_key: String) -> void:
	if _weapon_definitions.has(weapon_key):
		current_weapon = _weapon_definitions[weapon_key]
		weapon_changed.emit(current_weapon)
		print("[Weapon] Đã trang bị: ", current_weapon.weapon_name)

func _prewarm_flying_sword():
	# Pre-warm tất cả scene kiếm để tránh stutter lần đầu
	var scenes_to_warm = [_normal_sword_scene, _fire_sword_scene, _poison_sword_scene]
	for scene in scenes_to_warm:
		var dummy = scene.instantiate()
		dummy.set_physics_process(false)
		dummy.set_process(false)
		dummy.set_deferred("monitoring", false)
		dummy.set_deferred("monitorable", false)
		get_tree().current_scene.add_child(dummy)
		dummy.global_position = Vector3(0, -999, 0)
		dummy.scale = Vector3.ONE
	# Xóa tất cả sau 2 frame
	get_tree().process_frame.connect(func():
		get_tree().process_frame.connect(func():
			for child in get_tree().current_scene.get_children():
				if child is FlyingSword and child.global_position.y < -900:
					child.queue_free()
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)

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
	
	if input_dir == Vector2.ZERO:
		idle_time += delta
	else:
		idle_time = 0.0
	
	var direction = (spring_arm.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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
		visual_pivot.global_rotation.y = lerp_angle(visual_pivot.global_rotation.y, spring_arm.rotation.y, turn_speed * 3.0 * delta)
	elif direction != Vector3.ZERO:
		var target_angle = atan2(-direction.x, -direction.z)
		visual_pivot.global_rotation.y = lerp_angle(visual_pivot.global_rotation.y, target_angle, turn_speed * delta)
	elif direction == Vector3.ZERO and idle_time >= 0.5:
		pass

	move_and_slide()

# =========================================================
#  TÂM NGẮM & NHẮM BẮN TPS
# =========================================================

func get_aim_target() -> Vector3:
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().size / 2.0
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)
	var ray_end = ray_origin + ray_direction * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self.get_rid()]
	query.collision_mask = 0xFFFFFFFF
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	else:
		return ray_origin + ray_direction * 1000.0

# =========================================================
#  PHÓNG KIẾM (FIRE SWORD) — Dùng current_weapon
# =========================================================

func fire_sword():
	if not current_weapon:
		return
	
	var atk_speed = stats_manager.get_stat("attack_speed")
	attack_cooldown_timer = 1.0 / atk_speed
	
	var aim_target = get_aim_target()
	
	# Tạo DamageData động
	var current_atk = stats_manager.get_stat("attack_damage")
	var damage = DamageData.new()
	damage.amount = current_atk
	damage.damage_type = DamageData.DamageType.PHYSICAL
	
	var spawn_pos = _calculate_spawn_position()
	
	# Instantiate kiếm theo loại vũ khí hiện tại
	var sword = current_weapon.weapon_scene.instantiate()
	get_tree().current_scene.add_child(sword)
	sword.global_position = spawn_pos
	sword.setup(damage, aim_target, self, current_weapon.on_hit_effects)

# =========================================================
#  THUẬT TOÁN SINH KIẾM SAU LƯNG
# =========================================================

func _calculate_spawn_position() -> Vector3:
	var new_offset = _get_spread_offset()
	last_sword_offset = new_offset
	
	var player_basis = visual_pivot.global_transform.basis
	var behind_dir = player_basis.z.normalized()
	var right_dir = player_basis.x.normalized()
	
	var spawn_pos = global_position
	spawn_pos += behind_dir * SPAWN_BEHIND_DISTANCE
	spawn_pos += right_dir * new_offset.x
	spawn_pos += Vector3.UP * (new_offset.y + 1.0)
	
	return spawn_pos

func _get_spread_offset() -> Vector2:
	var new_offset: Vector2
	var attempts = 0
	
	while attempts < MAX_SPAWN_ATTEMPTS:
		new_offset = Vector2(
			randf_range(-2.0, 2.0),
			randf_range(0.5, 2.5)
		)
		
		if last_sword_offset == Vector2.ZERO:
			break
		
		if new_offset.distance_to(last_sword_offset) >= MIN_SWORD_DISTANCE:
			break
		
		if attempts > MAX_SPAWN_ATTEMPTS / 2.0:
			new_offset.x *= -1.0
		if attempts > MAX_SPAWN_ATTEMPTS * 3.0 / 4.0:
			new_offset.y = 3.0 - new_offset.y
		
		attempts += 1
	
	return new_offset
