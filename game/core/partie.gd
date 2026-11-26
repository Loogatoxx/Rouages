extends Node
## Fait avancer les ateliers, les arrivées et la simulation pendant une vague (remontage instantané entre les vagues).

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


func _ready() -> void:
	Events.piece_reprise.connect(_piece_reprise)
	Events.plateau_modifie.connect(_configurer)
	Events.vague_commencee.connect(_commencer)
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


func _configurer() -> void:
	sim.configurer(_source.plateau, Run.regles.garde_ratio)
	_entrees = ChampFlux.entrees(_source.plateau, ChampFlux.calculer(_source.plateau))


func _commencer(numero: int) -> void:
	directeur.commencer(Run.vagues[numero - 1], _entrees)
	production.nouvelle_pause()


## Fait vivre la vague. Entre les vagues (construction), la production est à l'arrêt : chaque atelier alimenté reçoit
## d'un coup son « remontage », une seule fois par pause, et les jouets rejoignent leur poste (aucun ennemi).
## Pourquoi (playtest 1) : les jouets s'accumulaient avant le lancement et on attendait passivement pour frapper plus fort ;
## désormais attendre ne rapporte rien. Le remontage évite toujours la spirale de défaite (une vague ratée ne vide pas
## l'armée de la suivante, mesuré au banc) et montre tout de suite qu'un atelier relié fonctionne.
func _physics_process(delta: float) -> void:
	var vague: bool = Run.phase == Run.Phase.VAGUE
	if not vague and Run.phase != Run.Phase.CONSTRUCTION:
		return
	var dt: float = delta * Run.vitesse
	production.bonus_cadence = Run.bonus_cadence
	var allies_avant: int = sim.nombre(SwarmSim.ALLIE)
	if vague:
		production.avancer(dt, _source.plateau, _source.alimentees, sim, Run.regles)
	else:
		production.remonter(Run.regles.remontage_lancement, _source.plateau, _source.alimentees, sim, Run.regles)
	if sim.nombre(SwarmSim.ALLIE) > allies_avant:
		Sons.jouer(&"jouet_sort", 0.08)  # anti-répétition gérée par Sons
	if vague:
		directeur.avancer(dt, sim)
		tourelles.avancer(dt, _source.plateau, _source.alimentees, sim)
	sim.avancer(dt)
	if Run.phase == Run.Phase.VAGUE and directeur.est_terminee(sim):
		Run.terminer_vague()
