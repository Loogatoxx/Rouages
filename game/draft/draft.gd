class_name Draft extends RefCounted
## Prépare les choix de lots proposés avant la construction.

const Lot = preload("res://game/core/lot.gd")


## Tire sans remise parmi les lots disponibles pour la vague, selon leurs poids.
## Jamais deux fois le même objet dans une offre (playtest 1 : « empêcher les doublons »), même si deux lots le
## proposent en quantités différentes ; `exclus` écarte des objets déjà montrés (cartes de coffre tirées une à une).
static func tirer(lots: Array[Lot], n: int, vague: int, rng: RandomNumberGenerator, exclus: Array = []) -> Array[Lot]:
	var candidats: Array[Lot] = []
	var poids: PackedFloat32Array = []
	for lot: Lot in lots:
		if lot != null and lot.vague_min <= vague and lot.poids > 0.0 and not candidats.has(lot) \
				and (lot.objet == null or not exclus.has(lot.objet)):
			candidats.append(lot)
			poids.append(lot.poids)
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
