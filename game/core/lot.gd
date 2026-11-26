class_name Lot extends Resource
## Réunit un objet et sa quantité pour les réserves, les tirages et les récompenses.

@export var objet: Resource
@export var quantite: int = 1
@export var poids: float = 1.0
@export var vague_min: int = 1
