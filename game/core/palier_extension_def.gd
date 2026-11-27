class_name PalierExtensionDef extends Resource
## Bonus créatif débloqué quand le joueur a posé `seuil` extensions dans la run (playtest 1, PT-61).
## Pourquoi : agrandir le terrain ne doit pas « juste doubler » (retour du playtest de l'étape 6) ; chaque palier change
## un peu la manière de jouer, comme les « perks » de Thronefall (benchmark D6 : méta horizontale, pas de chiffres bruts).

@export var seuil: int = 1
@export var titre: String
@export var description: String
## `choix_draft` (+valeur cartes par tirage), `remise_amelioration` (fraction du prix), `chance` (+valeur),
## `piece` (ajoute `objet` à la réserve).
@export var effet: StringName
@export var valeur: float = 0.0
@export var objet: Resource
