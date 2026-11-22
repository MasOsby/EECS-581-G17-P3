class_name MapNode
extends Resource
## One room on the generated map.

var id: int = 0
var tier: int = 0           # 0 = start (bottom), highest tier = boss (top)
var lane: float = 0.0       # horizontal slot; start and boss sit in the middle
var type: String = ""       # "start", "fight", "shop", "rest" or "boss"
var encounter_path: String = "" # EncounterData resource used by fight nodes
var next: Array[int] = []   # ids of nodes one tier up that this node connects to
var prev: Array[int] = []   # ids of nodes one tier down that connect to this node
var jitter: Vector2 = Vector2.ZERO # adds jitter to the placement of nodes
