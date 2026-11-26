class_name Production extends RefCounted
## Suit la progression de chaque atelier et place ses jouets à la sortie du port.

signal jouet_produit(case: Vector2i)

const Plateau = preload("res://game/board/plateau.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Regles = preload("res://game/core/regles.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _progressions: Dictionary[Vector2i, float] = {}


## Avance les ateliers alimentés et limite leur effectif total de jouets vivants.
func avancer(dt: float, plateau: Plateau, alimentees: Dictionary, sim: SwarmSim, regles: Regles) -> void:
	var ateliers: Array[Vector2i] = []
	for case: Vector2i in alimentees:
		var piece: Plateau.PieceDef = plateau.piece_de(case)
		if piece != null and piece.type == Plateau.PieceDef.Type.ATELIER:
			ateliers.append(case)
	var plafond: int = regles.plafond_allies_par_atelier * ateliers.size()
	for case: Vector2i in ateliers:
		var atelier: Plateau.PieceDef = plateau.piece_de(case)
		if atelier.cadence_production <= 0.0 or atelier.unite_produite == null:
			continue
		var progression: float = _progressions.get(case, 0.0) + dt * atelier.cadence_production
		var prets: int = floori(progression)
		_progressions[case] = progression - prets
		var places: int = plafond - sim.nombre(SwarmSim.ALLIE)
		if prets > 0 and places > 0:
			var sortie: Vector2 = _sortie(case, plateau.ports_de(case))
			for i: int in mini(prets, places):
				if not sim.ajouter(atelier.unite_produite, sortie):
					break
				jouet_produit.emit(case)


func _sortie(case: Vector2i, ports: int) -> Vector2:
	var centre: Vector2 = Vector2(case) * GrilleMonde.TAILLE_CASE
	for i: int in DIRECTIONS.size():
		if ports & (1 << i):
			return centre + Vector2(DIRECTIONS[i]) * (GrilleMonde.TAILLE_CASE / 2.0)
	return centre
