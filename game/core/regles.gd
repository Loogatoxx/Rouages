class_name Regles extends Resource
## Regroupe les réglages communs à toutes les vagues d'une partie.

const AmeliorationDef = preload("res://game/core/amelioration_def.gd")
const DepartDef = preload("res://game/core/depart_def.gd")
const Lot = preload("res://game/core/lot.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")

@export var ameliorations: Array[AmeliorationDef] = []
@export var engrenages_par_vague: int
@export var engrenages_victoire: int
@export var departs: Array[DepartDef] = []
@export var garde_ratio: float = 0.55
@export var prix_rotation: int = 2
@export var prix_deplacement: int = 3
@export var prix_deplacement_pas: int = 2
@export var pv_horloge: int
@export var plafond_allies_par_atelier: int
## Secondes de production versées d'un coup à chaque atelier alimenté, une fois par pause entre les vagues
## (« remontage »). La production elle-même est arrêtée entre les vagues : attendre ne rapporte rien (playtest 1).
@export var remontage_lancement: float = 20.0
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
@export var vagues_coffre: Array[int] = [3, 6, 9]
@export var coffre: Array[Lot] = []
@export var vagues: Array[VagueDef] = []
