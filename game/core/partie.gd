extends Node
## Fait avancer les ateliers, les arrivées et la simulation pendant une vague.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
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
	_configurer()


func _configurer() -> void:
	sim.configurer(_source.plateau)
	_entrees = ChampFlux.entrees(_source.plateau, ChampFlux.calculer(_source.plateau))


func _commencer(numero: int) -> void:
	directeur.commencer(Run.vagues[numero - 1], _entrees)


func _physics_process(delta: float) -> void:
	if Run.phase != Run.Phase.VAGUE:
		return
	var dt: float = delta
	if Input.is_action_pressed("accelerer"):
		dt *= Run.regles.multiplicateur_acceleration
	production.avancer(dt, _source.plateau, _source.alimentees, sim, Run.regles)
	directeur.avancer(dt, sim)
	sim.avancer(dt)
	if Run.phase == Run.Phase.VAGUE and directeur.est_terminee(sim):
		Events.vague_terminee.emit(Run.vague_actuelle)
		if Run.vague_actuelle == Run.nb_vagues:
			Run.changer_phase(Run.Phase.FIN)
			Events.run_terminee.emit(true)
		else:
			Run.changer_phase(Run.Phase.CONSTRUCTION)
