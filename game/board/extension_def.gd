class_name ExtensionDef extends Resource
## Décrit le terrain d'une extension et les pièces reçues à sa pose.

const Lot = preload("res://game/core/lot.gd")

@export var id: StringName
@export var nom: String
@export var description: String
@export var taille: int = 3
@export var chemins: Array[Vector2i] = []
@export var bonus: Array[Lot] = []
