class_name PieceDef extends Resource

enum Type { HORLOGE, ENGRENAGE, ATELIER }

@export var id: StringName
@export var nom: String
@export var type: Type
@export_flags("N", "E", "S", "O") var ports: int
@export var transmet: bool = true


static func tourner_ports(ports: int, rotation: int) -> int:
	var r: int = posmod(rotation, 4)
	return ((ports << r) | (ports >> (4 - r))) & 15
