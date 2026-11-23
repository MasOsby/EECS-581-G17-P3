class_name Player
extends Combatant
## The swordsman. Health, gold, XP and unlocked skills persist between fights
## through GameState. Skill cooldowns do not: they start fresh every fight.

signal gold_changed(new_gold: int)
signal xp_changed(new_xp: int, new_max: int)
signal level_changed(new_level: int)
signal skill_pts_changed(new_skill_pts: int)
signal cooldowns_changed

var gold: int = 0:
	set(value):
		gold = max(0, value)
		gold_changed.emit(gold)

#Init XP
var xp: int = 0
var max_xp: int = 10

#Player Level
var level: int = 1

#Skill points
var skill_pts: int = 0

## Skills unlocked in the skill tree (copied from GameState at fight start).
var unlocked_skills: Array[SkillData] = []

# skill_id -> turns left before the skill can be used again
var _cooldowns: Dictionary = {}

func _init() -> void:
	#Init base stats
	combatant_name = "Swordsman"
	max_health = GameState.player_max_health
	health = GameState.player_health
	base_damage = 2
	base_speed = 2

	gold = GameState.player_gold
	xp = GameState.player_xp
	max_xp = GameState.player_max_xp
	skill_pts = GameState.player_skillpts
	level = GameState.player_level
	unlocked_skills = GameState.player_skills.duplicate()

#XP Gain functions
func gain_xp(amount: int) -> void:
	xp += amount

	#Level up character
	while xp >= max_xp:
		xp -= max_xp
		level += 1
		skill_pts += 1

		#+1 Level
		level_changed.emit(level)
		#+1 Skill point
		skill_pts_changed.emit(skill_pts)

		max_xp = maxi(max_xp + 1, int(round(max_xp * 1.05)))

	xp_changed.emit(xp, max_xp)

# Skills and cooldowns

## Turns left before `skill` is usable again (0 = ready).
func cooldown_remaining(skill: SkillData) -> int:
	return _cooldowns.get(skill.skill_id, 0)

func is_skill_ready(skill: SkillData) -> bool:
	return cooldown_remaining(skill) == 0

## Hits the targets with a skill and starts its cooldown.
## Returns false (and does nothing) if the skill is still cooling down.
func use_skill(skill: SkillData, targets: Array[Enemy]) -> bool:
	if not is_skill_ready(skill):
		return false
	for _hit in skill.hits:
		for target in targets:
			if target.alive:
				target.take_damage(skill.damage_against(base_damage, target))
	if skill.cooldown > 0:
		# +1 because the end-of-round tick of the round it was used in doesn't
		# count: "cooldown 2" means the next 2 turns are blocked.
		_cooldowns[skill.skill_id] = skill.cooldown + 1
	cooldowns_changed.emit()
	return true

## Called once per round (after the enemies act): every cooldown drops by 1.
func tick_cooldowns() -> void:
	for id in _cooldowns.keys():
		_cooldowns[id] -= 1
		if _cooldowns[id] <= 0:
			_cooldowns.erase(id)
	cooldowns_changed.emit()
