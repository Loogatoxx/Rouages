extends Node3D
## Héberge le modèle du plateau et publie son état après chaque changement.

const Plateau = preload("res://game/board/plateau.gd")
const Energie = preload("res://game/board/energie.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const TERRAIN := Rect2i(-4, -4, 9, 9)

var plateau: Plateau = Plateau.new()
var alimentees: Dictionary = {}


func _ready() -> void:
	for x: int in range(TERRAIN.position.x, TERRAIN.end.x):
		for y: int in range(TERRAIN.position.y, TERRAIN.end.y):
			var chemin: bool = x == 4 or (y == 0 and x >= 1 and x <= 3)
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.CHEMIN if chemin else Plateau.Sol.HERBE)
	plateau.modifie.connect(_actualiser)
	plateau.poser(Vector2i.ZERO, HORLOGE)


func _actualiser() -> void:
	alimentees = Energie.calculer(plateau)
	Events.plateau_modifie.emit()
	Events.energie_recalculee.emit(alimentees.keys())
