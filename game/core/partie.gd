extends Node
## Fait avancer les ateliers, les arrivées et la simulation pendant une vague (et le remontage en construction).

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")
const Production = preload("res://game/workshops/production.gd")
const DirecteurVagues = preload("res://game/waves/directeur_vagues.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")

@onready var _source: PlateauNoeud = $"../PlateauNoeud"
var sim: SwarmSim = SwarmSim.new()
var production: Production = Production.new()
var directeur: DirecteurVagues = DirecteurVagues.new()
var _entrees: Array[Vector2i] = []


func _ready() -> void:
	Events.plateau_modifie.connect(_configurer)
	Events.vague_commencee.connect(_commencer)
	sim.ennemi_arrive.connect(Run.subir_degats)
	sim.unite_morte.connect(_unite_morte)
	_configurer()


func _unite_morte(camp: int, position: Vector2, def: UniteDef) -> void:
	if camp == SwarmSim.ENNEMI:
		Run.casser_ennemi(def, position)


func _configurer() -> void:
	sim.configurer(_source.plateau, Run.regles.garde_ratio)
	_entrees = ChampFlux.entrees(_source.plateau, ChampFlux.calculer(_source.plateau))


func _commencer(numero: int) -> void:
	directeur.commencer(Run.vagues[numero - 1], _entrees)


## Fait vivre la vague ; en construction, « remonte » les jouets : les ateliers produisent et les jouets
## rejoignent leur poste, sans ennemi. Pourquoi : une vague ratée ne vide plus l'armée de la suivante
## (spirale de défaite mesurée au banc d'équilibrage), et le joueur voit tout de suite qu'un atelier fonctionne.
func _physics_process(delta: float) -> void:
	var vague: bool = Run.phase == Run.Phase.VAGUE
	if not vague and Run.phase != Run.Phase.CONSTRUCTION:
		return
	var dt: float = delta * Run.vitesse
	var allies_avant: int = sim.nombre(SwarmSim.ALLIE)
	production.avancer(dt, _source.plateau, _source.alimentees, sim, Run.regles)
	if sim.nombre(SwarmSim.ALLIE) > allies_avant:
		Sons.jouer(&"jouet_sort", 0.08)  # anti-répétition gérée par Sons
	if vague:
		directeur.avancer(dt, sim)
	sim.avancer(dt)
	if vague and Run.phase == Run.Phase.VAGUE and directeur.est_terminee(sim):
		Run.terminer_vague()
