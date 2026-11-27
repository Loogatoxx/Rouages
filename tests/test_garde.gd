extends RefCounted
## Vérifie le poste de garde et la poursuite sur la route de Prairie.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const PRAIRIE = preload("res://data/depart.tres")
const REGLES = preload("res://data/regles.tres")
const SOLDAT = preload("res://data/unites/soldat_remontoir.tres")
const FOURMI = preload("res://data/unites/fourmi.tres")
const SCARABEE = preload("res://data/unites/scarabee.tres")
const MEANDRES = preload("res://data/departs/meandres.tres")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const Plateau = preload("res://game/board/plateau.gd")
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


## Playtest 2 (carte en S) : un jouet posé au-delà de son poste ne reste pas planté quand les ennemis l'ont
## dépassé ; il revient vers l'horloge par la route.
func test_jouet_isole_revient() -> String:
	var sim := SwarmSim.new()
	sim.configurer(MEANDRES.creer_plateau(), REGLES.garde_ratio)
	# Case (-3, -3) : 12 pas de l'horloge sur 19, au-delà du poste (10). Le scarabée est en (3, -1), 4 pas.
	sim.ajouter(SOLDAT, Vector2(-6, -6))
	sim.ajouter(SCARABEE, Vector2(6, -2))
	for pas: int in 30:
		sim.avancer(1.0 / 30.0)
	return "" if sim.positions(SwarmSim.ALLIE)[0].y > -6.0 else "Le jouet isolé est resté immobile."


## Un cul-de-sac sans entrée (laissé par une extension) ne retient pas les jouets.
func test_cul_de_sac() -> String:
	var plateau := Plateau.new()
	plateau.ajouter_sol(Vector2i.ZERO, Plateau.Sol.HERBE)
	plateau.poser(Vector2i.ZERO, HORLOGE)
	for x: int in range(1, 7):
		plateau.ajouter_sol(Vector2i(x, 0), Plateau.Sol.CHEMIN)
	plateau.ajouter_sol(Vector2i(3, 1), Plateau.Sol.CHEMIN)
	plateau.ajouter_sol(Vector2i(3, 2), Plateau.Sol.CHEMIN)
	for herbe: Vector2i in [Vector2i(2, 1), Vector2i(4, 1), Vector2i(2, 2), Vector2i(4, 2), Vector2i(3, 3)]:
		plateau.ajouter_sol(herbe, Plateau.Sol.HERBE)
	var sim := SwarmSim.new()
	sim.configurer(plateau)
	sim.ajouter(SOLDAT, Vector2(6, 4))
	for pas: int in 30:
		sim.avancer(1.0 / 30.0)
	return "" if sim.positions(SwarmSim.ALLIE)[0].y < 4.0 else "Le jouet attend au bout d'un cul-de-sac."
