class_name Enemy
extends Combatant
## An enemy built from an EnemyData resource.

func _init(data: EnemyData) -> void:
	combatant_name = data.enemy_name
	max_health = data.health
	health = data.health
	base_damage = data.base_damage
	base_speed = data.speed
