class_name MapData
extends Resource

const MIN_TIERS := 8
const MAX_TIERS := 10
const MIN_LANES := 3
const MAX_LANES := 4
const STRAIGHT_CHANCE := 0.7
const DIAGONAL_CHANCE := 0.4
const NODE_SPAWN_CHANCE := 0.75
const JITTER_X := 16.0
const JITTER_Y := 14.0
const TYPE_WEIGHTS := {"fight": 60, "shop": 25, "rest": 15}
const ENEMY_POOL := ["res://Combatant/Enemy/data/enemy_bat.tres"]

var map_seed: int = 0
var tier_count: int = 0
var lane_count: int = 0
var nodes: Array[MapNode] = []
var tiers: Array = []        # tiers[t] = node ids in tier t, ordered by lane
var repairs_made: int = 0    # how many connections repair() had to add
var _rng := RandomNumberGenerator.new()

static func generate(seed_value: int) -> MapData:
	var result := MapData.new()
	result._build(seed_value)
	return result

func boss_id() -> int:
	return tiers[tier_count - 1][0]

# generation
func _build(seed_value: int) -> void:
	map_seed = seed_value
	_rng.seed = seed_value
	tier_count = _rng.randi_range(MIN_TIERS, MAX_TIERS)
	lane_count = _rng.randi_range(MIN_LANES, MAX_LANES)
	_create_nodes()
	_connect_tiers()
	repair()
	_assign_types()
	_assign_enemies()
	var problems := validate()
	if not problems.is_empty():
		push_error("Map for seed %d is invalid: %s" % [seed_value, ", ".join(problems)])

func _add_node(tier: int, lane: float) -> MapNode:
	var n := MapNode.new()
	n.id = nodes.size()
	n.tier = tier
	n.lane = lane
	if tier > 0 and tier < tier_count - 1:
		n.jitter = Vector2(
			_rng.randf_range(-JITTER_X, JITTER_X),
			_rng.randf_range(-JITTER_Y, JITTER_Y)
		)
	nodes.append(n)
	tiers[tier].append(n.id)
	return n

func _create_nodes() -> void:
	nodes.clear()
	tiers.clear()
	for t in tier_count:
		tiers.append([])
	var middle := (lane_count - 1) / 2.0
	_add_node(0, middle)                     # start
	for lane in lane_count:
		_add_node(1, float(lane))            # full opening row
	for t in range(2, tier_count - 1):
		for lane in lane_count:
			if _rng.randf() < NODE_SPAWN_CHANCE:
				_add_node(t, float(lane))
		if tiers[t].is_empty():
			_add_node(t, float(_rng.randi_range(0, lane_count - 1)))
	_add_node(tier_count - 1, middle)        # boss

func _link(a: int, b: int) -> void:
	if b in nodes[a].next:
		return
	nodes[a].next.append(b)
	nodes[b].prev.append(a)

func _connect_tiers() -> void:
	# The start node opens onto every lane of the first tier.
	for id in tiers[1]:
		_link(0, id)
	# Random forward connections between the full tiers.
	for t in range(1, tier_count - 2):
		_random_edges(t)
	# Everything in the last tier before the boss leads to the boss.
	for id in tiers[tier_count - 2]:
		_link(id, boss_id())

func _random_edges(t: int) -> void:
	var lower: Array = tiers[t]
	var upper: Array = tiers[t + 1]
	for i in lower.size():
		var lane_a: float = nodes[lower[i]].lane
		for j in upper.size():
			var lane_diff := absf(nodes[upper[j]].lane - lane_a)
			if lane_diff > 1.0:
				continue
			var chance := STRAIGHT_CHANCE if is_zero_approx(lane_diff) else DIAGONAL_CHANCE
			# Always roll so the random sequence stays the same for a seed.
			if _rng.randf() < chance and not _crosses_existing(t, i, j):
				_link(lower[i], upper[j])

# Pairs of (index in tier t, index in tier t+1) for every edge between them.
func _edges_between(t: int) -> Array:
	var result := []
	var upper: Array = tiers[t + 1]
	for ia in tiers[t].size():
		for nx in nodes[tiers[t][ia]].next:
			result.append(Vector2i(ia, upper.find(nx)))
	return result

func _crosses_existing(t: int, i: int, j: int) -> bool:
	for e in _edges_between(t):
		if (e.x < i and e.y > j) or (e.x > i and e.y < j):
			return true
	return false

# repair
func repair() -> int:
	var fixes := 0
	# Bottom-up: every node above the start needs an incoming connection.
	for t in range(1, tier_count - 1):
		for j in tiers[t].size():
			var id: int = tiers[t][j]
			if nodes[id].prev.is_empty():
				_link(tiers[t - 1][_pick_source(t - 1, j)], id)
				fixes += 1
	# Top-down: every node below the boss needs an outgoing connection.
	for t in range(tier_count - 1):
		for i in tiers[t].size():
			var id: int = tiers[t][i]
			if nodes[id].next.is_empty():
				_link(id, tiers[t + 1][_pick_target(t, i)])
				fixes += 1
	repairs_made = fixes
	return fixes

# Source index in tier t_lower that can connect to upper[j] without crossing.
func _pick_source(t_lower: int, j: int) -> int:
	var lower: Array = tiers[t_lower]
	var upper: Array = tiers[t_lower + 1]
	var lo := 0
	var hi := lower.size() - 1
	for ia in lower.size():
		for nx in nodes[lower[ia]].next:
			var jb := upper.find(nx)
			if jb < j:
				lo = maxi(lo, ia)
			elif jb > j:
				hi = mini(hi, ia)
	return _closest(lower, lo, hi, nodes[upper[j]].lane)

# Target index in tier t+1 that lower[i] can connect to without crossing.
func _pick_target(t: int, i: int) -> int:
	var lower: Array = tiers[t]
	var upper: Array = tiers[t + 1]
	var lo := 0
	var hi := upper.size() - 1
	for ia in lower.size():
		for nx in nodes[lower[ia]].next:
			var jb := upper.find(nx)
			if ia < i:
				lo = maxi(lo, jb)
			elif ia > i:
				hi = mini(hi, jb)
	return _closest(upper, lo, hi, nodes[lower[i]].lane)

# Index in [lo, hi] whose node is horizontally closest to the given lane.
func _closest(tier_ids: Array, lo: int, hi: int, lane: float) -> int:
	if lo > hi:
		push_warning("Map repair found no non-crossing option")
		return lo
	var best := lo
	var best_dist := INF
	for i in range(lo, hi + 1):
		var d := absf(nodes[tier_ids[i]].lane - lane)
		if d < best_dist:
			best_dist = d
			best = i
	return best

# validation
func validate() -> PackedStringArray:
	var problems := PackedStringArray()

	if tiers[tier_count - 1].size() != 1:
		problems.append("top tier must hold exactly one boss node")

	var reachable := {0: true}
	for t in range(tier_count - 1):
		for id in tiers[t]:
			if reachable.has(id):
				for nx in nodes[id].next:
					reachable[nx] = true
	var leads_to_boss := {boss_id(): true}
	for t in range(tier_count - 1, 0, -1):
		for id in tiers[t]:
			if leads_to_boss.has(id):
				for pv in nodes[id].prev:
					leads_to_boss[pv] = true

	for n in nodes:
		if n.tier > 0 and n.prev.is_empty():
			problems.append("node %d has no incoming connection" % n.id)
		if n.tier < tier_count - 1 and n.next.is_empty():
			problems.append("node %d has no outgoing connection" % n.id)
		if not reachable.has(n.id):
			problems.append("node %d is unreachable from the start" % n.id)
		if not leads_to_boss.has(n.id):
			problems.append("node %d does not lead to the boss" % n.id)

	for t in range(tier_count - 1):
		var edges := _edges_between(t)
		for a in edges:
			for b in edges:
				if a.x < b.x and a.y > b.y:
					problems.append("connections cross between tiers %d and %d" % [t, t + 1])

	if nodes[0].type != "":
		problems.append_array(_validate_types())
	return problems

func _validate_types() -> PackedStringArray:
	var problems := PackedStringArray()
	var shops := 0
	for n in nodes:
		if n.type == "shop":
			shops += 1
			for nx in n.next:
				if nodes[nx].type == "shop":
					problems.append("shops %d and %d are back to back" % [n.id, nx])
	if shops == 0:
		problems.append("map has no shop")
	for id in tiers[tier_count - 2]:
		if nodes[id].type != "rest":
			problems.append("node %d before the boss is not a rest node" % id)
	return problems

# node types
func _assign_types() -> void:
	nodes[0].type = "start"
	nodes[boss_id()].type = "boss"
	for id in tiers[1]:
		nodes[id].type = "fight"           # guaranteed easy opening tier
	for id in tiers[tier_count - 2]:
		nodes[id].type = "rest"            # guaranteed rest before the boss
	for t in range(2, tier_count - 2):
		for id in tiers[t]:
			nodes[id].type = _roll_type(not _has_shop_before(id))
	_ensure_shop()

func _has_shop_before(id: int) -> bool:
	for pv in nodes[id].prev:
		if nodes[pv].type == "shop":
			return true
	return false

func _roll_type(allow_shop: bool) -> String:
	var total := 0
	for kind in TYPE_WEIGHTS:
		if kind != "shop" or allow_shop:
			total += TYPE_WEIGHTS[kind]
	var roll := _rng.randi_range(0, total - 1)
	for kind in TYPE_WEIGHTS:
		if kind == "shop" and not allow_shop:
			continue
		roll -= TYPE_WEIGHTS[kind]
		if roll < 0:
			return kind
	return "fight"

# Rolls can leave a map with no shop; force one onto a random middle node.
func _ensure_shop() -> void:
	var candidates: Array[int] = []
	for n in nodes:
		if n.type == "shop":
			return
	for t in range(2, tier_count - 2):
		for id in tiers[t]:
			candidates.append(id)
	var pick: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
	nodes[pick].type = "shop"

func _assign_enemies() -> void:
	for n in nodes:
		if n.type == "fight":
			n.enemy_path = ENEMY_POOL[_rng.randi_range(0, ENEMY_POOL.size() - 1)]

## Text fingerprint of the whole map, used to compare two maps for equality.
func signature() -> String:
	var parts := PackedStringArray(["%d|%d" % [tier_count, lane_count]])
	for n in nodes:
		parts.append("%d:%s:%s:%s" % [n.id, n.type, n.enemy_path, str(n.next)])
	return ";".join(parts)
