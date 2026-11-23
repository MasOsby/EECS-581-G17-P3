class_name Enemy
extends Combatant
## An enemy built from an EnemyData resource.

var gold_reward: int = 0
var xp_reward: int = 0

func _init(data: EnemyData) -> void:
	combatant_name = data.enemy_name
	max_health = data.health
	health = data.health
	base_damage = data.base_damage
	base_speed = data.speed
	gold_reward = data.gold_reward
	xp_reward = data.xp_reward
