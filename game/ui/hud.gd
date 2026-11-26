extends CanvasLayer
## Affiche l'état de l'horloge et propose l'action disponible à chaque phase.

const Lot = preload("res://game/core/lot.gd")

@onready var _draft: CenterContainer = $Draft
@onready var _lots: VBoxContainer = %Lots
@onready var _pv: Label = %PV
@onready var _vague: Label = %Vague
@onready var _lancer: Button = %Lancer
@onready var _fin: ColorRect = $Fin
@onready var _bilan: Label = %Bilan


func _ready() -> void:
	Events.phase_changee.connect(_actualiser_phase)
	Events.horloge_touchee.connect(_afficher_pv)
	Events.run_terminee.connect(_afficher_fin)
	_lancer.pressed.connect(Run.lancer_vague)
	%Rejouer.pressed.connect(_rejouer)
	_actualiser_phase(Run.phase)


func _actualiser_phase(phase: int) -> void:
	var construction: bool = phase == Run.Phase.CONSTRUCTION
	_lancer.visible = construction
	_fin.visible = phase == Run.Phase.FIN
	_draft.visible = phase == Run.Phase.DRAFT
	if _draft.visible:
		_afficher_lots()
	var numero: int = Run.vague_actuelle
	if construction or _draft.visible:
		numero += 1
	_vague.text = "Vague %d / %d" % [numero, Run.nb_vagues]
	_afficher_pv(Run.pv_horloge)


func _afficher_lots() -> void:
	for ancien: Node in _lots.get_children():
		_lots.remove_child(ancien)
		ancien.queue_free()
	for i: int in range(Run.offre.size()):
		var lot: Lot = Run.offre[i]
		var bouton: Button = Button.new()
		bouton.text = "%s ×%d\n%s" % [lot.objet.get("nom"), lot.quantite, lot.objet.get("description")]
		bouton.pressed.connect(Run.choisir_lot.bind(i))
		_lots.add_child(bouton)


func _afficher_pv(restants: int) -> void:
	_pv.text = "Horloge · %d / %d PV" % [restants, Run.regles.pv_horloge]


func _afficher_fin(victoire: bool) -> void:
	_bilan.text = "Victoire !" if victoire else "L'horloge s'est arrêtée…"
	%Rejouer.grab_focus()


func _rejouer() -> void:
	Run.reinitialiser()
	get_tree().reload_current_scene()
