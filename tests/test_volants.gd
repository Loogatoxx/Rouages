extends RefCounted
## Vérifie le survol des jouets, les défenses à distance et les arrivées de la vague 6.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const DirecteurVagues = preload("res://game/waves/directeur_vagues.gd")
const LIBELLULE: UniteDef = preload("res://data/unites/libellule.tres")
const VAGUE_06 = preload("res://data/vagues/vague_06.tres")


func _jouet(portee: float) -> UniteDef:
	var jouet := UniteDef.new()
	jouet.camp = UniteDef.Camp.ALLIE
	jouet.portee = portee
	jouet.pv = LIBELLULE.degats
	jouet.degats = LIBELLULE.pv
	jouet.cadence = 1.0
	jouet.vitesse = 2.0
	return jouet


## Au contact, ni le soldat ni la libellule ne frappent.
func test_survol_du_soldat() -> String:
	var sim := SwarmSim.new()
	sim.ajouter(_jouet(0.6), Vector2.ZERO)
	sim.ajouter(LIBELLULE, Vector2(0.2, 0))
	sim.avancer(0.1)
	if sim.nombre(SwarmSim.ALLIE) != 1:
		return "La libellule a frappé le soldat."
	if sim.nombre(SwarmSim.ENNEMI) != 1:
		return "Le soldat a frappé la libellule."
	return ""


## Le soldat poursuit le scarabée même si la libellule est plus proche.
func test_poursuite_au_sol() -> String:
	var sim := SwarmSim.new()
	sim.ajouter(_jouet(0.6), Vector2.ZERO)
	sim.ajouter(LIBELLULE, Vector2.RIGHT)
	sim.ajouter(VAGUE_06.unite, Vector2.LEFT * 3.0)
	sim.avancer(0.1)
	return "" if sim.positions(SwarmSim.ALLIE)[0].x < 0.0 else "La libellule détourne le soldat."


## Un lance-bille peut abattre une libellule dès le seuil de portée à distance.
func test_lance_bille() -> String:
	var sim := SwarmSim.new()
	sim.ajouter(_jouet(1.0), Vector2.ZERO)
	sim.ajouter(LIBELLULE, Vector2.RIGHT)
	sim.avancer(0.1)
	return "" if sim.nombre(SwarmSim.ENNEMI) == 0 else "Le tir a épargné la libellule."


## La tourelle atteint aussi bien sa cible volante qu'une voisine dans la zone.
func test_tourelle() -> String:
	var sim := SwarmSim.new()
	sim.ajouter(LIBELLULE, Vector2.ZERO)
	sim.ajouter(LIBELLULE, Vector2.RIGHT)
	sim.blesser_zone(Vector2.ZERO, 0.5, LIBELLULE.pv, 1.0)
	sim.avancer(0.1)
	return "" if sim.nombre(SwarmSim.ENNEMI) == 0 else "La zone a épargné une libellule."


## La V6 répartit ses libellules et attend la dernière avant de se terminer.
func test_vague_06() -> String:
	var sim := SwarmSim.new()
	var directeur := DirecteurVagues.new()
	# Rythme régulier pour compter les apparitions une à une (le rythme par paquets est testé dans test_vagues).
	var reguliere: Resource = VAGUE_06.duplicate()
	reguliere.groupe = 1
	directeur.commencer(reguliere, [Vector2i.ZERO, Vector2i(10, 0)])
	var attendu: int = VAGUE_06.nombre + VAGUE_06.nombre_renforts + VAGUE_06.nombre_volants
	if directeur.total() != attendu or directeur.restants(sim) != attendu:
		return "Le compteur initial de la V6 doit inclure ses libellules."
	var volants: int = 0
	var renforts: int = 0
	for rang: int in attendu:
		directeur.avancer(0.0 if rang == 0 else VAGUE_06.intervalle, sim)
		if sim.nombre(SwarmSim.ENNEMI) != rang + 1:
			return "Une apparition manque à son intervalle."
		var modele: UniteDef = sim.modeles(SwarmSim.ENNEMI)[rang]
		if modele.volant:
			var x: float = sim.positions(SwarmSim.ENNEMI)[rang].x
			if (x > 10.0) != (volants % 2 == 1):
				return "Les libellules doivent alterner les entrées."
			volants += 1
		elif modele.id == VAGUE_06.renfort.id:
			renforts += 1
		if absi(volants * attendu - (rang + 1) * VAGUE_06.nombre_volants) > attendu * 0.5:
			return "Les libellules sont mal réparties dans la vague."
	if volants != VAGUE_06.nombre_volants or renforts != VAGUE_06.nombre_renforts:
		return "La composition de la V6 est incorrecte."
	for i: int in attendu:
		if not sim.modeles(SwarmSim.ENNEMI)[i].volant:
			sim.blesser_zone(sim.positions(SwarmSim.ENNEMI)[i], 0.0, 1000.0, 0.0)
	sim.avancer(0.1)
	if directeur.restants(sim) != VAGUE_06.nombre_volants or directeur.est_terminee(sim):
		return "Les libellules vivantes doivent prolonger la vague."
	sim.blesser_zone(Vector2.ZERO, 100.0, 1000.0, 100.0)
	sim.avancer(0.1)
	return "" if directeur.est_terminee(sim) else "La vague devrait être terminée."


## Taupe (fouisseuse) : les tourelles et les tireurs l'ignorent, les jouets au corps à corps la frappent.
func test_taupe_sous_les_tirs() -> String:
	var SwarmSim = load("res://game/swarm/swarm_sim.gd")
	var taupe = load("res://data/unites/taupe.tres")
	var sim = SwarmSim.new()
	sim.ajouter(taupe, Vector2(1, 0))
	if sim.blesser_zone(Vector2.ZERO, 5.0, 10.0, 0.0):
		return "Une tourelle ne doit pas viser une taupe sous terre."
	sim.ajouter(load("res://data/unites/soldat_remontoir.tres"), Vector2(0.5, 0))
	var pv_avant: float = taupe.pv
	for pas: int in 60:
		sim.avancer(1.0 / 60.0)
	return "" if sim.nombre(1) == 0 or sim._camps[1].vies[0] < pv_avant else "Un soldat doit pouvoir frapper la taupe."


## Porte-bouclier : ses voisins encaissent moins ; loin de lui, rien ne change.
func test_porte_bouclier() -> String:
	var SwarmSim = load("res://game/swarm/swarm_sim.gd")
	var sim = SwarmSim.new()
	var scarabee = load("res://data/unites/scarabee.tres")
	sim.ajouter(load("res://data/unites/porte_bouclier.tres"), Vector2(0, 0))
	sim.ajouter(scarabee, Vector2(1, 0))
	sim.ajouter(scarabee, Vector2(20, 0))
	sim._calculer_boucliers()
	if sim._bouclier(1) <= 0.0 or sim._bouclier(2) > 0.0:
		return "Seuls les voisins du porte-bouclier doivent être protégés."
	return "" if scarabee.degats_recus(5.0, false, sim._bouclier(1)) < 5.0 else "L'aura doit réduire les coups."
