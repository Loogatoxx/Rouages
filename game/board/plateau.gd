class_name Plateau extends RefCounted

signal modifie

const PieceDef = preload("res://game/board/piece_def.gd")

enum Sol { HERBE, CHEMIN }

var _sols: Dictionary[Vector2i, Sol] = {}
var _pieces: Dictionary[Vector2i, PieceDef] = {}
var _rotations: Dictionary[Vector2i, int] = {}


func ajouter_sol(coord: Vector2i, sol: Sol) -> void:
	if sol_de(coord) != sol:
		_sols[coord] = sol
		modifie.emit()


func a_sol(coord: Vector2i) -> bool:
	return _sols.has(coord)


func sol_de(coord: Vector2i) -> int:
	return _sols.get(coord, -1)


func poser(coord: Vector2i, def: PieceDef, rotation: int = 0) -> bool:
	if def == null or sol_de(coord) != Sol.HERBE or _pieces.has(coord):
		return false
	_pieces[coord] = def
	_rotations[coord] = posmod(rotation, 4)
	modifie.emit()
	return true


func tourner(coord: Vector2i) -> bool:
	if not _pieces.has(coord):
		return false
	_rotations[coord] = (_rotations[coord] + 1) % 4
	modifie.emit()
	return true


func piece_de(coord: Vector2i) -> PieceDef:
	return _pieces.get(coord)


func rotation_de(coord: Vector2i) -> int:
	return _rotations.get(coord, 0)


func ports_de(coord: Vector2i) -> int:
	var piece: PieceDef = piece_de(coord)
	return PieceDef.tourner_ports(piece.ports, rotation_de(coord)) if piece != null else 0


func coords_pieces() -> Array[Vector2i]:
	return _pieces.keys()
