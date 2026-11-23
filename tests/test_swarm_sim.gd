extends RefCounted
## Exerce la simulation par ses entrées publiques et ses signaux locaux.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Plateau = preload("res://game/board/plateau.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const SCARABEE = preload("res://data/unites/scarabee.tres")
const SOLDAT = preload("res://data/unites/soldat_remontoir.tres")
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
	return "" if impacts == [SCARABEE.degats] else "Un seul impact de deux dégâts était attendu."


## Rejoue le duel et vérifie le quatrième coup de soldat à 2,5 secondes.
func test_duel() -> String:
	for essai: int in 2:
		var sim := SwarmSim.new()
		var morts: Array[int] = []
		sim.unite_morte.connect(func(camp: int, _p: Vector2) -> void: morts.append(camp))
		sim.ajouter(SCARABEE, Vector2(0.5, 0))
		sim.ajouter(SOLDAT, Vector2.ZERO)
		for i: int in 150:
			sim.avancer(PAS)
		if not morts.is_empty():
			return "Trois coups de soldat ne doivent pas tuer le scarabée."
		sim.avancer(PAS)
		if morts != [SwarmSim.ENNEMI] or sim.nombre(SwarmSim.ALLIE) != 1 or sim.nombre(SwarmSim.ENNEMI) != 0:
			return "Le quatrième coup de soldat doit terminer le duel."
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
