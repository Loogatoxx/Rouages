extends RefCounted
## Vérifie les extensions sur le plateau de départ, de la pioche au raccordement.

const Plateau = preload("res://game/board/plateau.gd")
const Extension = preload("res://game/board/extension.gd")
const ExtensionDef = preload("res://game/board/extension_def.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const Lot = preload("res://game/core/lot.gd")
const DEPART = preload("res://data/depart.tres")
const REGLES = preload("res://data/regles.tres")
const SENTIER = preload("res://data/extensions/sentier.tres")
const CARREFOUR = preload("res://data/extensions/carrefour.tres")


## Vérifie les neuf cases du sentier après un quart de tour.
func test_cases_sentier() -> String:
	var sols: Dictionary = Extension.cases(SENTIER, Vector2i(6, 2), 1)
	if sols.size() != 9:
		return "Le sentier doit couvrir neuf cases."
	for x: int in range(5, 8):
		for y: int in range(1, 4):
			var attendu: Plateau.Sol = Plateau.Sol.CHEMIN if y == 2 else Plateau.Sol.HERBE
			if sols.get(Vector2i(x, y), -1) != attendu:
				return "Sol incorrect en (%d, %d)." % [x, y]
	return ""


func _verifier_pose(def: ExtensionDef, centre: Vector2i, rotation: int, attendues: Array[Vector2i]) -> String:
	var plateau: Plateau = DEPART.creer_plateau()
	var signaux: Array[bool] = []
	plateau.modifie.connect(func() -> void: signaux.append(true))
	if not Extension.est_valide(plateau, def, centre, rotation):
		return "La pose de %s devrait être valide." % def.nom
	if not Extension.appliquer(plateau, def, centre, rotation):
		return "Le plateau doit accepter la pose de %s." % def.nom
	if signaux.size() != 1 or plateau.coords_sols().size() != DEPART.terrain.get_area() + 9:
		return "La pose doit signaler le terrain complet une seule fois."
	var entrees: Array[Vector2i] = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau))
	return "" if entrees == attendues else "Entrées de %s inattendues : %s." % [def.nom, entrees]


## Le sentier latéral conserve les entrées initiales et en ouvre une à l'est.
func test_pose_sentier() -> String:
	return _verifier_pose(SENTIER, Vector2i(6, 2), 1, [Vector2i(4, -4), Vector2i(4, 4), Vector2i(7, 2)])


## Le carrefour remplace l'entrée nord par les deux extrémités de sa traverse.
func test_pose_carrefour() -> String:
	return _verifier_pose(CARREFOUR, Vector2i(4, -6), 0, [Vector2i(3, -6), Vector2i(4, 4), Vector2i(5, -6)])


## Refuse le chevauchement, le chemin isolé et le simple prolongement sans signal.
func test_refus_sans_modification() -> String:
	var plateau: Plateau = DEPART.creer_plateau()
	var signaux: Array[bool] = []
	plateau.modifie.connect(func() -> void: signaux.append(true))
	for centre: Vector2i in [Vector2i(3, 0), Vector2i(6, 2), Vector2i(4, -6)]:
		if Extension.est_valide(plateau, SENTIER, centre, 0) or Extension.appliquer(plateau, SENTIER, centre, 0):
			return "Le sentier doit être refusé au centre %s." % centre
		if not signaux.is_empty() or plateau.coords_sols().size() != DEPART.terrain.get_area():
			return "Le refus au centre %s a modifié le plateau." % centre
	return ""


## Vérifie l'indépendance des trois collections et le silence d'un lot de sols identiques.
func test_copie_independante() -> String:
	var original: Plateau = DEPART.creer_plateau()
	original.tourner(DEPART.horloge)
	var copie: Plateau = original.dupliquer()
	if (copie.coords_sols() != original.coords_sols()
			or copie.piece_de(DEPART.horloge) != original.piece_de(DEPART.horloge)
			or copie.rotation_de(DEPART.horloge) != 1):
		return "La copie doit reprendre le sol, l'horloge et son orientation."
	var signaux: Array[bool] = []
	copie.modifie.connect(func() -> void: signaux.append(true))
	copie.ajouter_sols({DEPART.horloge: Plateau.Sol.HERBE})
	if not signaux.is_empty():
		return "Des sols identiques ne doivent émettre aucun signal."
	var nouvelle := Vector2i(8, 8)
	copie.ajouter_sols({nouvelle: Plateau.Sol.HERBE})
	copie.poser(nouvelle, copie.piece_de(DEPART.horloge))
	copie.tourner(DEPART.horloge)
	if original.a_sol(nouvelle) or original.piece_de(nouvelle) != null or original.rotation_de(DEPART.horloge) != 1:
		return "Modifier la copie a changé l'original."
	return ""


## Contrôle les définitions, leurs récompenses et les conditions de tirage.
func test_donnees_et_pioche() -> String:
	for def: ExtensionDef in [SENTIER, CARREFOUR]:
		var sentier: bool = def == SENTIER
		var id_attendu: StringName = &"extension_sentier" if sentier else &"extension_carrefour"
		if def.id != id_attendu or def.taille != 3:
			return "Identifiant ou taille incorrects pour %s." % def.nom
		for case: Vector2i in def.chemins:
			if not Rect2i(0, 0, 3, 3).has_point(case):
				return "Chemin hors du carré de %s." % def.nom
		var bonus: Dictionary = {}
		for lot: Lot in def.bonus:
			bonus[lot.objet.id] = lot.quantite
		var attendus: Dictionary = {&"atelier_soldats": 1, &"engrenage_droit": 2} if sentier \
				else {&"atelier_billes": 1, &"engrenage_droit": 2}
		# Le bonus en ressorts rend l'extension tentante (retour playtest « je double juste »).
		if bonus != attendus or def.ressorts != (15 if sentier else 25):
			return "Bonus incorrect pour %s." % def.nom
		var occurrences: int = 0
		for lot: Lot in REGLES.pioche:
			if lot.objet == def:
				occurrences += 1
				if lot.quantite != 1 or lot.poids != (1.5 if sentier else 1.0) or lot.vague_min != (2 if sentier else 3):
					return "Conditions de tirage incorrectes pour %s." % def.nom
		if occurrences != 1:
			return "%s doit figurer une fois dans la pioche." % def.nom
	return ""


## Playtest 1 : un sentier contre un bord sans route se raccorde seul à la route, sans longer l'horloge.
func test_sentier_sans_route_adjacente() -> String:
	var plateau: Plateau = DEPART.creer_plateau()
	# Côté ouest de la Prairie : aucune route n'y touche le bord.
	var centre := Vector2i(-6, 0)
	if not Extension.est_valide(plateau, SENTIER, centre, 1):
		return "Le sentier ouest doit être accepté grâce au raccord."
	var raccord: Array[Vector2i] = Extension.raccord(plateau, SENTIER, centre, 1)
	if raccord.is_empty():
		return "Le sentier ouest doit creuser un raccord."
	for case: Vector2i in raccord:
		if plateau.sol_de(case) != Plateau.Sol.HERBE or plateau.piece_de(case) != null:
			return "Le raccord ne doit passer que par de l'herbe libre (%s)." % case
		for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if case + direction == DEPART.horloge:
				return "Le raccord ne doit pas toucher le flanc de l'horloge (%s)." % case
	if not Extension.appliquer(plateau, SENTIER, centre, 1):
		return "La pose avec raccord doit réussir."
	var distances: Dictionary = ChampFlux.calculer(plateau)
	for case: Vector2i in raccord:
		if not distances.has(case):
			return "Le raccord doit être relié à l'horloge."
	if not ChampFlux.entrees(plateau, distances).has(Vector2i(-7, 0)):
		return "L'extrémité du sentier doit devenir une entrée."
	return ""


## Une pièce posée bloque le raccord : on contourne, et si tout est fermé, la pose est refusée.
func test_raccord_bloque_par_des_pieces() -> String:
	var plateau: Plateau = DEPART.creer_plateau()
	var atelier: Plateau.PieceDef = preload("res://data/tuiles/atelier_soldats.tres")
	# Mur d'ateliers sur toute la colonne x = -4 : plus aucun passage depuis l'ouest.
	for y: int in range(-4, 5):
		plateau.poser(Vector2i(-4, y), atelier)
	if Extension.est_valide(plateau, SENTIER, Vector2i(-6, 0), 1):
		return "Sans passage libre, le sentier ouest doit être refusé."
	return ""
