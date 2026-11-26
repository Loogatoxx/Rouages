class_name Production extends RefCounted
## Suit la progression de chaque atelier et place ses jouets à la sortie du port.

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
var _remontages_a_deduire: int = 0
var _remontes: Dictionary[Vector2i, bool] = {}


## Avance les ateliers alimentés et limite leur effectif total de jouets vivants.
func avancer(dt: float, plateau: Plateau, alimentees: Dictionary, sim: SwarmSim, regles: Regles) -> void:
	var ateliers: Array[Vector2i] = []
	for case: Vector2i in alimentees:
		var piece: Plateau.PieceDef = plateau.piece_de(case)
		if piece != null and piece.type == Plateau.PieceDef.Type.ATELIER:
			ateliers.append(case)
	var plafond: int = regles.plafond_allies_par_atelier * ateliers.size()
	for case: Vector2i in ateliers:
		plafond += Placement.plafond_atelier(plateau, alimentees, case)
	for case: Vector2i in ateliers:
		var atelier: Plateau.PieceDef = plateau.piece_de(case)
		if atelier.cadence_production <= 0.0 or atelier.unite_produite == null:
			continue
		var cadence: float = atelier.cadence_production * bonus_cadence \
				* Placement.cadence_atelier(plateau, alimentees, case, regles)
		var progression: float = _progressions.get(case, 0.0) + dt * cadence
		var prets: int = floori(progression)
		_progressions[case] = progression - prets
		var places: int = plafond - sim.nombre(SwarmSim.ALLIE)
		if prets > 0 and places > 0:
			var sortie: Vector2 = _sortie(case, plateau)
			for i: int in mini(prets, places):
				if not sim.ajouter(atelier.unite_produite, sortie):
					break
				jouet_produit.emit(case)


# Un atelier en bord de route lâche ses jouets sur la route (front immédiat) ; sinon, par son premier port.
func _sortie(case: Vector2i, plateau: Plateau) -> Vector2:
	var centre: Vector2 = Vector2(case) * GrilleMonde.TAILLE_CASE
	var route: Vector2i = Placement.cote_route(plateau, case)
	if route != Vector2i.ZERO:
		return centre + Vector2(route) * (GrilleMonde.TAILLE_CASE / 2.0)
	var ports: int = plateau.ports_de(case)
	for i: int in DIRECTIONS.size():
		if ports & (1 << i):
			return centre + Vector2(DIRECTIONS[i]) * (GrilleMonde.TAILLE_CASE / 2.0)
	return centre


## Remonte d'un coup les ateliers alimentés qui ne l'ont pas encore été pendant cette pause : chacun sort `secondes`
## de production (cadence × bonus), à tour de rôle, dans la limite du plafond de jouets vivants.
## Appelé en continu entre les vagues : un atelier relié en cours de pause est remonté aussitôt, mais une seule fois,
## donc attendre ne rapporte rien (playtest 1 : vraie pause, plus d'accumulation passive).
func remonter(secondes: float, plateau: Plateau, alimentees: Dictionary, sim: SwarmSim, regles: Regles) -> void:
	var dus: Dictionary[Vector2i, int] = {}
	var ateliers: int = 0
	var plafond: int = 0
	for case: Vector2i in alimentees:
		var piece: Plateau.PieceDef = plateau.piece_de(case)
		if piece == null or piece.type != Plateau.PieceDef.Type.ATELIER or piece.unite_produite == null:
			continue
		ateliers += 1
		plafond += regles.plafond_allies_par_atelier + Placement.plafond_atelier(plateau, alimentees, case)
		if not _remontes.has(case):
			_remontes[case] = true
			if _remontages_a_deduire > 0:
				_remontages_a_deduire -= 1
				continue
			dus[case] = floori(secondes * piece.cadence_production * bonus_cadence
					* Placement.cadence_atelier(plateau, alimentees, case, regles))
	var places: int = plafond - sim.nombre(SwarmSim.ALLIE)
	var cases: Array[Vector2i] = dus.keys()
	cases.sort()
	var reste: bool = true
	while places > 0 and reste:
		reste = false
		for case: Vector2i in cases:
			if dus[case] <= 0 or places <= 0:
				continue
			if not sim.ajouter(plateau.piece_de(case).unite_produite, _sortie(case, plateau)):
				return
			dus[case] -= 1
			places -= 1
			reste = true
			jouet_produit.emit(case)


## Reporte le remontage déjà reçu sur le prochain atelier alimenté après la reprise.
func atelier_repris(case: Vector2i) -> void:
	_progressions.erase(case)
	if _remontes.erase(case):
		_remontages_a_deduire += 1


## Ouvre une nouvelle pause : tous les ateliers pourront de nouveau être remontés (appelé au lancement d'une vague).
func nouvelle_pause() -> void:
	_remontes.clear()
	_remontages_a_deduire = 0
