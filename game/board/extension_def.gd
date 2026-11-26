class_name ExtensionDef extends Resource
## Décrit le terrain d'une extension et les pièces reçues à sa pose.

const Lot = preload("res://game/core/lot.gd")

@export var id: StringName
@export var nom: String
@export var description: String
@export var taille: int = 3
@export var chemins: Array[Vector2i] = []
@export var bonus: Array[Lot] = []
@export var ressorts: int = 0
## Ressorts gagnés en plus à chaque fin de vague, pour le reste de la run (rente de l'extension).
@export var revenu: int = 0
