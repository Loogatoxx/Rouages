class_name Energie extends RefCounted
## Calcule quelles pièces reçoivent de l'énergie, de quelle source, et lesquelles restent éteintes faute de capacité.

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## Résultat complet d'un calcul d'énergie.
class Bilan:
	## Pièce alimentée → profondeur. Profondeur ≥ 0 : réseau de l'horloge (distance en pièces). Profondeur < 0 :
	## réseau d'un générateur (−1 pour le générateur, −2 pour ses voisins…) : énergie faible, sans bonus d'engrenage.
	var alimentees: Dictionary[Vector2i, int] = {}
	## Ateliers et tourelles reliés à un générateur plein : ils restent éteints (ce sont les derniers posés).
	var surcharge: Array[Vector2i] = []
	## Générateur autonome → dents d'énergie consommées sur lui.
	var charges: Dictionary[Vector2i, int] = {}
	## Dents consommées sur l'Horloge, et bâtiments qu'elle n'a pas pu servir (compris dans `surcharge`).
	var charge_horloge: int = 0
	var surcharge_horloge: Array[Vector2i] = []


## Calcule les pièces alimentées (voir `Bilan.alimentees` pour le sens des valeurs).
## L'horloge alimente tout son réseau sans limite. Un générateur isolé (playtest 3, refonte) alimente seulement :
## - les pièces à `portee_generateur` pièces de lui au plus (chaîne courte) ;
## - des ateliers et tourelles dans la limite de sa capacité, **dans l'ordre où ils ont été posés** : quand il est
##   plein, c'est le dernier bâtiment posé qui reste éteint, jamais un bâtiment déjà en marche.
static func calculer(plateau: Plateau, dents_horloge: int = -1) -> Dictionary:
	return analyser(plateau, dents_horloge).alimentees


## Calcul complet : pièces alimentées, bâtiments en surcharge et charge de chaque source.
## `dents_horloge` (playtest 3, « Tic-tac ») : énergie de l'Horloge, servie aux ateliers et tourelles de son réseau
## dans l'ordre de pose ; négatif = illimitée (tests anciens, bac à sable).
static func analyser(plateau: Plateau, dents_horloge: int = -1) -> Bilan:
	var bilan := Bilan.new()
	var horloges: Array[Vector2i] = []
	var generateurs: Array[Vector2i] = []
	for coord: Vector2i in plateau.coords_pieces():
		match plateau.piece_de(coord).type:
			PieceDef.Type.HORLOGE:
				horloges.append(coord)
			PieceDef.Type.GENERATEUR:
				generateurs.append(coord)
	_propager(plateau, horloges, bilan.alimentees)
	_rationner_horloge(plateau, bilan, dents_horloge)
	generateurs.sort()
	for coord: Vector2i in generateurs:
		if bilan.alimentees.has(coord):
			continue  # relié à l'horloge : il transmet comme un engrenage
		_alimenter_generateur(plateau, coord, bilan)
	return bilan


## Capacité actuelle d'un générateur, en dents (0 si la case ne porte pas de générateur).
static func capacite_du_generateur(plateau: Plateau, coord: Vector2i) -> int:
	var piece: PieceDef = plateau.piece_de(coord)
	if piece == null or piece.type != PieceDef.Type.GENERATEUR:
		return 0
	return piece.capacite_generateur + piece.capacite_par_niveau * (plateau.niveau_de(coord) - 1)


## Dents consommées sur un générateur autonome (pour l'afficher) ; 0 s'il est relié à l'horloge.
static func consommateurs_du_generateur(plateau: Plateau, coord: Vector2i) -> int:
	return analyser(plateau).charges.get(coord, 0)


## Vrai si la case est alimentée par un générateur (énergie faible : ses engrenages ne donnent pas leurs bonus).
static func energie_faible(alimentees: Dictionary, case: Vector2i) -> bool:
	var profondeur: Variant = alimentees.get(case)
	return profondeur is int and profondeur < 0


static func _consomme(piece: PieceDef) -> bool:
	return piece != null and (piece.type == PieceDef.Type.ATELIER or piece.type == PieceDef.Type.TOURELLE)


# Réseau de l'horloge : parcours en largeur, sans limite de capacité ni de longueur.
static func _propager(plateau: Plateau, sources: Array[Vector2i], profondeurs: Dictionary) -> void:
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
		for voisine: Vector2i in _voisines_reliees(plateau, coord):
			if profondeurs.has(voisine):
				continue
			profondeurs[voisine] = profondeurs[coord] + 1
			file.append(voisine)


# Tic-tac : les bâtiments du réseau de l'Horloge se partagent ses dents, les plus anciens d'abord. Celui qui ne
# peut pas être servi sort des pièces alimentées (il reste éteint, signalé « Plein »). Un générateur relié au réseau
# de l'Horloge n'ajoute rien : il transmet comme un engrenage.
static func _rationner_horloge(plateau: Plateau, bilan: Bilan, dents: int) -> void:
	var batiments: Array[Vector2i] = []
	for coord: Vector2i in bilan.alimentees:
		if _consomme(plateau.piece_de(coord)):
			batiments.append(coord)
	batiments.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return plateau.ordre_de(a) < plateau.ordre_de(b))
	var reste: int = dents
	for coord: Vector2i in batiments:
		var cout: int = plateau.piece_de(coord).cout_energie
		if dents < 0 or cout <= reste:
			reste -= cout
			bilan.charge_horloge += cout
		else:
			bilan.alimentees.erase(coord)
			bilan.surcharge.append(coord)
			bilan.surcharge_horloge.append(coord)


# Réseau d'un générateur autonome : chaîne courte, capacité servie dans l'ordre de pose.
static func _alimenter_generateur(plateau: Plateau, source: Vector2i, bilan: Bilan) -> void:
	var piece: PieceDef = plateau.piece_de(source)
	var portee: int = piece.portee_generateur
	var distances: Dictionary[Vector2i, int] = {source: 0}
	var file: Array[Vector2i] = [source]
	var candidats: Array[Vector2i] = []
	var indice: int = 0
	while indice < file.size():
		var coord: Vector2i = file[indice]
		indice += 1
		if portee > 0 and distances[coord] >= portee:
			continue
		for voisine: Vector2i in _voisines_reliees(plateau, coord):
			if distances.has(voisine) or bilan.alimentees.has(voisine) or bilan.surcharge_horloge.has(voisine):
				continue
			distances[voisine] = distances[coord] + 1
			if _consomme(plateau.piece_de(voisine)):
				candidats.append(voisine)
			elif plateau.piece_de(voisine).transmet:
				file.append(voisine)
	for coord: Vector2i in file:
		bilan.alimentees[coord] = -1 - distances[coord]
	# Les plus anciens d'abord : le bâtiment qu'on vient de poser est celui qui reste éteint si la capacité manque.
	candidats.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return plateau.ordre_de(a) < plateau.ordre_de(b))
	var reste: int = capacite_du_generateur(plateau, source)
	var charge: int = 0
	for coord: Vector2i in candidats:
		var cout: int = plateau.piece_de(coord).cout_energie
		if cout <= reste:
			reste -= cout
			charge += cout
			bilan.alimentees[coord] = -1 - distances[coord]
		else:
			bilan.surcharge.append(coord)
	bilan.charges[source] = charge


# Cases voisines dont le port fait face à un port ouvert de `coord`.
static func _voisines_reliees(plateau: Plateau, coord: Vector2i) -> Array[Vector2i]:
	var resultat: Array[Vector2i] = []
	var ports: int = plateau.ports_de(coord)
	for direction: int in range(4):
		if (ports & (1 << direction)) == 0:
			continue
		var voisine: Vector2i = coord + DIRECTIONS[direction]
		if plateau.ports_de(voisine) & (1 << ((direction + 2) % 4)):
			resultat.append(voisine)
	return resultat
