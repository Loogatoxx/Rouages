class_name RouteLongue extends RefCounted
## Runs plus longues et cartes qui évoluent en cours de partie (playtest 1, PT-60). Logique pure, sans autoload.
##
## Mode « Longue route » : 15 vagues (les 5 dernières extrapolées depuis la 10e) ; après certaines vagues, un tiroir de
## l'établi s'ouvre : un sentier se pose tout seul au bord du plateau (nouvelle entrée), la carte change sous les yeux
## du joueur. Pourquoi : « la carte paraît petite et évolue peu sur 10 vagues ».

const Plateau = preload("res://game/board/plateau.gd")
const Extension = preload("res://game/board/extension.gd")
const ExtensionDef = preload("res://game/board/extension_def.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")


## Complète la liste jusqu'à `total` vagues : chaque vague ajoutée reprend la dernière avec 12 % d'ennemis et 10 % de PV
## en plus (et un intervalle un peu plus court), pour une montée régulière.
static func prolonger(vagues: Array[VagueDef], total: int) -> Array[VagueDef]:
	var resultat: Array[VagueDef] = vagues.duplicate()
	while resultat.size() < total and not resultat.is_empty():
		var precedente: VagueDef = resultat[-1]
		var suivante: VagueDef = precedente.duplicate() as VagueDef
		suivante.nombre = roundi(precedente.nombre * 1.12)
		suivante.multiplicateur_pv = snappedf(precedente.multiplicateur_pv * 1.1, 0.01)
		suivante.intervalle = maxf(0.15, precedente.intervalle * 0.96)
		suivante.nombre_renforts = roundi(precedente.nombre_renforts * 1.15)
		if "nombre_volants" in suivante:
			suivante.nombre_volants = roundi(precedente.get("nombre_volants") * 1.15)
		# Le boss ne revient qu'à la toute dernière vague.
		suivante.boss = vagues[-1].boss if resultat.size() == total - 1 else null
		resultat.append(suivante)
	return resultat


## Cherche une pose valide (centre, rotation) pour une extension au bord du plateau, tirée au hasard parmi toutes les poses
## possibles (raccord compris) ; tableau vide si aucune.
static func choisir_pose(plateau: Plateau, def: ExtensionDef, rng: RandomNumberGenerator) -> Array:
	var poses: Array = []
	var vus: Dictionary = {}
	for sol: Vector2i in plateau.coords_sols():
		for x: int in range(-2, 3):
			for y: int in range(-2, 3):
				var centre: Vector2i = sol + Vector2i(x, y)
				if vus.has(centre) or plateau.a_sol(centre):
					continue
				vus[centre] = true
				for tour: int in 4:
					if Extension.est_valide(plateau, def, centre, tour):
						poses.append([centre, tour])
	if poses.is_empty():
		return []
	poses.sort()
	return poses[rng.randi_range(0, poses.size() - 1)]


## Ouvre un tiroir : pose l'extension à une place tirée au hasard ; renvoie la pose utilisée ou [] si impossible.
static func ouvrir_tiroir(plateau: Plateau, def: ExtensionDef, rng: RandomNumberGenerator) -> Array:
	var pose: Array = choisir_pose(plateau, def, rng)
	if pose.is_empty() or not Extension.appliquer(plateau, def, pose[0], pose[1]):
		return []
	return pose
