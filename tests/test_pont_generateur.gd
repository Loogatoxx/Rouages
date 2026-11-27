extends RefCounted
## Vérifie le Pont (pose sur la route, énergie par-dessus) et le Générateur autonome (capacité limitée).

const Plateau = preload("res://game/board/plateau.gd")
const Energie = preload("res://game/board/energie.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const PONT = preload("res://data/tuiles/pont.tres")
const GENERATEUR = preload("res://data/tuiles/generateur.tres")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const DROIT = preload("res://data/tuiles/engrenage_droit.tres")
const CANON = preload("res://data/tuiles/tourelle_canon.tres")


## Le Pont ne se pose que sur une route ; posé en travers, il relie l'herbe des deux côtés.
func test_pont_traverse_la_route() -> String:
	var plateau := Plateau.new()
	# Horloge (0,0), engrenage droit E-O en (1,0), route verticale en x = 2, atelier en (3,0) tourné vers l'ouest.
	for x: int in [0, 1, 3]:
		plateau.ajouter_sol(Vector2i(x, 0), Plateau.Sol.HERBE)
	for y: int in range(-2, 3):
		plateau.ajouter_sol(Vector2i(2, y), Plateau.Sol.CHEMIN)
	plateau.poser(Vector2i.ZERO, HORLOGE)
	plateau.poser(Vector2i(1, 0), DROIT, 1)
	plateau.poser(Vector2i(3, 0), ATELIER, 1)
	if plateau.poser(Vector2i(1, 0) + Vector2i(0, 5), PONT):
		return "Le Pont ne doit pas se poser hors de la route."
	if Energie.calculer(plateau).has(Vector2i(3, 0)):
		return "Sans Pont, l'atelier de l'autre côté de la route ne doit pas être alimenté."
	if not plateau.poser(Vector2i(2, 0), PONT, 0):
		return "Le Pont doit se poser sur une case de route libre."
	return "" if Energie.calculer(plateau).has(Vector2i(3, 0)) else "Le Pont doit faire passer l'énergie."


## Un générateur isolé fournit 3 dents au niveau 1 (3 canons à 1 dent), 4 au niveau 2 ; les engrenages ne comptent pas.
func test_generateur_capacite() -> String:
	var plateau := Plateau.new()
	for x: int in range(-1, 4):
		for y: int in range(-1, 2):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	var cases: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(2, 0)]
	plateau.poser(Vector2i.ZERO, GENERATEUR)
	plateau.poser(Vector2i(1, 0), DROIT, 1)
	plateau.poser(Vector2i(0, 1), CANON, 2)  # port nord vers le générateur
	plateau.poser(Vector2i(0, -1), CANON, 0)  # port sud
	plateau.poser(Vector2i(-1, 0), CANON, 3)  # port est
	plateau.poser(Vector2i(2, 0), CANON, 1)  # port ouest vers l'engrenage
	var alimentees: Dictionary = Energie.calculer(plateau)
	var canons: int = 0
	for case: Vector2i in cases:
		if alimentees.has(case):
			canons += 1
	if canons != 3 or not alimentees.has(Vector2i(1, 0)):
		return "Au niveau 1, le générateur doit alimenter 3 canons et l'engrenage (obtenu %d)." % canons
	if Energie.consommateurs_du_generateur(plateau, Vector2i.ZERO) != 3:
		return "Le compteur du générateur doit afficher 3 dents."
	plateau.ameliorer(Vector2i.ZERO)
	alimentees = Energie.calculer(plateau)
	for case: Vector2i in cases:
		if not alimentees.has(case):
			return "Au niveau 2, le générateur doit alimenter les 4 canons."
	# Un atelier coûte 2 dents : avec 4 dents, deux ateliers et rien d'autre.
	return ""


func _pre() -> Plateau:
	var plateau := Plateau.new()
	for x: int in range(-3, 6):
		for y: int in range(-3, 4):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	return plateau


## Playtest 3 : quand le générateur est plein, c'est le bâtiment posé en DERNIER qui reste éteint, quel que soit
## son côté ; les bâtiments déjà en marche ne s'arrêtent jamais.
func test_surcharge_eteint_le_dernier_pose() -> String:
	var rotations: Dictionary = {Vector2i(0, 1): 2, Vector2i(0, -1): 0, Vector2i(-1, 0): 3, Vector2i(1, 0): 1}
	for ordre: Array in [[Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)],
			[Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]]:
		var plateau: Plateau = _pre()
		plateau.poser(Vector2i.ZERO, GENERATEUR)
		for case: Vector2i in ordre:
			plateau.poser(case, CANON, rotations[case])
		var bilan: Energie.Bilan = Energie.analyser(plateau)
		for i: int in 3:
			if not bilan.alimentees.has(ordre[i]):
				return "Les trois premiers canons posés doivent rester alimentés."
		if bilan.alimentees.has(ordre[3]) or bilan.surcharge != [ordre[3]]:
			return "Le dernier canon posé (%s) doit être le seul éteint, signalé en surcharge." % ordre[3]
		# Reprendre un ancien bâtiment libère une place : le dernier s'allume.
		plateau.retirer(ordre[0])
		bilan = Energie.analyser(plateau)
		if not bilan.alimentees.has(ordre[3]) or not bilan.surcharge.is_empty():
			return "Une place libérée doit rallumer le bâtiment en attente."
	return ""


## Tic-tac : l'Horloge sert ses dents dans l'ordre de pose ; un atelier coûte 2 dents, un canon 1.
func test_horloge_dents_comptees() -> String:
	var plateau: Plateau = _pre()
	plateau.poser(Vector2i.ZERO, HORLOGE)
	plateau.poser(Vector2i(1, 0), ATELIER, 1)   # 2 dents
	plateau.poser(Vector2i(-1, 0), ATELIER, 3)  # 2 dents
	plateau.poser(Vector2i(0, 1), CANON, 2)     # 1 dent : de trop avec 4 dents
	var bilan: Energie.Bilan = Energie.analyser(plateau, 4)
	if bilan.charge_horloge != 4 or bilan.surcharge_horloge != [Vector2i(0, 1)]:
		return "Avec 4 dents : deux ateliers alimentés, le canon posé en dernier éteint (charge %d)." % bilan.charge_horloge
	if bilan.alimentees.has(Vector2i(0, 1)):
		return "Le canon en surcharge ne doit pas être alimenté."
	bilan = Energie.analyser(plateau, 5)
	if not bilan.alimentees.has(Vector2i(0, 1)) or not bilan.surcharge.is_empty():
		return "Avec 5 dents, tout doit tourner."
	if not Energie.analyser(plateau).surcharge.is_empty():
		return "Sans limite (-1), rien n'est en surcharge."
	const REGLES = preload("res://data/regles.tres")
	if REGLES.dents_apres(0) != REGLES.dents_depart or REGLES.dents_apres(8) != REGLES.dents_depart + 4:
		return "L'Horloge doit gagner une dent après les vagues 2, 4, 6 et 8."
	return ""


## La chaîne d'un générateur est courte : au-delà de 2 pièces (un engrenage puis un bâtiment), plus rien ne s'allume.
func test_generateur_chaine_courte() -> String:
	var plateau: Plateau = _pre()
	plateau.poser(Vector2i.ZERO, GENERATEUR)
	plateau.poser(Vector2i(1, 0), DROIT, 1)
	plateau.poser(Vector2i(2, 0), DROIT, 1)
	plateau.poser(Vector2i(3, 0), ATELIER, 1)
	var alimentees: Dictionary = Energie.calculer(plateau)
	if not alimentees.has(Vector2i(1, 0)) or not alimentees.has(Vector2i(2, 0)):
		return "Les engrenages à portée du générateur doivent tourner."
	return "" if not alimentees.has(Vector2i(3, 0)) else "Un atelier à 3 pièces du générateur ne doit pas être alimenté."


## Le Générateur est légendaire et unique : on n'en pose qu'un par plateau.
func test_generateur_legendaire_unique() -> String:
	if GENERATEUR.rarete != Plateau.PieceDef.Rarete.LEGENDAIRE:
		return "Le Générateur doit être de rareté Légendaire."
	var plateau: Plateau = _pre()
	if not plateau.poser(Vector2i.ZERO, GENERATEUR):
		return "Le premier générateur doit se poser."
	if plateau.poser(Vector2i(3, 3), GENERATEUR):
		return "Un second générateur ne doit pas pouvoir être posé."
	plateau.retirer(Vector2i.ZERO)
	return "" if plateau.poser(Vector2i(3, 3), GENERATEUR) else "Une fois repris, le générateur doit pouvoir être reposé."


## L'énergie d'un générateur est faible : ses engrenages ne donnent pas leurs bonus (pas de cumul avec les engrenages).
func test_generateur_sans_bonus_d_engrenage() -> String:
	const Placement = preload("res://game/workshops/placement.gd")
	const REGLES = preload("res://data/regles.tres")
	var plateau: Plateau = _pre()
	# Générateur (0,0) → démultiplicateur (1,0) → atelier (2,0).
	plateau.poser(Vector2i.ZERO, GENERATEUR)
	plateau.poser(Vector2i(1, 0), DROIT, 1)
	plateau.poser(Vector2i(2, 0), ATELIER, 1)
	var alimentees: Dictionary = Energie.calculer(plateau)
	if not alimentees.has(Vector2i(2, 0)) or not Energie.energie_faible(alimentees, Vector2i(2, 0)):
		return "L'atelier doit tourner sur l'énergie faible du générateur."
	var faible: float = Placement.cadence_atelier(plateau, alimentees, Vector2i(2, 0), REGLES)
	# Même montage sur l'horloge : le démultiplicateur donne son bonus.
	var temoin: Plateau = _pre()
	temoin.poser(Vector2i.ZERO, HORLOGE)
	temoin.poser(Vector2i(1, 0), DROIT, 1)
	temoin.poser(Vector2i(2, 0), ATELIER, 1)
	var fort: float = Placement.cadence_atelier(temoin, Energie.calculer(temoin), Vector2i(2, 0), REGLES)
	return "" if fort > faible else "Sur un générateur, le démultiplicateur ne doit pas donner son bonus (%s contre %s)." % [faible, fort]


## Relecture T14b : quand l'Horloge est pleine, le bâtiment de trop reste éteint ; le même bâtiment, branché sur un
## générateur autonome, tourne. (Un bâtiment n'a qu'un port : il ne peut pas être sur les deux réseaux à la fois.)
func test_generateur_quand_l_horloge_est_pleine() -> String:
	var plateau: Plateau = _pre()
	plateau.poser(Vector2i.ZERO, HORLOGE)
	plateau.poser(Vector2i(1, 0), CANON, 1)    # sur l'Horloge (1 dent)
	plateau.poser(Vector2i(0, 1), DROIT, 0)    # engrenage nord-sud sous l'Horloge
	plateau.poser(Vector2i(0, 2), CANON, 2)    # relié à l'Horloge par l'engrenage : de trop avec 1 dent
	var bilan: Energie.Bilan = Energie.analyser(plateau, 1)
	if bilan.surcharge_horloge != [Vector2i(0, 2)]:
		return "Avec une dent, le second canon doit être refusé par l'Horloge."
	plateau.retirer(Vector2i(0, 2))
	plateau.poser(Vector2i(2, 2), GENERATEUR)
	plateau.poser(Vector2i(1, 2), CANON, 3)    # port est, vers le générateur ; pas relié à l'Horloge
	bilan = Energie.analyser(plateau, 1)
	if not bilan.alimentees.has(Vector2i(1, 2)) or not bilan.surcharge.is_empty():
		return "Le générateur doit alimenter le canon que l'Horloge pleine ne pouvait pas servir."
	return ""
