extends Node
## Autoload: owns run-wide state (current game state, the run's map, current
## map node, player health). Any change of game state is announced through the
## state_changed signal.

signal state_changed(new_state)
enum State { MAIN_MENU, MAP, COMBAT, VICTORY, DEATH, SKILLS }

var state: State = State.MAIN_MENU
var map: MapData
var run_seed: int = 0
var current_node: int = 0          # id of the node the swordsman is standing on
var visited: Array[int] = [0]
var run_complete: bool = false     # true once the boss node is reached
var map_intro_done: bool = false   # the map's scroll-down intro plays once per run
var player_max_health: int = 10
var player_health: int = 10

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
	player_health = player_max_health
	change_state(State.MAP)

func arrive_at(node_id: int) -> void:
	current_node = node_id
	if node_id not in visited:
		visited.append(node_id)

func change_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)

func current_encounter() -> EncounterData:
	return load(map.nodes[current_node].encounter_path) as EncounterData
