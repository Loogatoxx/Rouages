class_name Draft extends RefCounted
## Prépare les choix de lots proposés avant la construction.

const Lot = preload("res://game/core/lot.gd")


## Tire sans remise parmi les lots disponibles pour la vague, selon leurs poids.
## Jamais deux fois le même objet dans une offre (playtest 1 : « empêcher les doublons »), même si deux lots le
## proposent en quantités différentes ; `exclus` écarte des objets déjà montrés (cartes de coffre tirées une à une).
## `chance` (≥ 0) multiplie le poids des lots rares par (1 + chance × `facteurs.x`) et épiques par (1 + chance × `facteurs.y`).
static func tirer(lots: Array[Lot], n: int, vague: int, rng: RandomNumberGenerator, exclus: Array = [],
		chance: int = 0, facteurs: Vector2 = Vector2(0.25, 0.5)) -> Array[Lot]:
	var candidats: Array[Lot] = []
	var poids: PackedFloat32Array = []
	for lot: Lot in lots:
		if lot != null and lot.vague_min <= vague and lot.poids > 0.0 and not candidats.has(lot) \
				and (lot.objet == null or not exclus.has(lot.objet)):
			candidats.append(lot)
			poids.append(lot.poids * _bonus_chance(lot, chance, facteurs))
	var offre: Array[Lot] = []
	while offre.size() < n and not candidats.is_empty():
		var indice: int = rng.rand_weighted(poids)
		var choisi: Lot = candidats.pop_at(indice)
		poids.remove_at(indice)
		offre.append(choisi)
		if choisi.objet == null:
			continue
		for i: int in range(candidats.size() - 1, -1, -1):
			if candidats[i].objet == choisi.objet:
				candidats.remove_at(i)
				poids.remove_at(i)
	return offre


# Les lots sans rareté (engrenages, ateliers, extensions) gardent leur poids : la chance ne joue que sur les raretés.
static func _bonus_chance(lot: Lot, chance: int, facteurs: Vector2) -> float:
	if chance <= 0 or lot.objet == null or not "rarete" in lot.objet:
		return 1.0
	match int(lot.objet.get("rarete")):
		1:
			return 1.0 + chance * facteurs.x
		2:
			return 1.0 + chance * facteurs.y
	return 1.0
