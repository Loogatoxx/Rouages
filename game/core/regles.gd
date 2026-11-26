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
@export_group("Placement (playtest 1 : stratégie plutôt que spam)")
## Tourelle en bord de route : dégâts en plus.
@export var bonus_route_degats: float = 0.25
## Atelier à `distance_arriere` cases ou plus de la route : cadence en plus (« arrière-garde »).
@export var bonus_arriere_cadence: float = 0.2
@export var distance_arriere: int = 3
## Cadence en moins pour chaque atelier identique collé à un atelier (encombrement).
@export var malus_encombrement: float = 0.1
@export_group("Améliorations")
@export var gain_niveau_atelier: float
@export var plafond_niveau_atelier: int
@export var gain_niveau_tourelle: float
@export var gain_niveau_engrenage: float
@export_group("Chance (benchmark D4)")
## Chaque point de chance multiplie le poids des cartes rares par (1 + chance × ce facteur) dans les coffres.
@export var chance_rare: float = 0.25
## Idem pour les cartes épiques.
@export var chance_epique: float = 0.5
@export var chance_par_vague_propre: int = 1
@export var chance_max: int = 10
@export var prix_porte_bonheur: int = 8
@export var chance_porte_bonheur: int = 2
@export_group("")
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
