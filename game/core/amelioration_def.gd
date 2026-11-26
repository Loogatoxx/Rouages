class_name AmeliorationDef extends Resource
## Décrit les niveaux, le prix et l'effet permanent d'une amélioration de l'Établi.

@export var id: StringName
@export var nom: String
@export var description: String
@export var niveaux_max: int
@export var prix: Array[int] = []
@export var effet: StringName
@export var valeur_par_niveau: float
