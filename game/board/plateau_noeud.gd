extends Node3D
## Héberge le modèle du plateau et publie son état après chaque changement.

const Plateau = preload("res://game/board/plateau.gd")
const Energie = preload("res://game/board/energie.gd")

var plateau: Plateau
var alimentees: Dictionary = {}


func _ready() -> void:
	add_to_group(&"plateau_noeud")
	plateau = Run.depart.creer_plateau()
	plateau.modifie.connect(_actualiser)
	_actualiser()


func _actualiser() -> void:
	alimentees = Energie.calculer(plateau)
	Events.plateau_modifie.emit()
	Events.energie_recalculee.emit(alimentees.keys())
