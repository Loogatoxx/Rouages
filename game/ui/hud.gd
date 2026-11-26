extends CanvasLayer
## Affiche l'état de l'horloge et propose l'action disponible à chaque phase.

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
	var numero: int = Run.vague_actuelle + 1 if construction else Run.vague_actuelle
	_vague.text = "Vague %d / %d" % [numero, Run.nb_vagues]
	_afficher_pv(Run.pv_horloge)


func _afficher_pv(restants: int) -> void:
	_pv.text = "Horloge · %d / %d PV" % [restants, Run.regles.pv_horloge]


func _afficher_fin(victoire: bool) -> void:
	_bilan.text = "Victoire !" if victoire else "L'horloge s'est arrêtée…"
	%Rejouer.grab_focus()


func _rejouer() -> void:
	Run.reinitialiser()
	get_tree().reload_current_scene()
