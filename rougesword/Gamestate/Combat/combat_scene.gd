extends Control
## Combat state: swordsman vs. one or more enemies. CombatManager runs the
## turn loop; this scene owns sprites, bars, the HUD, target selection and the
## action menu (basic attack + unlocked skills with cooldowns).

const SWORDSMAN := preload("res://Combatant/Player/Swordsman.tscn")
const FALLBACK_ENEMY := preload("res://Combatant/Enemy/Bat.tscn")
const BACKGROUND := preload("res://assets/Old Dungeon/OldDungeon320X180.png")
const HUD := preload("res://UI/HUD/HUD.tscn")

const BAR_TEXTURE := preload("res://assets/UI/healthbar.tres")
const HEALTHBAR_PROGRESS := preload("res://assets/UI/healthbar_progress.tres")
const XP_BAR_PROGRESS := preload("res://assets/UI/xp_progress.tres")

const GROUND_Y := 330.0   # everyone's feet go here
const PLAYER_X := 100.0
const PLAYER_SCALE := Vector2(2.5, 2.5)
const BAR_SCALE := 1.1
const BAR_WIDTH := 84.0 * BAR_SCALE   # texture is 84 px wide at scale 1

var _manager := CombatManager.new()
var _player: Player
var _player_sprite: AnimatedSprite2D
var _player_bar: TextureProgressBar
var _player_hp_label: Label
var _player_xp: TextureProgressBar
var _player_xp_label: Label
var _turn_label: Label
var _menu: PanelContainer
var _attack_button: Button
var _skill_buttons: Dictionary = {}   # skill_id -> Button
var hud: CanvasLayer
var _hint: Label
var _fade: ColorRect
var _slots: Array[Dictionary] = []
var _selected: int = 0

func _ready() -> void:
	var encounter := GameState.current_encounter()
	_player = Player.new()
	var wave: Array[Enemy] = []
	for data in encounter.enemies:
		wave.append(Enemy.new(data))
	add_child(_manager)
	_manager.setup(_player, wave)
	_manager.turn_changed.connect(_on_turn_changed)
	_manager.combat_finished.connect(_on_combat_finished)
	_player.health_changed.connect(_on_player_health_changed)
	_player.xp_changed.connect(_on_player_xp_changed)
	_player.cooldowns_changed.connect(_refresh_skill_buttons)

	hud = HUD.instantiate()
	add_child(hud)
	hud.bind_player(_player)

	for i in wave.size():
		wave[i].health_changed.connect(_on_enemy_health_changed.bind(i))

	_build_scene(encounter)
	_update_bar(_player_bar, _player_hp_label, _player.health, _player.max_health, "HP")
	_update_bar(_player_xp, _player_xp_label, _player.xp, _player.max_xp, "XP")
	for i in _slots.size():
		var enemy: Enemy = _slots[i]["enemy"]
		_update_bar(_slots[i]["bar"], _slots[i]["hp_label"], enemy.health, enemy.max_health, "HP")
	_select_first_living()
	_update_turn_label()

func _build_scene(encounter: EncounterData) -> void:
	var bg := Sprite2D.new()
	bg.texture = BACKGROUND
	bg.scale = Vector2(2, 2)
	bg.position = Vector2(320, 180)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.07, 0.11)
	panel.position = Vector2(0, 360)
	panel.size = Vector2(640, 120)
	add_child(panel)

	_player_sprite = _make_fighter(PLAYER_X, false, Color.WHITE)
	var player_body := _body_rect_world(_player_sprite)
	var bar_x := PLAYER_X - BAR_WIDTH / 2.0
	_player_bar = _make_bar(Vector2(bar_x, GROUND_Y + 8))
	_player_hp_label = _make_bar_label(Vector2(bar_x, GROUND_Y + 16))
	# Swordsman xp bar (vertical on the left edge of the screen)
	_player_xp = _make_bar(Vector2(20, 310), BAR_TEXTURE, XP_BAR_PROGRESS, 1.5)
	_player_xp.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	_player_xp.texture_progress_offset = Vector2(7, 1.5)
	_player_xp.rotation_degrees = -90
	_player_xp_label = _make_bar_label(Vector2(20, 320))
	var name_p := Label.new()
	name_p.text = _player.combatant_name
	name_p.position = Vector2(bar_x, player_body.position.y - 22)
	name_p.add_theme_color_override("font_outline_color", Color.BLACK)
	name_p.add_theme_constant_override("outline_size", 6)
	add_child(name_p)

	var positions := _enemy_positions(encounter.enemies.size())
	for i in encounter.enemies.size():
		_slots.append(_make_enemy_slot(i, encounter.enemies[i], _manager.enemies[i], positions[i]))

	_turn_label = Label.new()
	_turn_label.add_theme_font_size_override("font_size", 20)
	_turn_label.position = Vector2(16, 12)
	add_child(_turn_label)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.position = Vector2(16, 36)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.text = "Click an enemy to target it"
	_hint.visible = encounter.enemies.size() > 1
	add_child(_hint)

	_build_action_menu()

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

## Basic attack plus one button per unlocked skill. Skills on cooldown are
## disabled and show the turns remaining.
func _build_action_menu() -> void:
	_menu = PanelContainer.new()
	_menu.position = Vector2(20, 374)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_menu.add_child(grid)

	_attack_button = _make_action_button("Basic attack")
	_attack_button.pressed.connect(_on_attack_pressed)
	grid.add_child(_attack_button)

	for skill in _player.unlocked_skills:
		var button := _make_action_button(skill.display_name)
		button.icon = skill.icon
		button.tooltip_text = "%s\nCooldown: %d turn(s)" % [skill.description, skill.cooldown]
		button.pressed.connect(_on_skill_pressed.bind(skill))
		grid.add_child(button)
		_skill_buttons[skill.skill_id] = button
	add_child(_menu)
	_refresh_skill_buttons()

func _make_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 34)
	button.add_theme_constant_override("icon_max_width", 22)
	return button

func _refresh_skill_buttons() -> void:
	for skill in _player.unlocked_skills:
		var button: Button = _skill_buttons.get(skill.skill_id)
		if button == null:
			continue
		var left := _player.cooldown_remaining(skill)
		button.disabled = left > 0
		button.text = skill.display_name if left == 0 else "%s  (CD %d)" % [skill.display_name, left]

func _enemy_positions(count: int) -> Array[float]:
	var xs: Array[float] = []
	match count:
		1: xs.append(470.0)
		2:
			xs.append(360.0)
			xs.append(500.0)
		_:
			xs.append(290.0)
			xs.append(420.0)
			xs.append(550.0)
	return xs

#
func _body_rect(sprite: AnimatedSprite2D) -> Rect2:
	var s := sprite.scale.abs()
	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation("Idle"):
		return Rect2(Vector2(-20, -40) * s, Vector2(40, 80) * s)
	var union := Rect2i()
	var size := Vector2.ZERO
	for i in frames.get_frame_count("Idle"):
		var tex := frames.get_frame_texture("Idle", i)
		size = tex.get_size()
		var used := tex.get_image().get_used_rect()
		union = used if i == 0 else union.merge(used)
	return Rect2((Vector2(union.position) - size / 2.0) * s, Vector2(union.size) * s)


func _body_rect_world(sprite: AnimatedSprite2D) -> Rect2:
	var rect := _body_rect(sprite)
	rect.position += sprite.get_parent().get_parent().position
	return rect

#put people on floor
func _stand_on_ground(root: Node2D, sprite: AnimatedSprite2D, x: float) -> void:
	root.position = Vector2(x, GROUND_Y - _body_rect(sprite).end.y)

#place the swordsman
func _make_fighter(x: float, flip: bool, tint: Color) -> AnimatedSprite2D:
	var root: Node2D = SWORDSMAN.instantiate()
	add_child(root)
	var sprite: AnimatedSprite2D = root.get_node("CharacterBody2D/AnimatedSprite2D")
	sprite.scale = PLAYER_SCALE
	sprite.flip_h = flip
	sprite.modulate = tint
	sprite.play("Idle")
	_stand_on_ground(root, sprite, x) #replaced the earlier position thing
	return sprite

func _make_enemy_slot(index: int, data: EnemyData, enemy: Enemy, x: float) -> Dictionary:
	var packed := FALLBACK_ENEMY
	if data.scene_path != "" and ResourceLoader.exists(data.scene_path):
		packed = load(data.scene_path) as PackedScene
	var root: Node2D = packed.instantiate()
	add_child(root)
	var sprite: AnimatedSprite2D = root.get_node("CharacterBody2D/AnimatedSprite2D")
	sprite.scale = data.sprite_scale
	sprite.flip_h = data.flip_h
	sprite.modulate = data.tint
	sprite.play("Idle")
	_stand_on_ground(root, sprite, x)
	root.position.y -= data.hover_height
	var body := _body_rect_world(sprite)


	var bar_x := x - BAR_WIDTH / 2.0
	var bar := _make_bar(Vector2(bar_x, GROUND_Y + 8))
	var hp_label := _make_bar_label(Vector2(bar_x, GROUND_Y + 16))
	var name_e := Label.new()
	name_e.text = enemy.combatant_name
	name_e.position = Vector2(bar_x, body.position.y - 22)
	name_e.add_theme_color_override("font_outline_color", Color.BLACK)
	name_e.add_theme_constant_override("outline_size", 6)
	add_child(name_e)

	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.position = body.position - Vector2(6, 6)
	hit.size = body.size + Vector2(12, 12)
	hit.custom_minimum_size = hit.size
	hit.self_modulate.a = 0.0
	hit.pressed.connect(_on_enemy_clicked.bind(index))
	add_child(hit)

	return {
		"enemy": enemy,
		"data": data,
		"sprite": sprite,
		"bar": bar,
		"hp_label": hp_label,
		"name_label": name_e,
		"hit": hit,
	}

func _make_bar(pos: Vector2, under: Texture2D = BAR_TEXTURE, progress: Texture2D = HEALTHBAR_PROGRESS, bar_scale: float = BAR_SCALE) -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.position = pos
	bar.texture_under = under
	bar.texture_progress = progress
	bar.texture_progress_offset = Vector2(2, 2)
	bar.scale = Vector2(bar_scale, bar_scale)
	add_child(bar)
	return bar

func _make_bar_label(pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

func _update_bar(bar: TextureProgressBar, label: Label, current: int, maximum: int, prefix: String) -> void:
	bar.max_value = maximum
	bar.value = current
	label.text = "%s %d / %d" % [prefix, current, maximum]

func _update_turn_label() -> void:
	var who := "Swordsman's turn" if _manager.turn == CombatManager.Turn.PLAYER_TURN else "Enemy's turn"
	_turn_label.text = "Turn %d - %s" % [_manager.turn_indicator, who]

func _on_player_health_changed(current: int, maximum: int) -> void:
	_update_bar(_player_bar, _player_hp_label, current, maximum, "HP")
	GameState.player_health = current

func _on_player_xp_changed(current: int, maximum: int) -> void:
	_update_bar(_player_xp, _player_xp_label, current, maximum, "XP")
	GameState.player_xp = current

func _on_enemy_health_changed(current: int, maximum: int, index: int) -> void:
	var slot := _slots[index]
	_update_bar(slot["bar"], slot["hp_label"], current, maximum, "HP")
	if current == 0:
		_fade_enemy(index)
		if _selected == index:
			_select_first_living()
		else:
			_refresh_selection()

func _fade_enemy(index: int) -> void:
	var sprite: AnimatedSprite2D = _slots[index]["sprite"]
	create_tween().tween_property(sprite, "modulate:a", 0.0, 0.6)
	var hit: Button = _slots[index]["hit"]
	hit.disabled = true

func _on_enemy_clicked(index: int) -> void:
	if _manager.turn != CombatManager.Turn.PLAYER_TURN:
		return
	var enemy: Enemy = _slots[index]["enemy"]
	if not enemy.alive:
		return
	_selected = index
	_refresh_selection()

func _select_first_living() -> void:
	_selected = -1
	for i in _slots.size():
		var enemy: Enemy = _slots[i]["enemy"]
		if enemy.alive:
			_selected = i
			break
	_refresh_selection()

func _refresh_selection() -> void:
	for i in _slots.size():
		var slot := _slots[i]
		var enemy: Enemy = slot["enemy"]
		var data: EnemyData = slot["data"]
		var sprite: AnimatedSprite2D = slot["sprite"]
		var name_label: Label = slot["name_label"]
		var alpha := sprite.modulate.a
		if not enemy.alive:
			sprite.modulate = Color(data.tint.r, data.tint.g, data.tint.b, alpha)
			name_label.modulate = Color(0.6, 0.6, 0.6)
		elif i == _selected:
			sprite.modulate = Color(data.tint.r * 1.15, data.tint.g * 1.15, data.tint.b * 0.85, alpha)
			name_label.modulate = Color(1.0, 0.92, 0.45)
		else:
			sprite.modulate = Color(data.tint.r, data.tint.g, data.tint.b, alpha)
			name_label.modulate = Color.WHITE

func _on_turn_changed(_turn: CombatManager.Turn) -> void:
	_update_turn_label()
	_refresh_skill_buttons()

func _play_attack(sprite: AnimatedSprite2D, animation: StringName = &"Attack") -> void:
	if sprite.sprite_frames != null and not sprite.sprite_frames.has_animation(animation):
		animation = &"Attack"
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation):
		var frames := sprite.sprite_frames.get_frame_count(animation)
		var fps := maxf(sprite.sprite_frames.get_animation_speed(animation), 1.0)
		sprite.play(animation)
		await get_tree().create_timer(frames / fps).timeout
	else:
		await get_tree().create_timer(0.45).timeout
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("Idle"):
		sprite.play("Idle")

func _on_attack_pressed() -> void:
	var target := _selected_target()
	if target == null:
		return
	await _take_player_action(&"Attack", func(): _manager.player_attack(target))

func _on_skill_pressed(skill: SkillData) -> void:
	if _manager.turn != CombatManager.Turn.PLAYER_TURN or not _player.is_skill_ready(skill):
		return
	var target: Enemy = null
	if not skill.hits_all_enemies:
		target = _selected_target()
		if target == null:
			return
	await _take_player_action(skill.animation, func(): _manager.player_use_skill(skill, target))

## The enemy currently selected for targeting, or null if it can't be attacked.
func _selected_target() -> Enemy:
	if _manager.turn != CombatManager.Turn.PLAYER_TURN or _selected < 0:
		return null
	var target: Enemy = _slots[_selected]["enemy"]
	if not target.alive:
		_select_first_living()
		return null
	return target

## Plays the swordsman's animation, runs `action` (a CombatManager call), then
## lets every living enemy act and hands the turn back.
func _take_player_action(animation: StringName, action: Callable) -> void:
	_menu.visible = false
	await _play_attack(_player_sprite, animation)
	action.call()
	if _manager.turn == CombatManager.Turn.PLAYER_TURN:
		_menu.visible = true   # the action was refused; nothing was spent
		return
	if _manager.turn != CombatManager.Turn.ENEMY_TURN:
		return  # combat finished
	await get_tree().create_timer(0.35).timeout
	for slot in _slots:
		var enemy: Enemy = slot["enemy"]
		if not enemy.alive:
			continue
		await _play_attack(slot["sprite"])
		_manager.enemy_attack(enemy)
		if _manager.turn == CombatManager.Turn.FINISHED:
			return
		await get_tree().create_timer(0.2).timeout
	_manager.end_enemy_round()
	if _manager.turn == CombatManager.Turn.PLAYER_TURN:
		_menu.visible = true

func _on_combat_finished(player_won: bool) -> void:
	_update_turn_label()
	_menu.visible = false
	if player_won:
		# Enemies fade out as they die (see _on_enemy_health_changed).
		_award_rewards()
		await get_tree().create_timer(2).timeout   # let the XP bar settle
	else:
		create_tween().tween_property(_player_sprite, "modulate:a", 0.0, 0.6)
	await get_tree().create_timer(0.9).timeout
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.4)
	await tween.finished
	if player_won:
		GameState.change_state(GameState.State.VICTORY)
	else:
		GameState.change_state(GameState.State.DEATH)

## Gold and XP from every enemy in the encounter, saved for the next fight.
func _award_rewards() -> void:
	var gold := 0
	var xp := 0
	for enemy in _manager.enemies:
		gold += enemy.gold_reward
		xp += enemy.xp_reward
	_player.gold += gold
	_player.gain_xp(xp)

	#Persist Player stats across encounters
	GameState.player_gold = _player.gold
	GameState.player_xp = _player.xp
	GameState.player_max_xp = _player.max_xp
	GameState.player_level = _player.level
	GameState.player_skillpts = _player.skill_pts
