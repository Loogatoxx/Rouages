class_name DirecteurVagues extends RefCounted
## Échelonne les arrivées de scarabées en partageant la vague entre les entrées.

const VagueDef = preload("res://game/waves/vague_def.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")

## Écart (secondes) entre deux ennemis d'un même paquet.
const ECART_GROUPE := 0.35

var facteur_pv: float = 1.0
var _vague: VagueDef
var _unite: UniteDef
var _renfort: UniteDef
var _volant: UniteDef
var _total_sol: int = 0
var _progression_volants: int = 0
var _volants_apparus: int = 0
var _total: int = 0
var _progression_renfort: int = 0
var _entrees: Array[Vector2i] = []
var _apparues: int = 0
var _delai: float = 0.0
var _boss: UniteDef
var _boss_lache: bool = false
var _speciaux: Array[Resource] = []
var _pas_speciaux: int = 0
var _ordinaires: int = 0


## Prépare les modèles avec les PV propres à la vague. `delai` = secondes avant le premier ennemi (le temps que les
## ateliers, repartis de zéro, sortent leurs premiers jouets : playtest 2).
## `speciaux` (ennemis propres au plateau) remplacent un scarabée ordinaire sur `1 / part` (sans changer le total).
func commencer(vague: VagueDef, entrees: Array[Vector2i], delai: float = 0.0, speciaux: Array[Resource] = [],
		part: float = 0.0) -> void:
	_vague = vague
	_unite = _modele_vague(vague.unite)
	_renfort = _modele_vague(vague.renfort) if vague.renfort != null else null
	_volant = _modele_vague(vague.volants) if vague.volants != null else null
	_total_sol = vague.nombre + (vague.nombre_renforts if _renfort != null else 0)
	_total = _total_sol + (vague.nombre_volants if _volant != null else 0)
	_progression_volants = floori(_total * 0.5)
	_volants_apparus = 0
	# Un demi-intervalle initial centre les renforts dans la vague.
	_progression_renfort = floori(_total_sol * 0.5)
	_entrees = entrees.duplicate()
	_apparues = 0
	_delai = delai
	_speciaux.clear()
	for special: Resource in speciaux:
		_speciaux.append(_modele_vague(special))
	_pas_speciaux = roundi(1.0 / part) if part > 0.0 else 0
	_ordinaires = 0
	_boss = null
	_boss_lache = vague.boss == null
	if vague.boss != null:
		_boss = _modele_vague(vague.boss)
		_boss.pv *= vague.pv_boss_facteur


func _modele_vague(source: UniteDef) -> UniteDef:
	var modele: UniteDef = source.duplicate() as UniteDef
	modele.pv *= _vague.multiplicateur_pv * facteur_pv
	# Une fuite coûte toujours le même prix à l'Horloge, quelle que soit la vague (playtest 3 : une ligne qui cède
	# coûte quelques PV, pas la partie). La valeur vient des données, sinon des dégâts d'origine.
	if modele.degats_horloge <= 0.0:
		modele.degats_horloge = source.degats
	modele.degats *= _vague.multiplicateur_degats
	return modele


## Fait arriver le premier scarabée après le délai de lancement, puis les suivants à intervalles réguliers.
func avancer(dt: float, sim: SwarmSim) -> void:
	if _entrees.is_empty():
		return
	if not _boss_lache and _apparues * 2 >= _total:
		var case_boss: Vector2i = _entrees[0]
		_boss_lache = sim.ajouter(_boss, Vector2(case_boss) * GrilleMonde.TAILLE_CASE)
	if _apparues >= _total:
		return
	_delai -= dt
	while _delai <= 0.0 and _apparues < _total:
		var progression_volants: int = _progression_volants
		if _volant != null:
			progression_volants += _vague.nombre_volants
		var en_vol: bool = progression_volants >= _total
		# Chaque groupe alterne ses entrées, même si ses apparitions sont espacées.
		var rang: int = _volants_apparus if en_vol else _apparues - _volants_apparus
		var case: Vector2i = _entrees[rang % _entrees.size()]
		var centre: Vector2 = Vector2(case) * GrilleMonde.TAILLE_CASE
		var decalage: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, 0.5)
		var progression: int = _progression_renfort
		var modele: UniteDef = _unite
		if en_vol:
			modele = _volant
		elif _renfort != null:
			progression += _vague.nombre_renforts
			if progression >= _total_sol:
				modele = _renfort
		if modele == _unite and not _speciaux.is_empty() and _pas_speciaux > 0:
			_ordinaires += 1
			if _ordinaires % _pas_speciaux == 0:
				modele = _speciaux[(_ordinaires / _pas_speciaux) % _speciaux.size()]
		if not sim.ajouter(modele, centre + decalage):
			_delai = 0.0
			break
		_progression_volants = progression_volants % _total
		if en_vol:
			_volants_apparus += 1
		else:
			_progression_renfort = progression % _total_sol
		_apparues += 1
		# Par paquets : écart court à l'intérieur d'un paquet, puis le reste du temps du paquet en pause.
		var taille: int = maxi(1, _vague.groupe)
		if taille <= 1:
			_delai += _vague.intervalle
		elif _apparues % taille == 0:
			_delai += maxf(ECART_GROUPE, _vague.intervalle * taille - ECART_GROUPE * (taille - 1))
		else:
			_delai += minf(ECART_GROUPE, _vague.intervalle)


## Indique que toute la vague est entrée et que le dernier ennemi a disparu.
func est_terminee(sim: SwarmSim) -> bool:
	return _vague != null and _apparues == _total and _boss_lache and sim.nombre(SwarmSim.ENNEMI) == 0


## Effectif total de la vague, boss compris (pour le compteur « ennemis restants » du HUD).
func total() -> int:
	return _total + (1 if _boss != null else 0)


## Ennemis encore à battre : ceux qui ne sont pas encore entrés (boss compris) et ceux qui sont en vie.
func restants(sim: SwarmSim) -> int:
	if _vague == null:
		return 0
	return (_total - _apparues) + (0 if _boss_lache else 1) + sim.nombre(SwarmSim.ENNEMI)
