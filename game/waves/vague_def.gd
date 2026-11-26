class_name VagueDef extends Resource
## Décrit l'effectif, le rythme d'arrivée et la vitalité d'une vague.

const UniteDef = preload("res://game/swarm/unite_def.gd")

@export var unite: UniteDef
@export var nombre: int
@export var renfort: UniteDef
@export var nombre_renforts: int = 0
@export var intervalle: float
@export var multiplicateur_pv: float
## Boss facultatif, lâché une seule fois quand la moitié de la vague est entrée.
@export var boss: UniteDef
## Part des PV du boss à cette vague (0,5 = boss « d'avertissement » en milieu de run).
@export var pv_boss_facteur: float = 1.0
