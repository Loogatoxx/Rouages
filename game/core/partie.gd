extends Node
## Fait avancer les ateliers, les arrivées et la simulation pendant une vague (plateau vide entre les vagues).

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const Production = preload("res://game/workshops/production.gd")
const Tourelles = preload("res://game/workshops/tourelles.gd")
const DirecteurVagues = preload("res://game/waves/directeur_vagues.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")

@onready var _source: PlateauNoeud = $"../PlateauNoeud"
var sim: SwarmSim = SwarmSim.new()
var production: Production = Production.new()
var tourelles: Tourelles = Tourelles.new()
var directeur: DirecteurVagues = DirecteurVagues.new()
var _entrees: Array[Vector2i] = []
## Coup de carillon : secondes avant de pouvoir sonner de nouveau (0 = prêt).
var carillon_attente: float = 0.0
var _enfermes: Array[Vector2i] = []


func _ready() -> void:
	add_to_group(&"partie")
	Events.piece_reprise.connect(_piece_reprise)
	Events.plateau_modifie.connect(_configurer)
	Events.vague_commencee.connect(_commencer)
	Events.vague_terminee.connect(_rentrer_jouets)
	Events.vague_terminee.connect(_ouvrir_tiroir)
	sim.ennemi_arrive.connect(Run.subir_degats)
	sim.unite_morte.connect(_unite_morte)
	_configurer()


func _unite_morte(camp: int, position: Vector2, def: UniteDef) -> void:
	if camp == SwarmSim.ENNEMI:
		Run.casser_ennemi(def, position)


func _piece_reprise(case: Vector2i, def: Resource) -> void:
	var piece: Production.Plateau.PieceDef = def as Production.Plateau.PieceDef
	if piece != null and piece.type == Production.Plateau.PieceDef.Type.ATELIER:
		production.atelier_repris(case)
		sim.rappeler(case)


# Carte qui évolue (PT-60) : après certaines vagues, un tiroir s'ouvre et un sentier se pose seul (nouvelle entrée).
# Tirage par `Run.rng` : au défi du jour, tout le monde voit le même tiroir.
func _ouvrir_tiroir(numero: int) -> void:
	if numero >= Run.nb_vagues or not numero in Run.tiroirs() or Run.regles.extension_tiroir == null:
		return
	var RouteLongue = preload("res://game/core/route_longue.gd")
	if not RouteLongue.ouvrir_tiroir(_source.plateau, Run.regles.extension_tiroir, Run.rng).is_empty():
		# Après le bandeau « Vague tenue » (même instant) : sinon il recouvrirait l'annonce.
		get_tree().create_timer(1.6).timeout.connect(func() -> void:
			Events.message_joueur.emit(tr("Un tiroir s’ouvre : une nouvelle entrée apparaît !")))
		Sons.jouer(&"pose")


# Playtest 2 : la vague tenue, les jouets survivants rentrent à leur atelier. La pause reste vide (on voit le
# plateau pour réfléchir à ses placements) et la vague suivante repart de zéro.
func _rentrer_jouets(_numero: int) -> void:
	sim.vider(SwarmSim.ALLIE)


func _configurer() -> void:
	sim.configurer(_source.plateau, Run.regles.garde_ratio)
	_entrees = ChampFlux.entrees(_source.plateau, ChampFlux.calculer(_source.plateau))
	# Atelier sans aucune case libre vers la route : il ne peut pas sortir ses jouets. On le dit une fois.
	var enfermes: Array[Vector2i] = []
	for case: Vector2i in _source.plateau.coords_pieces():
		if _source.plateau.piece_de(case).type == Production.Plateau.PieceDef.Type.ATELIER \
				and sim.sortie_atelier(case) == Vector2.INF:
			enfermes.append(case)
			if not _enfermes.has(case):
				Events.message_joueur.emit(tr("Cet atelier est enfermé : laisse une case libre entre lui et la route."))
	_enfermes = enfermes


func _commencer(numero: int) -> void:
	directeur.facteur_pv = Run.regles.difficultes_pv_ennemis[Run.difficulte] \
			* (Run.regles.facteur_pv_difficile if Run.chapitre_difficile else 1.0)
	var speciaux: Array[Resource] = Run.depart.ennemis_speciaux if numero >= Run.depart.vague_speciaux else ([] as Array[Resource])
	directeur.commencer(Run.vagues[numero - 1], entrees_de_la_vague(numero), Run.regles.delai_premier_ennemi, speciaux,
			Run.depart.part_speciaux)
	production.nouvelle_vague()
	carillon_attente = 0.0


## Entrées par où arrive la vague `numero`. Carte à marée : une seule, à tour de rôle (les autres sont sous l'eau).
func entrees_de_la_vague(numero: int) -> Array[Vector2i]:
	if Run.depart.maree and _entrees.size() > 1:
		return [_entrees[(numero - 1) % _entrees.size()]]
	return _entrees


## Coup de carillon du joueur (pilier 4) : étourdit les ennemis autour de `point` (mètres). Faux s'il n'est pas prêt
## ou hors vague.
func sonner_carillon(point: Vector2) -> bool:
	if Run.phase != Run.Phase.VAGUE or carillon_attente > 0.0:
		return false
	sim.ralentir_zone(point, Run.regles.carillon_rayon, 1.0, Run.regles.carillon_duree)
	carillon_attente = Run.regles.carillon_recharge
	Events.carillon_sonne.emit(point)
	return true


## Fait vivre la vague : les ateliers sortent leurs jouets un par un, les ennemis arrivent, les tourelles tirent.
## Entre les vagues, rien ne bouge (playtest 1 : attendre ne rapporte rien ; playtest 2 : aucun jouet, pas de rafale
## au lancement, chaque atelier repart de zéro).
func _physics_process(delta: float) -> void:
	if Run.phase != Run.Phase.VAGUE:
		return
	var dt: float = delta * Run.vitesse
	carillon_attente = maxf(0.0, carillon_attente - dt)
	production.bonus_cadence = Run.bonus_cadence
	var allies_avant: int = sim.nombre(SwarmSim.ALLIE)
	production.avancer(dt, _source.plateau, _source.alimentees, sim, Run.regles)
	if sim.nombre(SwarmSim.ALLIE) > allies_avant:
		Sons.jouer(&"jouet_sort", 0.08)  # anti-répétition gérée par Sons
	directeur.avancer(dt, sim)
	tourelles.avancer(dt, _source.plateau, _source.alimentees, sim)
	sim.avancer(dt)
	if Run.phase == Run.Phase.VAGUE and directeur.est_terminee(sim):
		Run.terminer_vague()
