extends Control
## Combat state: swordsman vs. one enemy, turn-based, basic attack only.
## Health bars use ProgressBar; CombatManager runs the turn loop.

const SWORDSMAN_SCENE := preload("res://Swordsman.tscn")
const BACKGROUND := preload("res://assets/Old Dungeon/OldDungeon320X180.png")
var _manager := CombatManager.new()
var _player: Player
var _enemy: Enemy
var _player_sprite: AnimatedSprite2D
var _enemy_sprite: AnimatedSprite2D
var _player_bar: ProgressBar
var _enemy_bar: ProgressBar
var _player_hp_label: Label
var _enemy_hp_label: Label
var _turn_label: Label
var _menu: PanelContainer
var _fade: ColorRect

func _ready() -> void:
	var data := GameState.current_enemy_data()
	_player = Player.new()
	_enemy = Enemy.new(data)
	add_child(_manager)
	_manager.setup(_player, _enemy)
	_manager.turn_changed.connect(_on_turn_changed)
	_manager.combat_finished.connect(_on_combat_finished)
	_player.health_changed.connect(_on_player_health_changed)
	_enemy.health_changed.connect(_on_enemy_health_changed)

	_build_scene(data)
	_update_bar(_player_bar, _player_hp_label, _player.health, _player.max_health)
	_update_bar(_enemy_bar, _enemy_hp_label, _enemy.health, _enemy.max_health)
	_update_turn_label()

func _build_scene(data: EnemyData) -> void:
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

	_player_sprite = _make_fighter(Vector2(170, 195), false, Color.WHITE)
	_enemy_sprite = _make_fighter(Vector2(470, 195), true, data.tint)

	# Swordsman health bar (below the swordsman)
	_player_bar = _make_bar(Vector2(100, 305))
	_player_hp_label = _make_bar_label(Vector2(100, 322), _player_bar)
	# Enemy health bar (below the enemy)
	_enemy_bar = _make_bar(Vector2(400, 305))
	_enemy_hp_label = _make_bar_label(Vector2(400, 322), _enemy_bar)

	var name_p := Label.new()
	name_p.text = _player.combatant_name
	name_p.position = Vector2(100, 280)
	name_p.add_theme_color_override("font_outline_color", Color.BLACK)
	name_p.add_theme_constant_override("outline_size", 6)
	add_child(name_p)
	var name_e := Label.new()
	name_e.text = _enemy.combatant_name
	name_e.position = Vector2(400, 280)
	name_e.add_theme_color_override("font_outline_color", Color.BLACK)
	name_e.add_theme_constant_override("outline_size", 6)
	add_child(name_e)

	_turn_label = Label.new()
	_turn_label.add_theme_font_size_override("font_size", 20)
	_turn_label.position = Vector2(16, 12)
	add_child(_turn_label)

	# Action menu shown on the swordsman's turn
	_menu = PanelContainer.new()
	_menu.position = Vector2(20, 380)
	var attack_button := Button.new()
	attack_button.text = "Basic attack"
	attack_button.custom_minimum_size = Vector2(150, 40)
	attack_button.pressed.connect(_on_attack_pressed)
	_menu.add_child(attack_button)
	add_child(_menu)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _make_fighter(pos: Vector2, flip: bool, tint: Color) -> AnimatedSprite2D:
	var root: Node2D = SWORDSMAN_SCENE.instantiate()
	root.position = pos
	add_child(root)
	var sprite: AnimatedSprite2D = root.get_node("CharacterBody2D/AnimatedSprite2D")
	sprite.scale = Vector2(3, 3)
	sprite.flip_h = flip
	sprite.modulate = tint
	sprite.play("Idle")
	return sprite

func _make_bar(pos: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(140, 16)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.05, 0.05)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.9, 0.9, 0.9)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.75, 0.3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	add_child(bar)
	return bar

func _make_bar_label(pos: Vector2, _bar: ProgressBar) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

func _update_bar(bar: ProgressBar, label: Label, current: int, maximum: int) -> void:
	bar.max_value = maximum
	bar.value = current
	label.text = "HP %d / %d" % [current, maximum]

func _update_turn_label() -> void:
	var who := "Swordsman's turn" if _manager.turn == CombatManager.Turn.PLAYER_TURN else "Enemy's turn"
	_turn_label.text = "Turn %d - %s" % [_manager.turn_indicator, who]

func _on_player_health_changed(current: int, maximum: int) -> void:
	_update_bar(_player_bar, _player_hp_label, current, maximum)
	GameState.player_health = current

func _on_enemy_health_changed(current: int, maximum: int) -> void:
	_update_bar(_enemy_bar, _enemy_hp_label, current, maximum)

func _on_turn_changed(_turn: CombatManager.Turn) -> void:
	_update_turn_label()

func _play_attack(sprite: AnimatedSprite2D) -> void:
	sprite.play("Attack")
	await get_tree().create_timer(0.45).timeout
	sprite.play("Idle")

func _on_attack_pressed() -> void:
	_menu.visible = false
	await _play_attack(_player_sprite)
	_manager.player_attack()
	if _manager.turn != CombatManager.Turn.ENEMY_TURN:
		return  # combat finished
	await get_tree().create_timer(0.5).timeout
	await _play_attack(_enemy_sprite)
	_manager.enemy_attack()
	if _manager.turn == CombatManager.Turn.PLAYER_TURN:
		_menu.visible = true

func _on_combat_finished(player_won: bool) -> void:
	_update_turn_label()
	if player_won:
		create_tween().tween_property(_enemy_sprite, "modulate:a", 0.0, 0.6)
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
