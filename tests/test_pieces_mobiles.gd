extends RefCounted
## Vie ambiante (P3-43) : détacher une pièce mobile (clé de remontoir, cloche) d'un modèle d'un seul bloc.
##
## En rendu factice (tests sans fenêtre), un maillage importé n'a pas de géométrie lisible : on fabrique donc un petit
## maillage en mémoire (deux cubes empilés). Si même lui est illisible, le test vérifie au moins le repli : rien
## n'est détaché, le modèle reste entier.

const DecoupeTourelle = preload("res://game/board/decoupe_tourelle.gd")
const PlateauVisuel = preload("res://game/board/plateau_visuel.gd")


# Deux cubes : un socle de 1 m (y 0 à 1) et une « clé » de 0,4 m posée dessus (y 1 à 1,4), centrés en x et z.
func _deux_cubes() -> ArrayMesh:
	var sommets := PackedVector3Array()
	var indices := PackedInt32Array()
	for cube: Array in [[Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1)], [Vector3(-0.2, 1.0, -0.2), Vector3(0.4, 0.4, 0.4)]]:
		var base: int = sommets.size()
		var o: Vector3 = cube[0]
		var t: Vector3 = cube[1]
		for k: int in 8:
			sommets.append(o + Vector3(t.x * (k & 1), t.y * ((k >> 1) & 1), t.z * ((k >> 2) & 1)))
		for face: Array in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]:
			indices.append_array(PackedInt32Array([base + face[0], base + face[1], base + face[2],
					base + face[0], base + face[2], base + face[3]]))
	var tableaux: Array = []
	tableaux.resize(Mesh.ARRAY_MAX)
	tableaux[Mesh.ARRAY_VERTEX] = sommets
	tableaux[Mesh.ARRAY_INDEX] = indices
	var maillage := ArrayMesh.new()
	maillage.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tableaux)
	return maillage


## La zone du haut ne prend que la clé ; son pivot est en son centre (ou en haut pour une cloche).
func test_extraire_la_cle_du_haut() -> String:
	var maillage: ArrayMesh = _deux_cubes()
	var zone := AABB(Vector3(0, 0.75, 0), Vector3(1, 0.25, 1))
	var decoupe: DecoupeTourelle.Decoupe = DecoupeTourelle.extraire(maillage, zone)
	if (maillage.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
		return "" if decoupe == null else "rendu factice : rien ne doit être détaché"
	if decoupe == null:
		return "la clé aurait dû être détachée"
	var tete: int = (decoupe.tete.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	var socle: int = (decoupe.socle.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	# La face du dessous de la clé (y = 1,0, cachée contre le socle) reste au socle : le tri se fait par le centre de
	# chaque triangle. La clé emporte ses 4 côtés et son dessus (10 triangles), le socle garde le reste (14).
	if tete != 10 or socle != 14:
		return "attendu 10 triangles pour la clé et 14 pour le socle, obtenu %d et %d" % [tete, socle]
	if not decoupe.pivot.is_equal_approx(Vector3(0, 1.2, 0)):
		return "pivot attendu au centre de la clé (0, 1,2, 0), obtenu %s" % decoupe.pivot
	var cloche: DecoupeTourelle.Decoupe = DecoupeTourelle.extraire(maillage, zone, true)
	if not is_equal_approx(cloche.pivot.y, 1.4):
		return "pivot « en haut » attendu à 1,4 m, obtenu %.2f" % cloche.pivot.y
	return ""


## Une zone vide ne détache rien (null) : le modèle reste entier et immobile.
func test_zone_vide_ne_detache_rien() -> String:
	var decoupe: DecoupeTourelle.Decoupe = DecoupeTourelle.extraire(_deux_cubes(), AABB(Vector3(0.9, 0.9, 0.9), Vector3(0.05, 0.05, 0.05)))
	return "" if decoupe == null else "une zone sans triangle ne doit rien détacher"


## Les réglages des pièces mobiles restent cohérents : zones dans le cadre [0, 1], axe unitaire, mouvement connu.
func test_reglages_des_pieces_mobiles() -> String:
	for nom: StringName in PlateauVisuel.PIECES_MOBILES:
		for reglage: Array in PlateauVisuel.PIECES_MOBILES[nom]:
			var zone: AABB = reglage[1]
			if zone.position.x < 0 or zone.position.y < 0 or zone.position.z < 0 or zone.end.x > 1.001 \
					or zone.end.y > 1.001 or zone.end.z > 1.001 or not zone.has_volume():
				return "%s/%s : zone hors du cadre [0, 1]" % [nom, reglage[0]]
			if not (reglage[3] as Vector3).is_normalized():
				return "%s/%s : axe non unitaire" % [nom, reglage[0]]
			if reglage[4] not in [&"tic", &"balance"]:
				return "%s/%s : mouvement inconnu %s" % [nom, reglage[0], reglage[4]]
	return ""
