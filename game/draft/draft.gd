class_name Draft extends RefCounted
## Prépare les choix de lots proposés avant la construction.

const Lot = preload("res://game/core/lot.gd")


## Tire sans remise parmi les lots disponibles pour la vague, selon leurs poids.
static func tirer(lots: Array[Lot], n: int, vague: int, rng: RandomNumberGenerator) -> Array[Lot]:
	var candidats: Array[Lot] = []
	var poids: PackedFloat32Array = []
	for lot: Lot in lots:
		if lot != null and lot.vague_min <= vague and lot.poids > 0.0 and not candidats.has(lot):
			candidats.append(lot)
			poids.append(lot.poids)
	if candidats.size() <= n:
		return candidats
	var offre: Array[Lot] = []
	for i: int in range(n):
		var indice: int = rng.rand_weighted(poids)
		offre.append(candidats.pop_at(indice))
		poids.remove_at(indice)
	return offre
