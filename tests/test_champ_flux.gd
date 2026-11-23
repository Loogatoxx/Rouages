extends RefCounted
## Vérifie la navigation depuis les horloges et le raccordement de l'herbe.

const Plateau = preload("res://game/board/plateau.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")


## Vérifie le coude, l'îlot déconnecté et la source la plus proche depuis l'herbe.
func test_chemin_en_l() -> String:
	var plateau := Plateau.new()
	plateau.ajouter_sol(Vector2i.ZERO, Plateau.Sol.HERBE)
	plateau.poser(Vector2i.ZERO, HORLOGE)
	var chemin := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]
	for case: Vector2i in chemin:
		plateau.ajouter_sol(case, Plateau.Sol.CHEMIN)
	plateau.ajouter_sol(Vector2i(3, 2), Plateau.Sol.HERBE)
	plateau.ajouter_sol(Vector2i(4, 2), Plateau.Sol.CHEMIN)
	var distances: Dictionary = ChampFlux.calculer(plateau)
	if distances.size() != 5 or distances.get(Vector2i.ZERO) != 0:
		return "Seuls l'horloge et les quatre tronçons reliés doivent être accessibles."
	for i: int in chemin.size():
		if distances.get(chemin[i]) != i + 1:
			return "Distance incorrecte au coude %s." % chemin[i]
	var sources: Dictionary = ChampFlux.vers_chemin(plateau, distances)
	if sources.get(Vector2i(3, 2)) != Vector2i(2, 2) or sources.get(Vector2i(4, 2)) != Vector2i(2, 2):
		return "Le raccordement doit traverser l'herbe jusqu'au réseau relié."
	plateau.ajouter_sol(Vector2i(2, 3), Plateau.Sol.HERBE)
	plateau.poser(Vector2i(2, 3), HORLOGE)
	distances = ChampFlux.calculer(plateau)
	return "" if distances.get(Vector2i(2, 2)) == 1 else "La seconde horloge doit raccourcir le trajet."
