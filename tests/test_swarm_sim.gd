extends RefCounted
## Exerce la simulation par ses entrées publiques et ses signaux locaux.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Plateau = preload("res://game/board/plateau.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const SCARABEE = preload("res://data/unites/scarabee.tres")
const LANCE_BILLE = preload("res://data/unites/lance_bille.tres")
const SOLDAT = preload("res://data/unites/soldat_remontoir.tres")
const DEPART = preload("res://data/depart.tres")
const Extension = preload("res://game/board/extension.gd")
const CARREFOUR = preload("res://data/extensions/carrefour.tres")
const PAS := 1.0 / 60.0


func _ligne(longueur: int) -> Plateau:
	var plateau := Plateau.new()
	plateau.ajouter_sol(Vector2i.ZERO, Plateau.Sol.HERBE)
	plateau.poser(Vector2i.ZERO, HORLOGE)
	for x: int in range(1, longueur + 1):
		plateau.ajouter_sol(Vector2i(x, 0), Plateau.Sol.CHEMIN)
	return plateau


## Vérifie la vitesse et l'unicité du signal à l'entrée du disque de l'horloge.
func test_arrivee() -> String:
	var sim := SwarmSim.new()
	sim.configurer(_ligne(6))
	var impacts: Array[float] = []
	sim.ennemi_arrive.connect(func(d: float) -> void: impacts.append(d))
	sim.ajouter(SCARABEE, Vector2(8, 0))
	for i: int in 209:
		sim.avancer(PAS)
	if not impacts.is_empty():
		return "L'ennemi a parcouru sept mètres trop vite."
	for i: int in 3:
		sim.avancer(PAS)
	if sim.nombre(SwarmSim.ENNEMI) != 0:
		return "Le scarabée aurait dû atteindre l'horloge après 3,5 s."
	sim.avancer(1.0)
	return "" if impacts == [SCARABEE.degats_horloge] else "Un seul impact, au prix d'une fuite de scarabée, était attendu."


## Rejoue le duel : le scarabée tombe au coup de soldat prévu par les données (PV ÷ dégâts), pas avant.
func test_duel() -> String:
	var coups: int = ceili(SCARABEE.pv / SOLDAT.degats)
	var pas_attendus: int = roundi((coups - 1) / SOLDAT.cadence / PAS)
	for essai: int in 2:
		var sim := SwarmSim.new()
		var morts: Array = []
		sim.unite_morte.connect(func(camp: int, position: Vector2, def: UniteDef) -> void:
			morts.append([camp, position, def]))
		sim.ajouter(SCARABEE, Vector2(0.5, 0))
		sim.ajouter(SOLDAT, Vector2.ZERO)
		for i: int in pas_attendus - 2:
			sim.avancer(PAS)
		if not morts.is_empty():
			return "%d coups de soldat ne doivent pas tuer le scarabée." % (coups - 1)
		for i: int in 4:
			sim.avancer(PAS)
		if morts != [[SwarmSim.ENNEMI, Vector2(0.5, 0), SCARABEE]]:
			return "Le signal de mort doit identifier le scarabée et sa position."
		if sim.nombre(SwarmSim.ALLIE) != 1 or sim.nombre(SwarmSim.ENNEMI) != 0:
			return "Le dernier coup de soldat doit terminer le duel."
	return ""


## Vérifie les extrémités et le nombre de tirs, y compris sur un pas couvrant deux frappes.
func test_signal_tir() -> String:
	for modele: UniteDef in [LANCE_BILLE, SOLDAT]:
		var sim := SwarmSim.new()
		var tirs: Array[Vector2] = []
		sim.tir.connect(func(depart: Vector2, arrivee: Vector2) -> void:
			tirs.append(depart)
			tirs.append(arrivee))
		var cible := Vector2(modele.portee * 0.9, 0.0)
		sim.ajouter(modele, Vector2.ZERO)
		sim.ajouter(SCARABEE, cible)
		sim.avancer(PAS)
		sim.avancer(PAS)
		if modele == SOLDAT:
			if not tirs.is_empty() or sim.touches(SwarmSim.ENNEMI)[0] <= 0.0:
				return "Le soldat doit toucher au contact sans émettre de tir."
		else:
			if tirs != [Vector2.ZERO, cible]:
				return "Un seul tir aux coordonnées de la frappe était attendu pendant la recharge."
			sim.avancer(2.0 / modele.cadence)
			if tirs.size() != 6:
				return "Les deux frappes du grand pas doivent émettre deux tirs."
	return ""


## Mesure la plus petite distance après deux secondes de départ superposé.
func test_separation() -> String:
	var sim := SwarmSim.new()
	sim.configurer(_ligne(16))
	for i: int in 50:
		sim.ajouter(SCARABEE, Vector2(20, 0))
	for i: int in 120:
		sim.avancer(PAS)
	var lieux: PackedVector2Array = sim.positions(SwarmSim.ENNEMI)
	var minimum: float = INF
	for i: int in lieux.size():
		for j: int in i:
			minimum = minf(minimum, lieux[i].distance_to(lieux[j]))
	return "" if lieux.size() == 50 and minimum > 0.15 else "Distance minimale : %.3f m." % minimum


## Tue deux indices intérieurs, puis sonde les PV des survivants par des frappes connues.
func test_retrait_par_echange() -> String:
	var sim := SwarmSim.new()
	var frappeur: UniteDef = SOLDAT.duplicate()
	frappeur.vitesse = 0.0
	frappeur.degats = 10.0
	frappeur.cadence = 1.0
	for i: int in 5:
		var cible: UniteDef = SCARABEE.duplicate()
		cible.vitesse = 0.0
		cible.degats = 0.0
		cible.pv = 10.0 if i % 2 else (i + 1) * 10.0
		sim.ajouter(cible, Vector2(i * 10, 0))
	for i: int in [1, 3]:
		sim.ajouter(frappeur, Vector2(i * 10, 0))
	sim.avancer(1.0)
	if sim.nombre(SwarmSim.ENNEMI) != 3:
		return "Deux retraits au milieu étaient attendus."
	for i: int in [0, 2, 4]:
		sim.ajouter(frappeur, Vector2(i * 10, 0))
	for coup: int in range(1, 6):
		sim.avancer(1.0)
		var lieux: PackedVector2Array = sim.positions(SwarmSim.ENNEMI)
		var attendus: int = 0
		for i: int in [0, 2, 4]:
			if coup < i + 1:
				attendus += 1
				if not lieux.has(Vector2(i * 10, 0)):
					return "Les PV de la cible %d ont changé après échange." % i
		if lieux.size() != attendus:
			return "Effectif incorrect après la frappe %d." % coup
	return ""


## Suit un soldat à sa sortie de l'herbe, puis sur le chemin vers l'entrée.
func test_allie_hors_chemin() -> String:
	var plateau: Plateau = _ligne(8)
	plateau.ajouter_sol(Vector2i(2, 1), Plateau.Sol.HERBE)
	plateau.ajouter_sol(Vector2i(2, 2), Plateau.Sol.HERBE)
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	sim.ajouter(SOLDAT, Vector2(4, 4))
	for i: int in 120:
		sim.avancer(PAS)
	var passage: Vector2 = sim.positions(SwarmSim.ALLIE)[0]
	for i: int in 120:
		sim.avancer(PAS)
	var fin: Vector2 = sim.positions(SwarmSim.ALLIE)[0]
	return "" if absf(passage.y) < 1.0 and fin.x > passage.x + 4.0 and absf(fin.y) < 0.2 else "Trajet inattendu : %s puis %s." % [passage, fin]


## Vérifie que les deux fronts attirent chacun une part de la troupe.
func test_repartition_embranchement() -> String:
	var sim := SwarmSim.new()
	sim.configurer(DEPART.creer_plateau())
	seed(2718)
	for i: int in 100:
		sim.ajouter(SOLDAT, Vector2(4, 0) * SwarmSim.MAILLE)
	randomize()
	# Le rayon de 0,3 m allonge la sortie du groupe initialement superposé.
	for i: int in 360:
		sim.avancer(PAS)
	var nord: int = 0
	var sud: int = 0
	for position: Vector2 in sim.positions(SwarmSim.ALLIE):
		if position.y < -SwarmSim.MAILLE / 2:
			nord += 1
		elif position.y > SwarmSim.MAILLE / 2:
			sud += 1
	return "" if nord + sud == 100 and nord >= 35 and nord <= 65 else "%d soldats au nord, %d au sud." % [nord, sud]


## Deux embranchements successifs : la seconde bifurcation (carrefour au nord) reçoit des jouets des deux côtés.
func test_repartition_embranchements_successifs() -> String:
	var plateau: Plateau = DEPART.creer_plateau()
	if not Extension.appliquer(plateau, CARREFOUR, Vector2i(4, -6), 0):
		return "Le carrefour devrait se poser au nord du plateau de départ."
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	seed(314)
	for i: int in 200:
		sim.ajouter(SOLDAT, Vector2(4, 0) * SwarmSim.MAILLE)
	randomize()
	for i: int in 600:
		sim.avancer(PAS)
	var ouest: int = 0
	var est: int = 0
	for position: Vector2 in sim.positions(SwarmSim.ALLIE):
		if position.y < -5.0 * SwarmSim.MAILLE:
			if position.x < 7.0:
				ouest += 1
			elif position.x > 9.0:
				est += 1
	var total: int = ouest + est
	if total < 50 or ouest < total / 4 or est < total / 4:
		return "Seconde bifurcation déséquilibrée : %d à l'ouest, %d à l'est." % [ouest, est]
	return ""


## Détecte le plus proche à travers plusieurs cellules et ignore un ennemi au-delà de six mètres.
func test_poursuite() -> String:
	var sim := SwarmSim.new()
	sim.ajouter(SOLDAT, Vector2(-0.1, 0))
	sim.ajouter(SCARABEE, Vector2(-5.9, 0))
	sim.ajouter(SCARABEE, Vector2(5.4, 0))
	sim.avancer(PAS)
	if sim.positions(SwarmSim.ALLIE)[0].x <= -0.1:
		return "Le soldat doit se diriger vers l'ennemi de droite."
	var isole := SwarmSim.new()
	isole.ajouter(SOLDAT, Vector2.ZERO)
	isole.ajouter(SCARABEE, Vector2(6.01, 0))
	isole.avancer(PAS)
	return "" if isole.positions(SwarmSim.ALLIE)[0] == Vector2.ZERO else "Poursuite hors rayon."


## Vérifie les limites indépendantes et la réutilisation de la place d'un arrivant.
func test_capacite_par_camp() -> String:
	var sim := SwarmSim.new()
	sim.configurer(_ligne(1))
	for i: int in SwarmSim.CAPACITE:
		if not sim.ajouter(SCARABEE, Vector2(i * 3, 0)):
			return "La capacité ennemie est inférieure à 400."
	if sim.ajouter(SCARABEE, Vector2.ZERO) or not sim.ajouter(SOLDAT, Vector2.ZERO):
		return "Seul le camp ennemi devrait être plein."
	sim.avancer(PAS)
	if sim.nombre(SwarmSim.ENNEMI) != SwarmSim.CAPACITE - 1:
		return "Le scarabée né sur l'horloge aurait dû libérer une place."
	return "" if sim.ajouter(SCARABEE, Vector2(2, 0)) else "La place libérée doit être réutilisable."


## Chronomètre soixante pas de deux groupes en contact répartis sur vingt cases.
func test_performance() -> String:
	var sim := SwarmSim.new()
	sim.configurer(_ligne(21))
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 2718
	for modele: UniteDef in [SOLDAT, SCARABEE]:
		for i: int in 300:
			var centre := Vector2((1 + i % 20) * 2, 0)
			sim.ajouter(modele, centre + Vector2(hasard.randf_range(-0.9, 0.9), hasard.randf_range(-0.9, 0.9)))
	var duree_us: int = 0
	for i: int in 60:
		for modele: UniteDef in [SOLDAT, SCARABEE]:
			while sim.nombre(modele.camp) < 300:
				sim.ajouter(modele, Vector2(hasard.randf_range(2.0, 40.0), hasard.randf_range(-0.9, 0.9)))
		var debut: int = Time.get_ticks_usec()
		sim.avancer(PAS)
		duree_us += Time.get_ticks_usec() - debut
	var moyenne: float = duree_us / 60000.0
	print("300 contre 300 · 60 pas · avancer : %.3f ms en moyenne" % moyenne)
	return "" if moyenne < 6.0 else "Budget de 6 ms dépassé : %.3f ms." % moyenne
