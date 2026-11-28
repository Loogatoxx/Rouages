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
## Playtest 3 (« suivi strict des chemins ») : marge entre une unité et le bord d'herbe de la route.
const MARGE_ROUTE := 0.28
## Demi-largeur du tablier d'un Pont (les unités montent dessus : elles s'y serrent un peu plus).
const DEMI_TABLIER := 0.5
## Hauteur du tablier d'un Pont et longueur de la marche d'accès (mètres), lues par le visuel des nuées : les jouets
## sautent sur le pont juste avant sa culée, comme sur une marche.
const HAUTEUR_PONT := 0.6
const RAMPE_PONT := 0.3
## Pas d'échantillonnage (mètres) pour vérifier qu'une poursuite en ligne droite reste sur la route.
const PAS_VOIE := 0.5
## Postes de garde (playtest 3, « Tenir la ligne ») : une escouade ne s'éloigne pas de son poste de plus de
## `RAYON_GARDE` mètres pour attaquer, et chaque jouet y a sa place à `RAYON_RANG` mètres du centre au plus.
const RAYON_GARDE := 3.2
const RAYON_RANG := 0.75


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
	## Ralentissement (playtest 3) : secondes restantes et part de vitesse retirée (1 = étourdi, ne frappe plus).
	var ralentis := PackedFloat32Array()
	var freins := PackedFloat32Array()
	## Étourdissement (coup de carillon) : minuterie à part, que les ralentissements des tourelles ne prolongent pas.
	var etourdis := PackedFloat32Array()
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
		ralentis[i] = ralentis[fin]
		freins[i] = freins[fin]
		etourdis[i] = etourdis[fin]
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
		ralentis.resize(fin)
		freins.resize(fin)
		etourdis.resize(fin)
		choix.resize(fin)
		modeles.pop_back()
		origines.pop_back()

	func _vider() -> void:
		lieux.clear()
		angles.clear()
		vies.clear()
		touches.clear()
		recharges.clear()
		ralentis.clear()
		freins.clear()
		etourdis.clear()
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
# Playtest 3 : zone autorisée de chaque case de route (Rect2 en mètres) ; cases d'herbe libres → case suivante vers la
# route (les jouets contournent les bâtiments) ; cases occupées par une pièce ; ponts [centre, axe de la route].
var _couloirs: Dictionary[Vector2i, Rect2] = {}
var _libres: Dictionary[Vector2i, Vector2i] = {}
var _profondeurs_libres: Dictionary[Vector2i, int] = {}
var _occupees: Dictionary[Vector2i, bool] = {}
var _ponts: Array[PackedVector2Array] = []
# Postes de garde : atelier → case de route où son escouade se range ; et, pour chaque case de poste, la case
# suivante à prendre depuis n'importe quelle case de route (parcours en largeur depuis le poste).
var _postes: Dictionary[Vector2i, Vector2i] = {}
var _pistes_postes: Dictionary[Vector2i, Dictionary] = {}
var _passages: Dictionary[Vector2i, int] = {}
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
	_tracer_couloirs(plateau)


# Playtest 3 : les unités au sol ne quittent plus la route et ne traversent plus les bâtiments.
# - `_couloirs` : rectangle autorisé de chaque case de route (une marge du côté de l'herbe, rien du côté d'une autre
#   case de route) ; le tablier d'un Pont est plus étroit.
# - `_libres` : parcours en largeur depuis la route à travers l'herbe sans pièce ; un jouet né derrière les
#   engrenages rejoint la route de case libre en case libre, sans passer à travers un atelier.
func _tracer_couloirs(plateau: Plateau) -> void:
	_couloirs.clear()
	_libres.clear()
	_profondeurs_libres.clear()
	_occupees.clear()
	_ponts.clear()
	for case: Vector2i in plateau.coords_pieces():
		# Un Pont posé sur l'eau se traverse (relecture T14c) : ce n'est pas un obstacle.
		if not _distances.has(case) and not plateau.piece_de(case).sur_route:
			_occupees[case] = true
	# Décors et eau : les jouets les contournent comme des bâtiments (sauf l'eau enjambée par un Pont).
	for case: Vector2i in plateau.coords_decors():
		_occupees[case] = true
	for case: Vector2i in plateau.coords_sols():
		if plateau.sol_de(case) == Plateau.Sol.EAU and plateau.piece_de(case) == null:
			_occupees[case] = true
	var demi: float = MAILLE / 2.0
	var file: Array[Vector2i] = []
	for case: Vector2i in _distances:
		var centre: Vector2 = Vector2(case) * MAILLE
		var gauche: bool = _distances.has(case + Vector2i.LEFT)
		var droite: bool = _distances.has(case + Vector2i.RIGHT)
		var haut: bool = _distances.has(case + Vector2i.UP)
		var bas: bool = _distances.has(case + Vector2i.DOWN)
		var marge_x: float = MARGE_ROUTE
		var marge_y: float = MARGE_ROUTE
		var piece: Plateau.PieceDef = plateau.piece_de(case)
		if piece != null and piece.sur_route:
			# Le tablier suit la route : axe X si la route continue à gauche ou à droite, sinon axe Y.
			var axe: Vector2 = Vector2.RIGHT if (gauche or droite) and not (haut or bas) else Vector2.DOWN
			if axe == Vector2.RIGHT:
				marge_y = demi - DEMI_TABLIER
			else:
				marge_x = demi - DEMI_TABLIER
			_ponts.append(PackedVector2Array([centre, axe]))
		var x0: float = centre.x - demi + (0.0 if gauche else marge_x)
		var x1: float = centre.x + demi - (0.0 if droite else marge_x)
		var y0: float = centre.y - demi + (0.0 if haut else marge_y)
		var y1: float = centre.y + demi - (0.0 if bas else marge_y)
		_couloirs[case] = Rect2(x0, y0, x1 - x0, y1 - y0)
		_profondeurs_libres[case] = 0
		file.append(case)
	var tete: int = 0
	while tete < file.size():
		var case: Vector2i = file[tete]
		tete += 1
		for direction: Vector2i in ChampFlux.VOISINS:
			var voisin: Vector2i = case + direction
			if _profondeurs_libres.has(voisin) or _occupees.has(voisin) or not plateau.a_sol(voisin):
				continue
			_profondeurs_libres[voisin] = _profondeurs_libres[case] + 1
			_libres[voisin] = case
			_objectifs[ALLIE][voisin] = Vector2(case) * MAILLE
			file.append(voisin)
	_tracer_postes(plateau)


# Playtest 3 (pilier 2) : chaque atelier a un poste de garde sur la route — la case choisie par le joueur
# (`Plateau.poste_de`), sinon la case de route la plus proche de sa sortie. Ses jouets s'y rangent et y tiennent
# la ligne : le combat a lieu là où le joueur a construit, devant ses tourelles, plus au bord du plateau.
func _tracer_postes(plateau: Plateau) -> void:
	_postes.clear()
	_pistes_postes.clear()
	_compter_passages(plateau)
	for case: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(case).type != Plateau.PieceDef.Type.ATELIER:
			continue
		var route: Vector2i = plateau.poste_de(case)
		if not _couloirs.has(route) or _distances.get(route, 0) <= 0:
			route = _route_proche(case)
		if route == SANS_ORIGINE:
			continue
		_postes[case] = route
		if _pistes_postes.has(route):
			continue
		var piste: Dictionary[Vector2i, Vector2i] = {route: route}
		var file: Array[Vector2i] = [route]
		var tete: int = 0
		while tete < file.size():
			var courante: Vector2i = file[tete]
			tete += 1
			for direction: Vector2i in ChampFlux.VOISINS:
				var voisin: Vector2i = courante + direction
				if not piste.has(voisin) and _distances.has(voisin):
					piste[voisin] = courante
					file.append(voisin)
		_pistes_postes[route] = piste


# Nombre d'entrées dont le plus court trajet vers l'horloge passe par chaque case de route.
func _compter_passages(plateau: Plateau) -> void:
	_passages.clear()
	for entree: Vector2i in ChampFlux.entrees(plateau, _distances):
		var case: Vector2i = entree
		var garde_fou: int = 0
		while _distances.get(case, 0) > 0 and garde_fou < 400:
			_passages[case] = _passages.get(case, 0) + 1
			var suivante: Vector2i = case
			for direction: Vector2i in ChampFlux.VOISINS:
				if _distances.get(case + direction, 1 << 30) < _distances[suivante]:
					suivante = case + direction
			if suivante == case:
				break
			case = suivante
			garde_fou += 1


## Poste de garde par défaut d'un atelier posé sur `case` : parmi les cases de route voisines, celle où passent le
## plus d'entrées (tenir un tronc commun vaut mieux qu'une seule branche), puis la plus proche de l'horloge ; sinon
## la route la plus proche de sa sortie en suivant les cases libres. Jamais la case de l'horloge.
func _route_proche(case: Vector2i) -> Vector2i:
	var meilleure: Vector2i = SANS_ORIGINE
	var profondeur_min: int = 1 << 30
	for direction: Vector2i in ChampFlux.VOISINS:
		var voisin: Vector2i = case + direction
		var profondeur: int = _profondeurs_libres.get(voisin, -1)
		if profondeur < 0 or profondeur > profondeur_min or _distances.get(voisin, 1) == 0:
			continue
		if profondeur == profondeur_min and meilleure != SANS_ORIGINE and profondeur == 0:
			# Deux routes voisines : la plus passante, puis la plus proche de l'horloge.
			var gagne: bool = _passages.get(voisin, 0) > _passages.get(meilleure, 0) or (
					_passages.get(voisin, 0) == _passages.get(meilleure, 0) and _distances[voisin] < _distances[meilleure])
			if not gagne:
				continue
		elif profondeur == profondeur_min:
			continue
		profondeur_min = profondeur
		meilleure = voisin
	var garde_fou: int = 0
	while meilleure != SANS_ORIGINE and _libres.has(meilleure) and garde_fou < 200:
		meilleure = _libres[meilleure]
		garde_fou += 1
	if meilleure != SANS_ORIGINE and _distances.get(meilleure, 1) == 0:
		return SANS_ORIGINE  # la seule route voisine est la case de l'horloge
	return meilleure


## Nombre d'entrées dont le trajet passe par cette case de route (0 hors des trajets) : pour l'aide au placement.
func passage(case: Vector2i) -> int:
	return _passages.get(case, 0)


## Poste de garde de l'atelier `origine`, en mètres (`Vector2.INF` s'il n'en a pas) : pour le visuel (drapeau).
func poste(origine: Vector2i) -> Vector2:
	return Vector2(_postes[origine]) * MAILLE if _postes.has(origine) else Vector2.INF


# Place d'un jouet dans son escouade : un point fixe autour du centre du poste, tiré de son numéro de hasard
# (chacun le sien : l'escouade se range au lieu de se marcher dessus). Hors du poste : la case suivante par la route.
func _vers_poste(lieu: Vector2, poste_case: Vector2i, choix: int) -> Vector2:
	var case := Vector2i((lieu / MAILLE).round())
	if case == poste_case:
		var alea: int = choix & 0x7FFFFFFF
		var place: Vector2 = Vector2(poste_case) * MAILLE + Vector2.from_angle((alea % 628) / 100.0) \
				* (RAYON_RANG * (0.25 + 0.75 * ((alea / 628) % 100) / 100.0))
		return lieu if lieu.distance_squared_to(place) <= 0.04 else place
	var piste: Dictionary = _pistes_postes.get(poste_case, {})
	if piste.has(case):
		return Vector2(piste[case]) * MAILLE
	return _objectifs[ALLIE].get(case, Vector2(poste_case) * MAILLE)


## Point de sortie des jouets d'un atelier (playtest 3) : sur la route s'il la borde, sinon du côté de la case libre
## qui mène le plus vite à la route (jamais à travers un engrenage ou un autre bâtiment). `Vector2.INF` si l'atelier
## est enfermé : l'appelant garde alors son ancien point de sortie.
func sortie_atelier(case: Vector2i) -> Vector2:
	var meilleure: Vector2i = Vector2i.ZERO
	var profondeur_min: int = 1 << 30
	for direction: Vector2i in ChampFlux.VOISINS:
		var profondeur: int = _profondeurs_libres.get(case + direction, -1)
		if profondeur >= 0 and profondeur < profondeur_min:
			profondeur_min = profondeur
			meilleure = direction
	if meilleure == Vector2i.ZERO:
		return Vector2.INF
	# Sur la route : au bord de l'atelier. Dans l'herbe : un peu à l'intérieur de la case libre, pour que le jouet
	# s'y trouve dès sa naissance.
	var recul: float = MAILLE / 2.0 + (MARGE_ROUTE if profondeur_min == 0 else 0.4)
	return Vector2(case) * MAILLE + Vector2(meilleure) * recul


## Hauteur du sol sous une unité (playtest 3) : 0 partout, sauf sur le tablier d'un Pont et ses deux rampes.
## Le visuel des nuées s'en sert pour faire monter les unités sur le pont au lieu de le traverser.
func relief(lieu: Vector2) -> float:
	var hauteur: float = 0.0
	for pont: PackedVector2Array in _ponts:
		var ecart: Vector2 = lieu - pont[0]
		var long: float = absf(ecart.dot(pont[1]))
		var large: float = absf(ecart.dot(pont[1].orthogonal()))
		if large > MAILLE / 2.0 or long >= MAILLE / 2.0 + RAMPE_PONT:
			continue
		hauteur = maxf(hauteur, HAUTEUR_PONT * minf(1.0, (MAILLE / 2.0 + RAMPE_PONT - long) / RAMPE_PONT))
	return hauteur


## Vrai une fois la simulation configurée sur un plateau (les tests de combat pur n'en ont pas).
func a_un_plateau() -> bool:
	return not _distances.is_empty()


## Indique si le plateau porte un Pont (évite de calculer le relief pour rien).
func a_du_relief() -> bool:
	return not _ponts.is_empty()


# Vrai si le segment a → b reste sur des cases de route : sinon une poursuite en ligne droite couperait par l'herbe.
func _voie_libre(a: Vector2, b: Vector2) -> bool:
	if _distances.is_empty():
		return true  # pas de plateau (tests de combat) : rien à couper
	var longueur: float = a.distance_to(b)
	var pas: int = ceili(longueur / PAS_VOIE)
	for k: int in range(0, pas + 1):
		var point: Vector2 = a.lerp(b, float(k) / maxf(1.0, float(pas)))
		if not _distances.has(Vector2i((point / MAILLE).round())):
			return false
	return true


# Garde chaque unité au sol dans son couloir (appelé après la séparation, qui pousse les unités de côté).
# Une unité sur la route n'entre que dans une case de route ; une unité dans l'herbe n'entre jamais dans une case
# occupée par un bâtiment.
func _contenir(nuee: Nuee) -> void:
	if _couloirs.is_empty():
		return
	var demi: float = MAILLE / 2.0 - 0.02
	for i: int in nuee.suivants.size():
		if nuee.modeles[i].volant:
			continue
		var lieu: Vector2 = nuee.suivants[i]
		var case := Vector2i((lieu / MAILLE).round())
		if _couloirs.has(case):
			var couloir: Rect2 = _couloirs[case]
			nuee.suivants[i] = lieu.clamp(couloir.position, couloir.end)
			continue
		var avant := Vector2i((nuee.lieux[i] / MAILLE).round())
		if _couloirs.has(avant):
			var couloir: Rect2 = _couloirs[avant]
			nuee.suivants[i] = lieu.clamp(couloir.position, couloir.end)
		elif _occupees.has(case) and not _occupees.has(avant):
			var centre: Vector2 = Vector2(avant) * MAILLE
			nuee.suivants[i] = lieu.clamp(centre - Vector2(demi, demi), centre + Vector2(demi, demi))


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
	nuee.ralentis.append(0.0)
	nuee.freins.append(0.0)
	nuee.etourdis.append(0.0)
	nuee.choix.append(randi() if def.camp == ALLIE else 0)
	nuee.modeles.append(def)
	nuee.rayon_max = maxf(nuee.rayon_max, def.rayon)
	nuee.portee_max = maxf(nuee.portee_max, def.portee)
	return true


## Frappe l'ennemi vivant le plus proche, puis ses voisins si le tir a une zone d'effet.
## `frein` (0 à 1) et `duree` : ralentissement appliqué aux ennemis touchés (carillon, playtest 3).
func blesser_zone(centre: Vector2, portee: float, degats: float, zone: float, frein: float = 0.0, duree: float = 0.0) -> bool:
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
	_freiner(ennemis, cible, frein, duree)
	if zone > 0.0:
		var rayon_carre: float = zone * zone
		for i: int in ennemis.lieux.size():
			if i != cible and ennemis.vies[i] > 0.0 and not ennemis.modeles[i].fouisseur \
					and impact.distance_squared_to(ennemis.lieux[i]) <= rayon_carre:
				ennemis.vies[i] -= ennemis.modeles[i].degats_recus(degats, false, _bouclier(i))
				ennemis.touches[i] = 0.12
				_freiner(ennemis, i, frein, duree)
	tir.emit(centre, impact)
	return true


# Ralentit un ennemi : on garde le plus fort des freins et la plus longue des durées. Un boss n'en subit que la moitié.
func _freiner(ennemis: Nuee, i: int, frein: float, duree: float) -> void:
	if frein <= 0.0 or duree <= 0.0:
		return
	if ennemis.modeles[i].boss:
		frein *= 0.5
		duree *= 0.5
	# Étourdissement (frein plein) : minuterie séparée. Relecture T14c : sinon un carillon voisin, qui ralentit toutes
	# les 1,25 s, prolongeait sans fin le « frein maximal » laissé par le coup du joueur.
	if frein >= 0.99:
		ennemis.etourdis[i] = maxf(ennemis.etourdis[i], duree)
		return
	if ennemis.ralentis[i] <= 0.0:
		ennemis.freins[i] = frein
	else:
		ennemis.freins[i] = maxf(ennemis.freins[i], frein)
	ennemis.ralentis[i] = maxf(ennemis.ralentis[i], duree)


## Blesse toutes les unités au sol (des deux camps) qui se trouvent sur la case `case` : le train du Rail.
## Les jouets ne sont pas épargnés : c'est au joueur de garder ses fanions hors de la voie.
func frapper_case(case: Vector2i, degats: float) -> void:
	for nuee: Nuee in _camps:
		for i: int in nuee.lieux.size():
			if nuee.modeles[i].volant or nuee.modeles[i].fouisseur:
				continue
			if Vector2i((nuee.lieux[i] / MAILLE).round()) == case:
				nuee.vies[i] -= degats
				nuee.touches[i] = 0.12


## Ralentit (ou étourdit, `frein` = 1) tous les ennemis à moins de `rayon` mètres de `centre` : le coup de carillon
## du joueur. Renvoie le nombre d'ennemis touchés. Volants et fouisseurs compris : c'est le son de l'Horloge.
func ralentir_zone(centre: Vector2, rayon: float, frein: float, duree: float) -> int:
	var ennemis: Nuee = _camps[ENNEMI]
	var touches_zone: int = 0
	for i: int in ennemis.lieux.size():
		if ennemis.vies[i] > 0.0 and centre.distance_squared_to(ennemis.lieux[i]) <= rayon * rayon:
			_freiner(ennemis, i, frein, duree)
			touches_zone += 1
	return touches_zone


## Secondes de ralentissement restantes pour chaque unité du camp (pour teinter les ennemis ralentis ou étourdis).
func ralentis(camp: int) -> PackedFloat32Array:
	var nuee: Nuee = _camps[camp]
	var resultat: PackedFloat32Array = nuee.ralentis.duplicate()
	for i: int in resultat.size():
		resultat[i] = maxf(resultat[i], nuee.etourdis[i])
	return resultat


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
		# Un étourdi ne bouge pas, même poussé par ses voisins (relecture T14c).
		for i: int in nuee.etourdis.size():
			if nuee.etourdis[i] > 0.0:
				nuee.suivants[i] = nuee.lieux[i]
		_contenir(nuee)
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
		var modele: UniteDef = ennemis.modeles[i]
		var degats: float = modele.degats_horloge if modele.degats_horloge > 0.0 else modele.degats
		ennemis._retirer(i)
		ennemi_arrive.emit(degats)


func _indexer(nuee: Nuee, dt: float) -> void:
	nuee.grille.clear()
	nuee.influence.clear()
	nuee.suivants = nuee.lieux.duplicate()
	for i: int in nuee.lieux.size():
		if nuee.touches[i] > 0.0:
			nuee.touches[i] = maxf(0.0, nuee.touches[i] - dt)
		if nuee.ralentis[i] > 0.0:
			nuee.ralentis[i] = maxf(0.0, nuee.ralentis[i] - dt)
		if nuee.etourdis[i] > 0.0:
			nuee.etourdis[i] = maxf(0.0, nuee.etourdis[i] - dt)
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
	# Ralentissement (carillon) : l'unité avance moins vite ; étourdie (frein ≥ 1), elle ne bouge ni ne frappe.
	var allure: float = 1.0
	if nuee.etourdis[i] > 0.0:
		nuee.recharges[i] = maxf(0.0, recharge - dt)
		return
	if nuee.ralentis[i] > 0.0:
		allure = maxf(0.0, 1.0 - nuee.freins[i])
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
	# Playtest 3 (postes de garde) : un jouet sorti d'un atelier tient son poste. Il ne va au contact que d'un
	# ennemi entré dans le rayon de garde du poste, en ligne droite sur la route ; les tireurs ne quittent pas leur
	# place. Sinon il rejoint (ou garde) sa place dans l'escouade.
	var poste_case: Vector2i = _postes.get(nuee.origines[i], SANS_ORIGINE) if camp == ALLIE else SANS_ORIGINE
	if poste_case != SANS_ORIGINE:
		var centre: Vector2 = Vector2(poste_case) * MAILLE
		var a_rejoindre: int = _cible_de_garde(lieu, centre, cibles, adverse) if melee else -1
		if a_rejoindre >= 0:
			destination = adversaires[a_rejoindre]
		else:
			destination = _vers_poste(lieu, poste_case, nuee.choix[i])
		if destination != lieu:
			nuee.suivants[i] = lieu.move_toward(destination, modele.vitesse * dt)
			nuee.angles[i] = (destination - lieu).angle()
		return
	# Playtest 3 : on ne poursuit en ligne droite que si le trajet reste sur la route ; sinon on suit la route
	# (plus de raccourci par l'herbe entre deux boucles du chemin).
	var en_vue: bool = cible >= 0 and meilleur < POURSUITE * POURSUITE
	if en_vue and _voie_libre(lieu, adverse.lieux[cible]):
		destination = adverse.lieux[cible]
	else:
		# Ennemi en vue mais derrière un virage : on le rejoint par la route, même au-delà du poste de garde
		# (comme le faisait la poursuite en ligne droite). Sans cela, la garde tenait les jouets immobiles à un
		# mètre d'un ennemi caché par le coin (banc : la vague 6 passait).
		destination = _objectif_flux(camp, lieu, nuee.choix[i], melee, en_vue)
	if destination != lieu:
		nuee.suivants[i] = lieu.move_toward(destination, modele.vitesse * allure * dt)
		nuee.angles[i] = (destination - lieu).angle()


# Ennemi au sol le plus proche qu'un garde peut aller frapper : entré dans le rayon de garde de son poste ET
# joignable en ligne droite sur la route (relecture T14b : l'ennemi le plus proche, caché par un virage, faisait
# rentrer le garde au poste alors qu'un autre ennemi était à sa portée). -1 s'il n'y en a pas.
func _cible_de_garde(lieu: Vector2, centre: Vector2, cibles: Array, adverse: Nuee) -> int:
	var meilleur: float = POURSUITE * POURSUITE
	var cible: int = -1
	for cellule: Cellule in cibles:
		if lieu.distance_squared_to(lieu.clamp(cellule.minimum, cellule.maximum)) > meilleur:
			continue
		for j: int in cellule.indices:
			if adverse.modeles[j].volant or adverse.vies[j] <= 0.0:
				continue
			var d: float = lieu.distance_squared_to(adverse.lieux[j])
			if d >= meilleur or adverse.lieux[j].distance_squared_to(centre) > RAYON_GARDE * RAYON_GARDE:
				continue
			if _voie_libre(lieu, adverse.lieux[j]):
				meilleur = d
				cible = j
	return cible


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


func _objectif_flux(camp: int, lieu: Vector2, choix: int, melee: bool = false, en_poursuite: bool = false) -> Vector2:
	var case := Vector2i((lieu / MAILLE).round())
	var limite: float = garde_ratio * _distance_max
	if camp == ALLIE and _distances.has(case):
		# Un ennemi frappable existe : on marche vers lui par la route, sans dépasser le poste de garde,
		# sauf pour revenir vers l'horloge (les ennemis qui ont dépassé un jouet isolé ne le laissent plus planté).
		var pas: Vector2i = _pistes[0 if melee else 1].get(case, case)
		if pas != case:
			var distance_pas: int = _distances.get(pas, -1)
			if en_poursuite or distance_pas <= limite or distance_pas < _distances[case]:
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
