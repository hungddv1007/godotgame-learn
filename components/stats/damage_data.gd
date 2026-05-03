extends Resource
class_name DamageData

enum DamageType { PHYSICAL, MAGIC, TRUE }

@export var amount: float = 0.0
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var flat_pen: float = 0.0
@export var percent_pen: float = 0.0 # 0.0 đến 1.0 (ví dụ 0.3 = 30% xuyên)
