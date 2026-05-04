extends Node3D

var effect_zone_scene = preload("res://components/environment/effect_zone_3d.tscn")
var poison_script = preload("res://data/effects/dot_effect.gd")
var heal_script = preload("res://data/effects/hot_effect.gd")
var buff_script = preload("res://data/effects/buff_effect.gd")

func _ready():
	_create_poison_swamp()
	_create_fire_wall()
	_create_healing_spring()
	_create_power_buff()

func _create_poison_swamp():
	var effect = poison_script.new()
	effect.effect_name = "Trúng Độc"
	effect.duration = 10.0
	effect.damage_per_second = 5.0
	_spawn_zone("Vùng Độc", effect, true, Vector3(-5, 1.0, -5), Color(0.2, 0.8, 0.2, 0.5))

func _create_fire_wall():
	var effect = poison_script.new()
	effect.effect_name = "Bỏng Lửa"
	effect.duration = 0.0 # Bằng 0 để chỉ tác dụng khi đứng trong vùng
	effect.damage_per_second = 15.0
	_spawn_zone("Vùng Lửa", effect, false, Vector3(5, 1.0, -5), Color(0.8, 0.2, 0.1, 0.5))

func _create_healing_spring():
	var effect = heal_script.new()
	effect.effect_name = "Hồi Máu"
	effect.duration = 0.0
	effect.hp_per_second = 20.0
	effect.mp_per_second = 10.0
	_spawn_zone("Suối Tiên", effect, false, Vector3(-5, 1.0, 5), Color(0.2, 0.5, 0.8, 0.5))

func _create_power_buff():
	var effect = buff_script.new()
	effect.effect_name = "Sức Mạnh"
	effect.duration = 15.0
	effect.stat_to_buff = "attack_damage"
	effect.modifier_type = StatsManager.ModifierType.FLAT
	effect.buff_amount = 50.0
	_spawn_zone("Vòng Buff", effect, true, Vector3(5, 1.0, 5), Color(0.8, 0.8, 0.2, 0.5))

func _spawn_zone(zone_name: String, effect: StatusEffect, is_instant: bool, pos: Vector3, color: Color):
	var zone = effect_zone_scene.instantiate()
	zone.zone_name = zone_name
	zone.zone_effect = effect
	zone.is_instant_zone = is_instant
	zone.position = pos
	
	# Tạo một mặt phẳng đại diện cho vùng
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.height = 0.2
	mesh.top_radius = 2.0
	mesh.bottom_radius = 2.0
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0, -0.9, 0) # Gắn sát mặt đất
	zone.add_child(mesh_instance)
	
	add_child(zone)
