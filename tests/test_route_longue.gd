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
