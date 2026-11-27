class_name ChapitreDef extends Resource
## Décrit le diorama à déplier, son récit et les conditions de la partie.

const DepartDef = preload("res://game/core/depart_def.gd")

@export var id: int
@export var titre: String
@export_multiline var recit: String
@export var depart: DepartDef
@export_range(0, 2) var difficulte: int = 1
## Vagues après lesquelles un tiroir s'ouvre (la carte évolue en cours de partie, PT-60).
@export var tiroirs: Array[int] = []
## Partie en « Longue route » (15 vagues).
@export var longue_route: bool = false
