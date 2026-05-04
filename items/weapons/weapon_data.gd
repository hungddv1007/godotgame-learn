extends Resource
# WeaponData — dữ liệu phi kiếm (không dùng class_name, dùng preload)

## Dữ liệu định nghĩa loại phi kiếm
@export var weapon_name: String = "Phi Kiếm"
@export var weapon_scene: PackedScene
@export var weapon_color: Color = Color(0.85, 0.85, 0.92, 1) # Màu hiển thị UI
@export var on_hit_effects: Array = [] # Hiệu ứng áp dụng khi trúng đích (StatusEffect)
@export var description: String = "Thanh kiếm bay thường"
