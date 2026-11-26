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
	%QuitterJeu.pressed.connect(get_tree().quit)
	%Aide.toggled.connect(_afficher_aide)


## Liste des commandes (le menu en jeu sert aussi d'aide-mémoire, playtest 1 : « un vrai menu en pleine partie »).
const AIDE := "Clic gauche : poser · R ou clic droit : tourner\nÉchap : désélectionner, puis menu · B : boutique\nEspace : vitesse ×1 / ×2 · Tab : vue de dessus / inclinée\nMolette ou + / − : zoom · Clic molette glissé ou A / E : inclinaison\nZ Q S D : déplacer la vue · F11 : plein écran"


func _afficher_aide(visible_aide: bool) -> void:
	%TexteAide.text = tr(AIDE)
	Interface.caler_hauteur(%TexteAide, 500.0)
	%TexteAide.visible = visible_aide


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
