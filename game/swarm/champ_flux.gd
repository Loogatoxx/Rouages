class_name ChampFlux extends RefCounted
## Construit les deux cartes de navigation sur les quatre voisins de chaque case.

const Plateau = preload("res://game/board/plateau.gd")
const VOISINS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## Calcule la longueur du plus court chemin vers une horloge depuis le réseau relié.
static func calculer(plateau: Plateau) -> Dictionary:
	var distances: Dictionary[Vector2i, int] = {}
	var file: Array[Vector2i] = []
	for case: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(case).type == Plateau.PieceDef.Type.HORLOGE:
			distances[case] = 0
			file.append(case)
	var tete: int = 0
	while tete < file.size():
		var case: Vector2i = file[tete]
		tete += 1
		for direction: Vector2i in VOISINS:
			var voisin: Vector2i = case + direction
			if not distances.has(voisin) and plateau.sol_de(voisin) == Plateau.Sol.CHEMIN:
				distances[voisin] = distances[case] + 1
				file.append(voisin)
	return distances


## Repère les extrémités du chemin ouvertes sur une case sans sol, dans un ordre stable.
static func entrees(plateau: Plateau, distances: Dictionary) -> Array[Vector2i]:
	var resultat: Array[Vector2i] = []
	for case: Vector2i in distances:
		if distances[case] <= 0:
			continue
		var en_bordure: bool = false
		var voisins_relies: int = 0
		for direction: Vector2i in VOISINS:
			var voisin: Vector2i = case + direction
			if distances.has(voisin):
				voisins_relies += 1
			elif not plateau.a_sol(voisin):
				en_bordure = true
		if en_bordure and voisins_relies == 1:
			resultat.append(case)
	resultat.sort()
	return resultat


## Attribue à chaque case de sol accessible sa source la plus proche sur le chemin.
static func vers_chemin(plateau: Plateau, distances: Dictionary) -> Dictionary:
	var sources: Dictionary[Vector2i, Vector2i] = {}
	var file: Array[Vector2i] = []
	for case: Vector2i in distances:
		sources[case] = case
		file.append(case)
	var tete: int = 0
	while tete < file.size():
		var case: Vector2i = file[tete]
		tete += 1
		for direction: Vector2i in VOISINS:
			var voisin: Vector2i = case + direction
			if not sources.has(voisin) and plateau.a_sol(voisin):
				sources[voisin] = sources[case]
				file.append(voisin)
	return sources
