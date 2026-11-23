extends RefCounted
## Vérifie le pas de la grille et les frontières entre cases.

const GrilleMonde = preload("res://game/board/grille_monde.gd")


## Vérifie les centres, y compris dans les quadrants négatifs.
func test_aller_retour() -> String:
	for c: Vector2i in [Vector2i.ZERO, Vector2i(-4, 3), Vector2i(2, -1)]:
		var p: Vector3 = GrilleMonde.vers_monde(c)
		if p != Vector3(2 * c.x, 0, 2 * c.y) or GrilleMonde.vers_case(p) != c:
			return "Centre incorrect pour %s" % c
	return ""


## Vérifie les deux côtés d'un bord, indépendamment de la hauteur.
func test_arrondi_bord() -> String:
	if GrilleMonde.vers_case(Vector3(0.99, 7, -1.01)) != Vector2i(0, -1):
		return "Arrondi incorrect avant le bord"
	if GrilleMonde.vers_case(Vector3(1.01, -3, -0.99)) != Vector2i(1, 0):
		return "Arrondi incorrect après le bord"
	return ""
