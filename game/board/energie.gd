class_name Energie extends RefCounted

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## Calcule les pièces alimentées et leur distance (en pièces) à leur source.
## L'horloge alimente tout son réseau ; chaque générateur (playtest 2) alimente ensuite, parmi les pièces restantes,
## au plus `capacite_generateur + capacite_par_niveau × (niveau − 1)` ateliers et tourelles (les engrenages ne comptent pas).
static func calculer(plateau: Plateau) -> Dictionary:
	var profondeurs: Dictionary[Vector2i, int] = {}
	var horloges: Array[Vector2i] = []
	var generateurs: Array[Vector2i] = []
	for coord: Vector2i in plateau.coords_pieces():
		match plateau.piece_de(coord).type:
			PieceDef.Type.HORLOGE:
				horloges.append(coord)
			PieceDef.Type.GENERATEUR:
				generateurs.append(coord)
	_propager(plateau, horloges, profondeurs, -1)
	generateurs.sort()
	for coord: Vector2i in generateurs:
		if profondeurs.has(coord):
			continue  # relié à l'horloge : il transmet comme un engrenage
		var piece: PieceDef = plateau.piece_de(coord)
		_propager(plateau, [coord], profondeurs,
				piece.capacite_generateur + piece.capacite_par_niveau * (plateau.niveau_de(coord) - 1))
	return profondeurs


## Nombre d'ateliers et de tourelles qu'un générateur alimente lui-même (pour l'afficher).
static func consommateurs_du_generateur(plateau: Plateau, coord: Vector2i) -> int:
	var seul: Dictionary[Vector2i, int] = {}
	var piece: PieceDef = plateau.piece_de(coord)
	if piece == null or piece.type != PieceDef.Type.GENERATEUR:
		return 0
	var reseau_horloge: Dictionary = {}
	for c: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(c).type == PieceDef.Type.HORLOGE:
			_propager(plateau, [c], reseau_horloge, -1)
	if reseau_horloge.has(coord):
		return 0
	_propager(plateau, [coord], seul, piece.capacite_generateur + piece.capacite_par_niveau * (plateau.niveau_de(coord) - 1))
	var compte: int = 0
	for c: Vector2i in seul:
		if not reseau_horloge.has(c) and _consomme(plateau.piece_de(c)):
			compte += 1
	return compte


static func _consomme(piece: PieceDef) -> bool:
	return piece != null and (piece.type == PieceDef.Type.ATELIER or piece.type == PieceDef.Type.TOURELLE)


# Parcours en largeur depuis `sources` ; `budget` < 0 = illimité, sinon nombre maximal d'ateliers et de tourelles
# ajoutés (une fois le budget épuisé, les engrenages continuent de transmettre mais plus aucun consommateur ne s'allume).
static func _propager(plateau: Plateau, sources: Array[Vector2i], profondeurs: Dictionary, budget: int) -> void:
	var file: Array[Vector2i] = []
	for coord: Vector2i in sources:
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
			if budget >= 0 and _consomme(plateau.piece_de(voisine)):
				if budget == 0:
					continue
				budget -= 1
			profondeurs[voisine] = profondeurs[coord] + 1
			file.append(voisine)
