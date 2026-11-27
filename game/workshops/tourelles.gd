class_name Tourelles extends RefCounted
## Suit le temps de recharge de chaque tourelle alimentée.

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Placement = preload("res://game/workshops/placement.gd")
const Regles = preload("res://game/core/regles.gd")

## Règles de la partie (bonus de bord de route) ; réglé par `Partie` pour ne pas lire d'autoload.
var regles: Regles = preload("res://data/regles.tres")

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
		var degats: float = piece.degats_tir * Placement.degats_tourelle(plateau, case, regles)
		var cadence: float = piece.cadence_tir * Placement.cadence_tourelle(plateau, alimentees, case)
		while reste < dt:
			if not sim.blesser_zone(centre, piece.portee_tir, degats, piece.zone_tir, piece.ralentissement, piece.duree_ralenti):
				break
			reste += 1.0 / cadence
		_recharges[case] = maxf(0.0, reste - dt)
