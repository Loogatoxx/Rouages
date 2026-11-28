class_name DepartDef extends Resource
## Décrit le terrain, l'horloge et les pièces confiées au début d'une partie.

const Plateau = preload("res://game/board/plateau.gd")
const Lot = preload("res://game/core/lot.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")

@export var nom: String
@export var description: String
@export var terrain: Rect2i
@export var chemins: Array[Vector2i] = []
@export var horloge: Vector2i
@export var reserve: Array[Lot] = []
## Dents d'énergie en plus au départ sur ce plateau (playtest 3) : un plateau à plusieurs entrées sans tronc commun
## demande une escouade par entrée, donc plus d'énergie dès la première vague.
@export var dents_bonus: int = 0
@export_group("Décor et mécaniques propres à la carte (playtest 3)")
## Rigoles et bassins : cases d'eau où l'on ne pose qu'un Pont.
@export var eau: Array[Vector2i] = []
## Cases de décor non constructibles : case → nom du modèle (`decor_bosquet`, `decor_rocher`…).
@export var decors: Dictionary[Vector2i, StringName] = {}
## Marée : une seule entrée est ouverte par vague, à tour de rôle ; les autres routes sont sous l'eau.
@export var maree: bool = false
## Manège (plaque tournante) : deux tronçons de route qui s'échangent toutes les `periode_variantes` vagues. Le
## tronçon inactif est une plaque de manège (herbe où l'on ne pose rien).
@export var variante_a: Array[Vector2i] = []
@export var variante_b: Array[Vector2i] = []
@export var periode_variantes: int = 2
## Rail : cases de la voie, dans l'ordre où passe le train ; il passe toutes les `periode_train` secondes de vague
## et blesse de `degats_train` tout ce qui est sur la voie (ennemis ET jouets).
@export var rail: Array[Vector2i] = []
@export var periode_train: float = 14.0
@export var degats_train: float = 18.0
## Palette de la carte : teintes multipliées sur l'herbe, la route et la table, et couleur du soleil.
@export var teinte_herbe: Color = Color.WHITE
@export var teinte_route: Color = Color.WHITE
@export var teinte_table: Color = Color.WHITE
@export var lumiere: Color = Color.WHITE
@export_group("")
## Ennemis propres à ce plateau (playtest 2 : plus de variété), mêlés aux scarabées à partir de `vague_speciaux`.
@export var ennemis_speciaux: Array[Resource] = []
## Part des scarabées ordinaires remplacés par ces ennemis (0,1 = un sur dix).
@export var part_speciaux: float = 0.1
@export var vague_speciaux: int = 3


## Manège : active le tronçon `indice` % 2 (0 = A, 1 = B) et transforme l'autre en plaque tournante.
func appliquer_variante(plateau: Plateau, indice: int) -> void:
	if variante_a.is_empty() or variante_b.is_empty():
		return
	var actif: Array[Vector2i] = variante_a if indice % 2 == 0 else variante_b
	var inactif: Array[Vector2i] = variante_b if indice % 2 == 0 else variante_a
	for case: Vector2i in inactif:
		if not actif.has(case):
			plateau.ajouter_sol(case, Plateau.Sol.HERBE)
			plateau.ajouter_decor(case, &"decor_plaque")
	for case: Vector2i in actif:
		plateau.retirer_decor(case)
		plateau.ajouter_sol(case, Plateau.Sol.CHEMIN)


## Construit un plateau neuf en plaçant les chemins puis l'horloge sur le terrain.
func creer_plateau() -> Plateau:
	var plateau: Plateau = Plateau.new()
	for x: int in range(terrain.position.x, terrain.end.x):
		for y: int in range(terrain.position.y, terrain.end.y):
			plateau.ajouter_sol(Vector2i(x, y), Plateau.Sol.HERBE)
	for case: Vector2i in chemins:
		plateau.ajouter_sol(case, Plateau.Sol.CHEMIN)
	for case: Vector2i in eau:
		plateau.ajouter_sol(case, Plateau.Sol.EAU)
	plateau.poser(horloge, HORLOGE)
	appliquer_variante(plateau, 0)
	# La voie ferrée est un décor sur l'herbe (on n'y construit pas) ; elle croise les routes sans les couper.
	for case: Vector2i in rail:
		if plateau.sol_de(case) == Plateau.Sol.HERBE:
			plateau.ajouter_decor(case, &"decor_rail")
	for case: Vector2i in decors:
		plateau.ajouter_decor(case, decors[case])
	return plateau
