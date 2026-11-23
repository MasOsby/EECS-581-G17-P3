class_name Player
extends Combatant
## The swordsman. Health persists between fights through GameState.

signal gold_changed(new_gold: int)
signal xp_changed(new_xp: int, new_max: int)
signal level_changed(new_level: int)
signal skill_pts_changed(new_skill_pts: int)

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

#Prototype for skill tracking (?)
#Track available skills
#var unlocked_skills: Dictionary = {}
#
#func unlock_skill(skill: SkillData) -> void:
	#unlocked_skills[skill.skill_id] = skill
#
#func is_unlocked(skill_id: StringName) -> bool:
	#return unlocked_skills.has(skill_id)
	
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
	

func _init() -> void:
	#Init base stats
	combatant_name = "Swordsman"
	max_health = GameState.player_max_health
	health = GameState.player_health
	base_damage = 2
	base_speed = 2
	
	gold = GameState.player_gold
	xp = GameState.player_xp
	skill_pts = GameState.player_skillpts
	level = GameState.player_level
	

	
	
	
	
	
