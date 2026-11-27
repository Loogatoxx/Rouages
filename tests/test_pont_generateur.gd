extends RefCounted
## Vérifie le Pont (pose sur la route, énergie par-dessus) et le Générateur autonome (capacité limitée).

const Plateau = preload("res://game/board/plateau.gd")
const Energie = preload("res://game/board/energie.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const PONT = preload("res://data/tuiles/pont.tres")
const GENERATEUR = preload("res://data/tuiles/generateur.tres")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const DROIT = preload("res://data/tuiles/engrenage_droit.tres")


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


## Un générateur isolé alimente 2 ateliers au niveau 1, 3 au niveau 2 ; les engrenages ne comptent pas.
func test_generateur_capacite() -> String:
	var plateau := Plateau.new()
	for x: int in range(-1, 4):
		for y: int in range(-1, 2):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	plateau.poser(Vector2i.ZERO, GENERATEUR)
	plateau.poser(Vector2i(1, 0), DROIT, 1)
	plateau.poser(Vector2i(2, 0), ATELIER, 1)  # port ouest vers l'engrenage
	plateau.poser(Vector2i(0, 1), ATELIER, 2)  # port nord vers le générateur
	plateau.poser(Vector2i(0, -1), ATELIER, 0)  # port sud vers le générateur
	var alimentees: Dictionary = Energie.calculer(plateau)
	var ateliers: int = 0
	for case: Vector2i in [Vector2i(2, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if alimentees.has(case):
			ateliers += 1
	if ateliers != 2 or not alimentees.has(Vector2i(1, 0)):
		return "Au niveau 1, le générateur doit alimenter 2 ateliers et l'engrenage (obtenu %d)." % ateliers
	if Energie.consommateurs_du_generateur(plateau, Vector2i.ZERO) != 2:
		return "Le compteur du générateur doit afficher 2."
	plateau.ameliorer(Vector2i.ZERO)
	alimentees = Energie.calculer(plateau)
	for case: Vector2i in [Vector2i(2, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if not alimentees.has(case):
			return "Au niveau 2, le générateur doit alimenter les 3 ateliers."
	return ""


## L'armure retire un montant fixe par coup, moitié moins au corps à corps, sans jamais annuler un coup.
func test_armure() -> String:
	var cuirasse = load("res://data/unites/scarabee_cuirasse.tres")
	if cuirasse.armure <= 0.0:
		return "Le cuirassé doit avoir de l'armure."
	var fort: float = cuirasse.degats_recus(18.0)
	var faible: float = cuirasse.degats_recus(3.0)
	var melee: float = cuirasse.degats_recus(3.0, true)
	if not is_equal_approx(fort, 18.0 - cuirasse.armure):
		return "Un gros coup perd exactement l'armure."
	if faible <= 0.0 or faible >= 3.0 - cuirasse.armure + 0.001 and 3.0 - cuirasse.armure > 0.0:
		return "Un petit coup doit être fortement réduit sans être nul."
	return "" if melee > faible else "Le corps à corps doit mieux passer l'armure."


func _pre() -> Plateau:
	var plateau := Plateau.new()
	for x: int in range(-3, 6):
		for y: int in range(-3, 4):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	return plateau


## Playtest 3 : quand le générateur est plein, c'est le bâtiment posé en DERNIER qui reste éteint, quel que soit
## son côté ; les bâtiments déjà en marche ne s'arrêtent jamais.
func test_surcharge_eteint_le_dernier_pose() -> String:
	for ordre: Array in [[Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0)], [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]]:
		var plateau: Plateau = _pre()
		plateau.poser(Vector2i.ZERO, GENERATEUR)
		var rotations: Dictionary = {Vector2i(0, 1): 2, Vector2i(0, -1): 0, Vector2i(-1, 0): 3}
		for case: Vector2i in ordre:
			plateau.poser(case, ATELIER, rotations[case])
		var bilan: Energie.Bilan = Energie.analyser(plateau)
		if not bilan.alimentees.has(ordre[0]) or not bilan.alimentees.has(ordre[1]):
			return "Les deux premiers ateliers posés doivent rester alimentés."
		if bilan.alimentees.has(ordre[2]) or bilan.surcharge != [ordre[2]]:
			return "Le dernier atelier posé (%s) doit être le seul éteint, signalé en surcharge." % ordre[2]
		# Reprendre un ancien bâtiment libère une place : le dernier s'allume.
		plateau.retirer(ordre[0])
		bilan = Energie.analyser(plateau)
		if not bilan.alimentees.has(ordre[2]) or not bilan.surcharge.is_empty():
			return "Une place libérée doit rallumer le bâtiment en attente."
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
