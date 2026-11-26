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
@export_group("Identité d'engrenage (bonus aux voisins alimentés)")
## Démultiplicateur : cadence en plus pour chaque atelier voisin (cumul limité à 2 engrenages).
@export var bonus_voisins_cadence: float = 0.0
## Répartiteur : jouets en plus au plafond de chaque atelier voisin.
@export var bonus_voisins_plafond: int = 0
## Moyeu : cadence de tir en plus pour chaque tourelle voisine.
@export var bonus_voisins_tourelle: float = 0.0


## Oriente le masque des ports par quarts de tour dans le sens horaire.
static func tourner_ports(ports: int, rotation: int) -> int:
	var r: int = posmod(rotation, 4)
	return ((ports << r) | (ports >> (4 - r))) & 15
