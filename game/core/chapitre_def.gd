class_name ChapitreDef extends Resource
## Décrit le diorama à déplier, son récit et les conditions de la partie.

const DepartDef = preload("res://game/core/depart_def.gd")

@export var id: int
@export var titre: String
@export_multiline var recit: String
@export var depart: DepartDef
@export_range(0, 2) var difficulte: int = 1
## Vagues après lesquelles un tiroir s'ouvre (la carte évolue en cours de partie, PT-60).
@export var tiroirs: Array[int] = []
## Partie en « Longue route » (15 vagues).
@export var longue_route: bool = false
## Pièces débloquées à partir de ce chapitre (playtest 2 : le pool de départ est réduit, chaque chapitre en ajoute).
## Disponibles dans un chapitre = cumul des `debloque` des chapitres 1 à celui-ci ; annoncées en début de chapitre.
@export var debloque: Array[Resource] = []
## Lore en BD (P2-58, « façon Plants vs. Zombies ») : quelques cases illustrées montrées au premier lancement du
## chapitre. Aucun texte dans les images ; la bulle de chaque case (même ordre) est traduite par `tr()`.
@export var bd: Array[Texture2D] = []
@export var bulles: PackedStringArray = []
