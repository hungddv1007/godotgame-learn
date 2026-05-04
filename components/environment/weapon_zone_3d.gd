extends Area3D

## Khu vực đổi vũ khí — Khi player bước vào sẽ tự động đổi sang loại kiếm được chỉ định
@export var zone_name: String = "Khu vực Vũ khí"
@export var weapon_key: String = "normal" # Key trong _weapon_definitions của player

func _ready():
	$Label3D.text = zone_name
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	# Chỉ xử lý nếu đối tượng là Player và có hàm equip_weapon
	if body.has_method("equip_weapon"):
		body.equip_weapon(weapon_key)
