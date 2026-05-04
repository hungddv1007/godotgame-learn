extends Node3D

var effect_zone_scene = preload("res://components/environment/effect_zone_3d.tscn")
var weapon_zone_scene = preload("res://components/environment/weapon_zone_3d.tscn")
var poison_script = preload("res://data/effects/dot_effect.gd")
var heal_script = preload("res://data/effects/hot_effect.gd")
var buff_script = preload("res://data/effects/buff_effect.gd")

func _ready():
	_create_poison_swamp()
	_create_fire_wall()
	_create_healing_spring()
	_create_power_buff()
	
	# Khu vực đổi vũ khí
	_create_weapon_zones()

func _create_poison_swamp():
	var effect = poison_script.new()
	effect.effect_name = "Trúng Độc"
	effect.duration = 10.0
	effect.damage_per_second = 5.0
	_spawn_zone("Vùng Độc", effect, true, Vector3(-5, 1.0, -5), Color(0.2, 0.8, 0.2, 0.5))

func _create_fire_wall():
	var effect = poison_script.new()
	effect.effect_name = "Bỏng Lửa"
	effect.duration = 0.0
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

func _create_weapon_zones():
	# 3 khu vực đổi vũ khí, đặt thành hàng ngang phía sau spawn
	_spawn_weapon_zone("⚔️ Phi Kiếm", "normal", Vector3(-6, 1.0, 8), Color(0.85, 0.85, 0.92, 0.5))
	_spawn_weapon_zone("🔥 Kiếm Lửa", "fire", Vector3(0, 1.0, 8), Color(1.0, 0.4, 0.1, 0.5))
	_spawn_weapon_zone("☠️ Kiếm Độc", "poison", Vector3(6, 1.0, 8), Color(0.3, 0.85, 0.2, 0.5))

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
	mesh_instance.position = Vector3(0, -0.9, 0)
	zone.add_child(mesh_instance)
	
	add_child(zone)

func _spawn_weapon_zone(zone_name: String, weapon_key: String, pos: Vector3, color: Color):
	var zone = weapon_zone_scene.instantiate()
	zone.zone_name = zone_name
	zone.weapon_key = weapon_key
	zone.position = pos
	
	# Tạo hình đại diện — hình hộp với viền sáng
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(3.0, 0.15, 3.0)
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = 0.5
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0, -0.9, 0)
	zone.add_child(mesh_instance)
	
	add_child(zone)
