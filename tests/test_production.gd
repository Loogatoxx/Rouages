extends RefCounted
## Vérifie la cadence, la sortie orientée et le plafond des ateliers.

const Production = preload("res://game/workshops/production.gd")
const Plateau = preload("res://game/board/plateau.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const REGLES = preload("res://data/regles.tres")
const Regles = preload("res://game/core/regles.gd")


# Règles sans malus d'encombrement : le plateau de test colle deux ateliers identiques (voir test_placement.gd).
func _regles() -> Regles:
	var regles: Regles = REGLES.duplicate()
	regles.malus_encombrement = 0.0
	return regles


func _plateau() -> Plateau:
	var plateau: Plateau = Plateau.new()
	for case: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT]:
		plateau.ajouter_sol(case, Plateau.Sol.HERBE)
		plateau.poser(case, ATELIER, 1)
	return plateau


## Un atelier tourné et alimenté produit « cadence × 10 » soldats en dix secondes par son port ouest.
func test_cadence_et_port() -> String:
	var plateau: Plateau = _plateau()
	var production: Production = Production.new()
	var sim: SwarmSim = SwarmSim.new()
	# 41 pas de 0,25 s : la marge évite qu'une somme flottante (10,9999…) fasse perdre un jouet.
	for i: int in 41:
		production.avancer(0.25, plateau, {Vector2i.ZERO: true}, sim, _regles())
	var attendu: int = floori(10.25 * ATELIER.cadence_production)
	if sim.nombre(SwarmSim.ALLIE) != attendu:
		return "Un atelier alimenté doit produire %d soldats en 10 s." % attendu
	for position: Vector2 in sim.positions(SwarmSim.ALLIE):
		if not position.is_equal_approx(Vector2.LEFT):
			return "Le soldat doit apparaître sur le bord du port tourné."
	return ""


## Un atelier privé d'énergie ne produit rien et ne rattrape pas le temps écoulé.
func test_atelier_sans_energie() -> String:
	var plateau: Plateau = _plateau()
	var sim: SwarmSim = SwarmSim.new()
	var production: Production = Production.new()
	production.avancer(100.0, plateau, {}, sim, REGLES)
	production.avancer(0.1, plateau, {Vector2i.ZERO: true}, sim, REGLES)
	return "" if sim.nombre(SwarmSim.ALLIE) == 0 else "L'atelier a produit sans énergie."


## Le plafond est individuel (playtest 2) : un atelier plein n'empêche pas son voisin de produire, et ne
## reproduit que lorsque ses propres jouets tombent.
func test_plafond_par_atelier() -> String:
	var plateau: Plateau = _plateau()
	var sim: SwarmSim = SwarmSim.new()
	var production: Production = Production.new()
	var alimentees: Dictionary = {Vector2i.ZERO: true}
	production.avancer(100.0, plateau, alimentees, sim, REGLES)
	if sim.effectif(Vector2i.ZERO) != REGLES.plafond_allies_par_atelier:
		return "Un atelier doit s'arrêter à son propre plafond."
	alimentees[Vector2i.RIGHT] = true
	production.avancer(100.0, plateau, alimentees, sim, REGLES)
	if sim.effectif(Vector2i.RIGHT) != REGLES.plafond_allies_par_atelier:
		return "Le voisin d'un atelier plein doit pouvoir remplir son propre plafond."
	if sim.nombre(SwarmSim.ALLIE) != 2 * REGLES.plafond_allies_par_atelier:
		return "Plafond incorrect pour deux ateliers."
	sim.vider(SwarmSim.ALLIE)
	return "" if sim.effectif(Vector2i.ZERO) == 0 else "Vider le camp doit remettre les effectifs à zéro."


## Playtest 2 : au lancement, chaque atelier repart de zéro et sort ses jouets un par un (aucune rafale).
func test_sortie_un_par_un() -> String:
	var plateau: Plateau = _plateau()
	var production: Production = Production.new()
	var sim: SwarmSim = SwarmSim.new()
	var alimentees: Dictionary = {Vector2i.ZERO: true}
	production.avancer(30.0, plateau, alimentees, sim, REGLES)
	sim.vider(SwarmSim.ALLIE)
	production.nouvelle_vague()
	production.avancer(0.0, plateau, alimentees, sim, REGLES)
	if REGLES.avance_lancement < 1.0 and sim.nombre(SwarmSim.ALLIE) != 0:
		return "Aucun jouet ne doit être prêt à l'instant du lancement."
	var maximum: int = 0
	for pas: int in 310:
		var avant: int = sim.nombre(SwarmSim.ALLIE)
		production.avancer(1.0 / 60.0, plateau, alimentees, sim, REGLES)
		maximum = maxi(maximum, sim.nombre(SwarmSim.ALLIE) - avant)
	# Cadence de base ± bonus de placement (encombrement, arrière-garde).
	var minimum: int = floori(310.0 / 60.0 * ATELIER.cadence_production * 0.5)
	var plafond: int = ceili(310.0 / 60.0 * ATELIER.cadence_production * 1.3)
	if sim.nombre(SwarmSim.ALLIE) < minimum or sim.nombre(SwarmSim.ALLIE) > plafond:
		return "En 5,2 s, l'atelier doit sortir %d à %d jouets (obtenu %d)." % [minimum, plafond, sim.nombre(SwarmSim.ALLIE)]
	return "" if maximum <= 1 else "Les jouets doivent sortir un par un, pas en rafale."


## Un atelier repris en pleine vague rappelle ses jouets (relecture T13a) : son plafond ne se « recharge » pas en
## le déplaçant, et les autres ateliers gardent les leurs.
func test_rappel_atelier_repris() -> String:
	var plateau: Plateau = _plateau()
	var sim: SwarmSim = SwarmSim.new()
	var production: Production = Production.new()
	production.avancer(100.0, plateau, {Vector2i.ZERO: true, Vector2i.RIGHT: true}, sim, REGLES)
	sim.rappeler(Vector2i.ZERO)
	if sim.effectif(Vector2i.ZERO) != 0:
		return "Les jouets de l'atelier repris doivent rentrer."
	return "" if sim.effectif(Vector2i.RIGHT) == REGLES.plafond_allies_par_atelier else "Le voisin a perdu ses jouets."
