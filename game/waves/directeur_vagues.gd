class_name DirecteurVagues extends RefCounted
## Échelonne les arrivées de scarabées en partageant la vague entre les entrées.

const VagueDef = preload("res://game/waves/vague_def.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")

var _vague: VagueDef
var _unite: UniteDef
var _renfort: UniteDef
var _total: int = 0
var _progression_renfort: int = 0
var _entrees: Array[Vector2i] = []
var _apparues: int = 0
var _delai: float = 0.0


## Prépare les deux modèles avec les PV propres à la vague.
func commencer(vague: VagueDef, entrees: Array[Vector2i]) -> void:
	_vague = vague
	_unite = _modele_vague(vague.unite)
	_renfort = _modele_vague(vague.renfort) if vague.renfort != null else null
	_total = vague.nombre + (vague.nombre_renforts if _renfort != null else 0)
	# Un demi-intervalle initial centre les renforts dans la vague.
	_progression_renfort = floori(_total * 0.5)
	_entrees = entrees.duplicate()
	_apparues = 0
	_delai = 0.0


func _modele_vague(source: UniteDef) -> UniteDef:
	var modele: UniteDef = source.duplicate() as UniteDef
	modele.pv *= _vague.multiplicateur_pv
	return modele


## Fait arriver le premier scarabée dès le lancement, puis les suivants à intervalles réguliers.
func avancer(dt: float, sim: SwarmSim) -> void:
	if _entrees.is_empty() or _apparues >= _total:
		return
	_delai -= dt
	while _delai <= 0.0 and _apparues < _total:
		var case: Vector2i = _entrees[_apparues % _entrees.size()]
		var centre: Vector2 = Vector2(case) * GrilleMonde.TAILLE_CASE
		var decalage: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, 0.5)
		var progression: int = _progression_renfort
		if _renfort != null:
			progression += _vague.nombre_renforts
		var modele: UniteDef = _renfort if progression >= _total else _unite
		if not sim.ajouter(modele, centre + decalage):
			_delai = 0.0
			break
		_progression_renfort = progression % _total
		_apparues += 1
		_delai += _vague.intervalle


## Indique que toute la vague est entrée et que le dernier ennemi a disparu.
func est_terminee(sim: SwarmSim) -> bool:
	return _vague != null and _apparues == _total and sim.nombre(SwarmSim.ENNEMI) == 0
