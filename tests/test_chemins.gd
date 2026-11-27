extends RefCounted
## Playtest 3 : les unités suivent strictement les routes, contournent les bâtiments et montent sur le Pont.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Plateau = preload("res://game/board/plateau.gd")
const Production = preload("res://game/workshops/production.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const DROIT = preload("res://data/tuiles/engrenage_droit.tres")
const PONT = preload("res://data/tuiles/pont.tres")
const SOLDAT = preload("res://data/unites/soldat_remontoir.tres")
const SCARABEE = preload("res://data/unites/scarabee.tres")
const REGLES = preload("res://data/regles.tres")


# Route en U : (0,0) horloge, descend en x = 0 jusqu'à y = 3, part à droite jusqu'à x = 2, remonte jusqu'à y = 0.
# Les deux bras du U sont séparés par une colonne d'herbe (x = 1) : 4 m à vol d'oiseau, bien plus par la route.
func _plateau_en_u() -> Plateau:
	var plateau := Plateau.new()
	for x: int in range(-2, 5):
		for y: int in range(-2, 6):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	for case: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 2),
			Vector2i(2, 1), Vector2i(2, 0), Vector2i(2, -1), Vector2i(2, -2)]:
		plateau.ajouter_sol(case, Plateau.Sol.CHEMIN)
	plateau.poser(Vector2i.ZERO, HORLOGE)
	return plateau


func _sur_route(plateau: Plateau, lieu: Vector2) -> bool:
	var case := Vector2i((lieu / SwarmSim.MAILLE).round())
	return plateau.sol_de(case) == Plateau.Sol.CHEMIN or plateau.piece_de(case) == HORLOGE


## Un soldat qui voit un ennemi de l'autre côté de l'herbe le rejoint par la route, jamais en coupant.
func test_poursuite_par_la_route() -> String:
	var plateau: Plateau = _plateau_en_u()
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	sim.ajouter(SOLDAT, Vector2(0, 2))
	var immobile: SwarmSim.UniteDef = SCARABEE.duplicate()
	immobile.vitesse = 0.0
	immobile.pv = 9999.0
	sim.ajouter(immobile, Vector2(4, 2))
	var depart: Vector2 = sim.positions(SwarmSim.ALLIE)[0]
	for pas: int in 200:
		sim.avancer(0.05)
		if sim.nombre(SwarmSim.ALLIE) == 0:
			break
		if not _sur_route(plateau, sim.positions(SwarmSim.ALLIE)[0]):
			return "Le soldat a quitté la route en %s." % sim.positions(SwarmSim.ALLIE)[0]
	if sim.nombre(SwarmSim.ALLIE) > 0 and sim.positions(SwarmSim.ALLIE)[0].distance_to(Vector2(4, 2)) > 1.2 \
			and sim.positions(SwarmSim.ALLIE)[0].is_equal_approx(depart):
		return "Le soldat doit rejoindre l'ennemi par la route."
	return ""


## Une foule née au même point se serre sans déborder sur l'herbe.
func test_foule_reste_dans_le_couloir() -> String:
	var plateau: Plateau = _plateau_en_u()
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	for i: int in 40:
		sim.ajouter(SCARABEE, Vector2(4, -4))
	for pas: int in 120:
		sim.avancer(0.05)
		for lieu: Vector2 in sim.positions(SwarmSim.ENNEMI):
			if not _sur_route(plateau, lieu):
				return "Un scarabée a débordé sur l'herbe en %s." % lieu
	return ""


## Un atelier derrière un engrenage lâche ses jouets du côté d'une case libre ; ils rejoignent la route sans
## traverser de bâtiment.
func test_jouets_contournent_les_batiments() -> String:
	var plateau: Plateau = _plateau_en_u()
	# Chaîne horloge → engrenage (-1,0) → atelier (-2,0) ; la route est à droite : les jouets doivent contourner.
	plateau.poser(Vector2i(-1, 0), DROIT, 1)
	plateau.poser(Vector2i(-2, 0), ATELIER, 3)
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	var sortie: Vector2 = sim.sortie_atelier(Vector2i(-2, 0))
	if sortie == Vector2.INF:
		return "L'atelier a une case libre à côté de lui : il doit avoir une sortie."
	var case_sortie := Vector2i((sortie / SwarmSim.MAILLE).round())
	if plateau.piece_de(case_sortie) != null:
		return "La sortie donne sur un bâtiment (%s)." % case_sortie
	sim.ajouter(SOLDAT, sortie)
	for pas: int in 400:
		sim.avancer(0.05)
		var lieu: Vector2 = sim.positions(SwarmSim.ALLIE)[0]
		var case := Vector2i((lieu / SwarmSim.MAILLE).round())
		var piece: Plateau.PieceDef = plateau.piece_de(case)
		if piece != null and piece != HORLOGE:
			return "Le jouet traverse un bâtiment en %s." % case
		if plateau.sol_de(case) == Plateau.Sol.CHEMIN:
			return ""
	return "Le jouet n'a jamais rejoint la route."


## Les unités montent sur le tablier du Pont (relief) ; ailleurs le sol est plat.
func test_relief_du_pont() -> String:
	var plateau: Plateau = _plateau_en_u()
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	if sim.a_du_relief() or sim.relief(Vector2(0, 4)) != 0.0:
		return "Sans Pont, le sol doit être plat."
	plateau.poser(Vector2i(0, 2), PONT, 0)
	sim.configurer(plateau)
	if not is_equal_approx(sim.relief(Vector2(0, 4)), SwarmSim.HAUTEUR_PONT):
		return "Au milieu du Pont, l'unité doit être à la hauteur du tablier."
	if sim.relief(Vector2(0, 5.15)) <= 0.0 or sim.relief(Vector2(0, 5.15)) >= SwarmSim.HAUTEUR_PONT:
		return "Sur la marche, la hauteur doit être intermédiaire."
	return "" if sim.relief(Vector2(0, 7)) == 0.0 else "Loin du Pont, le sol doit être plat."
