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


func _commencer(numero: int) -> void:
	directeur.facteur_pv = Run.regles.difficultes_pv_ennemis[Run.difficulte] \
			* (Run.regles.facteur_pv_difficile if Run.chapitre_difficile else 1.0)
	var speciaux: Array[Resource] = Run.depart.ennemis_speciaux if numero >= Run.depart.vague_speciaux else ([] as Array[Resource])
	directeur.commencer(Run.vagues[numero - 1], _entrees, Run.regles.delai_premier_ennemi, speciaux, Run.depart.part_speciaux)
	production.nouvelle_vague()


## Fait vivre la vague : les ateliers sortent leurs jouets un par un, les ennemis arrivent, les tourelles tirent.
## Entre les vagues, rien ne bouge (playtest 1 : attendre ne rapporte rien ; playtest 2 : aucun jouet, pas de rafale
## au lancement, chaque atelier repart de zéro).
func _physics_process(delta: float) -> void:
	if Run.phase != Run.Phase.VAGUE:
		return
	var dt: float = delta * Run.vitesse
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
