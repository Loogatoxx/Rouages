class_name SwarmSim extends RefCounted
## Simule deux nuées sur le plan du plateau, avec un état compact par camp.

signal tir(depart: Vector2, arrivee: Vector2)
signal ennemi_arrive(degats: float)
signal unite_morte(camp: int, position: Vector2, def: UniteDef)

const Plateau = preload("res://game/board/plateau.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const CAPACITE := 400
const MAILLE := 2.0
const POURSUITE := 6.0
const ALLIE := UniteDef.Camp.ALLIE
const ENNEMI := UniteDef.Camp.ENNEMI


## Une cellule de deux mètres conserve les indices locaux et son rectangle occupé.
class Cellule:
	var indices: Array[int] = []
	var minimum: Vector2
	var maximum: Vector2


## Les tableaux parallèles partagent le même indice pour toutes les données d'une unité.
class Nuee:
	var lieux := PackedVector2Array()
	var angles := PackedFloat32Array()
	var vies := PackedFloat32Array()
	var touches := PackedFloat32Array()
	var recharges := PackedFloat32Array()
	var choix := PackedInt64Array()
	var modeles: Array[UniteDef] = []
	var suivants := PackedVector2Array()
	var grille: Dictionary[Vector2i, Cellule] = {}
	var influence: Dictionary[Vector2i, Array] = {}
	var rayon_max: float = 0.0
	var portee_max: float = 0.0

	func _retirer(i: int) -> void:
		var fin: int = lieux.size() - 1
		lieux[i] = lieux[fin]
		angles[i] = angles[fin]
		vies[i] = vies[fin]
		touches[i] = touches[fin]
		recharges[i] = recharges[fin]
		choix[i] = choix[fin]
		modeles[i] = modeles[fin]
		lieux.resize(fin)
		angles.resize(fin)
		vies.resize(fin)
		touches.resize(fin)
		recharges.resize(fin)
		choix.resize(fin)
		modeles.pop_back()


## Fraction du chemin que les alliés peuvent parcourir sans cible.
var garde_ratio: float = 1.0
var _distance_max: int = 0
var _camps: Array[Nuee] = [Nuee.new(), Nuee.new()]
var _distances: Dictionary = {}
var _objectifs: Array[Dictionary] = [{}, {}]
var _branches: Dictionary[Vector2i, PackedVector2Array] = {}


## Recalcule les cartes et les prochains centres à viser, sans déplacer les unités.
func configurer(plateau: Plateau, ratio: float = 1.0) -> void:
	garde_ratio = ratio
	_distance_max = 0
	_distances = ChampFlux.calculer(plateau)
	var sources: Dictionary = ChampFlux.vers_chemin(plateau, _distances)
	for objectifs: Dictionary in _objectifs:
		objectifs.clear()
	_branches.clear()
	for case: Vector2i in sources:
		var source: Vector2i = sources[case]
		_objectifs[ALLIE][case] = Vector2(source) * MAILLE
		_objectifs[ENNEMI][case] = Vector2(source) * MAILLE
		if case != source:
			continue
		var branches := PackedVector2Array()
		var retour: Vector2i = case
		var distance: int = _distances[case]
		_distance_max = maxi(_distance_max, distance)
		for direction: Vector2i in ChampFlux.VOISINS:
			var voisin: Vector2i = case + direction
			var suivante: int = _distances.get(voisin, -1)
			if suivante > distance:
				branches.append(Vector2(voisin) * MAILLE)
			elif suivante >= 0 and suivante < distance and retour == case:
				retour = voisin
		_objectifs[ENNEMI][case] = Vector2(retour) * MAILLE
		if branches.size() == 1:
			_objectifs[ALLIE][case] = branches[0]
		elif branches.size() > 1:
			_branches[case] = branches


## Ajoute une unité prête à frapper tant qu'il reste une place dans son camp.
func ajouter(def: UniteDef, position: Vector2) -> bool:
	var nuee: Nuee = _camps[def.camp]
	if nuee.lieux.size() >= CAPACITE:
		return false
	nuee.lieux.append(position)
	nuee.angles.append(0.0)
	nuee.vies.append(def.pv)
	nuee.touches.append(0.0)
	nuee.recharges.append(0.0)
	nuee.choix.append(randi() if def.camp == ALLIE else 0)
	nuee.modeles.append(def)
	nuee.rayon_max = maxf(nuee.rayon_max, def.rayon)
	nuee.portee_max = maxf(nuee.portee_max, def.portee)
	return true


## Renvoie l'effectif vivant du camp.
func nombre(camp: int) -> int:
	return _camps[camp].lieux.size()


## Renvoie les positions en mètres dans le plan horizontal.
func positions(camp: int) -> PackedVector2Array:
	return _camps[camp].lieux


## Renvoie la durée restante du flash de chaque unité du camp.
func touches(camp: int) -> PackedFloat32Array:
	return _camps[camp].touches


## Renvoie les angles de marche depuis l'axe X vers l'axe Z.
func caps(camp: int) -> PackedFloat32Array:
	return _camps[camp].angles


## Renvoie les modèles en lecture seule par convention, dans le même ordre que les positions.
func modeles(camp: int) -> Array[UniteDef]:
	return _camps[camp].modeles


## Résout les décisions sur un même instantané, puis applique déplacements et retraits.
func avancer(dt: float) -> void:
	if dt <= 0.0:
		return
	var ennemis: Nuee = _camps[ENNEMI]
	for i: int in range(ennemis.lieux.size() - 1, -1, -1):
		_verifier_arrivee(ennemis, i)
	for nuee: Nuee in _camps:
		_indexer(nuee, dt)
	for camp: int in [ALLIE, ENNEMI]:
		var nuee: Nuee = _camps[camp]
		var adverse: Nuee = _camps[1 - camp]
		var detection: float = maxf(POURSUITE if camp == ALLIE else 0.0, nuee.portee_max)
		if nuee.grille.is_empty():
			continue
		_diffuser(adverse, detection)
		for case: Vector2i in nuee.grille:
			var cellule: Cellule = nuee.grille[case]
			var cibles: Array = adverse.influence.get(case, [])
			for i: int in cellule.indices:
				_decider(camp, i, cibles, dt)
	for nuee: Nuee in _camps:
		_separer(nuee, dt)
		nuee.lieux = nuee.suivants
	for camp: int in [ALLIE, ENNEMI]:
		var nuee: Nuee = _camps[camp]
		for i: int in range(nuee.lieux.size() - 1, -1, -1):
			var lieu: Vector2 = nuee.lieux[i]
			if nuee.vies[i] <= 0.0:
				unite_morte.emit(camp, lieu, nuee.modeles[i])
				nuee._retirer(i)
			elif camp == ENNEMI:
				_verifier_arrivee(nuee, i)


func _verifier_arrivee(ennemis: Nuee, i: int) -> void:
	var lieu: Vector2 = ennemis.lieux[i]
	var case := Vector2i((lieu / MAILLE).round())
	if _distances.get(case, -1) == 0 and lieu.distance_squared_to(Vector2(case) * MAILLE) < 1.0:
		var degats: float = ennemis.modeles[i].degats
		ennemis._retirer(i)
		ennemi_arrive.emit(degats)


func _indexer(nuee: Nuee, dt: float) -> void:
	nuee.grille.clear()
	nuee.influence.clear()
	nuee.suivants = nuee.lieux.duplicate()
	for i: int in nuee.lieux.size():
		if nuee.touches[i] > 0.0:
			nuee.touches[i] = maxf(0.0, nuee.touches[i] - dt)
		var lieu: Vector2 = nuee.lieux[i]
		var case := Vector2i((lieu / MAILLE).floor())
		var cellule: Cellule = nuee.grille.get(case)
		if cellule == null:
			cellule = Cellule.new()
			cellule.minimum = lieu
			cellule.maximum = lieu
			nuee.grille[case] = cellule
		else:
			cellule.minimum = cellule.minimum.min(lieu)
			cellule.maximum = cellule.maximum.max(lieu)
		cellule.indices.append(i)


# Chaque cellule occupée inscrit son influence dans les cases couvertes. Une poursuite
# à six mètres se résout ensuite par lecture locale, même au-delà des voisins immédiats.
func _diffuser(adverse: Nuee, rayon: float) -> void:
	var marge := Vector2.ONE * rayon
	for origine: Vector2i in adverse.grille:
		var cellule: Cellule = adverse.grille[origine]
		var debut := Vector2i(((cellule.minimum - marge) / MAILLE).floor())
		var fin := Vector2i(((cellule.maximum + marge) / MAILLE).floor())
		for x: int in range(debut.x, fin.x + 1):
			for y: int in range(debut.y, fin.y + 1):
				var case := Vector2i(x, y)
				if not adverse.influence.has(case):
					adverse.influence[case] = []
				# Une cible de la même cellule donne tôt une borne pour écarter les autres.
				if case == origine:
					adverse.influence[case].push_front(cellule)
				else:
					adverse.influence[case].append(cellule)


func _decider(camp: int, i: int, cibles: Array, dt: float) -> void:
	var nuee: Nuee = _camps[camp]
	var adverse: Nuee = _camps[1 - camp]
	var lieu: Vector2 = nuee.lieux[i]
	var modele: UniteDef = nuee.modeles[i]
	var rayon: float = maxf(POURSUITE, modele.portee) if camp == ALLIE else modele.portee
	var meilleur: float = rayon * rayon
	var cible: int = -1
	var adversaires: PackedVector2Array = adverse.lieux
	for cellule: Cellule in cibles:
		if lieu.distance_squared_to(lieu.clamp(cellule.minimum, cellule.maximum)) > meilleur:
			continue
		for j: int in cellule.indices:
			var d: float = lieu.distance_squared_to(adversaires[j])
			if d < meilleur or (d == meilleur and (cible < 0 or j < cible)):
				meilleur = d
				cible = j

	var recharge: float = nuee.recharges[i]
	if cible >= 0 and meilleur <= modele.portee * modele.portee:
		if modele.cadence > 0.0:
			var periode: float = 1.0 / modele.cadence
			# Compte aussi les frappes intermédiaires si un pas dépasse une période.
			if recharge < dt - 0.000001 or recharge <= 0.0:
				var coups: int = maxi(1, ceili((dt - recharge - 0.000001) / periode))
				adverse.vies[cible] -= modele.degats * coups
				adverse.touches[cible] = 0.12
				if camp == ALLIE and modele.portee > 1.0:
					for coup: int in coups:
						tir.emit(lieu, adversaires[cible])
				recharge += periode * coups
		nuee.recharges[i] = maxf(0.0, recharge - dt)
		return
	nuee.recharges[i] = maxf(0.0, recharge - dt)
	var destination: Vector2
	if cible >= 0 and meilleur < POURSUITE * POURSUITE:
		destination = adverse.lieux[cible]
	else:
		destination = _objectif_flux(camp, lieu, nuee.choix[i])
	if destination != lieu:
		nuee.suivants[i] = lieu.move_toward(destination, modele.vitesse * dt)
		nuee.angles[i] = (destination - lieu).angle()


func _objectif_flux(camp: int, lieu: Vector2, choix: int) -> Vector2:
	var case := Vector2i((lieu / MAILLE).round())
	if camp == ALLIE and _distances.get(case, -1) > garde_ratio * _distance_max:
		return lieu
	if camp == ALLIE and _branches.has(case):
		var branches: PackedVector2Array = _branches[case]
		# Le hachage mêle le choix et la case : deux embranchements successifs restent indépendants
		# (avec un simple `choix % 2`, tous les jouets partis au nord prendraient la même branche ensuite).
		return branches[posmod(hash(Vector3i(choix & 0x7FFFFFFF, case.x, case.y)), branches.size())]
	var objectifs: Dictionary = _objectifs[camp]
	if objectifs.has(case):
		return objectifs[case]
	if _distances.is_empty():
		return lieu
	# Un débordement hors du plateau garde un chemin de retour mémorisé.
	var minimum: float = INF
	var cible: Vector2i = case
	for source: Vector2i in _distances:
		var d: float = case.distance_squared_to(source)
		if d < minimum:
			minimum = d
			cible = source
	objectifs[case] = Vector2(cible) * MAILLE
	return objectifs[case]


# Chaque paire locale est traitée une fois. Les corrections successives évitent
# d'additionner cinquante répulsions quand un groupe naît au même point.
func _separer(nuee: Nuee, dt: float) -> void:
	var limite: float = minf(nuee.rayon_max, MAILLE) * minf(1.0, dt * 12.0)
	for case: Vector2i in nuee.grille:
		var ici: Cellule = nuee.grille[case]
		_ecarter(nuee, ici, ici, limite)
		for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1), Vector2i(-1, 1)]:
			var voisin: Cellule = nuee.grille.get(case + direction)
			if voisin != null:
				_ecarter(nuee, ici, voisin, limite)


func _ecarter(nuee: Nuee, a: Cellule, b: Cellule, limite: float) -> void:
	var lieux: PackedVector2Array = nuee.suivants
	var modeles: Array[UniteDef] = nuee.modeles
	var voisins: Array[int] = b.indices
	for k: int in a.indices.size():
		var i: int = a.indices[k]
		var lieu: Vector2 = lieux[i]
		var rayon: float = modeles[i].rayon
		var maximum: float = (rayon + nuee.rayon_max) ** 2
		for l: int in range(k + 1 if a == b else 0, voisins.size()):
			var j: int = voisins[l]
			var ecart: Vector2 = lieu - lieux[j]
			var carre: float = ecart.length_squared()
			if carre >= maximum:
				continue
			var contact: float = rayon + modeles[j].rayon
			if carre >= contact * contact:
				continue
			var distance: float = sqrt(carre)
			var normale: Vector2 = ecart / distance if distance > 0.0 else Vector2.from_angle(i * 2.4 + j)
			var correction: Vector2 = normale * minf(limite, (contact - distance) * 0.5)
			lieu += correction
			lieux[j] -= correction
		lieux[i] = lieu
