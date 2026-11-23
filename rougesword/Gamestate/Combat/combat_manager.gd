class_name CombatManager
extends Node
## Runs the turn loop. The swordsman acts once (basic attack or a skill), then
## every living enemy acts. Skill cooldowns tick down once per round.
## Combat ends when the player dies or every enemy is dead.

signal turn_changed(turn: Turn)
signal combat_finished(player_won: bool)
enum Turn { PLAYER_TURN, ENEMY_TURN, FINISHED }
var turn: Turn = Turn.PLAYER_TURN
var turn_indicator: int = 1
var player: Player
var enemies: Array[Enemy] = []

func setup(p: Player, wave: Array[Enemy]) -> void:
	player = p
	enemies = wave
	turn = Turn.PLAYER_TURN
	turn_indicator = 1

func living_enemies() -> Array[Enemy]:
	var living: Array[Enemy] = []
	for enemy in enemies:
		if enemy.alive:
			living.append(enemy)
	return living

func all_enemies_dead() -> bool:
	return living_enemies().is_empty()

func player_attack(target: Enemy) -> void:
	if turn != Turn.PLAYER_TURN or target == null or not target.alive:
		return
	player.attack(target)
	_end_player_action()

## Uses a skill. `target` is the selected enemy; skills that hit all enemies
## ignore it. Returns false (and the turn is NOT spent) if the skill is on
## cooldown, isn't one the player has unlocked, or there's nothing to hit.
func player_use_skill(skill: SkillData, target: Enemy) -> bool:
	if turn != Turn.PLAYER_TURN or skill == null:
		return false
	var targets: Array[Enemy] = []
	if skill.hits_all_enemies:
		targets = living_enemies()
	elif target != null and target.alive:
		targets.append(target)
	if targets.is_empty():
		return false
	if not player.use_skill(skill, targets):
		return false
	_end_player_action()
	return true

func _end_player_action() -> void:
	if all_enemies_dead():
		_finish(true)
	else:
		turn = Turn.ENEMY_TURN
		turn_changed.emit(turn)

func enemy_attack(attacker: Enemy) -> void:
	if turn != Turn.ENEMY_TURN or attacker == null or not attacker.alive or not player.alive:
		return
	attacker.attack(player)
	if not player.alive:
		_finish(false)

func end_enemy_round() -> void:
	if turn != Turn.ENEMY_TURN:
		return
	player.tick_cooldowns()
	turn_indicator += 1
	turn = Turn.PLAYER_TURN
	turn_changed.emit(turn)

func _finish(player_won: bool) -> void:
	turn = Turn.FINISHED
	combat_finished.emit(player_won)
