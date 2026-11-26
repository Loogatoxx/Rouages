class_name Tourelles extends RefCounted
## Suit le temps de recharge de chaque tourelle alimentée.

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")

var _recharges: Dictionary[Vector2i, float] = {}


## Fait tirer les tourelles prêtes et les laisse disponibles tant qu'elles manquent de cible.
func avancer(dt: float, plateau: Plateau, alimentees: Dictionary, sim: SwarmSim) -> void:
	if dt <= 0.0:
		return
	for case: Vector2i in alimentees:
		var piece: PieceDef = plateau.piece_de(case)
		if piece == null or piece.type != PieceDef.Type.TOURELLE or piece.cadence_tir <= 0.0:
			continue
		var reste: float = _recharges.get(case, 0.0)
		var centre: Vector2 = Vector2(case) * GrilleMonde.TAILLE_CASE
		while reste < dt:
			if not sim.blesser_zone(centre, piece.portee_tir, piece.degats_tir, piece.zone_tir):
				break
			reste += 1.0 / piece.cadence_tir
		_recharges[case] = maxf(0.0, reste - dt)
