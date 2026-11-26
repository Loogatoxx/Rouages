class_name VagueDef extends Resource
## Décrit l'effectif, le rythme d'arrivée et la vitalité d'une vague.

const UniteDef = preload("res://game/swarm/unite_def.gd")

@export var unite: UniteDef
@export var nombre: int
@export var intervalle: float
@export var multiplicateur_pv: float
