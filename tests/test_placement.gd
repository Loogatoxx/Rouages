extends RefCounted
## Vérifie les effets de place (playtest 1, benchmark D1-D3) : route, arrière-garde, engrenages à identité, encombrement.

const Plateau = preload("res://game/board/plateau.gd")
const Placement = preload("res://game/workshops/placement.gd")
const REGLES = preload("res://data/regles.tres")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const DROIT = preload("res://data/tuiles/engrenage_droit.tres")
const T = preload("res://data/tuiles/engrenage_t.tres")
const CROIX = preload("res://data/tuiles/engrenage_croix.tres")
const CANON = preload("res://data/tuiles/tourelle_canon.tres")


# Bande d'herbe de 8 cases sur y = 0, avec un chemin le long de y = -1.
func _plateau() -> Plateau:
	var plateau := Plateau.new()
	for x: int in 8:
		plateau.ajouter_sol(Vector2i(x, 0), Plateau.Sol.HERBE)
		plateau.ajouter_sol(Vector2i(x, 1), Plateau.Sol.HERBE)
		plateau.ajouter_sol(Vector2i(x, 2), Plateau.Sol.HERBE)
		plateau.ajouter_sol(Vector2i(x, 3), Plateau.Sol.HERBE)
		plateau.ajouter_sol(Vector2i(x, -1), Plateau.Sol.CHEMIN)
	return plateau


## Bord de route : sortie côté route et dégâts de tourelle en plus ; arrière-garde à 3 cases : cadence en plus.
func test_route_et_arriere_garde() -> String:
	var plateau: Plateau = _plateau()
	plateau.poser(Vector2i(0, 0), ATELIER)
	plateau.poser(Vector2i(4, 2), ATELIER)
	plateau.poser(Vector2i(6, 0), CANON)
	if Placement.cote_route(plateau, Vector2i(0, 0)) != Vector2i.UP:
		return "L'atelier en bord de route doit lâcher ses jouets côté route."
	if not is_equal_approx(Placement.cadence_atelier(plateau, {}, Vector2i(0, 0), REGLES), 1.0):
		return "En bord de route, la cadence ne change pas."
	if not is_equal_approx(Placement.cadence_atelier(plateau, {}, Vector2i(4, 2), REGLES), 1.0 + REGLES.bonus_arriere_cadence):
		return "À 3 cases de la route, l'atelier gagne le bonus d'arrière-garde."
	if not is_equal_approx(Placement.degats_tourelle(plateau, Vector2i(6, 0), REGLES), 1.0 + REGLES.bonus_route_degats):
		return "Une tourelle en bord de route frappe plus fort."
	return ""


## Démultiplicateurs (cumul 2), répartiteur, moyeu : seulement s'ils sont alimentés ; encombrement des ateliers collés.
func test_engrenages_a_identite() -> String:
	var plateau: Plateau = _plateau()
	var atelier := Vector2i(3, 1)
	plateau.poser(atelier, ATELIER)
	for case: Vector2i in [Vector2i(2, 1), Vector2i(4, 1), Vector2i(3, 0)]:
		plateau.poser(case, DROIT)
	var alimentees: Dictionary = {Vector2i(2, 1): true, Vector2i(4, 1): true, Vector2i(3, 0): true}
	var attendu: float = 1.0 + 2 * DROIT.bonus_voisins_cadence
	if not is_equal_approx(Placement.cadence_atelier(plateau, alimentees, atelier, REGLES), attendu):
		return "Trois démultiplicateurs ne doivent compter que pour deux."
	if not is_equal_approx(Placement.cadence_atelier(plateau, {}, atelier, REGLES), 1.0):
		return "Un engrenage non alimenté ne donne rien."
	plateau.poser(Vector2i(3, 2), T)
	if Placement.plafond_atelier(plateau, {Vector2i(3, 2): true}, atelier) != T.bonus_voisins_plafond:
		return "Le répartiteur ajoute des places au plafond de l'atelier voisin."
	plateau.poser(Vector2i(6, 2), CANON)
	plateau.poser(Vector2i(6, 3), CROIX)
	if not is_equal_approx(Placement.cadence_tourelle(plateau, {Vector2i(6, 3): true}, Vector2i(6, 2)), 1.0 + CROIX.bonus_voisins_tourelle):
		return "Le moyeu accélère la tourelle voisine."
	var serre: Plateau = _plateau()
	serre.poser(Vector2i(1, 1), ATELIER)
	serre.poser(Vector2i(2, 1), ATELIER)
	if not is_equal_approx(Placement.cadence_atelier(serre, {}, Vector2i(1, 1), REGLES), 1.0 - REGLES.malus_encombrement):
		return "Deux ateliers identiques collés s'encombrent."
	return ""
