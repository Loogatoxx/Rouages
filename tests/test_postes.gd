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


## Cartes à mécaniques : l'eau ne reçoit qu'un Pont, un décor ne reçoit rien, et les jouets les contournent.
func test_eau_et_decors() -> String:
	const PONT = preload("res://data/tuiles/pont.tres")
	var plateau: Plateau = _plateau()
	plateau.ajouter_sol(Vector2i(3, -2), Plateau.Sol.EAU)
	plateau.ajouter_decor(Vector2i(4, -1), &"decor_rocher")
	if plateau.peut_poser(Vector2i(3, -2), ATELIER) or not plateau.peut_poser(Vector2i(3, -2), PONT):
		return "Sur l'eau, on ne pose qu'un Pont."
	if plateau.peut_poser(Vector2i(4, -1), ATELIER) or plateau.peut_poser(Vector2i(4, -1), PONT):
		return "Sur un décor, on ne pose rien."
	if plateau.dupliquer().decor_de(Vector2i(4, -1)) != &"decor_rocher":
		return "La copie du plateau doit garder ses décors."
	# Atelier en (3,-3) : au sud l'eau, il doit sortir ses jouets par une case libre et contourner.
	plateau.poser(Vector2i(3, -3), ATELIER, 0)
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	var sortie: Vector2 = sim.sortie_atelier(Vector2i(3, -3))
	var case_sortie := Vector2i((sortie / SwarmSim.MAILLE).round())
	return "" if sortie != Vector2.INF and plateau.sol_de(case_sortie) == Plateau.Sol.HERBE \
			else "L'atelier doit sortir ses jouets dans l'herbe libre, pas dans l'eau (%s)." % case_sortie


## Toutes les cartes des règles respectent leurs propres contraintes : décors et eau hors de la route, palette valide.
func test_cartes_a_mecaniques() -> String:
	for depart: Resource in REGLES.departs:
		var plateau: Plateau = depart.creer_plateau()
		for case: Vector2i in depart.eau:
			if case in depart.chemins or case == depart.horloge:
				return "%s : une case d'eau recouvre la route ou l'horloge (%s)." % [depart.nom, case]
		for case: Vector2i in depart.decors:
			if plateau.decor_de(case) == &"":
				return "%s : le décor de la case %s n'a pas pu être posé (route, eau ou hors terrain)." % [depart.nom, case]
			if not ResourceLoader.exists("res://assets/final/kit_v2/%s/%s.glb" % [depart.decors[case], depart.decors[case]]) \
					and not depart.decors[case] in [&"decor_rail", &"decor_plaque"]:
				return "%s : modèle de décor introuvable (%s)." % [depart.nom, depart.decors[case]]
	return ""


## Relecture T14c : un carillon qui ralentit sans cesse ne prolonge pas l'étourdissement du coup de carillon.
func test_etourdissement_non_prolonge() -> String:
	var plateau: Plateau = _plateau()
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	sim.ajouter(SCARABEE, Vector2(16, 0))
	sim.ralentir_zone(Vector2(16, 0), 3.0, 1.0, 1.0)
	# Pendant 3 s, un carillon le ralentit toutes les 0,5 s.
	for pas: int in 90:
		if pas % 15 == 0:
			sim.blesser_zone(sim.positions(SwarmSim.ENNEMI)[0], 3.0, 0.01, 1.0, 0.35, 1.5)
		sim.avancer(1.0 / 30.0)
	var avant: Vector2 = sim.positions(SwarmSim.ENNEMI)[0]
	return "" if avant.x < 15.5 else "L'étourdissement (1 s) ne doit pas durer 3 s : le scarabée doit avoir avancé, ralenti."


## Relecture T14c : un Pont posé sur l'eau se traverse ; sans lui, l'eau bloque les jouets.
func test_pont_sur_l_eau_praticable() -> String:
	const PONT = preload("res://data/tuiles/pont.tres")
	var plateau: Plateau = _plateau()
	plateau.ajouter_sol(Vector2i(3, -2), Plateau.Sol.EAU)
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	if not sim._occupees.has(Vector2i(3, -2)):
		return "L'eau nue doit bloquer les jouets."
	plateau.poser(Vector2i(3, -2), PONT, 0)
	sim.configurer(plateau)
	return "" if not sim._occupees.has(Vector2i(3, -2)) else "Un Pont sur l'eau doit se traverser."


## Le Manège : la plaque tournante échange les deux tronçons ; l'entrée change de côté, la route reste reliée.
func test_manege_tourne() -> String:
	const ChampFlux = preload("res://game/swarm/champ_flux.gd")
	var manege: Resource = load("res://data/departs/manege.tres")
	var plateau: Plateau = manege.creer_plateau()
	var entrees_a: Array[Vector2i] = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau))
	if plateau.decor_de(manege.variante_b[0]) != &"decor_plaque" or plateau.sol_de(manege.variante_a[0]) != Plateau.Sol.CHEMIN:
		return "Au départ, le tronçon A est une route et le tronçon B une plaque."
	manege.appliquer_variante(plateau, 1)
	var entrees_b: Array[Vector2i] = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau))
	if entrees_a == entrees_b or entrees_b.size() != entrees_a.size():
		return "Le manège doit déplacer une entrée (avant %s, après %s)." % [entrees_a, entrees_b]
	if plateau.decor_de(manege.variante_b[0]) != &"" or plateau.decor_de(manege.variante_a[0]) != &"decor_plaque":
		return "Après un tour, le tronçon B est la route et A la plaque."
	return ""


## Le Rail : le train blesse tout ce qui est sur sa case, jouets compris, et rien à côté.
func test_train_frappe_la_voie() -> String:
	var plateau: Plateau = _plateau()
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	sim.ajouter(SCARABEE, Vector2(6, 0))
	sim.ajouter(SOLDAT, Vector2(6.3, 0), Vector2i(3, -1))
	sim.ajouter(SCARABEE, Vector2(10, 0))
	sim.frapper_case(Vector2i(3, 0), 5.0)
	var vies_e: PackedFloat32Array = sim._camps[SwarmSim.ENNEMI].vies
	var vies_a: PackedFloat32Array = sim._camps[SwarmSim.ALLIE].vies
	if not is_equal_approx(vies_e[0], SCARABEE.pv - 5.0) or not is_equal_approx(vies_a[0], SOLDAT.pv - 5.0):
		return "Le train doit blesser l'ennemi ET le jouet de la case."
	return "" if is_equal_approx(vies_e[1], SCARABEE.pv) else "Le train ne doit pas toucher la case voisine."
