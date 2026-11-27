extends RefCounted
## Vérifie les routes initiales, la sélection du départ et les règles de partie.

const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const DepartDef = preload("res://game/core/depart_def.gd")
const REGLES = preload("res://data/regles.tres")


## Chaque chemin rejoint l'horloge et débouche sur les entrées prévues.
func test_plateaux_raccordes() -> String:
	var noms: Array[String] = ["Prairie", "Méandres", "Fourche"]
	var entrees: Array = [
		[Vector2i(4, -4), Vector2i(4, 4)], [Vector2i(3, -4)], [Vector2i(-2, 4), Vector2i(2, -4)]]  # Fourche : chemins en coude (Claude)
	# Les trois premiers plateaux ; les suivants (playtest 2 : un plateau par chapitre) sont vérifiés par
	# `test_plateaux_jouables`.
	if REGLES.departs.size() < noms.size():
		return "Au moins trois plateaux de départ sont attendus."
	for i: int in noms.size():
		var depart: DepartDef = REGLES.departs[i]
		if depart.nom != noms[i] or depart.description.is_empty():
			return "Nom ou description manquants pour %s." % noms[i]
		if depart.terrain != Rect2i(-4, -4, 9, 9) or depart.horloge != Vector2i.ZERO:
			return "Terrain ou horloge incorrects pour %s." % depart.nom
		var plateau: DepartDef.Plateau = depart.creer_plateau()
		var distances: Dictionary = ChampFlux.calculer(plateau)
		if distances.get(Vector2i.ZERO, -1) != 0:
			return "Horloge absente de %s." % depart.nom
		for case: Vector2i in depart.chemins:
			if not depart.terrain.has_point(case) or not distances.has(case):
				return "Chemin déconnecté ou hors terrain en %s sur %s." % [case, depart.nom]
		if ChampFlux.entrees(plateau, distances) != entrees[i]:
			return "Entrées incorrectes pour %s." % depart.nom
	return ""


## Choisir Fourche conserve la sélection au redémarrage et fournit deux ateliers.
func test_choisir_depart() -> String:
	Run.choisir_depart(2)
	Run.reinitialiser()
	var valide: bool = (Run.depart == REGLES.departs[2] and not Run.defi_du_jour
			and Run.reserve.quantite(&"atelier_soldats") == 2)
	Run.choisir_depart(0)
	Run.reinitialiser()
	return "" if valide else "La sélection de Fourche ou sa réserve est incorrecte."


## Une date reproduit le plateau, le draft et les deux suites de nombres aléatoires.
func test_graine_du_jour() -> String:
	var date: String = "2026-11-26"
	var graine: int = Run.graine_du_jour(date)
	Run.preparer_defi(date)
	Run.reinitialiser()
	var plateau_attendu: DepartDef = REGLES.departs[posmod(hash(date), REGLES.departs.size())]
	var valide: bool = Run.defi_du_jour and graine == hash(date) and Run.depart == plateau_attendu
	var offre: Array = Run.offre.duplicate()
	var local: int = Run.rng.randi()
	var global: int = randi()
	Run.reinitialiser()
	valide = (valide and Run.graine_du_jour(date) == graine and offre == Run.offre
			and Run.rng.randi() == local and randi() == global)
	Run.choisir_depart(0)
	valide = valide and not Run.defi_du_jour
	Run.reinitialiser()
	return "" if valide else "La date doit reproduire le même défi."


## Avant la vague 1 la rotation est gratuite ; ensuite elle coûte deux ressorts et un refus conserve solde et ports.
func test_prix_rotation() -> String:
	var depart: DepartDef = REGLES.departs[0]
	var plateau: DepartDef.Plateau = depart.creer_plateau()
	var case := Vector2i(-1, 0)
	plateau.poser(case, preload("res://data/tuiles/engrenage_droit.tres"))
	var solde: int = Run.ressorts
	var vague: int = Run.vague_actuelle
	Run.vague_actuelle = 0
	Run.ressorts = 0
	if not Run.tourner_piece(plateau, case) or Run.ressorts != 0:
		Run.ressorts = solde
		return "Avant la vague 1, tourner une pièce posée doit être gratuit."
	if Run.tourner_piece(plateau, depart.horloge):
		Run.ressorts = solde
		return "L'horloge ne se tourne pas."
	Run.vague_actuelle = 1
	var ports: int = plateau.ports_de(case)
	Run.ressorts = 1
	var valide: bool = (REGLES.prix_rotation == 2 and not Run.tourner_piece(plateau, case)
			and plateau.ports_de(case) == ports and Run.ressorts == 1)
	Run.ressorts = 2
	valide = valide and not Run.tourner_piece(plateau, Vector2i(1, 1)) and Run.ressorts == 2
	valide = valide and Run.tourner_piece(plateau, case) and plateau.ports_de(case) != ports and Run.ressorts == 0
	Run.ressorts = solde
	Run.vague_actuelle = vague
	return "" if valide else "La rotation doit débiter deux ressorts uniquement en cas de succès."


## Chaque plateau est jouable : toute la route rejoint l'horloge, au moins une entrée, et chaque chapitre a le sien.
func test_plateaux_jouables() -> String:
	var ChampFlux = load("res://game/swarm/champ_flux.gd")
	var regles = load("res://data/regles.tres")
	for depart in regles.departs:
		var plateau = depart.creer_plateau()
		var distances: Dictionary = ChampFlux.calculer(plateau)
		for case: Vector2i in depart.chemins:
			if not distances.has(case):
				return "%s : la case %s de la route n'atteint pas l'horloge." % [depart.nom, case]
		if ChampFlux.entrees(plateau, distances).is_empty():
			return "%s : aucune entrée pour les ennemis." % depart.nom
	var vus: Array = []
	for chapitre in regles.chapitres:
		if vus.has(chapitre.depart):
			return "Le plateau %s sert à deux chapitres." % chapitre.depart.nom
		vus.append(chapitre.depart)
	return ""
