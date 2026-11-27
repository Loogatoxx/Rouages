extends RefCounted
## Vérifie les runs longues (vagues extrapolées) et l'ouverture automatique d'un tiroir (PT-60).

const RouteLongue = preload("res://game/core/route_longue.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const DEPART = preload("res://data/depart.tres")
const SENTIER = preload("res://data/extensions/sentier.tres")


## Les 5 vagues ajoutées montent régulièrement, sans toucher aux vagues d'origine ; le boss revient à la fin.
func test_prolonger() -> String:
	var regles: Resource = load("res://data/regles.tres")
	var longues: Array = RouteLongue.prolonger(regles.vagues, 15)
	if longues.size() != 15 or longues[9] != regles.vagues[9]:
		return "Il faut 15 vagues, les 10 premières inchangées."
	for i: int in range(10, 15):
		if longues[i].nombre <= longues[i - 1].nombre or longues[i].multiplicateur_pv <= longues[i - 1].multiplicateur_pv:
			return "La vague %d doit être plus dure que la précédente." % (i + 1)
	if longues[14].boss == null or longues[11].boss != null:
		return "Le boss ne revient qu'à la dernière vague."
	if regles.vagues.size() != 10:
		return "Les vagues d'origine ne doivent pas changer."
	return ""


## Un tiroir qui s'ouvre ajoute une entrée et reste relié à l'horloge ; même graine, même pose.
func test_ouvrir_tiroir() -> String:
	var plateau = DEPART.creer_plateau()
	var avant: int = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau)).size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var pose: Array = RouteLongue.ouvrir_tiroir(plateau, SENTIER, rng)
	if pose.is_empty():
		return "Le tiroir doit trouver une place."
	if ChampFlux.entrees(plateau, ChampFlux.calculer(plateau)).size() <= avant:
		return "Le tiroir doit ouvrir une nouvelle entrée."
	var autre = DEPART.creer_plateau()
	rng.seed = 4
	if RouteLongue.choisir_pose(autre, SENTIER, rng) != pose:
		return "La même graine doit donner la même pose (défi du jour)."
	return ""


## Paliers d'extension (PT-61) : carte de plus, remise d'amélioration, carillon offert, chance.
func test_paliers_extension() -> String:
	var run: Node = Engine.get_main_loop().root.get_node_or_null("Run")
	if run == null:
		return ""
	run.reinitialiser()
	var choix: int = run.choix_par_draft
	run.poser_extension(0, 0)
	if run.choix_par_draft != choix + 1:
		return "La 1re extension doit ajouter une carte aux tirages."
	run.poser_extension(0, 0)
	if not is_equal_approx(run.remise_amelioration, 0.25):
		return "La 2e extension doit donner 25 % de remise sur les améliorations."
	run.poser_extension(0, 0)
	if run.reserve.quantite(&"tourelle_carillon") != 1:
		return "La 3e extension doit offrir un carillon."
	var chance: int = run.chance
	run.poser_extension(0, 0)
	if run.chance != mini(chance + 3, run.regles.chance_max):
		return "La 4e extension doit donner de la chance."
	run.reinitialiser()
	if run.extensions_posees != 0 or run.remise_amelioration != 0.0:
		return "Les paliers repartent de zéro à chaque partie."
	return ""


## Longue route : 15 vagues et 3 tiroirs ; jamais au défi du jour ; partie classique inchangée.
func test_longue_route_dans_run() -> String:
	var run: Node = Engine.get_main_loop().root.get_node_or_null("Run")
	if run == null:
		return ""
	run.choisir_depart(0)
	run.longue_route = true
	run.reinitialiser()
	var ok: bool = run.nb_vagues == 15 and run.tiroirs() == run.regles.tiroirs_longue_route
	run.longue_route = false
	run.reinitialiser()
	ok = ok and run.nb_vagues == 10 and run.tiroirs().is_empty()
	return "" if ok else "La Longue route doit compter 15 vagues et 3 tiroirs, la partie classique 10 et aucun."
