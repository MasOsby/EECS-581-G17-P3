class_name SkillData
extends Resource
## One combat ability, stored as a .tres so new skills need no code changes.
## Cooldown is counted in turns: a skill with cooldown 2 used on turn 1 is
## unavailable on turns 2 and 3 and ready again on turn 4.

@export var skill_id: StringName = &""
@export var display_name: String = "Skill"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var point_cost: int = 1          # skill points spent to unlock it in the tree

@export_group("Combat")
@export var cooldown: int = 2            # turns you must wait after using it (0 = none)
@export var damage_multiplier: float = 1.0   # of the swordsman's base damage, per hit
@export var hits: int = 1                # how many times it hits each target
@export var hits_all_enemies: bool = false   # true = ignores the selected target
@export var execute_threshold: float = 0.0   # >0: kills a target at or below this fraction of its max health
@export var animation: StringName = &"Attack" # swordsman animation to play

## Damage this skill deals to `target` in one hit.
func damage_against(user_damage: int, target: Combatant) -> int:
	if execute_threshold > 0.0 and target.health <= int(ceil(target.max_health * execute_threshold)):
		return target.health
	return maxi(1, roundi(user_damage * damage_multiplier))
