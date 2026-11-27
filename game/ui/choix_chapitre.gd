extends CanvasLayer
## Écran « Chapitres » de la campagne (playtest 3) : la liste des six chapitres et, à côté, l'aperçu du chapitre
## choisi (mini-plan de son diorama, récit, pièces qu'il débloque, état Normal / Difficile).
##
## Pourquoi : le Difficile se choisissait en faisant défiler les chapitres au clic sur un seul bouton. Même règle
## que pour la partie libre : plus de trois choix = une liste et un aperçu.

signal ferme

const Progression = preload("res://game/core/progression.gd")
const Interface = preload("res://game/ui/menu_titre.gd")
const Plan = preload("res://game/ui/choix_partie.gd").Plan

var _chapitre: int = 0
var _boutons: Array[Button] = []
var _plan := Plan.new()
var _titre := Label.new()
var _nom := Label.new()
var _recit := Label.new()
var _faits := Label.new()
var _jouer := Button.new()
var _difficile := Button.new()
var _retour := Button.new()
var _panneau := PanelContainer.new()


func _ready() -> void:
	layer = 5
	hide()
	var voile := ColorRect.new()
	voile.color = Color(0.16, 0.1, 0.05, 0.55)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	voile.theme = preload("res://game/ui/theme_rouages.tres")
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	voile.add_child(centre)
	centre.add_child(_panneau)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override(&"separation", 12)
	_panneau.add_child(colonne)
	_titre.theme_type_variation = &"TitreMenu"
	_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colonne.add_child(_titre)
	var corps := HBoxContainer.new()
	corps.add_theme_constant_override(&"separation", 18)
	colonne.add_child(corps)
	var liste := VBoxContainer.new()
	liste.add_theme_constant_override(&"separation", 6)
	liste.custom_minimum_size.x = 330
	corps.add_child(liste)
	var groupe := ButtonGroup.new()
	for i: int in Run.regles.chapitres.size():
		var bouton := Button.new()
		bouton.toggle_mode = true
		bouton.button_group = groupe
		bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bouton.custom_minimum_size.y = 46
		bouton.pressed.connect(_choisir.bind(i))
		bouton.focus_entered.connect(_choisir.bind(i))
		liste.add_child(bouton)
		_boutons.append(bouton)
	var fiche := PanelContainer.new()
	fiche.theme_type_variation = &"Fiche"
	fiche.custom_minimum_size = Vector2(620, 0)
	corps.add_child(fiche)
	var contenu := HBoxContainer.new()
	contenu.add_theme_constant_override(&"separation", 16)
	fiche.add_child(contenu)
	_plan.custom_minimum_size = Vector2(250, 250)
	contenu.add_child(_plan)
	var textes := VBoxContainer.new()
	textes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textes.add_theme_constant_override(&"separation", 8)
	contenu.add_child(textes)
	_nom.theme_type_variation = &"CarteNom"
	_nom.add_theme_font_size_override(&"font_size", 26)
	_nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nom.custom_minimum_size.x = 320
	textes.add_child(_nom)
	for texte: Label in [_recit, _faits]:
		texte.theme_type_variation = &"CarteTexte"
		texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texte.custom_minimum_size.x = 320
		textes.add_child(texte)
	var pied := HBoxContainer.new()
	pied.alignment = BoxContainer.ALIGNMENT_CENTER
	pied.add_theme_constant_override(&"separation", 16)
	colonne.add_child(pied)
	_retour.custom_minimum_size = Vector2(180, 50)
	_retour.pressed.connect(_fermer)
	pied.add_child(_retour)
	_jouer.custom_minimum_size = Vector2(280, 50)
	_jouer.pressed.connect(_lancer.bind(false))
	pied.add_child(_jouer)
	_difficile.custom_minimum_size = Vector2(300, 50)
	_difficile.pressed.connect(_lancer.bind(true))
	pied.add_child(_difficile)
	Interface.preparer_boutons(self)


## Ouvre l'écran sur le chapitre en cours de la campagne.
func ouvrir() -> void:
	_chapitre = mini(Progression.chapitres_finis(), Run.regles.chapitres.size() - 1)
	show()
	_actualiser()
	Interface.apparaitre(_panneau)
	_boutons[_chapitre].grab_focus()


func _fermer() -> void:
	hide()
	ferme.emit()


func _choisir(i: int) -> void:
	if _chapitre != i:
		_chapitre = i
		_actualiser()


func _lancer(difficile: bool) -> void:
	Run.preparer_chapitre(_chapitre, difficile)
	Interface.commencer_partie(get_tree())


func _unhandled_input(evenement: InputEvent) -> void:
	if visible and evenement.is_action_pressed(&"annuler"):
		get_viewport().set_input_as_handled()
		_fermer()


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible:
		_actualiser()


func _actualiser() -> void:
	var finis: int = Progression.chapitres_finis()
	_titre.text = tr("Campagne")
	_retour.text = tr("Retour")
	for i: int in _boutons.size():
		var chapitre: Resource = Run.regles.chapitres[i]
		var marque: String = ""
		if i < finis:
			marque = "   ✓" + (" ★" if Progression.chapitre_difficile_fini(chapitre.id) else "")
		_boutons[i].text = "  %d. %s%s" % [chapitre.id, tr(chapitre.titre), marque]
		_boutons[i].modulate = Color(1, 1, 1, 0.5) if i > finis else Color.WHITE
		_boutons[i].set_pressed_no_signal(i == _chapitre)
	var choisi: Resource = Run.regles.chapitres[_chapitre]
	_plan.depart = choisi.depart
	_nom.text = tr("Chapitre %d : %s") % [choisi.id, tr(choisi.titre)]
	_recit.text = tr(choisi.recit)
	var lignes := PackedStringArray()
	var nouveautes := PackedStringArray()
	for piece: Resource in choisi.debloque:
		nouveautes.append(tr(piece.get("nom")))
	if not nouveautes.is_empty():
		lignes.append(tr("Nouvelles pièces : %s") % ", ".join(nouveautes))
	if _chapitre > finis:
		lignes.append(tr("Verrouillé : termine le chapitre %d") % Run.regles.chapitres[_chapitre - 1].id)
	elif _chapitre == finis:
		lignes.append(tr("À jouer : c’est la suite de l’histoire."))
	elif Progression.chapitre_difficile_fini(choisi.id):
		lignes.append(tr("Terminé en Normal et en Difficile."))
	else:
		lignes.append(tr("Terminé en Normal. Le Difficile donne plus d’engrenages d’or (optionnel)."))
	_faits.text = "\n".join(lignes)
	_jouer.text = tr("Jouer ce chapitre") if _chapitre >= finis else tr("Rejouer ce chapitre")
	_jouer.disabled = _chapitre > finis
	_difficile.text = tr("Rejouer en Difficile")
	_difficile.visible = _chapitre < finis
	_difficile.tooltip_text = tr("Difficile : plus de PV ennemis, engrenages d’or ×1,5, un coffre de plus, +2 chance. Optionnel.")
