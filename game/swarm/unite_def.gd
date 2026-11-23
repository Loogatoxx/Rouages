class_name UniteDef extends Resource
## Décrit les caractéristiques communes aux unités d'un même modèle.

enum Camp { ALLIE, ENNEMI }

@export var id: StringName
@export var camp: Camp
@export var pv: float
@export var degats: float
@export var cadence: float
@export var portee: float
@export var vitesse: float
@export var rayon: float
