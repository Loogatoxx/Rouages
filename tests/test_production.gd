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


## Un atelier tourné et alimenté produit six soldats en dix secondes par son port ouest.
func test_cadence_et_port() -> String:
	var plateau: Plateau = _plateau()
	var production: Production = Production.new()
	var sim: SwarmSim = SwarmSim.new()
	for i: int in 40:
		production.avancer(0.25, plateau, {Vector2i.ZERO: true}, sim, _regles())
	if sim.nombre(SwarmSim.ALLIE) != 6:
		return "Un atelier alimenté doit produire 6 soldats en 10 s."
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


## Seuls les ateliers alimentés contribuent au plafond commun de soldats.
func test_plafond_partage() -> String:
	var plateau: Plateau = _plateau()
	var sim: SwarmSim = SwarmSim.new()
	var production: Production = Production.new()
	var alimentees: Dictionary = {Vector2i.ZERO: true}
	production.avancer(100.0, plateau, alimentees, sim, REGLES)
	if sim.nombre(SwarmSim.ALLIE) != REGLES.plafond_allies_par_atelier:
		return "Un seul atelier alimenté doit compter pour le plafond."
	alimentees[Vector2i.RIGHT] = true
	production.avancer(100.0, plateau, alimentees, sim, REGLES)
	if sim.nombre(SwarmSim.ALLIE) != 2 * REGLES.plafond_allies_par_atelier:
		return "Plafond incorrect pour deux ateliers."
	return ""


## Vraie pause entre les vagues : le remontage verse 20 s de production d'un coup, une fois par pause, dans le plafond.
func test_remontage_au_lancement() -> String:
	var plateau: Plateau = _plateau()
	var production: Production = Production.new()
	var sim: SwarmSim = SwarmSim.new()
	var alimentees: Dictionary = {Vector2i.ZERO: true, Vector2i.RIGHT: true}
	var regles: Regles = _regles()
	production.remonter(20.0, plateau, alimentees, sim, regles)
	var attendu: int = mini(2 * floori(20.0 * ATELIER.cadence_production), 2 * REGLES.plafond_allies_par_atelier)
	if sim.nombre(SwarmSim.ALLIE) != attendu:
		return "Le remontage doit sortir %d jouets (obtenu %d)." % [attendu, sim.nombre(SwarmSim.ALLIE)]
	var avant: int = sim.nombre(SwarmSim.ALLIE)
	production.remonter(20.0, plateau, alimentees, sim, regles)
	if sim.nombre(SwarmSim.ALLIE) != avant:
		return "Un atelier n'est remonté qu'une fois par pause : attendre ne rapporte rien."
	production.nouvelle_pause()
	production.remonter(20.0, plateau, alimentees, sim, regles)
	if sim.nombre(SwarmSim.ALLIE) > 2 * REGLES.plafond_allies_par_atelier:
		return "Le remontage ne doit jamais dépasser le plafond."
	return ""
