extends Node
## Conserve les PV de l'horloge et publie les transitions de la partie.

const Regles = preload("res://game/core/regles.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")

const DepartDef = preload("res://game/core/depart_def.gd")
const Reserve = preload("res://game/core/reserve.gd")
const Lot = preload("res://game/core/lot.gd")
const Draft = preload("res://game/draft/draft.gd")

enum Phase { DRAFT, CONSTRUCTION, VAGUE, FIN }

var regles: Regles = preload("res://data/regles.tres")
var depart: DepartDef = preload("res://data/depart.tres")
var reserve: Reserve = Reserve.new()
var offre: Array[Lot] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var vagues: Array[VagueDef]:
	get:
		return regles.vagues
var nb_vagues: int:
	get:
		return vagues.size()
var pv_horloge: int = regles.pv_horloge
var phase: Phase = Phase.DRAFT
var vague_actuelle: int = 0


func _ready() -> void:
	reinitialiser()


## Ajoute le lot choisi à la réserve et ouvre la construction.
func choisir_lot(i: int) -> void:
	if phase != Phase.DRAFT or i < 0 or i >= offre.size():
		return
	var lot: Lot = offre[i]
	offre.clear()
	reserve.ajouter(lot.objet, lot.quantite)
	changer_phase(Phase.CONSTRUCTION)


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


## Clôt la vague, puis propose un nouveau tirage ou annonce la victoire.
func terminer_vague() -> void:
	if phase != Phase.VAGUE:
		return
	Events.vague_terminee.emit(vague_actuelle)
	if vague_actuelle == nb_vagues:
		changer_phase(Phase.FIN)
		Events.run_terminee.emit(true)
	else:
		offre = Draft.tirer(regles.pioche, regles.choix_par_draft, vague_actuelle + 1, rng)
		changer_phase(Phase.DRAFT)


## Restaure l'horloge et la réserve, puis propose les lots de la première vague.
func reinitialiser() -> void:
	vague_actuelle = 0
	pv_horloge = regles.pv_horloge
	reserve.vider()
	reserve.ajouter_lots(depart.reserve)
	offre = Draft.tirer(regles.pioche, regles.choix_par_draft, 1, rng)
	phase = Phase.DRAFT
	Events.phase_changee.emit(phase)
