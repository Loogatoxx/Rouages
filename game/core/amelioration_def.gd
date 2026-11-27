class_name AmeliorationDef extends Resource
## Décrit les niveaux, le prix et l'effet permanent d'une amélioration de l'Établi.

@export var id: StringName
@export var nom: String
@export var description: String
@export var niveaux_max: int
@export var prix: Array[int] = []
@export var effet: StringName
@export var valeur_par_niveau: float

@export var chapitre_min: int = 0

enum Etat { DISPONIBLE, VERROUILLEE, MASQUEE }


## Indique si l’établi propose l’achat, annonce son déblocage ou garde la surprise.
func etat(chapitres_finis: int, ancien_joueur: bool) -> Etat:
	if ancien_joueur or chapitre_min <= chapitres_finis:
		return Etat.DISPONIBLE
	if chapitre_min == chapitres_finis + 1:
		return Etat.VERROUILLEE
	return Etat.MASQUEE
