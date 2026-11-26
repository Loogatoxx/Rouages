class_name PieceDef extends Resource
## Décrit les ports d'une pièce, sa production de jouets et son éventuel tir.

const UniteDef = preload("res://game/swarm/unite_def.gd")

enum Type { HORLOGE, ENGRENAGE, ATELIER, TOURELLE }
enum Rarete { COMMUNE, RARE, EPIQUE }

const TEINTES_RARETE: Array[Color] = [Color("#D4A84B"), Color("#8FB3D9"), Color("#E8B04A")]

@export var id: StringName
@export var nom: String
@export var description: String
@export var type: Type
@export_flags("N", "E", "S", "O") var ports: int
@export var transmet: bool = true
@export var unite_produite: UniteDef
@export var cadence_production: float = 0.0
@export var rarete: Rarete = Rarete.COMMUNE
@export var portee_tir: float = 0.0
@export var degats_tir: float = 0.0
@export var cadence_tir: float = 0.0
@export var zone_tir: float = 0.0


## Oriente le masque des ports par quarts de tour dans le sens horaire.
static func tourner_ports(ports: int, rotation: int) -> int:
	var r: int = posmod(rotation, 4)
	return ((ports << r) | (ports >> (4 - r))) & 15
