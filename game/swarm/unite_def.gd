class_name UniteDef extends Resource
## Décrit les caractéristiques communes aux unités d'un même modèle.

enum Camp { ALLIE, ENNEMI }

@export var id: StringName
@export var nom: String
@export var butin: int = 0
@export var camp: Camp
@export var pv: float
@export var degats: float
@export var cadence: float
@export var portee: float
@export var vitesse: float
@export var rayon: float
## Un boss a sa barre de vie dédiée en haut de l'écran.
@export var boss: bool = false
## Une unité volante survole les combattants au sol.
@export var volant: bool = false
## Armure : retirée à chaque coup reçu (playtest 2). Punit les tirs faibles et nombreux (spam de lance-billes) et
## récompense les gros coups (mortier, canon amélioré). Les jouets au corps à corps frappent aux jointures : seule la
## moitié de l'armure compte contre eux.
@export var armure: float = 0.0

## Part minimale d'un coup qui passe toujours l'armure (un coup n'est jamais totalement nul).
const PLANCHER_ARMURE := 0.15


## Dégâts réellement subis par cette unité pour un coup de `degats` (au corps à corps : moitié de l'armure).
func degats_recus(degats: float, corps_a_corps: bool = false) -> float:
	var armure_effective: float = armure * (0.5 if corps_a_corps else 1.0)
	return maxf(degats * PLANCHER_ARMURE, degats - armure_effective)
