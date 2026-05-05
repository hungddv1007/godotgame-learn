extends Area3D

## Pickup Item — Vật phẩm nhặt được (Vũ khí hoặc Cường hóa)
## Lơ lửng, xoay tròn, nhấp lên xuống. Khi player chạm → hiện prompt [E]/[Q]/[Esc]

enum PickupType { WEAPON, ENHANCEMENT }

@export var pickup_type: PickupType = PickupType.WEAPON
@export var item_name: String = "Vật phẩm"
@export var description: String = ""
@export var item_color: Color = Color.WHITE

# === WEAPON ===
@export var weapon_key: String = "" # Key trong player._weapon_definitions

# === ENHANCEMENT (Cường hóa) ===
@export var stat_name: String = "attack_damage"
@export var modifier_value: float = 10.0
@export var modifier_is_percent: bool = false # false=FLAT, true=PERCENT
@export var enhancement_mesh_type: String = "sphere" # sphere, box, cylinder

# === ANIMATION ===
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.15
@export var rotate_speed: float = 1.5
@export var float_height: float = 0.8
@export var tilt_angle: float = 30.0

var _base_y: float = 0.0
var _time: float = 0.0
var _visual_pivot: Node3D
var _light: OmniLight3D
var _is_collected: bool = false

func _ready():
	_base_y = position.y + float_height
	
	# Visual pivot xử lý rotation riêng
	_visual_pivot = Node3D.new()
	_visual_pivot.rotation_degrees.x = -tilt_angle # Nghiêng 30 độ
	add_child(_visual_pivot)
	
	# Setup visual dựa trên loại
	if pickup_type == PickupType.WEAPON:
		_setup_weapon_visual()
	else:
		_setup_enhancement_visual()
	
	# Glow light — phát sáng để dễ nhìn từ xa
	_light = OmniLight3D.new()
	_light.light_color = item_color
	_light.light_energy = 0.8
	_light.omni_range = 3.0
	_light.omni_attenuation = 1.5
	add_child(_light)
	
	# Label3D hiển thị tên vật phẩm
	$Label3D.text = item_name
	$Label3D.modulate = item_color
	
	# Kết nối signal
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_weapon_visual():
	# Preload scene vũ khí tương ứng
	var weapon_scenes = {
		"normal": preload("res://items/weapons/flying_sword/flying_sword.tscn"),
		"fire": preload("res://items/weapons/flying_sword/fire_sword.tscn"),
		"poison": preload("res://items/weapons/flying_sword/poison_sword.tscn"),
	}
	if weapon_scenes.has(weapon_key):
		var model = weapon_scenes[weapon_key].instantiate()
		# Xóa script để không chạy logic chiến đấu
		model.set_script(null)
		# Xóa collision shape — chỉ giữ mesh visual
		var col = model.get_node_or_null("CollisionShape3D")
		if col:
			col.queue_free()
		_visual_pivot.add_child(model)

func _setup_enhancement_visual():
	var mesh_instance = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = item_color
	mat.emission_enabled = true
	mat.emission = item_color
	mat.emission_energy_multiplier = 0.5
	
	match enhancement_mesh_type:
		"sphere":
			var mesh = SphereMesh.new()
			mesh.radius = 0.3
			mesh.height = 0.6
			mesh.material = mat
			mesh_instance.mesh = mesh
		"box":
			var mesh = BoxMesh.new()
			mesh.size = Vector3(0.4, 0.4, 0.4)
			mesh.material = mat
			mesh_instance.mesh = mesh
		"cylinder":
			var mesh = CylinderMesh.new()
			mesh.top_radius = 0.25
			mesh.bottom_radius = 0.25
			mesh.height = 0.5
			mesh.material = mat
			mesh_instance.mesh = mesh
		_:
			var mesh = SphereMesh.new()
			mesh.radius = 0.3
			mesh.height = 0.6
			mesh.material = mat
			mesh_instance.mesh = mesh
	
	_visual_pivot.add_child(mesh_instance)

func _process(delta):
	if _is_collected:
		return
	_time += delta
	# Bobbing — nhấp lên xuống nhẹ nhàng
	position.y = _base_y + sin(_time * bob_speed) * bob_height
	# Rotation — xoay tròn liên tục
	_visual_pivot.rotate_y(rotate_speed * delta)
	# Light pulse nhẹ
	if _light:
		_light.light_energy = 0.6 + sin(_time * 3.0) * 0.2

func _on_body_entered(body: Node3D):
	if body.has_method("on_pickup_enter"):
		body.on_pickup_enter(self)

func _on_body_exited(body: Node3D):
	if body.has_method("on_pickup_exit"):
		body.on_pickup_exit(self)

## Nhặt vật phẩm — hiệu ứng thu nhỏ rồi biến mất
func collect():
	if _is_collected:
		return
	_is_collected = true
	set_process(false)
	# Hiệu ứng: flash sáng → thu nhỏ → biến mất
	if _light:
		_light.light_energy = 3.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.25)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)

## Phân rã vật phẩm — hiệu ứng chớp đỏ rồi biến mất
func decompose():
	if _is_collected:
		return
	_is_collected = true
	set_process(false)
	# Hiệu ứng: chuyển đỏ → co lại → biến mất
	if _light:
		_light.light_color = Color.RED
		_light.light_energy = 2.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 1.3, 0.1)
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.15)
	tween.tween_callback(queue_free)

## Lấy mô tả đầy đủ cho UI prompt
func get_full_description() -> String:
	if pickup_type == PickupType.WEAPON:
		return description
	else:
		var prefix = "+" if modifier_value >= 0 else ""
		if modifier_is_percent:
			return "%s: %s%.0f%%" % [stat_name, prefix, modifier_value * 100]
		else:
			return "%s: %s%.0f" % [stat_name, prefix, modifier_value]
