extends RefCounted
## Vérifie les tirs autonomes et l'alternance entre drafts ordinaires et coffres.

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")
const EtatPartie = preload("res://game/core/run.gd")
const Energie = preload("res://game/board/energie.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const Tourelles = preload("res://game/workshops/tourelles.gd")
const Lot = preload("res://game/core/lot.gd")
const CANON = preload("res://data/tuiles/tourelle_canon.tres")
const CARILLON = preload("res://data/tuiles/tourelle_carillon.tres")


func _ennemi(pv: float) -> UniteDef:
	var modele := UniteDef.new()
	modele.camp = SwarmSim.ENNEMI
	modele.pv = pv
	return modele


## Vérifie que le tir simple atteint le plus proche et laisse la simulation annoncer sa mort.
func test_tir_a_portee() -> String:
	var sim := SwarmSim.new()
	var scarabee: UniteDef = _ennemi(CANON.degats_tir)
	var centre := Vector2(8, 6)
	var proche: Vector2 = centre + Vector2.RIGHT
	sim.ajouter(scarabee, centre + Vector2.UP * 2.0)
	sim.ajouter(scarabee, proche)
	var tirs: Array[Vector2] = []
	var morts: Array[Vector2] = []
	sim.tir.connect(func(de: Vector2, vers: Vector2) -> void: tirs.append_array([de, vers]))
	sim.unite_morte.connect(func(_camp: int, lieu: Vector2, _def: UniteDef) -> void: morts.append(lieu))
	if not sim.blesser_zone(centre, CANON.portee_tir, CANON.degats_tir, CANON.zone_tir):
		return "Le canon a manqué une cible à portée."
	if tirs != [centre, proche] or not is_equal_approx(sim.touches(SwarmSim.ENNEMI)[1], 0.12):
		return "La trajectoire ou le flash ne correspond pas à la cible la plus proche."
	if sim.nombre(SwarmSim.ENNEMI) != 2 or not morts.is_empty():
		return "La cible a été retirée avant le pas de simulation."
	sim.avancer(0.01)
	return "" if morts == [proche] and sim.nombre(SwarmSim.ENNEMI) == 1 else "Le tir simple doit casser un seul scarabée."


## Vérifie qu'un ennemi trop loin ne déclenche aucun tir.
func test_hors_portee() -> String:
	var sim := SwarmSim.new()
	sim.ajouter(_ennemi(CANON.degats_tir), Vector2.RIGHT * (CANON.portee_tir + 0.1))
	if sim.blesser_zone(Vector2.ZERO, CANON.portee_tir, CANON.degats_tir, CANON.zone_tir):
		return "Le canon a atteint un ennemi hors de portée."
	return "" if sim.touches(SwarmSim.ENNEMI)[0] == 0.0 else "L'ennemi hors de portée a clignoté."


## Vérifie que la zone est centrée sur la cible et qu'elle épargne les alliés.
func test_zone_autour_de_la_cible() -> String:
	var sim := SwarmSim.new()
	var scarabee: UniteDef = _ennemi(CARILLON.degats_tir)
	var impact: Vector2 = Vector2.RIGHT * CARILLON.portee_tir
	var bord: Vector2 = impact + Vector2.RIGHT * CARILLON.zone_tir
	sim.ajouter(scarabee, impact)
	sim.ajouter(scarabee, bord)
	sim.ajouter(scarabee, bord + Vector2.RIGHT)
	var allie: UniteDef = scarabee.duplicate()
	allie.camp = SwarmSim.ALLIE
	sim.ajouter(allie, impact)
	sim.blesser_zone(Vector2.ZERO, CARILLON.portee_tir, CARILLON.degats_tir, CARILLON.zone_tir)
	if sim.touches(SwarmSim.ENNEMI) != PackedFloat32Array([0.12, 0.12, 0.0]) or sim.touches(SwarmSim.ALLIE)[0] > 0.0:
		return "Seuls les deux ennemis dans la zone doivent clignoter."
	sim.avancer(0.01)
	return "" if sim.nombre(SwarmSim.ENNEMI) == 1 and sim.nombre(SwarmSim.ALLIE) == 1 else "Dégâts de zone incorrects."


## Vérifie qu'un canon posé sur l'herbe reste silencieux jusqu'au raccordement de son port.
func test_tourelle_non_alimentee() -> String:
	var plateau := Plateau.new()
	var case := Vector2i(8, 5)
	plateau.ajouter_sol(case, Plateau.Sol.HERBE)
	if not plateau.poser(case, CANON, 0):
		return "La tourelle doit pouvoir se poser sur l'herbe."
	var sim := SwarmSim.new()
	sim.ajouter(_ennemi(CANON.degats_tir), Vector2(case) * GrilleMonde.TAILLE_CASE)
	var tourelles := Tourelles.new()
	tourelles.avancer(0.1, plateau, Energie.calculer(plateau), sim)
	if sim.touches(SwarmSim.ENNEMI)[0] != 0.0:
		return "Une tourelle débranchée a tiré."
	var horloge := PieceDef.new()
	horloge.type = PieceDef.Type.HORLOGE
	horloge.ports = 15
	plateau.ajouter_sol(case + Vector2i.DOWN, Plateau.Sol.HERBE)
	if not plateau.poser(case + Vector2i.DOWN, horloge, 0):
		return "Impossible d'installer l'horloge du test."
	tourelles.avancer(0.1, plateau, Energie.calculer(plateau), sim)
	return "" if sim.touches(SwarmSim.ENNEMI)[0] > 0.0 else "Le canon raccordé doit tirer depuis sa case."


## Vérifie qu'une tourelle à l'affût tire aussitôt puis attend une période entre deux touches.
func test_recharge_seulement_apres_impact() -> String:
	var plateau := Plateau.new()
	var case := Vector2i.ZERO
	plateau.ajouter_sol(case, Plateau.Sol.HERBE)
	plateau.poser(case, CANON, 0)
	var sim := SwarmSim.new()
	var tourelles := Tourelles.new()
	var alimentees: Dictionary = {case: 1}
	var periode: float = 1.0 / CANON.cadence_tir
	tourelles.avancer(periode / 4.0, plateau, alimentees, sim)
	var scarabee: UniteDef = _ennemi(CANON.degats_tir)
	sim.ajouter(scarabee, Vector2.RIGHT)
	sim.ajouter(scarabee, Vector2.RIGHT * 2.0)
	tourelles.avancer(periode / 4.0, plateau, alimentees, sim)
	sim.avancer(0.01)
	if sim.nombre(SwarmSim.ENNEMI) != 1:
		return "Le canon doit tirer dès l'arrivée du premier ennemi."
	tourelles.avancer(periode / 2.0, plateau, alimentees, sim)
	if sim.touches(SwarmSim.ENNEMI)[0] != 0.0:
		return "Le canon a tiré pendant sa recharge."
	tourelles.avancer(periode / 2.0, plateau, alimentees, sim)
	return "" if sim.touches(SwarmSim.ENNEMI)[0] > 0.0 else "Le canon n'a pas repris le tir après sa recharge."


## Vérifie les sacs du départ, des fins de vague et de la relance payante.
func test_offres_de_coffre() -> String:
	var partie := EtatPartie.new()
	partie.reinitialiser()
	var resultat: String = _verifier_offres(partie)
	partie.free()
	return resultat


func _verifier_offres(partie: EtatPartie) -> String:
	for numero: int in range(partie.nb_vagues):
		var attendu: bool = numero in [3, 6, 9]
		if partie.offre_coffre != attendu:
			return "Mauvais type d'offre après %d vagues." % numero
		var sac: Array[Lot] = partie.regles.coffre if attendu else partie.regles.pioche
		if not _offre_du_sac(partie.offre, sac):
			return "Les trois cartes doivent provenir du sac prévu après %d vagues." % numero
		if attendu:
			if not partie.relancer_offre() or not _offre_du_sac(partie.offre, sac):
				return "La relance doit tirer trois cartes dans le coffre."
		partie.choisir_lot(0)
		partie.lancer_vague()
		partie.terminer_vague()
	return ""


func _offre_du_sac(offre: Array[Lot], sac: Array[Lot]) -> bool:
	if offre.size() != 3:
		return false
	for lot: Lot in offre:
		if lot not in sac:
			return false
	return true
