class_name Plateau extends RefCounted
## Mémorise le sol, les pièces et leur orientation sur la grille.

signal modifie

const PieceDef = preload("res://game/board/piece_def.gd")

enum Sol { HERBE, CHEMIN }
## Ordre des ports (bits N, E, S, O), comme `PieceDef.ports`.
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _sols: Dictionary[Vector2i, Sol] = {}
var _pieces: Dictionary[Vector2i, PieceDef] = {}
var _niveaux: Dictionary[Vector2i, int] = {}
var _rotations: Dictionary[Vector2i, int] = {}


## Définit le sol d’une case et signale tout changement.
func ajouter_sol(coord: Vector2i, sol: Sol) -> void:
	if sol_de(coord) != sol:
		_sols[coord] = sol
		modifie.emit()


## Met à jour un lot de sols et avertit les observateurs une fois le terrain complet.
func ajouter_sols(sols: Dictionary) -> void:
	var changement: bool = false
	for coord: Vector2i in sols:
		if sol_de(coord) != sols[coord]:
			_sols[coord] = sols[coord]
			changement = true
	if changement:
		modifie.emit()


## Copie le terrain et les placements en partageant les définitions des pièces.
func dupliquer() -> Plateau:
	var copie: Plateau = get_script().new()
	copie._sols = _sols.duplicate()
	copie._pieces = _pieces.duplicate()
	copie._rotations = _rotations.duplicate()
	copie._niveaux = _niveaux.duplicate()
	return copie


## Indique si la case appartient au plateau.
func a_sol(coord: Vector2i) -> bool:
	return _sols.has(coord)


## Renvoie le sol de la case, ou -1 en dehors du terrain.
func sol_de(coord: Vector2i) -> int:
	return _sols.get(coord, -1)


## Pose une pièce sur une case d’herbe libre.
func poser(coord: Vector2i, def: PieceDef, rotation: int = 0) -> bool:
	if def == null or sol_de(coord) != Sol.HERBE or _pieces.has(coord):
		return false
	_pieces[coord] = def
	_niveaux[coord] = 1
	_rotations[coord] = posmod(rotation, 4)
	modifie.emit()
	return true


## Retire une pièce et son orientation, sauf si la case porte l’horloge.
func retirer(coord: Vector2i) -> PieceDef:
	var piece: PieceDef = piece_de(coord)
	if piece == null or piece.type == PieceDef.Type.HORLOGE:
		return null
	_pieces.erase(coord)
	_niveaux.erase(coord)
	_rotations.erase(coord)
	modifie.emit()
	return piece


## Renvoie le niveau de la pièce ou le niveau initial d'une case libre.
func niveau_de(coord: Vector2i) -> int:
	return _niveaux.get(coord, 1)


## Monte la pièce d'un niveau et avertit les observateurs du plateau.
func ameliorer(coord: Vector2i) -> bool:
	var piece: PieceDef = piece_de(coord)
	if piece == null or niveau_de(coord) >= piece.niveau_max:
		return false
	_niveaux[coord] = niveau_de(coord) + 1
	modifie.emit()
	return true


## Tourne une pièce posée d’un quart de tour horaire.
func tourner(coord: Vector2i) -> bool:
	if not _pieces.has(coord):
		return false
	_rotations[coord] = (_rotations[coord] + 1) % 4
	modifie.emit()
	return true


## Retrouve la pièce posée sur la case.
func piece_de(coord: Vector2i) -> PieceDef:
	return _pieces.get(coord)


## Lit l’orientation de la pièce en quarts de tour.
func rotation_de(coord: Vector2i) -> int:
	return _rotations.get(coord, 0)


## Calcule les ports de la pièce dans son orientation actuelle.
## L'horloge n'a pas de port du côté d'une route (playtest 2) : c'est sa porte, pas une prise d'engrenage, et un
## engrenage ne peut pas être posé sur la route. Traverser une route est le rôle du Pont.
func ports_de(coord: Vector2i) -> int:
	var piece: PieceDef = piece_de(coord)
	if piece == null:
		return 0
	var ports: int = PieceDef.tourner_ports(piece.ports, rotation_de(coord))
	if piece.type == PieceDef.Type.HORLOGE:
		for i: int in DIRECTIONS.size():
			if sol_de(coord + DIRECTIONS[i]) == Sol.CHEMIN:
				ports &= ~(1 << i)
	return ports


## Liste les cases occupées par une pièce.
func coords_pieces() -> Array[Vector2i]:
	return _pieces.keys()


## Liste toutes les cases de sol, y compris les cases sans pièce.
func coords_sols() -> Array[Vector2i]:
	return _sols.keys()
