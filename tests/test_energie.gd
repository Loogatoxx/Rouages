extends RefCounted

const Energie = preload("res://game/board/energie.gd")
const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const HORLOGE: PieceDef = preload("res://data/tuiles/horloge.tres")
const DROIT: PieceDef = preload("res://data/tuiles/engrenage_droit.tres")
const CROIX: PieceDef = preload("res://data/tuiles/engrenage_croix.tres")
const ATELIER: PieceDef = preload("res://data/tuiles/atelier_soldats.tres")


func _placer(plateau: Plateau, coord: Vector2i, piece: PieceDef, rotation: int = 0) -> void:
	plateau.ajouter_sol(coord, Plateau.Sol.HERBE)
	plateau.poser(coord, piece, rotation)


func test_chaine_et_port_unilateral() -> String:
	var plateau: Plateau = Plateau.new()
	_placer(plateau, Vector2i.ZERO, HORLOGE)
	_placer(plateau, Vector2i.RIGHT, DROIT)
	_placer(plateau, Vector2i(2, 0), ATELIER, 1)
	if Energie.calculer(plateau) != {Vector2i.ZERO: 0}:
		return "le port est de l’horloge ne suffit pas avec un engrenage nord-sud"
	plateau.tourner(Vector2i.RIGHT)
	var attendu: Dictionary = {Vector2i.ZERO: 0, Vector2i.RIGHT: 1, Vector2i(2, 0): 2}
	return "" if Energie.calculer(plateau) == attendu else "profondeurs incorrectes après rotation"


func test_atelier_ne_transmet_pas() -> String:
	# Deux ports opposés pour que seule la propriété transmet interrompe la chaîne.
	var atelier: PieceDef = ATELIER.duplicate() as PieceDef
	atelier.ports = 10
	var plateau: Plateau = Plateau.new()
	_placer(plateau, Vector2i.ZERO, HORLOGE)
	_placer(plateau, Vector2i.RIGHT, atelier)
	_placer(plateau, Vector2i(2, 0), CROIX)
	var attendu: Dictionary = {Vector2i.ZERO: 0, Vector2i.RIGHT: 1}
	return "" if Energie.calculer(plateau) == attendu else "propagation incorrecte à travers l’atelier"


func test_boucle_et_sources_multiples() -> String:
	var plateau: Plateau = Plateau.new()
	for x: int in range(2):
		for y: int in range(2):
			_placer(plateau, Vector2i(x, y), CROIX)
	if not Energie.calculer(plateau).is_empty():
		return "boucle alimentée sans horloge"
	_placer(plateau, Vector2i.LEFT, HORLOGE)
	var attendu: Dictionary = {
		Vector2i.LEFT: 0, Vector2i.ZERO: 1, Vector2i.RIGHT: 2, Vector2i.DOWN: 2, Vector2i.ONE: 3
	}
	if Energie.calculer(plateau) != attendu:
		return "distances incorrectes dans la boucle"
	_placer(plateau, Vector2i(2, 1), HORLOGE)
	attendu[Vector2i(2, 1)] = 0
	attendu[Vector2i.ONE] = 1
	return "" if Energie.calculer(plateau) == attendu else "distance à la seconde horloge incorrecte"


func test_grille_30_par_30() -> String:
	var plateau: Plateau = Plateau.new()
	for x: int in range(30):
		for y: int in range(30):
			_placer(plateau, Vector2i(x, y), CROIX)
	_placer(plateau, Vector2i.LEFT, HORLOGE)
	var debut: int = Time.get_ticks_usec()
	var resultat: Dictionary = Energie.calculer(plateau)
	var duree: int = Time.get_ticks_usec() - debut
	if resultat.size() != 901 or resultat.get(Vector2i(29, 29)) != 59:
		return "couverture ou profondeur incorrecte sur la grille"
	return "" if duree < 50000 else "calcul trop lent : %d µs" % duree
