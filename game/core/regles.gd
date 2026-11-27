class_name Regles extends Resource
## Regroupe les réglages communs à toutes les vagues d'une partie.

const AmeliorationDef = preload("res://game/core/amelioration_def.gd")
const ChapitreDef = preload("res://game/core/chapitre_def.gd")
const DepartDef = preload("res://game/core/depart_def.gd")
const RecetteDef = preload("res://game/core/recette_def.gd")
const Lot = preload("res://game/core/lot.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")

@export var ameliorations: Array[AmeliorationDef] = []
@export var engrenages_par_vague: int
@export var engrenages_victoire: int
@export var chapitres: Array[ChapitreDef] = []
@export var chapitre_deblocage_libre: int
@export var difficultes_pv_ennemis: Array[float]
@export var difficultes_pv_horloge: Array[int]
@export_group("Difficile optionnel (playtest 2)")
## PV des ennemis en plus en mode Difficile d'un chapitre (multiplie la difficulté du chapitre).
@export var facteur_pv_difficile: float = 1.3
## Engrenages d'or gagnés ×… en Difficile.
@export var butin_difficile: float = 1.5
## Chance offerte au départ d'un chapitre en Difficile.
@export var chance_difficile: int = 2
## Vague après laquelle le Difficile offre un coffre de plus.
@export var vague_coffre_difficile: int = 5
@export_group("")
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
@export_group("Terrain (PT-60, PT-61)")
## Bonus créatifs débloqués par le nombre d'extensions posées dans la partie.
@export var paliers_extension: Array[Resource] = []
## Longue route : nombre total de vagues et vagues après lesquelles un tiroir s'ouvre.
@export var vagues_longue_route: int = 15
@export var tiroirs_longue_route: Array[int] = [4, 8, 12]
@export var extension_tiroir: Resource
@export_group("")
@export var prix_deplacement: int = 3
@export var prix_deplacement_pas: int = 2
@export var pv_horloge: int
## Plafond de jouets vivants **par atelier** (playtest 2 : individuel, plus partagé).
@export var plafond_allies_par_atelier: int
## Avance de production de chaque atelier au lancement d'une vague (0 = il repart de zéro, 1 = premier jouet
## immédiat). Playtest 2 : aucun jouet entre les vagues, puis sortie progressive, un par un.
@export_range(0.0, 1.0) var avance_lancement: float = 0.0
## Secondes entre le lancement d'une vague et le premier ennemi : les jouets sortent un par un pendant ce temps et
## tiennent leur poste quand les tiroirs s'ouvrent (sinon ils arriveraient un à un dans la mêlée et tomberaient seuls).
@export var delai_premier_ennemi: float = 5.0
@export var multiplicateur_acceleration: float
@export_group("Tic-tac : énergie de l'Horloge (playtest 3)")
## Dents d'énergie que fournit l'Horloge au début d'une partie. Chaque atelier ou tourelle en consomme
## (`PieceDef.cout_energie`) ; les engrenages ne consomment rien. Pourquoi : sans rareté, « un atelier de plus »
## était toujours la meilleure dépense (spam). Avec des dents comptées, on choisit et on améliore.
@export var dents_depart: int = 4
## L'Horloge se remonte : elle gagne une dent après chacune de ces vagues.
@export var vagues_dent: Array[int] = [2, 4, 6, 8, 11, 13]
## Jouets plus solides par niveau de leur atelier (PV et dégâts, en part du niveau 1).
@export var gain_niveau_unite: float = 0.15
## Coup de carillon (pilier 4) : le joueur fait sonner l'Horloge sur un point de la route ; les ennemis à moins de
## `carillon_rayon` mètres sont étourdis `carillon_duree` secondes. Prêt au début de chaque vague, puis toutes les
## `carillon_recharge` secondes. Pourquoi : sans geste du joueur, une vague n'est qu'une attente.
@export var carillon_recharge: float = 25.0
@export var carillon_rayon: float = 3.0
@export var carillon_duree: float = 2.5
@export_group("")
@export var ressorts_depart: int
@export var recompense_vague: int
@export var recompense_par_vague: int
@export var bonus_sans_degat: int
@export var prix_relance: int
@export var prix_reparation: int
@export var pv_reparation: int
@export var recettes: Array[RecetteDef] = []
@export var demontage_engrenage: int
@export var demontage_atelier: int
@export var demontage_tourelle: int
@export var boutique: Array[Lot] = []
@export var choix_par_draft: int = 3
@export var pioche: Array[Lot] = []
@export var vagues_coffre: Array[int] = [3, 6, 9]
@export var coffre: Array[Lot] = []
@export var vagues: Array[VagueDef] = []


## Dents d'énergie de l'Horloge après `vagues_tenues` vagues (sans les bonus de l'Établi).
func dents_apres(vagues_tenues: int) -> int:
	var total: int = dents_depart
	for vague: int in vagues_dent:
		if vagues_tenues >= vague:
			total += 1
	return total
