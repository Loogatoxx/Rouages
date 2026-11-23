class_name Energie extends RefCounted

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


static func calculer(plateau: Plateau) -> Dictionary:
	var profondeurs: Dictionary[Vector2i, int] = {}
	var file: Array[Vector2i] = []
	for coord: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(coord).type == PieceDef.Type.HORLOGE:
			profondeurs[coord] = 0
			file.append(coord)

	var indice: int = 0
	while indice < file.size():
		var coord: Vector2i = file[indice]
		indice += 1
		if not plateau.piece_de(coord).transmet:
			continue
		var ports: int = plateau.ports_de(coord)
		for direction: int in range(4):
			if (ports & (1 << direction)) == 0:
				continue
			var voisine: Vector2i = coord + DIRECTIONS[direction]
			var retour: int = 1 << ((direction + 2) % 4)
			if profondeurs.has(voisine) or (plateau.ports_de(voisine) & retour) == 0:
				continue
			profondeurs[voisine] = profondeurs[coord] + 1
			file.append(voisine)
	return profondeurs
