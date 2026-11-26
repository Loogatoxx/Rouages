extends RefCounted
## Vérifie le poste de garde et la poursuite sur la route de Prairie.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const PRAIRIE = preload("res://data/depart.tres")
const REGLES = preload("res://data/regles.tres")
const SOLDAT = preload("res://data/unites/soldat_remontoir.tres")
const FOURMI = preload("res://data/unites/fourmi.tres")
# La case (4, 2) est à six pas de l'horloge, sur une branche longue de huit pas.
const POSTE := Vector2(8, 4)


## Un soldat en garde reste sur place, même si la simulation avance plusieurs fois.
func test_garde_sans_cible() -> String:
	var sim := SwarmSim.new()
	sim.configurer(PRAIRIE.creer_plateau(), REGLES.garde_ratio)
	sim.ajouter(SOLDAT, POSTE)
	for pas: int in 10:
		sim.avancer(0.1)
	return "" if sim.positions(SwarmSim.ALLIE)[0] == POSTE else "Le soldat a quitté son poste."


## Avec le ratio historique, le soldat continue vers l'entrée.
func test_garde_ratio_un() -> String:
	var sim := SwarmSim.new()
	sim.configurer(PRAIRIE.creer_plateau())
	sim.ajouter(SOLDAT, POSTE)
	sim.avancer(0.1)
	return "" if sim.positions(SwarmSim.ALLIE)[0].y > POSTE.y else "Le soldat devrait avancer."


## Une fourmi détectée au-delà du poste déclenche toujours la poursuite.
func test_garde_avec_cible() -> String:
	var sim := SwarmSim.new()
	sim.configurer(PRAIRIE.creer_plateau(), REGLES.garde_ratio)
	sim.ajouter(SOLDAT, POSTE)
	sim.ajouter(FOURMI, POSTE + Vector2(0, 2))
	sim.avancer(0.1)
	return "" if sim.positions(SwarmSim.ALLIE)[0].y > POSTE.y else "Le soldat devrait poursuivre la fourmi."
