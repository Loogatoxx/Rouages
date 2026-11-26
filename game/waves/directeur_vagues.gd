class_name DirecteurVagues extends RefCounted
## Échelonne les arrivées de scarabées en partageant la vague entre les entrées.

const VagueDef = preload("res://game/waves/vague_def.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")

var _vague: VagueDef
var _unite: UniteDef
var _entrees: Array[Vector2i] = []
var _apparues: int = 0
var _delai: float = 0.0


## Prépare une copie du modèle d'unité avec les PV propres à cette vague.
func commencer(vague: VagueDef, entrees: Array[Vector2i]) -> void:
	_vague = vague
	_unite = vague.unite.duplicate() as UniteDef
	_unite.pv *= vague.multiplicateur_pv
	_entrees = entrees.duplicate()
	_apparues = 0
	_delai = 0.0


## Fait arriver le premier scarabée dès le lancement, puis les suivants à intervalles réguliers.
func avancer(dt: float, sim: SwarmSim) -> void:
	if _vague == null or _entrees.is_empty() or _apparues >= _vague.nombre:
		return
	_delai -= dt
	while _delai <= 0.0 and _apparues < _vague.nombre:
		var case: Vector2i = _entrees[_apparues % _entrees.size()]
		var centre: Vector2 = Vector2(case) * GrilleMonde.TAILLE_CASE
		var decalage: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, 0.5)
		if not sim.ajouter(_unite, centre + decalage):
			_delai = 0.0
			break
		_apparues += 1
		_delai += _vague.intervalle


## Indique que toute la vague est entrée et que le dernier ennemi a disparu.
func est_terminee(sim: SwarmSim) -> bool:
	return _vague != null and _apparues == _vague.nombre and sim.nombre(SwarmSim.ENNEMI) == 0
