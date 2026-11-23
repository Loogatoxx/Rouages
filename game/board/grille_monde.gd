class_name GrilleMonde extends RefCounted
## Convertit les coordonnées entre les cases du plateau et le plan horizontal.

const TAILLE_CASE := 2.0


## Renvoie le centre de la case sur le plan du plateau.
static func vers_monde(c: Vector2i) -> Vector3:
	return Vector3(c.x * TAILLE_CASE, 0, c.y * TAILLE_CASE)


## Renvoie la case dont le centre est le plus proche du point.
static func vers_case(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x / TAILLE_CASE), roundi(p.z / TAILLE_CASE))
