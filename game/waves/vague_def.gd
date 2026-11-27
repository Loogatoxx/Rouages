class_name VagueDef extends Resource
## Décrit l'effectif, le rythme d'arrivée et la vitalité d'une vague.

const UniteDef = preload("res://game/swarm/unite_def.gd")

@export var unite: UniteDef
@export var nombre: int
@export var renfort: UniteDef
@export var nombre_renforts: int = 0
@export var volants: UniteDef
@export var nombre_volants: int = 0
@export var intervalle: float
@export var multiplicateur_pv: float
## Playtest 3 : les ennemis arrivent par paquets de `groupe` (serrés, `ECART_GROUPE` s entre deux), puis une pause.
## La durée totale reste `nombre × intervalle` : seul le rythme change. Pourquoi : un filet continu d'ennemis isolés
## meurt un par un sans jamais menacer une ligne ; un paquet se lit d'un coup d'œil et met la ligne à l'épreuve.
@export var groupe: int = 1
## Dégâts des ennemis de cette vague contre les jouets (les dégâts infligés à l'Horloge ne changent pas).
@export var multiplicateur_degats: float = 1.0
## Boss facultatif, lâché une seule fois quand la moitié de la vague est entrée.
@export var boss: UniteDef
## Part des PV du boss à cette vague (0,5 = boss « d'avertissement » en milieu de run).
@export var pv_boss_facteur: float = 1.0
