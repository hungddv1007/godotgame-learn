extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var spring_arm = $SpringArm3D
@onready var visual_pivot = $VisualPivot
@export var mouse_sensitivity = 0.003

var idle_time = 0.0
var combat_timer = 0.0
var is_in_combat = false
var turn_speed = 10.0

func _ready():
	spring_arm.top_level = true
	spring_arm.add_excluded_object(self.get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta):
	# Update SpringArm3D position
	var target_pos = global_position + Vector3(0, 1.5, 0) + spring_arm.global_transform.basis.x * 0.5
	spring_arm.global_position = spring_arm.global_position.lerp(target_pos, 20.0 * delta)

	# Combat State Logic
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		is_in_combat = true
		combat_timer = 0.0
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
