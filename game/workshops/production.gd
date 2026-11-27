class_name Production extends RefCounted
## Fait sortir les jouets des ateliers alimentés, un par un, pendant les vagues, dans la limite du plafond de
## chaque atelier.
##
## Playtest 2 : plus de « remontage » en rafale. Entre les vagues, aucun jouet ne sort (le plateau est vide) ; au
## lancement, chaque atelier repart de zéro et ses jouets apparaissent progressivement, à sa cadence.

signal jouet_produit(case: Vector2i)

const Plateau = preload("res://game/board/plateau.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Regles = preload("res://game/core/regles.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")
const Placement = preload("res://game/workshops/placement.gd")
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## Multiplicateur de cadence (progression méta), réglé par `Partie` : la logique ne lit pas les autoloads,
## pour rester utilisable par les tests et le banc d'équilibrage.
var bonus_cadence: float = 1.0
var _progressions: Dictionary[Vector2i, float] = {}
# Modèles de jouets renforcés par niveau d'atelier : [modèle de base, niveau] → copie aux PV et dégâts relevés.
var _renforces: Dictionary = {}


## Plafond de jouets vivants d'un atelier : base des règles + bonus de placement et de niveau.
## Le plafond est individuel (playtest 2) : un atelier plein n'empêche pas ses voisins de produire.
static func plafond(plateau: Plateau, alimentees: Dictionary, case: Vector2i, regles: Regles) -> int:
	return regles.plafond_allies_par_atelier + Placement.plafond_atelier(plateau, alimentees, case)


## Avance les ateliers alimentés : chacun sort ses jouets un par un, tant qu'il n'a pas atteint son plafond.
func avancer(dt: float, plateau: Plateau, alimentees: Dictionary, sim: SwarmSim, regles: Regles) -> void:
	for case: Vector2i in alimentees:
		var atelier: Plateau.PieceDef = plateau.piece_de(case)
		if atelier == null or atelier.type != Plateau.PieceDef.Type.ATELIER \
				or atelier.cadence_production <= 0.0 or atelier.unite_produite == null:
			continue
		var cadence: float = atelier.cadence_production * bonus_cadence \
				* Placement.cadence_atelier(plateau, alimentees, case, regles)
		var progression: float = _progressions.get(case, regles.avance_lancement) + dt * cadence
		var places: int = plafond(plateau, alimentees, case, regles) - sim.effectif(case)
		var sortis: int = 0
		# Atelier enfermé entre des bâtiments (aucune case libre vers la route) : il garde son jouet prêt et attend
		# qu'un passage s'ouvre, au lieu de le lâcher à travers ses voisins (relecture T14b).
		if places > 0 and progression >= 1.0 and sim.sortie_atelier(case) == Vector2.INF and sim.a_un_plateau():
			places = 0
		if places > 0 and progression >= 1.0:
			var sortie: Vector2 = _sortie(case, plateau, sim)
			var unite: Plateau.PieceDef.UniteDef = unite_de_niveau(atelier.unite_produite, plateau.niveau_de(case), regles)
			for i: int in mini(floori(progression), places):
				if not sim.ajouter(unite, sortie, case):
					break
				sortis += 1
				jouet_produit.emit(case)
		# Un atelier plein garde au plus un jouet « prêt » : il ressort dès qu'une place se libère, sans rafale.
		_progressions[case] = minf(progression - sortis, 1.0)


## Modèle du jouet que sort un atelier de ce niveau (playtest 3 : améliorer rend les jouets plus solides, pas
## seulement plus nombreux — « mieux, pas plus »). PV et dégâts × (1 + `gain_niveau_unite` × (niveau − 1)).
func unite_de_niveau(base: Plateau.PieceDef.UniteDef, niveau: int, regles: Regles) -> Plateau.PieceDef.UniteDef:
	if niveau <= 1 or regles.gain_niveau_unite <= 0.0:
		return base
	var cle: Array = [base, niveau]
	if not _renforces.has(cle):
		var copie: Plateau.PieceDef.UniteDef = base.duplicate()
		var facteur: float = 1.0 + regles.gain_niveau_unite * (niveau - 1)
		copie.pv *= facteur
		copie.degats *= facteur
		_renforces[cle] = copie
	return _renforces[cle]


# Un atelier en bord de route lâche ses jouets sur la route (front immédiat) ; sinon, du côté d'une case libre qui
# mène à la route (playtest 3 : plus de jouets qui traversent les engrenages) ; en dernier recours, par son premier port.
func _sortie(case: Vector2i, plateau: Plateau, sim: SwarmSim = null) -> Vector2:
	if sim != null:
		var libre: Vector2 = sim.sortie_atelier(case)
		if libre != Vector2.INF:
			return libre
	var centre: Vector2 = Vector2(case) * GrilleMonde.TAILLE_CASE
	var route: Vector2i = Placement.cote_route(plateau, case)
	if route != Vector2i.ZERO:
		return centre + Vector2(route) * (GrilleMonde.TAILLE_CASE / 2.0)
	var ports: int = plateau.ports_de(case)
	for i: int in DIRECTIONS.size():
		if ports & (1 << i):
			return centre + Vector2(DIRECTIONS[i]) * (GrilleMonde.TAILLE_CASE / 2.0)
	return centre


## Un atelier repris (déplacé) perd sa progression : il repartira de zéro là où on le repose.
func atelier_repris(case: Vector2i) -> void:
	_progressions.erase(case)


## Au lancement d'une vague : chaque atelier repart de zéro (les jouets de la vague précédente sont rentrés).
func nouvelle_vague() -> void:
	_progressions.clear()
