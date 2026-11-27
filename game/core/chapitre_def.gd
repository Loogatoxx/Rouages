class_name ChapitreDef extends Resource
## Décrit le diorama à déplier, son récit et les conditions de la partie.

const DepartDef = preload("res://game/core/depart_def.gd")

@export var id: int
@export var titre: String
@export_multiline var recit: String
@export var depart: DepartDef
@export_range(0, 2) var difficulte: int = 1
