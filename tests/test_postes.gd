extends RefCounted
## Playtest 3 (« Tenir la ligne ») : postes de garde des escouades, jouets renforcés par niveau, dents de l'Horloge.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Plateau = preload("res://game/board/plateau.gd")
const Production = preload("res://game/workshops/production.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const SOLDAT = preload("res://data/unites/soldat_remontoir.tres")
const SCARABEE = preload("res://data/unites/scarabee.tres")
const REGLES = preload("res://data/regles.tres")


# Horloge en (0,0), route droite vers l'est jusqu'à x = 8 (une seule entrée), herbe au nord et au sud.
func _plateau() -> Plateau:
	var plateau := Plateau.new()
	for x: int in range(-1, 9):
		for y: int in range(-3, 4):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	for x: int in range(1, 9):
		plateau.ajouter_sol(Vector2i(x, 0), Plateau.Sol.CHEMIN)
	plateau.poser(Vector2i.ZERO, HORLOGE)
	return plateau


## L'escouade d'un atelier se range sur la route devant lui et n'en bouge pas tant qu'aucun ennemi n'approche.
func test_escouade_tient_son_poste() -> String:
	var plateau: Plateau = _plateau()
	plateau.poser(Vector2i(3, -1), ATELIER, 0)
	var sim := SwarmSim.new()
	sim.configurer(plateau, REGLES.garde_ratio)
	var poste: Vector2 = sim.poste(Vector2i(3, -1))
	if poste != Vector2(6, 0):
		return "Le poste par défaut doit être la case de route devant l'atelier (obtenu %s)." % poste
	for i: int in 5:
		sim.ajouter(SOLDAT, sim.sortie_atelier(Vector2i(3, -1)), Vector2i(3, -1))
	# Un ennemi immobile loin du poste (hors du rayon de garde) : personne ne doit partir le chercher.
	var statue: SwarmSim.UniteDef = SCARABEE.duplicate()
	statue.vitesse = 0.0
	statue.pv = 9999.0
	sim.ajouter(statue, Vector2(14, 0))
	for pas: int in 300:
		sim.avancer(1.0 / 30.0)
	for lieu: Vector2 in sim.positions(SwarmSim.ALLIE):
		if lieu.distance_to(poste) > SwarmSim.RAYON_RANG + 0.6:
			return "Un soldat a quitté son poste (%s) sans ennemi dans le rayon de garde." % lieu
	return ""


## Un ennemi qui entre dans le rayon de garde est attaqué ; il est arrêté avant l'Horloge.
func test_escouade_bloque() -> String:
	var plateau: Plateau = _plateau()
	plateau.poser(Vector2i(3, -1), ATELIER, 0)
	var sim := SwarmSim.new()
	sim.configurer(plateau, REGLES.garde_ratio)
	var fuites: Array[int] = [0]
	sim.ennemi_arrive.connect(func(_d: float) -> void: fuites[0] += 1)
	for i: int in 5:
		sim.ajouter(SOLDAT, Vector2(6, 0), Vector2i(3, -1))
	sim.ajouter(SCARABEE, Vector2(16, 0))
	for pas: int in 900:
		sim.avancer(1.0 / 30.0)
	if fuites[0] != 0:
		return "Le scarabée a traversé le poste de garde."
	return "" if sim.nombre(SwarmSim.ENNEMI) == 0 else "L'escouade doit venir à bout d'un scarabée arrêté à son poste."


## Le joueur plante le drapeau où il veut sur la route, à 3 cases de l'atelier au plus.
func test_drapeau_choisi() -> String:
	var plateau: Plateau = _plateau()
	plateau.poser(Vector2i(3, -1), ATELIER, 0)
	if plateau.definir_poste(Vector2i(3, -1), Vector2i(7, 0)):
		return "Un poste à plus de 3 cases de l'atelier doit être refusé."
	if plateau.definir_poste(Vector2i(3, -1), Vector2i(3, -2)):
		return "Un poste hors de la route doit être refusé."
	if not plateau.definir_poste(Vector2i(3, -1), Vector2i(5, 0)):
		return "Un poste sur la route à 3 cases doit être accepté."
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	if sim.poste(Vector2i(3, -1)) != Vector2(10, 0):
		return "La simulation doit suivre le drapeau choisi."
	plateau.retirer(Vector2i(3, -1))
	return "" if plateau.poste_de(Vector2i(3, -1)) == Plateau.SANS_POSTE else "Reprendre l'atelier doit retirer son drapeau."


## Entre deux routes voisines, le poste par défaut va sur celle où passent le plus d'entrées.
func test_poste_sur_le_tronc_commun() -> String:
	var plateau := Plateau.new()
	for x: int in range(-4, 5):
		for y: int in range(-4, 5):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	# Tronc commun (0,1)-(0,2), puis deux branches : vers l'ouest depuis (0,2) et vers le sud depuis (0,2).
	for case: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(-1, 2), Vector2i(-2, 2), Vector2i(-3, 2), Vector2i(-4, 2),
			Vector2i(0, 3), Vector2i(0, 4)]:
		plateau.ajouter_sol(case, Plateau.Sol.CHEMIN)
	plateau.poser(Vector2i.ZERO, HORLOGE)
	# L'atelier en (-1,3) touche la branche ouest (-1,2) et la branche sud (0,3) : une entrée chacune. Celui en
	# (1,2) ne touche que le tronc (0,2), où passent les deux entrées.
	plateau.poser(Vector2i(1, 2), ATELIER, 0)
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	if sim.passage(Vector2i(0, 2)) != 2 or sim.passage(Vector2i(-1, 2)) != 1:
		return "Le tronc commun doit compter deux entrées, une branche une seule."
	return "" if sim.poste(Vector2i(1, 2)) == Vector2(0, 4) else "Le poste doit être sur le tronc commun."


## Améliorer un atelier rend ses jouets plus solides (PV et dégâts), sans toucher au modèle de base.
func test_jouets_renforces_par_niveau() -> String:
	var production := Production.new()
	var base_pv: float = SOLDAT.pv
	var niveau_3: SwarmSim.UniteDef = production.unite_de_niveau(SOLDAT, 3, REGLES)
	var facteur: float = 1.0 + 2.0 * REGLES.gain_niveau_unite
	if not is_equal_approx(niveau_3.pv, base_pv * facteur) or not is_equal_approx(niveau_3.degats, SOLDAT.degats * facteur):
		return "Au niveau 3, PV et dégâts doivent être multipliés par %s." % facteur
	if not is_equal_approx(SOLDAT.pv, base_pv) or production.unite_de_niveau(SOLDAT, 1, REGLES) != SOLDAT:
		return "Le modèle de base ne doit pas changer."
	return "" if production.unite_de_niveau(SOLDAT, 3, REGLES) == niveau_3 else "Le modèle renforcé doit être gardé en mémoire."


## Le carillon ralentit ce qu'il touche ; le coup de carillon du joueur étourdit (plus de mouvement ni de coups).
func test_ralentissement_et_etourdissement() -> String:
	var plateau: Plateau = _plateau()
	var temoin := SwarmSim.new()
	temoin.configurer(plateau)
	temoin.ajouter(SCARABEE, Vector2(16, 0))
	var ralenti := SwarmSim.new()
	ralenti.configurer(plateau)
	ralenti.ajouter(SCARABEE, Vector2(16, 0))
	if not ralenti.blesser_zone(Vector2(16, 2), 3.0, 0.5, 2.0, 0.5, 1.0):
		return "Le carillon doit toucher le scarabée à portée."
	for pas: int in 30:
		temoin.avancer(1.0 / 30.0)
		ralenti.avancer(1.0 / 30.0)
	var libre: float = 16.0 - temoin.positions(SwarmSim.ENNEMI)[0].x
	var freine: float = 16.0 - ralenti.positions(SwarmSim.ENNEMI)[0].x
	if absf(freine - libre * 0.5) > 0.05:
		return "Ralenti de moitié pendant 1 s, le scarabée doit avancer deux fois moins (%s contre %s)." % [freine, libre]
	if ralenti.ralentir_zone(Vector2(15, 0), 3.0, 1.0, 1.0) != 1:
		return "Le coup de carillon doit toucher le scarabée."
	var avant: Vector2 = ralenti.positions(SwarmSim.ENNEMI)[0]
	for pas: int in 25:
		ralenti.avancer(1.0 / 30.0)
	if not ralenti.positions(SwarmSim.ENNEMI)[0].is_equal_approx(avant):
		return "Étourdi, le scarabée ne doit plus bouger."
	for pas: int in 30:
		ralenti.avancer(1.0 / 30.0)
	return "" if ralenti.positions(SwarmSim.ENNEMI)[0].x < avant.x else "L'étourdissement doit finir."


## Relecture T14b : un atelier enfermé entre des bâtiments garde ses jouets au lieu de les lâcher à travers ses voisins.
func test_atelier_enferme_ne_produit_pas() -> String:
	const Energie = preload("res://game/board/energie.gd")
	const CROIX = preload("res://data/tuiles/engrenage_croix.tres")
	var plateau: Plateau = _plateau()
	# Horloge (0,0) → croix (0,-1) → atelier (0,-2), cerné par trois autres croix : aucune case libre autour de lui.
	plateau.poser(Vector2i(0, -1), CROIX)
	plateau.poser(Vector2i(0, -2), ATELIER, 0)
	for case: Vector2i in [Vector2i(-1, -2), Vector2i(1, -2), Vector2i(0, -3)]:
		plateau.poser(case, CROIX)
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	if sim.sortie_atelier(Vector2i(0, -2)) != Vector2.INF:
		return "L'atelier cerné ne doit pas avoir de sortie."
	var production := Production.new()
	var alimentees: Dictionary = Energie.calculer(plateau)
	for pas: int in 300:
		production.avancer(1.0 / 30.0, plateau, alimentees, sim, REGLES)
	if sim.nombre(SwarmSim.ALLIE) != 0:
		return "Un atelier enfermé ne doit sortir aucun jouet."
	plateau.retirer(Vector2i(1, -2))
	sim.configurer(plateau)
	production.avancer(1.0 / 30.0, plateau, alimentees, sim, REGLES)
	return "" if sim.nombre(SwarmSim.ALLIE) == 1 else "Dès qu'un passage s'ouvre, le jouet prêt doit sortir."


## Relecture T14b : une vague perdue ne remonte pas l'Horloge ; une vague tenue, si.
func test_dents_gagnees_par_les_vagues_tenues() -> String:
	Run.choisir_depart(0)
	Run.reinitialiser()
	var depart: int = REGLES.dents_depart
	if Run.dents != depart:
		return "Au départ, l'Horloge doit avoir %d dents (obtenu %d)." % [depart, Run.dents]
	for vague: int in 2:
		Run.choisir_lot(0)
		Run.lancer_vague()
		if Run.dents != depart:
			return "Pendant la vague %d, l'Horloge ne doit pas encore avoir gagné de dent." % (vague + 1)
		Run.terminer_vague()
	if Run.dents != depart + 1:
		return "Après la vague 2 tenue, l'Horloge doit gagner une dent."
	Run.choisir_lot(0)
	Run.lancer_vague()
	Run.choisir_lot(0)
	Run.subir_degats(999)
	var apres_defaite: int = Run.dents
	Run.reinitialiser()
	return "" if apres_defaite == depart + 1 else "Une vague perdue ne doit pas remonter l'Horloge."
