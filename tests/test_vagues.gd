extends RefCounted
## Vérifie les données des vagues, leurs entrées et leur condition de fin.

const Plateau = preload("res://game/board/plateau.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const DirecteurVagues = preload("res://game/waves/directeur_vagues.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")
const Regles = preload("res://game/core/regles.gd")
const SCARABEE = preload("res://data/unites/scarabee.tres")
const DONNEES_REGLES = preload("res://data/regles.tres")
## Courbe de difficulté (équilibrée au banc, voir taches/T05c_vagues_equilibrage.md) : [nombre, intervalle, × PV].
const COURBE := [
	[14, 1.25, 1.0], [36, 0.5, 1.0], [54, 0.37, 1.1], [80, 0.3, 1.2], [123, 0.26, 1.35],
	[140, 0.25, 1.5], [150, 0.25, 1.7], [160, 0.25, 1.85], [190, 0.23, 2.05], [229, 0.21, 2.4],
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
	for i: int in 600:
		sim.avancer(1.0 / 60.0)
		if directeur.est_terminee(sim):
			return ""
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
