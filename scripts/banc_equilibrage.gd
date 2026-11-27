extends SceneTree
## Banc d'équilibrage (outil de Claude, pas un test) : joue les vagues de `data/regles.tres` en headless contre un
## « profil de joueur » et mesure les PV que perd l'horloge.
##
## Pourquoi : la difficulté d'une vague se lit mal à l'œil, et la simulation des nuées est chaotique près du point de
## rupture. Le banc donne des chiffres reproductibles (graine fixe) pour comparer deux réglages.
##
## Usage : Godot --headless --path . --script res://scripts/banc_equilibrage.gd -- <profil> [graine] [vague_extension]
##   profil          : ateliers alimentés avant chaque vague, ex. 1,1,2,2,3,3,4,4,5,5
##   graine          : graine du hasard (défaut 1)
##   vague_extension : pose un sentier à l'est (3e entrée) avant cette vague ; 0 = aucune (défaut)
## Variable d'environnement REMONTAGE : secondes de construction simulées avant chaque vague (défaut 20).
##
## Limite connue : le banc place ses ateliers en grappe autour de l'horloge (placement « parfait » et compact).
## Un vrai joueur se situe plutôt un profil en dessous.

const Plateau = preload("res://game/board/plateau.gd")
const Energie = preload("res://game/board/energie.gd")
const Extension = preload("res://game/board/extension.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Production = preload("res://game/workshops/production.gd")
const DirecteurVagues = preload("res://game/waves/directeur_vagues.gd")
const Regles = preload("res://game/core/regles.gd")
const DepartDef = preload("res://game/core/depart_def.gd")
const ATELIER = preload("res://data/tuiles/atelier_soldats.tres")
const CROIX = preload("res://data/tuiles/engrenage_croix.tres")
const BILLES = preload("res://data/tuiles/atelier_billes.tres")
const SENTIER = preload("res://data/extensions/sentier.tres")
const DT := 1.0 / 30.0

## Chaque étape ajoute un atelier alimenté : [x, y, "A" atelier de soldats | "B" lance-billes | "X" croix, rotation].
## Par défaut le banc joue « mixte » (les étapes 3 et 5 posent des lance-billes, comme un joueur qui répond aux
## libellules) ; 4e argument `soldats` pour l'ancien banc tout soldats.
## Port de l'atelier : rotation 0 = sud, 1 = ouest, 2 = nord, 3 = est.
const ETAPES := [
	[[-1, 0, "A", 3]],
	[[0, 1, "A", 2]],
	[[0, -1, "X", 0], [-1, -1, "B", 3]],
	[[1, -1, "A", 1]],
	[[0, -2, "X", 0], [0, -3, "B", 0]],
	[[-1, -2, "A", 3]],
	[[1, -2, "A", 1]],
]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var profil: PackedStringArray = (args[0] if args.size() > 0 else "1,1,2,2,3,3,4,4,5,5").split(",")
	seed(int(args[1]) if args.size() > 1 else 1)
	var vague_extension: int = int(args[2]) if args.size() > 2 else 0
	var mixte: bool = not (args.size() > 3 and args[3] == "soldats")
	var regles: Regles = load("res://data/regles.tres")
	var remontage: float = float(OS.get_environment("REMONTAGE")) if OS.get_environment("REMONTAGE") != "" else regles.remontage_lancement
	var depart: DepartDef = load("res://data/depart.tres")
	var plateau: Plateau = depart.creer_plateau()
	var sim := SwarmSim.new()
	var production := Production.new()
	var directeur := DirecteurVagues.new()
	var fuites: Array[float] = [0.0]
	sim.ennemi_arrive.connect(func(d: float) -> void: fuites[0] += d)
	var ligne: String = ",".join(profil)
	var total: float = 0.0
	var mort: int = 0
	var etapes_faites: int = 0
	for i: int in regles.vagues.size():
		while etapes_faites < mini(int(profil[mini(i, profil.size() - 1)]), ETAPES.size()):
			for p: Array in ETAPES[etapes_faites]:
				var piece: Resource = CROIX if p[2] == "X" else (BILLES if p[2] == "B" and mixte else ATELIER)
				plateau.poser(Vector2i(p[0], p[1]), piece, p[3])
			etapes_faites += 1
		if i + 1 == vague_extension and not Extension.appliquer(plateau, SENTIER, Vector2i(6, 2), 1):
			push_error("Extension refusée : le banc ne correspond plus au plateau de départ.")
		var alimentees: Dictionary = Energie.calculer(plateau)
		sim.configurer(plateau, regles.garde_ratio)
		var entrees: Array[Vector2i] = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau))
		var t: float = 0.0
		# Même règle que le jeu : production à l'arrêt entre les vagues, remontage instantané une fois par pause,
		# puis les jouets rejoignent leur poste (20 s de marche simulées, sans ennemi).
		production.remonter(remontage, plateau, alimentees, sim, regles)
		while t < 20.0:
			sim.avancer(DT)
			t += DT
		production.nouvelle_pause()
		directeur.commencer(regles.vagues[i], entrees)
		fuites[0] = 0.0
		var allies: int = sim.nombre(SwarmSim.ALLIE)
		t = 0.0
		while t < 400.0 and not directeur.est_terminee(sim):
			production.avancer(DT, plateau, alimentees, sim, regles)
			directeur.avancer(DT, sim)
			sim.avancer(DT)
			t += DT
		total += fuites[0]
		if mort == 0 and total >= regles.pv_horloge:
			mort = i + 1
		ligne += " | V%d %3d PV %2d s (%d jouets, %d entrées)" % [i + 1, int(fuites[0]), int(t), allies, entrees.size()]
	print("%s || total %d PV%s" % [ligne, int(total), (" — horloge arrêtée en V%d" % mort) if mort > 0 else ""])
	quit(0)
