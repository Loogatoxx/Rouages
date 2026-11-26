extends RefCounted
## Vérifie les achats de niveaux, leur durée de vie et leurs effets sur les pièces voisines.

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const Placement = preload("res://game/workshops/placement.gd")
const Partie = preload("res://game/core/run.gd")
const REGLES = preload("res://data/regles.tres")
const DROIT = preload("res://data/tuiles/engrenage_droit.tres")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const CANON = preload("res://data/tuiles/tourelle_canon.tres")
const REPARTITEUR = preload("res://data/tuiles/engrenage_t.tres")
const MOYEU = preload("res://data/tuiles/engrenage_croix.tres")
const CENTRE: Vector2i = Vector2i.ZERO


func _poser(plateau: Plateau, case: Vector2i, piece: PieceDef) -> void:
	plateau.ajouter_sol(case, Plateau.Sol.HERBE)
	plateau.poser(case, piece)


func _verifier_achats(partie: Partie, piece: PieceDef, maximum: int, prix_base: int) -> String:
	var plateau: Plateau = Plateau.new()
	_poser(plateau, CENTRE, piece)
	for niveau: int in range(1, maximum):
		var prix: int = prix_base * niveau
		if partie.prix_amelioration(plateau, CENTRE) != prix:
			return "%s : prix incorrect au niveau %d" % [piece.nom, niveau]
		partie.ressorts = prix
		if not partie.ameliorer_piece(plateau, CENTRE) or partie.ressorts != 0 or plateau.niveau_de(CENTRE) != niveau + 1:
			return "%s : achat incorrect au niveau %d" % [piece.nom, niveau]
	partie.ressorts = 100
	if partie.ameliorer_piece(plateau, CENTRE) or partie.ressorts != 100 or plateau.niveau_de(CENTRE) != maximum:
		return "%s : le niveau maximum doit bloquer l'achat et le débit" % piece.nom
	return ""


## Vérifie tous les tarifs et les plafonds des trois familles pendant les deux phases de jeu.
func test_prix_et_niveaux_maximum() -> String:
	var partie: Partie = Partie.new()
	partie.phase = Partie.Phase.CONSTRUCTION
	var erreur: String = _verifier_achats(partie, DROIT, 3, 4)
	if erreur.is_empty():
		partie.phase = Partie.Phase.VAGUE
		erreur = _verifier_achats(partie, ATELIER, 5, 10)
	if erreur.is_empty():
		erreur = _verifier_achats(partie, CANON, 5, 12)
	partie.free()
	return erreur


## Un achat sans ressorts, hors phase, sur l'horloge ou sur une case vide laisse la partie intacte.
func test_achat_refuse() -> String:
	var plateau: Plateau = Plateau.new()
	_poser(plateau, CENTRE, ATELIER)
	var horloge: PieceDef = PieceDef.new()
	horloge.type = PieceDef.Type.HORLOGE
	_poser(plateau, Vector2i.UP, horloge)
	var partie: Partie = Partie.new()
	partie.ressorts = 10
	var refuse: bool = not partie.ameliorer_piece(plateau, CENTRE)
	partie.phase = Partie.Phase.FIN
	refuse = refuse and not partie.ameliorer_piece(plateau, CENTRE)
	partie.phase = Partie.Phase.CONSTRUCTION
	refuse = refuse and not partie.ameliorer_piece(plateau, Vector2i.UP)
	refuse = refuse and not partie.ameliorer_piece(plateau, Vector2i.DOWN) and partie.ressorts == 10
	partie.ressorts = 9
	refuse = refuse and not partie.ameliorer_piece(plateau, CENTRE) and partie.ressorts == 9
	partie.free()
	return "" if refuse and plateau.niveau_de(CENTRE) == 1 else "Un achat interdit a changé la partie"


## Tourner conserve le niveau, reprendre puis reposer la même pièce le ramène à un.
func test_reprise_et_rotation() -> String:
	var plateau: Plateau = Plateau.new()
	_poser(plateau, CENTRE, ATELIER)
	plateau.ameliorer(CENTRE)
	var partie: Partie = Partie.new()
	partie.phase = Partie.Phase.CONSTRUCTION
	var succes: bool = partie.tourner_piece(plateau, CENTRE) and plateau.niveau_de(CENTRE) == 2
	succes = succes and partie.reprendre_piece(plateau, CENTRE) and plateau.niveau_de(CENTRE) == 1
	succes = succes and plateau.poser(CENTRE, partie.reserve.trouver(ATELIER.id) as PieceDef)
	partie.free()
	return "" if succes and plateau.niveau_de(CENTRE) == 1 else "La rotation ou la reprise gère mal le niveau"


## Le niveau appartient à la case et sa copie évolue indépendamment.
func test_dupliquer_niveaux() -> String:
	var plateau: Plateau = Plateau.new()
	_poser(plateau, CENTRE, DROIT)
	_poser(plateau, Vector2i.UP, DROIT)
	plateau.ameliorer(CENTRE)
	var copie: Plateau = plateau.dupliquer()
	if copie.niveau_de(CENTRE) != 2 or not copie.ameliorer(CENTRE):
		return "La copie doit reprendre le niveau courant"
	return "" if plateau.niveau_de(CENTRE) == 2 and plateau.niveau_de(Vector2i.UP) == 1 else "Niveaux partagés"


## Chaque niveau ajoute cadence et capacité à l'atelier, et dégâts à la tourelle.
func test_gains_des_batiments() -> String:
	var plateau: Plateau = Plateau.new()
	_poser(plateau, CENTRE, ATELIER)
	_poser(plateau, Vector2i.UP, CANON)
	for rang: int in 5:
		if not is_equal_approx(Placement.cadence_atelier(plateau, {}, CENTRE, REGLES), 1.0 + 0.2 * rang):
			return "Cadence de l'atelier incorrecte"
		if Placement.plafond_atelier(plateau, {}, CENTRE) != 3 * rang:
			return "Plafond de l'atelier incorrect"
		if not is_equal_approx(Placement.degats_tourelle(plateau, Vector2i.UP, REGLES), 1.0 + 0.25 * rang):
			return "Dégâts de la tourelle incorrects"
		plateau.ameliorer(CENTRE)
		plateau.ameliorer(Vector2i.UP)
	return ""


## Au niveau trois, seuls les engrenages alimentés doublent leur bonus de voisinage.
func test_engrenages_niveau_trois() -> String:
	var plateau: Plateau = Plateau.new()
	_poser(plateau, CENTRE, ATELIER)
	_poser(plateau, Vector2i.UP, DROIT)
	_poser(plateau, Vector2i.LEFT, REPARTITEUR)
	_poser(plateau, Vector2i.RIGHT, MOYEU)
	_poser(plateau, Vector2i.RIGHT * 2, CANON)
	var alimentes: Dictionary = {}
	for case: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		plateau.ameliorer(case)
		plateau.ameliorer(case)
		alimentes[case] = true
	if not is_equal_approx(Placement.cadence_atelier(plateau, alimentes, CENTRE, REGLES), 1.30):
		return "Le bonus du démultiplicateur de niveau 3 doit atteindre 30 %"
	if Placement.plafond_atelier(plateau, alimentes, CENTRE) != 8:
		return "Le répartiteur de niveau 3 doit ajouter huit places"
	if not is_equal_approx(Placement.cadence_tourelle(plateau, alimentes, Vector2i.RIGHT * 2), 1.4):
		return "Le moyeu de niveau 3 doit ajouter 40 % de cadence"
	return "" if is_equal_approx(Placement.cadence_atelier(plateau, {}, CENTRE, REGLES), 1.0) else "Bonus sans énergie"
