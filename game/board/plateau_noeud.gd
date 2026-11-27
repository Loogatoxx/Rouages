extends Node3D
## Héberge le modèle du plateau et publie son état après chaque changement.

const Plateau = preload("res://game/board/plateau.gd")
const Energie = preload("res://game/board/energie.gd")

var plateau: Plateau
var alimentees: Dictionary = {}
## Bâtiments reliés à un générateur plein : éteints, signalés par le visuel (playtest 3).
var surcharge: Array[Vector2i] = []


func _ready() -> void:
	add_to_group(&"plateau_noeud")
	plateau = Run.depart.creer_plateau()
	plateau.modifie.connect(_actualiser)
	_actualiser()


func _actualiser() -> void:
	var bilan: Energie.Bilan = Energie.analyser(plateau)
	alimentees = bilan.alimentees
	# Un bâtiment vient de dépasser la capacité du générateur : on le dit tout de suite, en clair.
	for case: Vector2i in bilan.surcharge:
		if not surcharge.has(case):
			Events.message_joueur.emit(tr("Générateur plein : ce bâtiment reste éteint. Améliore le générateur ou reprends un bâtiment."))
			Sons.jouer(&"horloge_touchee")
			break
	surcharge = bilan.surcharge
	Events.plateau_modifie.emit()
	Events.energie_recalculee.emit(alimentees.keys())
