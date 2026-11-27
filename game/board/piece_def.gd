class_name PieceDef extends Resource
## Décrit les ports d'une pièce, sa production de jouets et son éventuel tir.

const UniteDef = preload("res://game/swarm/unite_def.gd")

## GENERATEUR (playtest 2) : source d'énergie autonome, limitée à quelques pièces (ajouté en fin d'énumération pour
## ne pas décaler les types déjà enregistrés dans les ressources).
enum Type { HORLOGE, ENGRENAGE, ATELIER, TOURELLE, GENERATEUR }
enum Rarete { COMMUNE, RARE, EPIQUE }

const TEINTES_RARETE: Array[Color] = [Color("#D4A84B"), Color("#8FB3D9"), Color("#E8B04A")]

@export var id: StringName
@export var nom: String
@export var description: String
@export var type: Type
@export var niveau_max: int = 1
@export var prix_amelioration: int = 0
@export_flags("N", "E", "S", "O") var ports: int
@export var transmet: bool = true
## Se pose sur une case de route (le Pont) au lieu de l'herbe ; les unités passent dessous.
@export var sur_route: bool = false
## Générateur : nombre d'ateliers et de tourelles qu'il alimente au niveau 1, puis en plus par niveau.
@export var capacite_generateur: int = 0
@export var capacite_par_niveau: int = 0
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
