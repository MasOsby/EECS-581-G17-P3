class_name EncounterData
extends Resource
## A fight composition: one or more EnemyData entries spawned together.

@export var encounter_name: String = "Encounter"
@export var enemies: Array[EnemyData] = []
