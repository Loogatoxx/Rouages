extends SceneTree
## Banc d'équilibrage (outil de Claude, pas un test) : joue les vagues de `data/regles.tres` en headless, sur Prairie,
## avec une défense posée d'avance, et mesure les PV que perd l'horloge.
##
## Pourquoi : comparer deux réglages de combat (PV, dégâts, vagues) à défense égale et graine fixe. Le banc ne joue
## ni les tirages ni la boutique : pour juger une partie entière, c'est `scripts/joueur_auto.gd` qui fait foi.
##
## Refait au playtest 3 (« Tenir la ligne ») : énergie de l'Horloge comptée en dents, postes de garde, jouets
## renforcés par niveau. La défense suit un plan fixe (deux escouades qui tiennent le tronc commun, des canons autour).
##
## Usage : Godot --headless --path . --script res://scripts/banc_equilibrage.gd -- <profil> [graine] [longue]
##   profil : `parfait` (tout est posé dès que les dents le permettent, 2 niveaux achetés par vague à partir de la V2)
##            ou `moyen` (un bâtiment de retard, 1 niveau par vague à partir de la V4, jamais au-delà du niveau 2)
##   graine : graine du hasard (défaut 1) — toujours comparer sur 3 graines
##   longue : Longue route (15 vagues)
## Variables d'environnement d'essai : CADENCE (multiplie la cadence des ateliers), DELAI (secondes avant le premier
## ennemi), PV (multiplie les PV des ennemis).

const Plateau = preload("res://game/board/plateau.gd")
const Energie = preload("res://game/board/energie.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Production = preload("res://game/workshops/production.gd")
const Tourelles = preload("res://game/workshops/tourelles.gd")
const DirecteurVagues = preload("res://game/waves/directeur_vagues.gd")
const Regles = preload("res://game/core/regles.gd")
const DepartDef = preload("res://game/core/depart_def.gd")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const CANON = preload("res://data/tuiles/tourelle_canon.tres")
const CROIX = preload("res://data/tuiles/engrenage_croix.tres")
const DT := 1.0 / 30.0

## Engrenages posés d'entrée (deux chaînes de croix, au nord et au sud de la route de Prairie).
const RESEAU: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
## Bâtiments dans l'ordre de pose : [case, pièce, rotation du port]. Les deux ateliers bordent la case (3, 0), où
## passent les deux entrées : leurs escouades y tiennent la ligne, sous le tir des canons.
const PLAN := [
	[Vector2i(3, -1), "atelier", 1], [Vector2i(3, 1), "atelier", 1], [Vector2i(2, -2), "canon", 0],
	[Vector2i(2, 2), "canon", 2], [Vector2i(1, -2), "canon", 0], [Vector2i(1, 2), "canon", 2],
]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var profil: String = args[0] if args.size() > 0 else "parfait"
	seed(int(args[1]) if args.size() > 1 else 1)
	var longue: bool = args.size() > 2 and args[2] == "longue"
	var parfait: bool = profil != "moyen"
	var regles: Regles = load("res://data/regles.tres")
	var depart: DepartDef = load("res://data/depart.tres")
	var plateau: Plateau = depart.creer_plateau()
	for case: Vector2i in RESEAU:
		plateau.poser(case, CROIX, 0)
	var sim := SwarmSim.new()
	var production := Production.new()
	var tourelles := Tourelles.new()
	tourelles.regles = regles
	if OS.get_environment("CADENCE") != "":
		production.bonus_cadence = float(OS.get_environment("CADENCE"))
	if OS.get_environment("DELAI") != "":
		regles.delai_premier_ennemi = float(OS.get_environment("DELAI"))
	var directeur := DirecteurVagues.new()
	if OS.get_environment("PV") != "":
		directeur.facteur_pv = float(OS.get_environment("PV"))
	var fuites: Array[float] = [0.0]
	sim.ennemi_arrive.connect(func(d: float) -> void: fuites[0] += d)
	var ligne: String = profil
	var total: float = 0.0
	var mort: int = 0
	var poses: int = 0
	var vagues: Array = load("res://game/core/route_longue.gd").prolonger(regles.vagues, regles.vagues_longue_route) \
			if longue else regles.vagues
	for i: int in vagues.size():
		var dents: int = regles.dents_apres(i) + depart.dents_bonus
		# Pose tout ce que les dents permettent (le profil moyen garde toujours un bâtiment de retard).
		while poses < PLAN.size():
			var etape: Array = PLAN[poses]
			var piece: Resource = ATELIER if etape[1] == "atelier" else CANON
			var charge: int = Energie.analyser(plateau, dents).charge_horloge
			if charge + piece.cout_energie > dents or (not parfait and poses >= 2 and charge + piece.cout_energie > dents - 1):
				break
			plateau.poser(etape[0], piece, etape[2])
			poses += 1
		# Améliorations : le bâtiment de plus bas niveau d'abord.
		var achats: int = (2 if i >= 1 else 0) if parfait else (1 if i >= 3 else 0)
		for achat: int in achats:
			var cible: Vector2i = Vector2i(999, 999)
			var niveau_min: int = 2 if not parfait else 99
			for k: int in poses:
				var case: Vector2i = PLAN[k][0]
				if plateau.niveau_de(case) < niveau_min and plateau.niveau_de(case) < plateau.piece_de(case).niveau_max:
					niveau_min = plateau.niveau_de(case)
					cible = case
			if cible.x != 999:
				plateau.ameliorer(cible)
		var alimentees: Dictionary = Energie.calculer(plateau, dents)
		sim.configurer(plateau, regles.garde_ratio)
		var entrees: Array[Vector2i] = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau))
		# Même règle que le jeu : les jouets rentrent à la fin de la vague, chaque atelier repart de zéro.
		sim.vider(SwarmSim.ALLIE)
		production.nouvelle_vague()
		directeur.commencer(vagues[i], entrees, regles.delai_premier_ennemi)
		fuites[0] = 0.0
		var allies: int = 0
		var t: float = 0.0
		while t < 400.0 and not directeur.est_terminee(sim):
			production.avancer(DT, plateau, alimentees, sim, regles)
			allies = maxi(allies, sim.nombre(SwarmSim.ALLIE))
			directeur.avancer(DT, sim)
			tourelles.avancer(DT, plateau, alimentees, sim)
			sim.avancer(DT)
			t += DT
		total += fuites[0]
		if mort == 0 and total >= regles.pv_horloge:
			mort = i + 1
		ligne += " | V%d %2d PV %3d s (%d jouets, %d bât.)" % [i + 1, int(fuites[0]), int(t), allies, poses]
	print("%s || total %d PV%s" % [ligne, int(total), (" — horloge arrêtée en V%d" % mort) if mort > 0 else ""])
	quit(0)
