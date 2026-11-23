extends Control
## Combat state: swordsman vs. one enemy, turn-based, basic attack only.
## Health bars use ProgressBar; CombatManager runs the turn loop.

const SWORDSMAN := preload("res://Combatant/Player/Swordsman.tscn")
const ENEMY_BASIC := preload("res://Combatant/Enemy/Bat.tscn")
const BACKGROUND := preload("res://assets/Old Dungeon/OldDungeon320X180.png")
const HUD := preload("res://UI/HUD/HUD.tscn")

const BAR_TEXTURE:= preload("res://assets/UI/healthbar.tres")
const HEALTHBAR_PROGRESS := preload("res://assets/UI/healthbar_progress.tres")
const XP_BAR_PROGRESS := preload("res://assets/UI/xp_progress.tres")

var _manager := CombatManager.new()
var _player: Player
var _enemy: Enemy
var _player_sprite: AnimatedSprite2D
var _enemy_sprite: AnimatedSprite2D
var _player_bar: TextureProgressBar
var _enemy_bar: TextureProgressBar
var _player_xp: TextureProgressBar
var _player_xp_label: Label
var _player_hp_label: Label
var _enemy_hp_label: Label
var _turn_label: Label
var _menu: PanelContainer
var _fade: ColorRect
var hud: CanvasLayer

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
	
	_player.xp_changed.connect(_on_player_xp_changed)
	
	hud = HUD.instantiate()
	add_child(hud)
	hud.bind_player(_player)
	
	_build_scene(data)
	_update_bar(_player_bar, _player_hp_label, _player.health, _player.max_health, "HP")
	_update_bar(_enemy_bar, _enemy_hp_label, _enemy.health, _enemy.max_health, "HP")
	_update_bar(_player_xp, _player_xp_label, _player.xp, _player.max_xp, "XP")
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
	_enemy_sprite = _make_enemy(Vector2(470, 195), true, data.tint)

	# Swordsman health bar (below the swordsman)
	_player_bar = _make_bar(Vector2(100, 302), BAR_TEXTURE, HEALTHBAR_PROGRESS)
	_player_hp_label = _make_bar_label(Vector2(100, 320), _player_bar)
	#Swordsman xp bar (vertical on edge of screen)
	_player_xp = _make_bar(Vector2(20,310), BAR_TEXTURE, XP_BAR_PROGRESS)
	_player_xp.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	_player_xp.texture_progress_offset = Vector2(7,1.5)
	_player_xp.rotation_degrees = -90
	_player_xp_label = _make_bar_label(Vector2(20, 320), _player_xp)
	
	# Enemy health bar (below the enemy)
	_enemy_bar = _make_bar(Vector2(400, 305), BAR_TEXTURE, HEALTHBAR_PROGRESS)
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
	var root: Node2D = SWORDSMAN.instantiate()
	root.position = pos
	add_child(root)
	var sprite: AnimatedSprite2D = root.get_node("CharacterBody2D/AnimatedSprite2D")
	sprite.scale = Vector2(3, 3)
	sprite.flip_h = flip
	sprite.modulate = tint
	sprite.play("Idle")
	return sprite
	
func _make_enemy(pos: Vector2, _flip: bool, tint: Color) -> AnimatedSprite2D:
	var root: Node2D = ENEMY_BASIC.instantiate()
	root.position = pos
	add_child(root)
	var sprite: AnimatedSprite2D = root.get_node("CharacterBody2D/AnimatedSprite2D")
	sprite.scale = Vector2(3, 3)
	sprite.modulate = tint
	sprite.play("Idle")
	return sprite

func _make_bar(pos: Vector2, under: Texture2D, progress: Texture2D) -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.position = pos
	
	#Load texture progress bar sprites
	bar.texture_under = under
	bar.texture_progress = progress
	
	#Size and scale
	bar.texture_progress_offset = Vector2(2,2)
	bar.scale = Vector2(1.5,1.5)
	
	add_child(bar)
	return bar

func _make_bar_label(pos: Vector2, _bar: TextureProgressBar) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

func _update_bar(bar: TextureProgressBar, label: Label, current: int, maximum: int, text: String) -> void:
	bar.max_value = maximum
	bar.value = current
	label.text = "%s %d / %d" % [text, current, maximum]
	
func _update_turn_label() -> void:
	var who := "Swordsman's turn" if _manager.turn == CombatManager.Turn.PLAYER_TURN else "Enemy's turn"
	_turn_label.text = "Turn %d - %s" % [_manager.turn_indicator, who]

func _on_player_health_changed(current: int, maximum: int) -> void:
	_update_bar(_player_bar, _player_hp_label, current, maximum, "HP")
	GameState.player_health = current

func _on_enemy_health_changed(current: int, maximum: int) -> void:
	_update_bar(_enemy_bar, _enemy_hp_label, current, maximum, "HP")
	
func _on_player_xp_changed(current: int, maximum: int) -> void:
	_update_bar(_player_xp, _player_xp_label, current, maximum, "XP")
	GameState.player_xp = current

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
		#Enemy death animation
		create_tween().tween_property(_enemy_sprite, "modulate:a", 0.0, 0.6)
		
		#Update Player gold and xp
		_player.gold += _enemy.gold_reward
		_player.gain_xp(_enemy.xp_reward)
		
		#Persist Player stats across encounters
		GameState.player_gold = _player.gold
		GameState.player_xp = _player.xp
		GameState.player_max_xp = _player.max_xp
		GameState.player_level = _player.level
		GameState.player_skillpts = _player.skill_pts
		
		await get_tree().create_timer(2).timeout
		
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
