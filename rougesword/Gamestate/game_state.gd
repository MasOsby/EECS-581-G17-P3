extends Node
## Autoload: owns run-wide state (current game state, the run's map, current
## map node, player health). Any change of game state is announced through the
## state_changed signal.

signal state_changed(new_state)
signal skill_points_changed(points: int)
enum State { MAIN_MENU, MAP, COMBAT, VICTORY, DEATH, SKILLS }

var state: State = State.MAIN_MENU
var map: MapData
var run_seed: int = 0
var current_node: int = 0          # id of the node the swordsman is standing on
var visited: Array[int] = [0]
var run_complete: bool = false     # true once the boss node is reached
var map_intro_done: bool = false   # the map's scroll-down intro plays once per run

#Player stats carried over between encounters
var player_max_health: int = 10
var player_health: int = 10

var player_gold: int = 0
var player_skillpts: int = 0
var player_xp: int = 0
var player_max_xp: int = 10
var player_level: int = 1
var player_skills: Array[SkillData] = []

## Starts a run. Pass a seed to replay a map; otherwise a random one is chosen.
func start_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		var picker := RandomNumberGenerator.new()
		picker.randomize()
		seed_value = picker.randi_range(0, 999999)
	run_seed = seed_value
	map = MapData.generate(run_seed)
	current_node = 0
	visited = [0]
	run_complete = false
	map_intro_done = false
	reset_player_progress()
	change_state(State.MAP)

func arrive_at(node_id: int) -> void:
	current_node = node_id
	if node_id not in visited:
		visited.append(node_id)

func change_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)

func reset_player_progress() -> void:
	player_health = player_max_health
	player_gold = 0
	player_skillpts = 0
	player_xp = 0
	player_max_xp = 10
	player_level = 1
	player_skills.clear()

func current_encounter() -> EncounterData:
	return load(map.nodes[current_node].encounter_path) as EncounterData

func has_skill(skill: SkillData) -> bool:
	for owned in player_skills:
		if owned.skill_id == skill.skill_id:
			return true
	return false

func try_unlock_skill(skill: SkillData) -> bool:
	if has_skill(skill):
		return true
	if player_skillpts < skill.point_cost:
		return false
	player_skillpts -= skill.point_cost
	player_skills.append(skill)
	skill_points_changed.emit(player_skillpts)
	return true
