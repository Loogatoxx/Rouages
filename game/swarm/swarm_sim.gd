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
const PORTEE_DISTANCE := 1.0
const POURSUITE := 6.0
const ALLIE := UniteDef.Camp.ALLIE
const ENNEMI := UniteDef.Camp.ENNEMI
## Origine des unités qui ne sortent d'aucun atelier (ennemis, tests).
const SANS_ORIGINE := Vector2i(-99999, -99999)
## Intervalle (secondes de simulation) entre deux recalculs du chemin vers les ennemis.
const RECALCUL_PISTE := 0.2


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
	## Atelier d'où sort chaque unité, et effectif vivant par atelier (plafond par bâtiment, playtest 2).
	var origines: Array[Vector2i] = []
	var effectifs: Dictionary[Vector2i, int] = {}
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
		var origine: Vector2i = origines[i]
		effectifs[origine] = effectifs.get(origine, 1) - 1
		origines[i] = origines[fin]
		lieux.resize(fin)
		angles.resize(fin)
		vies.resize(fin)
		touches.resize(fin)
		recharges.resize(fin)
		choix.resize(fin)
		modeles.pop_back()
		origines.pop_back()

	func _vider() -> void:
		lieux.clear()
		angles.clear()
		vies.clear()
		touches.clear()
		recharges.clear()
		choix.clear()
		modeles.clear()
		origines.clear()
		effectifs.clear()
		grille.clear()
		influence.clear()


## Fraction du chemin que les alliés peuvent parcourir sans cible.
var garde_ratio: float = 1.0
var _distance_max: int = 0
var _camps: Array[Nuee] = [Nuee.new(), Nuee.new()]
var _distances: Dictionary = {}
var _objectifs: Array[Dictionary] = [{}, {}]
var _branches: Dictionary[Vector2i, PackedVector2Array] = {}
# Case de chemin la plus proche de chaque case de sol (pour situer un ennemi hors de la route).
var _sources: Dictionary = {}
# Pour chaque case de chemin, la case suivante vers l'ennemi le plus proche par la route :
# [0] = ennemis au sol (jouets au corps à corps), [1] = tous (jouets à distance). Vide si aucun ennemi.
var _pistes: Array[Dictionary] = [{}, {}]
# Cases de chemin sur un trajet entrée → horloge (les autres sont des culs-de-sac).
var _utiles: Dictionary = {}
var _attente_piste: float = 0.0
# Armure prêtée à chaque ennemi par un porte-bouclier voisin (même indice que les ennemis), recalculée à chaque pas.
var _boucliers := PackedFloat32Array()


## Recalcule les cartes et les prochains centres à viser, sans déplacer les unités.
func configurer(plateau: Plateau, ratio: float = 1.0) -> void:
	garde_ratio = ratio
	_distance_max = 0
	_distances = ChampFlux.calculer(plateau)
	var sources: Dictionary = ChampFlux.vers_chemin(plateau, _distances)
	_sources = sources
	var utiles: Dictionary = _cases_utiles(plateau)
	_utiles = utiles
	for objectifs: Dictionary in _objectifs:
		objectifs.clear()
	_branches.clear()
	for piste: Dictionary in _pistes:
		piste.clear()
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
			# Playtest 2 : une branche sans entrée au bout (cul-de-sac laissé par une extension) n'attire plus
			# de jouets, qui y attendaient « comme des plots » sans jamais croiser d'ennemi.
			if suivante > distance and utiles.has(voisin):
				branches.append(Vector2(voisin) * MAILLE)
			elif suivante >= 0 and suivante < distance and retour == case:
				retour = voisin
		_objectifs[ENNEMI][case] = Vector2(retour) * MAILLE
		if not utiles.has(case):
			_objectifs[ALLIE][case] = Vector2(retour) * MAILLE
		elif branches.size() == 1:
			_objectifs[ALLIE][case] = branches[0]
		elif branches.size() > 1:
			_branches[case] = branches


# Cases de chemin situées sur un trajet entrée → horloge (en remontant les distances décroissantes depuis
# chaque entrée). Les autres sont des culs-de-sac où aucun ennemi ne passe.
func _cases_utiles(plateau: Plateau) -> Dictionary:
	var utiles: Dictionary = {}
	var file: Array[Vector2i] = ChampFlux.entrees(plateau, _distances)
	for case: Vector2i in file:
		utiles[case] = true
	var tete: int = 0
	while tete < file.size():
		var case: Vector2i = file[tete]
		tete += 1
		for direction: Vector2i in ChampFlux.VOISINS:
			var voisin: Vector2i = case + direction
			if not utiles.has(voisin) and _distances.has(voisin) and _distances[voisin] == _distances[case] - 1:
				utiles[voisin] = true
				file.append(voisin)
	return utiles


## Ajoute une unité prête à frapper tant qu'il reste une place dans son camp.
## `origine` = case de l'atelier qui l'a produite (sert au plafond par bâtiment).
func ajouter(def: UniteDef, position: Vector2, origine: Vector2i = SANS_ORIGINE) -> bool:
	var nuee: Nuee = _camps[def.camp]
	if nuee.lieux.size() >= CAPACITE:
		return false
	nuee.origines.append(origine)
	nuee.effectifs[origine] = nuee.effectifs.get(origine, 0) + 1
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


## Frappe l'ennemi vivant le plus proche, puis ses voisins si le tir a une zone d'effet.
func blesser_zone(centre: Vector2, portee: float, degats: float, zone: float) -> bool:
	if portee < 0.0 or degats <= 0.0:
		return false
	var ennemis: Nuee = _camps[ENNEMI]
	var distance_min: float = portee * portee
	var cible: int = -1
	for i: int in ennemis.lieux.size():
		if ennemis.modeles[i].fouisseur:
			continue  # sous terre : les tourelles ne le voient pas
		var distance: float = centre.distance_squared_to(ennemis.lieux[i])
		if ennemis.vies[i] > 0.0 and distance <= distance_min:
			cible = i
			distance_min = distance
	if cible < 0:
		return false
	var impact: Vector2 = ennemis.lieux[cible]
	ennemis.vies[cible] -= ennemis.modeles[cible].degats_recus(degats, false, _bouclier(cible))
	ennemis.touches[cible] = 0.12
	if zone > 0.0:
		var rayon_carre: float = zone * zone
		for i: int in ennemis.lieux.size():
			if i != cible and ennemis.vies[i] > 0.0 and not ennemis.modeles[i].fouisseur \
					and impact.distance_squared_to(ennemis.lieux[i]) <= rayon_carre:
				ennemis.vies[i] -= ennemis.modeles[i].degats_recus(degats, false, _bouclier(i))
				ennemis.touches[i] = 0.12
	tir.emit(centre, impact)
	return true


func _bouclier(i: int) -> float:
	return _boucliers[i] if i < _boucliers.size() else 0.0


# Porte-boucliers : chaque ennemi proche reçoit l'aura la plus forte (pas de cumul, pour rester lisible).
func _calculer_boucliers() -> void:
	var ennemis: Nuee = _camps[ENNEMI]
	_boucliers.resize(ennemis.lieux.size())
	_boucliers.fill(0.0)
	for b: int in ennemis.lieux.size():
		var porteur: UniteDef = ennemis.modeles[b]
		if porteur.aura_armure <= 0.0:
			continue
		var rayon_carre: float = porteur.rayon_aura * porteur.rayon_aura
		for i: int in ennemis.lieux.size():
			if i != b and ennemis.lieux[b].distance_squared_to(ennemis.lieux[i]) <= rayon_carre:
				_boucliers[i] = maxf(_boucliers[i], porteur.aura_armure)


## Renvoie (PV restants, PV max) du premier boss vivant, ou Vector2.ZERO s'il n'y en a pas.
func pv_boss() -> Vector2:
	var ennemis: Nuee = _camps[ENNEMI]
	for i: int in ennemis.modeles.size():
		if ennemis.modeles[i].boss:
			return Vector2(maxf(0.0, ennemis.vies[i]), ennemis.modeles[i].pv)
	return Vector2.ZERO


## Renvoie l'effectif vivant du camp.
func nombre(camp: int) -> int:
	return _camps[camp].lieux.size()


## Renvoie le nombre de jouets vivants sortis de l'atelier posé sur `origine`.
func effectif(origine: Vector2i) -> int:
	return _camps[ALLIE].effectifs.get(origine, 0)


## Rappelle les jouets d'un atelier repris en pleine vague (sans signal de mort) : sinon l'atelier reposé ailleurs
## retrouverait tout son plafond, et une autre pièce posée à sa place hériterait de ses survivants (relecture T13a).
func rappeler(origine: Vector2i) -> void:
	var allies: Nuee = _camps[ALLIE]
	for i: int in range(allies.lieux.size() - 1, -1, -1):
		if allies.origines[i] == origine:
			allies._retirer(i)


## Retire d'un coup toutes les unités d'un camp, sans signal de mort (les jouets rentrent à l'atelier).
func vider(camp: int) -> void:
	_camps[camp]._vider()


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
	_calculer_boucliers()
	_attente_piste -= dt
	if _attente_piste <= 0.0:
		_attente_piste = RECALCUL_PISTE
		_tracer_pistes()
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
				_decider(camp, i, [] if camp == ENNEMI and nuee.modeles[i].volant else cibles, dt)

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
	var melee: bool = camp == ALLIE and modele.portee < PORTEE_DISTANCE
	var adversaires: PackedVector2Array = adverse.lieux
	for cellule: Cellule in cibles:
		if lieu.distance_squared_to(lieu.clamp(cellule.minimum, cellule.maximum)) > meilleur:
			continue
		for j: int in cellule.indices:
			if melee and adverse.modeles[j].volant:
				continue
			if camp == ALLIE and not melee and adverse.modeles[j].fouisseur:
				continue
			var d: float = lieu.distance_squared_to(adversaires[j])
			if d < meilleur or (d == meilleur and (cible < 0 or j < cible)):
				meilleur = d
				cible = j

	var recharge: float = nuee.recharges[i]
	# Un boss est frappé à son bord : sinon son grand rayon (séparation) tiendrait les jouets hors de portée.
	var allonge: float = modele.portee
	if cible >= 0 and adverse.modeles[cible].boss:
		allonge += adverse.modeles[cible].rayon
	if cible >= 0 and meilleur <= allonge * allonge:
		if modele.cadence > 0.0:
			var periode: float = 1.0 / modele.cadence
			# Compte aussi les frappes intermédiaires si un pas dépasse une période.
			if recharge < dt - 0.000001 or recharge <= 0.0:
				var coups: int = maxi(1, ceili((dt - recharge - 0.000001) / periode))
				var bonus: float = _bouclier(cible) if camp == ALLIE else 0.0
				adverse.vies[cible] -= adverse.modeles[cible].degats_recus(modele.degats, melee, bonus) * coups
				adverse.touches[cible] = 0.12
				if camp == ALLIE and modele.portee >= PORTEE_DISTANCE:
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
		destination = _objectif_flux(camp, lieu, nuee.choix[i], melee)
	if destination != lieu:
		nuee.suivants[i] = lieu.move_toward(destination, modele.vitesse * dt)
		nuee.angles[i] = (destination - lieu).angle()


# Playtest 2 (jouets « plots ») : chaque case de chemin connaît la case suivante vers l'ennemi le plus proche
# par la route (parcours en largeur depuis les cases occupées par des ennemis). Recalculé toutes les 0,2 s.
func _tracer_pistes() -> void:
	var ennemis: Nuee = _camps[ENNEMI]
	for k: int in 2:
		var piste: Dictionary = _pistes[k]
		piste.clear()
		var file: Array[Vector2i] = []
		for i: int in ennemis.lieux.size():
			if k == 0 and ennemis.modeles[i].volant:
				continue
			if k == 1 and ennemis.modeles[i].fouisseur:
				continue
			var case := Vector2i((ennemis.lieux[i] / MAILLE).round())
			if not _distances.has(case):
				case = _sources.get(case, SANS_ORIGINE)
			if case != SANS_ORIGINE and not piste.has(case):
				piste[case] = case
				file.append(case)
		var tete: int = 0
		while tete < file.size():
			var case: Vector2i = file[tete]
			tete += 1
			for direction: Vector2i in ChampFlux.VOISINS:
				var voisin: Vector2i = case + direction
				if not piste.has(voisin) and _distances.has(voisin):
					piste[voisin] = case
					file.append(voisin)


func _objectif_flux(camp: int, lieu: Vector2, choix: int, melee: bool = false) -> Vector2:
	var case := Vector2i((lieu / MAILLE).round())
	var limite: float = garde_ratio * _distance_max
	if camp == ALLIE and _distances.has(case):
		# Un ennemi frappable existe : on marche vers lui par la route, sans dépasser le poste de garde,
		# sauf pour revenir vers l'horloge (les ennemis qui ont dépassé un jouet isolé ne le laissent plus planté).
		var pas: Vector2i = _pistes[0 if melee else 1].get(case, case)
		if pas != case:
			var distance_pas: int = _distances.get(pas, -1)
			if distance_pas <= limite or distance_pas < _distances[case]:
				return Vector2(pas) * MAILLE
			# Pas interdit (il sortirait du poste) : on tient la position. Sinon la patrouille pouvait l'envoyer
			# sur l'autre branche d'une fourche, d'où la piste le ramenait : aller-retour sans fin (relecture T13a).
			return lieu
	# Au-delà du poste on s'arrête, sauf dans un cul-de-sac : on en ressort vers l'horloge (relecture T13a).
	if camp == ALLIE and _distances.get(case, -1) > limite and _utiles.has(case):
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
