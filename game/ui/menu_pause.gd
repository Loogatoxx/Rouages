extends CanvasLayer
## Suspend le plateau en laissant les commandes du menu actives.

const Interface = preload("res://game/ui/menu_titre.gd")

var _ancien_focus: Control


func _ready() -> void:
	Events.pause_demandee.connect(_ouvrir)
	Interface.preparer_boutons(self)
	%Options.pressed.connect(func() -> void:
		%Panneau.hide()
		%Reglages.ouvrir())
	%Reglages.ferme.connect(func() -> void:
		%Panneau.show()
		%Options.grab_focus())
	%Reprendre.pressed.connect(_reprendre)
	%Recommencer.pressed.connect(Interface.commencer_partie.bind(get_tree()))
	%MenuTitre.pressed.connect(Interface.ouvrir_titre.bind(get_tree()))


func _input(evenement: InputEvent) -> void:
	if %Reglages.visible:
		return
	if evenement.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if visible:
			_reprendre()
		else:
			_ouvrir()
	elif visible and evenement.is_action_pressed(&"annuler"):
		get_viewport().set_input_as_handled()
		_reprendre()


func _ouvrir() -> void:
	if visible or Run.phase == Run.Phase.FIN:
		return
	_ancien_focus = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	show()
	Interface.apparaitre(%Panneau)
	%Reprendre.grab_focus()


func _reprendre() -> void:
	hide()
	get_tree().paused = false
	if is_instance_valid(_ancien_focus) and _ancien_focus.is_visible_in_tree():
		_ancien_focus.grab_focus()
