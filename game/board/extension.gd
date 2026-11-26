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


## Renvoie les cases d'herbe libre à paver pour relier le chemin de l'extension à une route existante.
## Vide si l'extension touche déjà le réseau ou si aucun tracé n'existe (dans ce cas `est_valide` la refuse).
## Pourquoi : sans ce raccord, un sentier ne se posait que contre un bord qui avait déjà une route (playtest 1).
## Le tracé vise une route et jamais l'horloge en direct : tout le réseau converge ainsi vers sa porte.
static func raccord(plateau: Plateau, def: ExtensionDef, centre: Vector2i, rotation: int) -> Array[Vector2i]:
	var sols: Dictionary = cases(def, centre, rotation)
	var reseau: Dictionary = ChampFlux.calculer(plateau)
	var depart: Array[Vector2i] = []
	for case: Vector2i in sols:
		if sols[case] != Plateau.Sol.CHEMIN:
			continue
		depart.append(case)
		for direction: Vector2i in ChampFlux.VOISINS:
			if reseau.has(case + direction):
				return []
	# Parcours en largeur depuis le chemin de l'extension, à travers l'herbe sans pièce du plateau.
	var precedent: Dictionary[Vector2i, Vector2i] = {}
	var file: Array[Vector2i] = depart.duplicate()
	for case: Vector2i in depart:
		precedent[case] = case
	var tete: int = 0
	while tete < file.size():
		var case: Vector2i = file[tete]
		tete += 1
		for direction: Vector2i in ChampFlux.VOISINS:
			var voisin: Vector2i = case + direction
			if precedent.has(voisin):
				continue
			if reseau.get(voisin, 0) > 0 and not sols.has(case):
				var trace: Array[Vector2i] = []
				while precedent[case] != case:
					trace.append(case)
					case = precedent[case]
				return trace
			if plateau.sol_de(voisin) == Plateau.Sol.HERBE and plateau.piece_de(voisin) == null \
					and not _touche_horloge(reseau, voisin):
				precedent[voisin] = case
				file.append(voisin)
	return []


# Une case collée à l'horloge ouvrirait une seconde arrivée sur son flanc, loin de la porte.
static func _touche_horloge(reseau: Dictionary, case: Vector2i) -> bool:
	for direction: Vector2i in ChampFlux.VOISINS:
		if reseau.get(case + direction, -1) == 0:
			return true
	return false


## Rassemble le terrain de l'extension et son raccord pavé, prêts à être posés ensemble.
static func sols_avec_raccord(plateau: Plateau, def: ExtensionDef, centre: Vector2i, rotation: int) -> Dictionary:
	var sols: Dictionary = cases(def, centre, rotation)
	for case: Vector2i in raccord(plateau, def, centre, rotation):
		sols[case] = Plateau.Sol.CHEMIN
	return sols


## Vérifie que tout le chemin rejoint l'horloge (raccord compris) et que le nombre d'entrées augmente.
static func est_valide(plateau: Plateau, def: ExtensionDef, centre: Vector2i, rotation: int) -> bool:
	var terrain: Dictionary = cases(def, centre, rotation)
	for case: Vector2i in terrain:
		if plateau.a_sol(case):
			return false
	var sols: Dictionary = sols_avec_raccord(plateau, def, centre, rotation)
	var copie: Plateau = plateau.dupliquer()
	copie.ajouter_sols(sols)
	var distances: Dictionary = ChampFlux.calculer(copie)
	for case: Vector2i in sols:
		if sols[case] == Plateau.Sol.CHEMIN and not distances.has(case):
			return false
	var avant: int = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau)).size()
	return ChampFlux.entrees(copie, distances).size() > avant


## Pose toutes les cases ensemble (raccord compris) si l'extension ouvre un nouveau front.
static func appliquer(plateau: Plateau, def: ExtensionDef, centre: Vector2i, rotation: int) -> bool:
	if not est_valide(plateau, def, centre, rotation):
		return false
	plateau.ajouter_sols(sols_avec_raccord(plateau, def, centre, rotation))
	return true
