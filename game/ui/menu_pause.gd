extends CanvasLayer
## Suspend le plateau en laissant les commandes du menu actives.

const Interface = preload("res://game/ui/menu_titre.gd")
const Touches = preload("res://game/core/touches.gd")

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


## Aide-mémoire des commandes (playtest 1 : « un vrai menu en pleine partie »). Playtest 3 : chaque ligne est une
## clé de traduction (elle restait en français : une seule grande clé avec des retours à la ligne ne correspondait à
## aucune entrée du fichier de traduction), et les touches sont lues dans les réglages du joueur : l'aide suit donc
## la langue ET les touches réassignées. [clé avec un %s par touche, actions dont on affiche la touche].
const LIGNES_AIDE: Array[Array] = [
	["%s : poser, ou ouvrir les actions d’une pièce posée · %s : tourner", [&"poser_tuile", &"tourner_tuile"]],
	["%s : désélectionner, puis menu · %s : boutique", [&"annuler", &"boutique"]],
	["%s : vitesse ×1 / ×2 · %s : vue de dessus / inclinée", [&"accelerer", &"basculer_camera"]],
	["Molette, %s ou %s : zoom · %s ou %s : inclinaison", [&"camera_zoom_avant", &"camera_zoom_arriere", &"camera_redresser", &"camera_coucher"]],
	["%s %s %s %s : déplacer la vue · %s : plein écran", [&"camera_haut", &"camera_gauche", &"camera_bas", &"camera_droite", &"plein_ecran"]],
	["%s : coup de carillon pendant une vague (étourdit les ennemis proches)", [&"coup_carillon"]],
	["Clic sur un atelier, puis sur le fanion du panneau : choisir son poste de garde", []],
]


## Texte de l'aide dans la langue courante, avec les touches actuelles du joueur.
static func texte_aide() -> String:
	var lignes := PackedStringArray()
	for ligne: Array in LIGNES_AIDE:
		var touches: Array = []
		for action: StringName in ligne[1]:
			var evenements: Array[InputEvent] = InputMap.action_get_events(action) if InputMap.has_action(action) else ([] as Array[InputEvent])
			touches.append("—" if evenements.is_empty() else Touches.decrire(evenements[0]))
		var texte: String = TranslationServer.translate(ligne[0])
		lignes.append(texte % touches if not touches.is_empty() else texte)
	return "\n".join(lignes)


func _afficher_aide(visible_aide: bool) -> void:
	%TexteAide.text = texte_aide()
	Interface.caler_hauteur(%TexteAide, 560.0)
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
