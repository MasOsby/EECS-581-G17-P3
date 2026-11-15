extends Control
## Map state: the generated map, drawn vertically with the start at the bottom
## and the boss at the top. The view scrolls (mouse wheel, drag, or Up/Down
## keys) and follows the swordsman as he moves. When a run begins the camera
## pans from the boss down to the start so the player sees the whole map.

const SWORDSMAN_SCENE := preload("res://Combatant/Player/Swordsman.tscn")
const NODE_SIZE := Vector2(64, 40)
const TIER_SPACING := 90.0
const LANE_SPACING := 110.0
const MARGIN := 100.0
const VIEW_HEIGHT := 480.0
const FOLLOW_Y := 340.0          # screen height the current node is kept near
const TYPE_ICONS := {
	"start": preload("res://Gamestate/Map/MapIcons/Rest.tres"),
	"fight": preload("res://Gamestate/Map/MapIcons/Enemy.tres"),
	"shop": preload("res://Gamestate/Map/MapIcons/Shop.tres"),
	"rest": preload("res://Gamestate/Map/MapIcons/Rest.tres"),
	"boss": preload("res://Gamestate/Map/MapIcons/Boss.tres"),
}
const TYPE_LABELS := {"start": "Start", "fight": "Fight", "shop": "Shop", "rest": "Rest", "boss": "BOSS"}

var _map: MapData
var _world: Node2D
var _buttons := {}               # node id -> Button
var _lines := {}                 # "from>to" -> Line2D
var _swordsman: Node2D
var _sprite: AnimatedSprite2D
var _fade: ColorRect
var _toast: Label
var _scroll := 0.0
var _max_scroll := 0.0
var _busy := false
var _dragging := false

func _ready() -> void:
	_map = GameState.map
	var content_height := (_map.tier_count - 1) * TIER_SPACING + 2.0 * MARGIN
	_max_scroll = maxf(0.0, content_height - VIEW_HEIGHT)

	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_world = Node2D.new()
	add_child(_world)
	_build_world()
	_build_overlay()

	_refresh()
	if GameState.map_intro_done:
		_set_scroll(_follow_scroll(GameState.current_node))
	else:
		_play_intro()

# building
func _node_pos(id: int) -> Vector2:
	var n: MapNode = _map.nodes[id]
	var x := 320.0 + (n.lane - (_map.lane_count - 1) / 2.0) * LANE_SPACING
	var y := MARGIN + (_map.tier_count - 1 - n.tier) * TIER_SPACING
	return Vector2(x, y) + n.jitter

func _build_world() -> void:
	for n in _map.nodes:
		for nx in n.next:
			var line := Line2D.new()
			line.width = 3.0
			line.add_point(_node_pos(n.id))
			line.add_point(_node_pos(nx))
			_world.add_child(line)
			_lines["%d>%d" % [n.id, nx]] = line

	for n in _map.nodes:
		var b := TextureButton.new()
		b.texture_normal = TYPE_ICONS[n.type]
		b.tooltip_text = TYPE_LABELS[n.type]
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = NODE_SIZE
		b.size = NODE_SIZE
		b.position = _node_pos(n.id) - NODE_SIZE / 2.0
		b.mouse_filter = Control.MOUSE_FILTER_PASS   # let scrolling pass through
		b.pressed.connect(_on_node_pressed.bind(n.id))
		b.mouse_entered.connect(_on_node_hover.bind(n.id, true))
		b.mouse_exited.connect(_on_node_hover.bind(n.id, false))
		_world.add_child(b)
		_buttons[n.id] = b

	_swordsman = SWORDSMAN_SCENE.instantiate()
	_world.add_child(_swordsman)
	_sprite = _swordsman.get_node("CharacterBody2D/AnimatedSprite2D")
	_sprite.scale = Vector2(1.5, 1.5)
	_sprite.play("Idle")
	_swordsman.position = _stand_position(GameState.current_node)

func _build_overlay() -> void:
	var top := ColorRect.new()
	top.color = Color(0, 0, 0, 0.65)
	top.size = Vector2(640, 28)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var seed_label := Label.new()
	seed_label.text = "Seed: %d" % GameState.run_seed
	seed_label.position = Vector2(10, 2)
	add_child(seed_label)

	var bottom := ColorRect.new()
	bottom.color = Color(0, 0, 0, 0.65)
	bottom.position = Vector2(0, 452)
	bottom.size = Vector2(640, 28)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	var hint := Label.new()
	hint.text = "Click a connected room to advance  |  Scroll, drag, or Up/Down to look around"
	hint.add_theme_font_size_override("font_size", 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 457)
	hint.size = Vector2(640, 20)
	add_child(hint)

	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 20)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 60)
	_toast.size = Vector2(640, 30)
	add_child(_toast)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _style_button(b: Button, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_border_width_all(3)
	box.border_color = Color(0.9, 0.9, 0.9)
	box.set_corner_radius_all(10)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, box)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)

func _stand_position(id: int) -> Vector2:
	return _node_pos(id) + Vector2(7.0, -82.0)

# scrolling
func _set_scroll(value: float) -> void:
	_scroll = clampf(value, 0.0, _max_scroll)
	_world.position.y = -_scroll

# Scroll offset that puts the given node near the lower part of the screen.
func _follow_scroll(id: int) -> float:
	return clampf(_node_pos(id).y - FOLLOW_Y, 0.0, _max_scroll)

func _play_intro() -> void:
	# Start at the boss (top of the map) and pan down to the start node.
	GameState.map_intro_done = true
	_busy = true
	_set_scroll(0.0)
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_method(_set_scroll, 0.0, _follow_scroll(GameState.current_node), 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): _busy = false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_set_scroll(_scroll - 60.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_set_scroll(_scroll + 60.0)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
	elif event is InputEventMouseMotion and _dragging:
		_set_scroll(_scroll - (event as InputEventMouseMotion).relative.y)


func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_up"):
		_set_scroll(_scroll - 400.0 * delta)
	if Input.is_action_pressed("ui_down"):
		_set_scroll(_scroll + 400.0 * delta)

# map state
func _refresh() -> void:
	var here: MapNode = _map.nodes[GameState.current_node]
	for id in _buttons:
		var b: TextureButton = _buttons[id]
		var reachable: bool = id in here.next
		b.disabled = not reachable
		if id in GameState.visited:
			b.modulate = Color(0.55, 0.55, 0.55)     # visited = darker
		elif reachable:
			b.modulate = Color.WHITE
		else:
			b.modulate = Color(0.75, 0.75, 0.75)
	for key in _lines:
		var line: Line2D = _lines[key]
		var from_id := int(key.split(">")[0])
		var to_id := int(key.split(">")[1])
		if from_id == here.id and to_id in here.next:
			line.default_color = Color(1.0, 0.9, 0.4)  # paths you can take now
			line.width = 4.0
		else:
			line.default_color = Color(0.4, 0.4, 0.5)
			line.width = 3.0

func _on_node_hover(id: int, hovering: bool) -> void:
	var b: TextureButton = _buttons[id]
	if b.disabled:
		return
	b.modulate = Color(1.4, 1.4, 0.8) if hovering else Color.WHITE

func _on_node_pressed(id: int) -> void:
	if _busy or id not in _map.nodes[GameState.current_node].next:
		return
	_busy = true
	var dest := _stand_position(id)
	_sprite.flip_h = dest.x < _swordsman.position.x
	_sprite.play("Run")
	var walk := create_tween().set_parallel(true)
	walk.tween_property(_swordsman, "position", dest, 1.0)
	walk.tween_method(_set_scroll, _scroll, _follow_scroll(id), 1.0)
	await walk.finished
	_sprite.play("Idle")
	var fade_out := create_tween()
	fade_out.tween_property(_fade, "color:a", 1.0, 0.4)
	await fade_out.finished
	_arrive(id)

func _arrive(id: int) -> void:
	GameState.arrive_at(id)
	match _map.nodes[id].type:
		"fight":
			GameState.change_state(GameState.State.COMBAT)
		"boss":
			GameState.run_complete = true
			GameState.change_state(GameState.State.VICTORY)
		_:
			# Shops and rests aren't built yet (Sprint 3): show a note and move on.
			_refresh()
			_toast.text = "%s - coming in Sprint 3" % TYPE_LABELS[_map.nodes[id].type]
			var back := create_tween()
			back.tween_property(_fade, "color:a", 0.0, 0.4)
			await back.finished
			await get_tree().create_timer(1.2).timeout
			_toast.text = ""
			_busy = false
