extends CenterContainer
## Affiche la réserve de construction et transmet la pièce choisie au plateau.

const Interface = preload("res://game/ui/menu_titre.gd")

var _boutons: Dictionary[StringName, Button] = {}
var _selection: StringName = &""


func _ready() -> void:
	Run.reserve.modifiee.connect(_reconstruire)
	Events.phase_changee.connect(_actualiser_phase)
	Events.tuile_choisie.connect(_afficher_selection)
	_reconstruire()


func _reconstruire() -> void:
	for bouton: Button in _boutons.values():
		%Pieces.remove_child(bouton)
		bouton.queue_free()
	_boutons.clear()
	for id: StringName in Run.reserve.ids():
		var objet: Resource = Run.reserve.trouver(id)
		var bouton := Button.new()
		_actualiser_texte(bouton, objet, Run.reserve.quantite(id))
		bouton.toggle_mode = true
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.set_pressed_no_signal(id == _selection)
		%Pieces.add_child(bouton)
		Interface.preparer_bouton(bouton)
		bouton.pressed.connect(Events.tuile_choisie.emit.bind(id))
		_boutons[id] = bouton
	_actualiser_phase(Run.phase)


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		for id: StringName in _boutons:
			_actualiser_texte(_boutons[id], Run.reserve.trouver(id), Run.reserve.quantite(id))


func _actualiser_texte(bouton: Button, objet: Resource, quantite: int) -> void:
	bouton.text = tr("%s ×%d") % [tr(objet.get("nom")), quantite]
	bouton.tooltip_text = tr(objet.get("description"))


func _actualiser_phase(phase: int) -> void:
	var afficher: bool = phase in [Run.Phase.CONSTRUCTION, Run.Phase.VAGUE] and not _boutons.is_empty()
	if afficher and not visible:
		show()
		Interface.apparaitre(%Panneau)
	else:
		visible = afficher


func _afficher_selection(id: StringName) -> void:
	_selection = id
	for cle: StringName in _boutons:
		_boutons[cle].set_pressed_no_signal(cle == id)
