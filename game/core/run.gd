extends Node
## Conserve les PV de l'horloge et publie les transitions de la partie.

const Regles = preload("res://game/core/regles.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")

enum Phase { DRAFT, CONSTRUCTION, VAGUE, FIN }

var regles: Regles = preload("res://data/regles.tres")
var vagues: Array[VagueDef] = [
	preload("res://data/vagues/vague_01.tres"),
	preload("res://data/vagues/vague_02.tres"),
	preload("res://data/vagues/vague_03.tres"),
]
var nb_vagues: int = vagues.size()
var pv_horloge: int = regles.pv_horloge
var phase: Phase = Phase.CONSTRUCTION
var vague_actuelle: int = 0


## Change de phase et prévient les systèmes qui en dépendent.
func changer_phase(nouvelle: Phase) -> void:
	if nouvelle != phase:
		phase = nouvelle
		Events.phase_changee.emit(phase)


## Lance la prochaine vague après la construction.
func lancer_vague() -> void:
	if phase != Phase.CONSTRUCTION or vague_actuelle >= nb_vagues:
		return
	vague_actuelle += 1
	changer_phase(Phase.VAGUE)
	Events.vague_commencee.emit(vague_actuelle)


## Retire les PV dus à une arrivée et annonce la défaite au dernier point perdu.
func subir_degats(d: float) -> void:
	if phase != Phase.VAGUE or d <= 0.0:
		return
	pv_horloge = maxi(0, pv_horloge - ceili(d))
	Events.horloge_touchee.emit(pv_horloge)
	if pv_horloge == 0:
		changer_phase(Phase.FIN)
		Events.run_terminee.emit(false)


## Restaure l'horloge et revient à la construction de départ.
func reinitialiser() -> void:
	vague_actuelle = 0
	pv_horloge = regles.pv_horloge
	phase = Phase.CONSTRUCTION
	Events.phase_changee.emit(phase)
