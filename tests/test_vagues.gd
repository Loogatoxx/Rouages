extends RefCounted
## Vérifie les données des vagues, leurs entrées et leur condition de fin.

const Plateau = preload("res://game/board/plateau.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const DirecteurVagues = preload("res://game/waves/directeur_vagues.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const Regles = preload("res://game/core/regles.gd")
const SCARABEE = preload("res://data/unites/scarabee.tres")
const CUIRASSE = preload("res://data/unites/scarabee_cuirasse.tres")
const FOURMI = preload("res://data/unites/fourmi.tres")
const RENFORTS := [0, 0, 12, 6, 5, 10, 10, 12, 18, 20]  # rééquilibré au banc après la garde des jouets (T09a)
const DONNEES_REGLES = preload("res://data/regles.tres")
## Courbe de difficulté (équilibrée au banc ; dernière passe : playtest 1, banc mixte soldats + lance-billes, pic de la V5
## lissé, milieu de partie durci) : [nombre, intervalle, × PV].
const COURBE := [
	[14, 1.25, 1.0], [36, 0.5, 1.1], [54, 0.37, 1.15], [80, 0.3, 1.4], [100, 0.26, 1.4],
	[140, 0.25, 1.85], [150, 0.25, 2.0], [160, 0.25, 2.4], [190, 0.23, 2.65], [229, 0.21, 2.55],
]


## Observe la définition reçue à l'apparition pour vérifier ses PV sans simuler un combat.
class SimulationTemoin extends SwarmSim:
	var unite_recue: UniteDef

	## Mémorise le modèle puis laisse la simulation enregistrer l'unité.
	func ajouter(def: UniteDef, position: Vector2) -> bool:
		unite_recue = def
		return super.ajouter(def, position)


## Vérifie les types et les valeurs des ressources utilisées par la partie.
func test_ressources() -> String:
	var regles: Regles = load("res://data/regles.tres") as Regles
	if (regles == null or regles.pv_horloge != 30
			or regles.plafond_allies_par_atelier != 15 or regles.multiplicateur_acceleration != 2.0):
		return "Règles de partie incorrectes."
	if regles.vagues.size() != COURBE.size():
		return "La run doit compter %d vagues, pas %d." % [COURBE.size(), regles.vagues.size()]
	var debit_precedent: float = 0.0
	for i: int in COURBE.size():
		var vague: VagueDef = regles.vagues[i]
		if vague == null or vague.unite != SCARABEE or vague.nombre != COURBE[i][0]:
			return "Unité ou effectif incorrect pour la vague %d." % (i + 1)
		var renfort: SwarmSim.UniteDef = FOURMI if i == 2 else CUIRASSE
		if vague.nombre_renforts != RENFORTS[i] or (RENFORTS[i] > 0 and vague.renfort != renfort):
			return "Renforts incorrects pour la vague %d." % (i + 1)
		if (not is_equal_approx(vague.intervalle, COURBE[i][1])
				or not is_equal_approx(vague.multiplicateur_pv, COURBE[i][2])):
			return "Intervalle ou vitalité incorrect pour la vague %d." % (i + 1)
		# Débit de PV ennemis par seconde : il doit monter à chaque vague (vraie courbe de difficulté).
		var debit: float = vague.unite.pv * vague.multiplicateur_pv / vague.intervalle
		if debit <= debit_precedent:
			return "La vague %d n'est pas plus dure que la précédente." % (i + 1)
		debit_precedent = debit
	return ""


## Vérifie les deux entrées sur le terrain initial effectivement construit par le jeu.
func test_entrees_plateau_depart() -> String:
	var source: Node = load("res://game/board/plateau_noeud.gd").new()
	source._ready()
	var plateau: Plateau = source.plateau
	source.free()
	var entrees: Array[Vector2i] = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau))
	return "" if entrees == [Vector2i(4, -4), Vector2i(4, 4)] else "Entrées obtenues : %s" % [entrees]


## Suit chaque apparition puis laisse les survivants atteindre une horloge voisine.
func test_alternance_et_fin() -> String:
	var directeur: DirecteurVagues = DirecteurVagues.new()
	var sim: SwarmSim = SwarmSim.new()
	var plateau: Plateau = Plateau.new()
	var entrees: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN]
	plateau.ajouter_sol(Vector2i.ZERO, Plateau.Sol.HERBE)
	plateau.poser(Vector2i.ZERO, preload("res://data/tuiles/horloge.tres"))
	for case: Vector2i in entrees:
		plateau.ajouter_sol(case, Plateau.Sol.CHEMIN)
	sim.configurer(plateau)
	var vague: VagueDef = DONNEES_REGLES.vagues[0]
	directeur.commencer(vague, entrees)
	if directeur.est_terminee(sim):
		return "La vague doit attendre ses premières apparitions."
	# Compteur du HUD (playtest 1 : « combien d'ennemis restent ») : tout reste à battre au lancement.
	if directeur.restants(sim) != directeur.total() or directeur.total() != vague.nombre:
		return "Au lancement, les ennemis restants doivent valoir l'effectif de la vague."
	for i: int in vague.nombre:
		directeur.avancer(0.0 if i == 0 else vague.intervalle, sim)
		if sim.nombre(SwarmSim.ENNEMI) != i + 1:
			return "L'intervalle entre les scarabées est incorrect."
		var centre: Vector2 = Vector2(entrees[i % 2]) * 2.0
		if sim.positions(SwarmSim.ENNEMI)[i].distance_to(centre) > 0.50001:
			return "Le scarabée a manqué son entrée."
	directeur.avancer(100.0, sim)
	if sim.nombre(SwarmSim.ENNEMI) != vague.nombre or directeur.est_terminee(sim):
		return "La vague doit attendre ses derniers survivants sans renforts."
	if directeur.restants(sim) != sim.nombre(SwarmSim.ENNEMI):
		return "Une fois tous entrés, les restants sont les ennemis vivants."
	for i: int in 600:
		sim.avancer(1.0 / 60.0)
		if directeur.est_terminee(sim):
			return "" if directeur.restants(sim) == 0 else "Vague finie : plus aucun ennemi restant."
	return "La vague est restée active après les arrivées à l'horloge."


## Vérifie les PV transmis à la simulation et la conservation du modèle partagé.
func test_multiplicateur_pv() -> String:
	var directeur: DirecteurVagues = DirecteurVagues.new()
	var sim: SimulationTemoin = SimulationTemoin.new()
	var pv_source: float = SCARABEE.pv
	var vague: VagueDef = DONNEES_REGLES.vagues[2]
	directeur.commencer(vague, [Vector2i.ZERO])
	directeur.avancer(0.0, sim)
	if sim.unite_recue == null or not is_equal_approx(sim.unite_recue.pv, pv_source * vague.multiplicateur_pv):
		return "La simulation doit recevoir les PV définis pour cette vague."
	if sim.unite_recue == SCARABEE or SCARABEE.pv != pv_source:
		return "Le multiplicateur a modifié la ressource scarabee.tres."
	return ""


## Vide la simulation entre deux arrivées pour vérifier la répartition et le comptage des renforts.
func test_renforts_repartis_et_comptes() -> String:
	var directeur: DirecteurVagues = DirecteurVagues.new()
	var sim: SimulationTemoin = SimulationTemoin.new()
	var vague: VagueDef = DONNEES_REGLES.vagues[3]
	var total: int = vague.nombre + vague.nombre_renforts
	var cuirasses: int = 0
	var plateau: Plateau = Plateau.new()
	plateau.ajouter_sol(Vector2i.ZERO, Plateau.Sol.HERBE)
	plateau.poser(Vector2i.ZERO, preload("res://data/tuiles/horloge.tres"))
	sim.configurer(plateau)
	directeur.commencer(vague, [Vector2i.ZERO])
	for i: int in total:
		if directeur.est_terminee(sim):
			return "La vague est terminée alors qu'il reste des unités à faire apparaître."
		directeur.avancer(0.0 if i == 0 else vague.intervalle, sim)
		if sim.nombre(SwarmSim.ENNEMI) != 1 or directeur.est_terminee(sim):
			return "La vague doit compter une apparition et attendre son arrivée à l'horloge."
		if sim.unite_recue.id == CUIRASSE.id:
			cuirasses += 1
			if not is_equal_approx(sim.unite_recue.pv, CUIRASSE.pv * vague.multiplicateur_pv):
				return "Le multiplicateur de PV doit aussi s'appliquer au cuirassé."
		var proportion_attendue: float = float(i + 1) * vague.nombre_renforts / total
		if absf(cuirasses - proportion_attendue) >= 1.0:
			return "Les cuirassés sont regroupés au lieu d'être répartis dans la vague."
		sim.avancer(vague.intervalle)
	if cuirasses != vague.nombre_renforts or not directeur.est_terminee(sim):
		return "Le dernier ennemi disparu doit clore la vague avec le nombre prévu de cuirassés."
	return ""


func test_boss_a_mi_vague() -> String:
	var boss: UniteDef = preload("res://data/unites/grand_scarabee.tres")
	var vague := VagueDef.new()
	vague.unite = SCARABEE
	vague.nombre = 4
	vague.intervalle = 1.0
	vague.multiplicateur_pv = 2.0
	vague.boss = boss
	vague.pv_boss_facteur = 0.5
	var sim: SwarmSim = SwarmSim.new()  # sans plateau : les unités restent immobiles
	var directeur: DirecteurVagues = DirecteurVagues.new()
	directeur.commencer(vague, [Vector2i(3, 0)])
	directeur.avancer(0.0, sim)
	directeur.avancer(1.0, sim)
	if sim.pv_boss() != Vector2.ZERO:
		return "Le boss ne doit pas apparaître avant la moitié de la vague."
	directeur.avancer(1.0, sim)
	directeur.avancer(1.0, sim)
	directeur.avancer(1.0, sim)
	var bosses: int = 0
	for modele: UniteDef in sim.modeles(SwarmSim.ENNEMI):
		if modele.boss:
			bosses += 1
	if bosses != 1:
		return "Le boss doit apparaître exactement une fois (%d)." % bosses
	if not is_equal_approx(sim.pv_boss().y, boss.pv * 2.0 * 0.5):
		return "Les PV du boss doivent suivre le multiplicateur de la vague et son facteur."
	if directeur.est_terminee(sim):
		return "La vague ne peut pas finir tant que des ennemis vivent."
	return ""
