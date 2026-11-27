extends Node3D
## Héberge le modèle du plateau et publie son état après chaque changement.

const Plateau = preload("res://game/board/plateau.gd")
const Energie = preload("res://game/board/energie.gd")

var plateau: Plateau
var alimentees: Dictionary = {}
## Bâtiments reliés à un générateur plein : éteints, signalés par le visuel (playtest 3).
var surcharge: Array[Vector2i] = []
## Tic-tac : dents de l'Horloge (-1 = illimitées) et dents consommées, lues par le HUD.
var dents: int = -1
var charge_horloge: int = 0
## Dents consommées sur chaque générateur autonome (lu par le panneau de pièce, sans refaire le calcul).
var charges_generateurs: Dictionary = {}


func _ready() -> void:
	add_to_group(&"plateau_noeud")
	plateau = Run.depart.creer_plateau()
	plateau.modifie.connect(_actualiser)
	# Les dents de l'Horloge changent après certaines vagues : l'énergie se recalcule quand la phase change.
	Events.phase_changee.connect(func(_phase: int) -> void:
		if Run.dents == dents:
			return
		if Run.dents > dents and dents >= 0:
			# Après le bandeau « Vague tenue » (et celui d'un éventuel tiroir).
			# Minuteur enfant du plateau : il disparaît avec lui (retour au menu avant la fin du délai).
			var minuteur := Timer.new()
			minuteur.one_shot = true
			minuteur.wait_time = 3.4
			add_child(minuteur)
			minuteur.timeout.connect(func() -> void:
				Events.message_joueur.emit(tr("L’Horloge se remonte : +1 dent d’énergie !"))
				minuteur.queue_free())
			minuteur.start()
		_actualiser())
	_actualiser()


func _actualiser() -> void:
	dents = Run.dents
	var bilan: Energie.Bilan = Energie.analyser(plateau, dents)
	alimentees = bilan.alimentees
	charge_horloge = bilan.charge_horloge
	charges_generateurs = bilan.charges
	# Un bâtiment vient de dépasser la capacité de sa source : on le dit tout de suite, en clair.
	for case: Vector2i in bilan.surcharge:
		if not surcharge.has(case):
			if bilan.surcharge_horloge.has(case):
				Events.message_joueur.emit(tr("Horloge pleine (%d dents) : ce bâtiment reste éteint. Reprends-en un autre, ou attends que l’Horloge se remonte.") % dents)
			else:
				Events.message_joueur.emit(tr("Générateur plein : ce bâtiment reste éteint. Améliore le générateur ou reprends un bâtiment."))
			Sons.jouer(&"horloge_touchee")
			break
	surcharge = bilan.surcharge
	Events.plateau_modifie.emit()
	Events.energie_recalculee.emit(alimentees.keys())
