extends HBoxContainer
## Affiche les pièces en réserve et permet d'en choisir une pendant la construction.

var _boutons: Dictionary[StringName, Button] = {}
var _selection: StringName = &""


func _ready() -> void:
	Run.reserve.modifiee.connect(_reconstruire)
	Events.phase_changee.connect(_actualiser_phase)
	Events.tuile_choisie.connect(_afficher_selection)
	_reconstruire()


func _reconstruire() -> void:
	for bouton: Button in _boutons.values():
		remove_child(bouton)
		bouton.queue_free()
	_boutons.clear()
	for id: StringName in Run.reserve.ids():
		var objet: Resource = Run.reserve.trouver(id)
		var bouton: Button = Button.new()
		bouton.text = "%s ×%d" % [objet.get("nom"), Run.reserve.quantite(id)]
		bouton.tooltip_text = objet.get("description")
		bouton.toggle_mode = true
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.set_pressed_no_signal(id == _selection)
		bouton.pressed.connect(Events.tuile_choisie.emit.bind(id))
		add_child(bouton)
		_boutons[id] = bouton
	_actualiser_phase(Run.phase)


func _actualiser_phase(phase: int) -> void:
	for bouton: Button in _boutons.values():
		bouton.disabled = phase != Run.Phase.CONSTRUCTION


func _afficher_selection(id: StringName) -> void:
	_selection = id
	for cle: StringName in _boutons:
		_boutons[cle].set_pressed_no_signal(cle == id)
