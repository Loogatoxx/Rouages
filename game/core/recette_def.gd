class_name RecetteDef extends Resource
## Décrit les lots consommés et le lot produit par un assemblage.

const Lot = preload("res://game/core/lot.gd")

@export var id: StringName
@export var entrees: Array[Lot] = []
@export var sortie: Lot
