class_name DecoupeTourelle extends RefCounted
## Sépare le maillage d'une tourelle en deux : un socle fixe et une tête qui pivote vers la cible (playtest 3).
##
## Pourquoi : les modèles (Hyper3D, kit Blender) sont d'un seul bloc. Faire tourner le bloc entier faisait pivoter le
## socle avec le fût (« tout le modèle tourne »). On découpe donc le maillage une fois, au chargement :
## - par hauteur (`seuil`, fraction de la hauteur) : tout triangle dont le centre est au-dessus va dans la tête ;
## - ou par morceaux (`morceaux` = vrai) : chaque morceau d'un seul tenant va dans la tête s'il monte plus haut que
##   le seuil (le fût et son affût), sinon il reste sur le socle (planches, tas de boulets).
## Les deux moitiés gardent les mêmes sommets et les mêmes matériaux ; seule la liste des triangles change.

## Résultat d'une découpe : les deux maillages et le pivot de la tête (centre de sa base, dans le repère du maillage).
class Decoupe:
	var socle: ArrayMesh
	var tete: ArrayMesh
	var pivot: Vector3
	## Bornes de la tête (repère du maillage).
	var mini: Vector3
	var maxi: Vector3


## Découpe `maillage` ; renvoie null s'il n'y a rien à séparer (tête ou socle vide).
static func decouper(maillage: Mesh, seuil: float, morceaux: bool) -> Decoupe:
	var surfaces: Array[Array] = _lire_surfaces(maillage)
	if surfaces.is_empty():
		return null
	var boite: AABB = maillage.get_aabb()
	var limite: float = boite.position.y + boite.size.y * seuil
	# Pour chaque triangle : va-t-il dans la tête ?
	var choix: Array[PackedByteArray] = []
	if morceaux:
		choix = _choisir_par_morceaux(surfaces, limite)
	else:
		for tableaux: Array in surfaces:
			var sommets: PackedVector3Array = tableaux[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = tableaux[Mesh.ARRAY_INDEX]
			var dans_tete := PackedByteArray()
			dans_tete.resize(indices.size() / 3)
			for t: int in dans_tete.size():
				var hauteur: float = (sommets[indices[t * 3]].y + sommets[indices[t * 3 + 1]].y + sommets[indices[t * 3 + 2]].y) / 3.0
				dans_tete[t] = 1 if hauteur > limite else 0
			choix.append(dans_tete)
	var resultat: Decoupe = _separer(maillage, surfaces, choix)
	if resultat == null:
		return null
	var mini: Vector3 = resultat.mini
	var maxi: Vector3 = resultat.maxi
	# Pivot : centre de la base de la tête (les sommets du premier cinquième de sa hauteur), au niveau de la coupe.
	var plancher: float = mini.y + (maxi.y - mini.y) * 0.2
	var somme := Vector3.ZERO
	var compte: int = 0
	for s: int in surfaces.size():
		var sommets: PackedVector3Array = surfaces[s][Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = surfaces[s][Mesh.ARRAY_INDEX]
		for t: int in choix[s].size():
			if choix[s][t] == 0:
				continue
			for k: int in 3:
				var sommet: Vector3 = sommets[indices[t * 3 + k]]
				if sommet.y <= plancher:
					somme += sommet
					compte += 1
	resultat.pivot = somme / compte if compte > 0 else (mini + maxi) / 2.0
	resultat.pivot.y = 0.0
	return resultat


## Extrait d'un modèle d'un seul bloc la pièce dont les triangles ont leur centre dans `zone` (fractions de l'AABB du
## maillage, de 0 à 1) : clé de remontoir, cloche (P3-43, vie ambiante). Pivot : centre de la pièce, ou milieu de son
## sommet si `pivot_haut` (une cloche se balance depuis son anse). Renvoie null sans géométrie lisible ou zone vide.
static func extraire(maillage: Mesh, zone: AABB, pivot_haut: bool = false, reference: AABB = AABB()) -> Decoupe:
	var surfaces: Array[Array] = _lire_surfaces(maillage)
	if surfaces.is_empty():
		return null
	# `reference` : boîte d'origine du modèle, pour enchaîner plusieurs extractions sur le même socle.
	var totale: AABB = reference if reference.has_volume() else maillage.get_aabb()
	var cadre := AABB(totale.position + zone.position * totale.size, zone.size * totale.size)
	var choix: Array[PackedByteArray] = []
	for tableaux: Array in surfaces:
		var sommets: PackedVector3Array = tableaux[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = tableaux[Mesh.ARRAY_INDEX]
		var dans_piece := PackedByteArray()
		dans_piece.resize(indices.size() / 3)
		for t: int in dans_piece.size():
			var centre: Vector3 = (sommets[indices[t * 3]] + sommets[indices[t * 3 + 1]] + sommets[indices[t * 3 + 2]]) / 3.0
			dans_piece[t] = 1 if cadre.has_point(centre) else 0
		choix.append(dans_piece)
	var resultat: Decoupe = _separer(maillage, surfaces, choix)
	if resultat == null:
		return null
	resultat.pivot = (resultat.mini + resultat.maxi) / 2.0
	if pivot_haut:
		resultat.pivot.y = resultat.maxi.y
	return resultat


# Tableaux de chaque surface, indices complétés ; vide en rendu factice (sans fenêtre), où la géométrie est illisible.
static func _lire_surfaces(maillage: Mesh) -> Array[Array]:
	var surfaces: Array[Array] = []
	if maillage == null:
		return surfaces
	for s: int in maillage.get_surface_count():
		var tableaux: Array = maillage.surface_get_arrays(s)
		var sommets: PackedVector3Array = tableaux[Mesh.ARRAY_VERTEX]
		if sommets.is_empty():
			return [] as Array[Array]
		if tableaux[Mesh.ARRAY_INDEX] == null or (tableaux[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty():
			var suite := PackedInt32Array()
			suite.resize(sommets.size())
			for i: int in sommets.size():
				suite[i] = i
			tableaux[Mesh.ARRAY_INDEX] = suite
		surfaces.append(tableaux)
	return surfaces


# Répartit les triangles entre socle (0) et tête (1) selon `choix` ; null si l'une des deux moitiés est vide.
static func _separer(maillage: Mesh, surfaces: Array[Array], choix: Array[PackedByteArray]) -> Decoupe:
	var resultat := Decoupe.new()
	resultat.socle = ArrayMesh.new()
	resultat.tete = ArrayMesh.new()
	var mini := Vector3(INF, INF, INF)
	var maxi := Vector3(-INF, -INF, -INF)
	for s: int in surfaces.size():
		var tableaux: Array = surfaces[s]
		var sommets: PackedVector3Array = tableaux[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = tableaux[Mesh.ARRAY_INDEX]
		var haut := PackedInt32Array()
		var bas := PackedInt32Array()
		for t: int in choix[s].size():
			for k: int in 3:
				var indice: int = indices[t * 3 + k]
				if choix[s][t] == 1:
					haut.append(indice)
					mini = mini.min(sommets[indice])
					maxi = maxi.max(sommets[indice])
				else:
					bas.append(indice)
		for moitie: Array in [[resultat.socle, bas], [resultat.tete, haut]]:
			if (moitie[1] as PackedInt32Array).is_empty():
				continue
			var copie: Array = tableaux.duplicate()
			copie[Mesh.ARRAY_INDEX] = moitie[1]
			var cible: ArrayMesh = moitie[0]
			cible.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, copie)
			cible.surface_set_material(cible.get_surface_count() - 1, maillage.surface_get_material(s))
	if resultat.socle.get_surface_count() == 0 or resultat.tete.get_surface_count() == 0:
		return null
	resultat.mini = mini
	resultat.maxi = maxi
	return resultat


## Renvoie une copie de `maillage` sans les morceaux posés au-dessus de `hauteur_min` dont le centre est à moins de
## `demi_largeur` de l'axe X (playtest 3 : dégage le tablier du Pont, sur lequel marchent les unités).
static func degager(maillage: Mesh, hauteur_min: float, demi_largeur: float) -> Mesh:
	var surfaces: Array[Array] = []
	for s: int in maillage.get_surface_count():
		var tableaux: Array = maillage.surface_get_arrays(s)
		if (tableaux[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty() or tableaux[Mesh.ARRAY_INDEX] == null:
			return maillage
		surfaces.append(tableaux)
	var numeros: Array[PackedInt32Array] = _numeroter_morceaux(surfaces)
	var bas: Dictionary[int, float] = {}
	var sommes: Dictionary[int, float] = {}
	var comptes: Dictionary[int, int] = {}
	for s: int in surfaces.size():
		var sommets: PackedVector3Array = surfaces[s][Mesh.ARRAY_VERTEX]
		for i: int in sommets.size():
			var morceau: int = numeros[s][i]
			bas[morceau] = minf(bas.get(morceau, INF), sommets[i].y)
			sommes[morceau] = sommes.get(morceau, 0.0) + sommets[i].z
			comptes[morceau] = comptes.get(morceau, 0) + 1
	var resultat := ArrayMesh.new()
	for s: int in surfaces.size():
		var indices: PackedInt32Array = surfaces[s][Mesh.ARRAY_INDEX]
		var gardes := PackedInt32Array()
		for t: int in indices.size() / 3:
			var morceau: int = numeros[s][indices[t * 3]]
			if bas[morceau] >= hauteur_min and absf(sommes[morceau] / comptes[morceau]) <= demi_largeur:
				continue
			for k: int in 3:
				gardes.append(indices[t * 3 + k])
		if gardes.is_empty():
			continue
		var copie: Array = surfaces[s].duplicate()
		copie[Mesh.ARRAY_INDEX] = gardes
		resultat.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, copie)
		resultat.surface_set_material(resultat.get_surface_count() - 1, maillage.surface_get_material(s))
	return resultat


# Numéro du morceau d'un seul tenant de chaque sommet (sommets soudés par position), surface par surface.
static func _numeroter_morceaux(surfaces: Array[Array]) -> Array[PackedInt32Array]:
	var numeros: Dictionary[Vector3i, int] = {}
	var parents := PackedInt32Array()
	var sommets_soudes: Array[PackedInt32Array] = []
	for tableaux: Array in surfaces:
		var sommets: PackedVector3Array = tableaux[Mesh.ARRAY_VERTEX]
		var soudes := PackedInt32Array()
		soudes.resize(sommets.size())
		for i: int in sommets.size():
			var cle := Vector3i((sommets[i] * 2000.0).round())
			if not numeros.has(cle):
				numeros[cle] = parents.size()
				parents.append(parents.size())
			soudes[i] = numeros[cle]
		sommets_soudes.append(soudes)
	for s: int in surfaces.size():
		var indices: PackedInt32Array = surfaces[s][Mesh.ARRAY_INDEX]
		var soudes: PackedInt32Array = sommets_soudes[s]
		for t: int in indices.size() / 3:
			var a: int = _racine(parents, soudes[indices[t * 3]])
			for k: int in [1, 2]:
				var b: int = _racine(parents, soudes[indices[t * 3 + k]])
				if a != b:
					parents[b] = a
	for soudes: PackedInt32Array in sommets_soudes:
		for i: int in soudes.size():
			soudes[i] = _racine(parents, soudes[i])
	return sommets_soudes


# Regroupe les triangles en morceaux d'un seul tenant (sommets soudés par position) et envoie dans la tête les
# morceaux qui dépassent `limite`.
static func _choisir_par_morceaux(surfaces: Array[Array], limite: float) -> Array[PackedByteArray]:
	var numeros: Array[PackedInt32Array] = _numeroter_morceaux(surfaces)
	var sommets_max: Dictionary[int, float] = {}
	for s: int in surfaces.size():
		var sommets: PackedVector3Array = surfaces[s][Mesh.ARRAY_VERTEX]
		for i: int in sommets.size():
			sommets_max[numeros[s][i]] = maxf(sommets_max.get(numeros[s][i], -INF), sommets[i].y)
	var choix: Array[PackedByteArray] = []
	for s: int in surfaces.size():
		var indices: PackedInt32Array = surfaces[s][Mesh.ARRAY_INDEX]
		var dans_tete := PackedByteArray()
		dans_tete.resize(indices.size() / 3)
		for t: int in dans_tete.size():
			dans_tete[t] = 1 if sommets_max[numeros[s][indices[t * 3]]] > limite else 0
		choix.append(dans_tete)
	return choix


static func _racine(parents: PackedInt32Array, i: int) -> int:
	while parents[i] != i:
		parents[i] = parents[parents[i]]
		i = parents[i]
	return i
