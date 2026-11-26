class_name DepartDef extends Resource
## Décrit le terrain, l'horloge et les pièces confiées au début d'une partie.

const Plateau = preload("res://game/board/plateau.gd")
const Lot = preload("res://game/core/lot.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")

@export var nom: String
@export var description: String
@export var terrain: Rect2i
@export var chemins: Array[Vector2i] = []
@export var horloge: Vector2i
@export var reserve: Array[Lot] = []


## Construit un plateau neuf en plaçant les chemins puis l'horloge sur le terrain.
func creer_plateau() -> Plateau:
	var plateau: Plateau = Plateau.new()
	for x: int in range(terrain.position.x, terrain.end.x):
		for y: int in range(terrain.position.y, terrain.end.y):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	for case: Vector2i in chemins:
		plateau.ajouter_sol(case, Plateau.Sol.CHEMIN)
	plateau.poser(horloge, HORLOGE)
	return plateau
