class_name EnemyData
extends Resource
## Enemy stats stored as a data resource (.tres), so new enemies need no code changes.

@export var enemy_name: String = "Enemy"
@export var health: int = 1
@export var base_damage: int = 1
@export var speed: int = 1
@export var tint: Color = Color.WHITE
@export_file("*.tscn") var scene_path: String = "res://Combatant/Enemy/Bat.tscn"
@export var sprite_scale: Vector2 = Vector2(2, 2)
@export var flip_h: bool = false
@export var difficulty_cost: float = 1.0
@export var hover_height: float = 0.0   # pixels above the ground line, for enemies that float like bat

#Init enemy drops
@export var gold_reward: int = 1
@export var xp_reward: int = 1
