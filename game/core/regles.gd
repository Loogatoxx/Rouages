class_name Regles extends Resource
## Regroupe les réglages communs à toutes les vagues d'une partie.

const Lot = preload("res://game/core/lot.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")

@export var pv_horloge: int
@export var plafond_allies_par_atelier: int
@export var multiplicateur_acceleration: float
@export var choix_par_draft: int = 3
@export var pioche: Array[Lot] = []
@export var vagues: Array[VagueDef] = []
