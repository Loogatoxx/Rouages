extends Node
## Fait avancer les ateliers, les arrivées et la simulation pendant une vague (et le remontage en construction).

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


## Fait vivre la vague ; en construction, « remonte » les jouets : les ateliers produisent et les jouets
## rejoignent leur poste, sans ennemi. Pourquoi : une vague ratée ne vide plus l'armée de la suivante
## (spirale de défaite mesurée au banc d'équilibrage), et le joueur voit tout de suite qu'un atelier fonctionne.
func _physics_process(delta: float) -> void:
	var vague: bool = Run.phase == Run.Phase.VAGUE
	if not vague and Run.phase != Run.Phase.CONSTRUCTION:
		return
	var dt: float = delta
	if Input.is_action_pressed("accelerer"):
		dt *= Run.regles.multiplicateur_acceleration
	production.avancer(dt, _source.plateau, _source.alimentees, sim, Run.regles)
	if vague:
		directeur.avancer(dt, sim)
	sim.avancer(dt)
	if vague and Run.phase == Run.Phase.VAGUE and directeur.est_terminee(sim):
		Run.terminer_vague()
