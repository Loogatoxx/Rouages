class_name Regles extends Resource
## Regroupe les réglages communs à toutes les vagues d'une partie.

const DepartDef = preload("res://game/core/depart_def.gd")
const Lot = preload("res://game/core/lot.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")

@export var departs: Array[DepartDef] = []
@export var garde_ratio: float = 0.55
@export var prix_rotation: int = 2
@export var pv_horloge: int
@export var plafond_allies_par_atelier: int
@export var multiplicateur_acceleration: float
@export var ressorts_depart: int
@export var recompense_vague: int
@export var recompense_par_vague: int
@export var bonus_sans_degat: int
@export var prix_relance: int
@export var prix_reparation: int
@export var pv_reparation: int
@export var boutique: Array[Lot] = []
@export var choix_par_draft: int = 3
@export var pioche: Array[Lot] = []
@export var vagues: Array[VagueDef] = []
