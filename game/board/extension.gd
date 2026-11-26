class_name Extension extends RefCounted
## Oriente une extension et vérifie son raccordement avant de modifier le plateau.

const Plateau = preload("res://game/board/plateau.gd")
const ExtensionDef = preload("res://game/board/extension_def.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")


## Renvoie les sols dans la grille du plateau après rotation autour du centre.
static func cases(def: ExtensionDef, centre: Vector2i, rotation: int) -> Dictionary:
	var sols: Dictionary[Vector2i, Plateau.Sol] = {}
	var origine: Vector2i = centre - Vector2i(def.taille, def.taille) / 2
	for x: int in def.taille:
		for y: int in def.taille:
			var locale := Vector2i(x, y)
			var sol: Plateau.Sol = Plateau.Sol.CHEMIN if locale in def.chemins else Plateau.Sol.HERBE
			for tour: int in posmod(rotation, 4):
				locale = Vector2i(def.taille - 1 - locale.y, locale.x)
			sols[origine + locale] = sol
	return sols


## Vérifie que tout le chemin rejoint l'horloge et que le nombre d'entrées augmente.
static func est_valide(plateau: Plateau, def: ExtensionDef, centre: Vector2i, rotation: int) -> bool:
	var sols: Dictionary = cases(def, centre, rotation)
	for case: Vector2i in sols:
		if plateau.a_sol(case):
			return false
	var copie: Plateau = plateau.dupliquer()
	copie.ajouter_sols(sols)
	var distances: Dictionary = ChampFlux.calculer(copie)
	for case: Vector2i in sols:
		if sols[case] == Plateau.Sol.CHEMIN and not distances.has(case):
			return false
	var avant: int = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau)).size()
	return ChampFlux.entrees(copie, distances).size() > avant


## Pose toutes les cases ensemble si l'extension ouvre un nouveau front.
static func appliquer(plateau: Plateau, def: ExtensionDef, centre: Vector2i, rotation: int) -> bool:
	if not est_valide(plateau, def, centre, rotation):
		return false
	plateau.ajouter_sols(cases(def, centre, rotation))
	return true
