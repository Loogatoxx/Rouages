extends CenterContainer
## Affiche la réserve de construction et transmet la pièce choisie au plateau.

const Interface = preload("res://game/ui/menu_titre.gd")

const RecetteDef = preload("res://game/core/recette_def.gd")
const Lot = preload("res://game/core/lot.gd")

var _actions: Dictionary[RecetteDef, Button] = {}
var _boutons: Dictionary[StringName, Button] = {}
var _selection: StringName = &""


func _ready() -> void:
	Interface.preparer_bouton(%Assembler)
	%Assembler.toggled.connect(%Fiche.set_visible)
	for recette: RecetteDef in Run.regles.recettes:
		_ajouter_recette(recette)
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
		# Vignette + quantité, nom et effet au survol (icônes d'abord) : la barre ne mord plus sur le plateau.
		# La vignette est un enfant de taille fixe : l'icône native du bouton rétrécissait avec les marges du thème.
		var vignette: Texture2D = Interface.vignette_de(objet)
		if vignette != null:
			bouton.custom_minimum_size = Vector2(118, 76)
			var ligne := HBoxContainer.new()
			ligne.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
			ligne.alignment = BoxContainer.ALIGNMENT_CENTER
			ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bouton.add_child(ligne)
			ligne.add_child(_image(vignette, 60))
			var nombre := Label.new()
			nombre.name = "Nombre"
			nombre.theme_type_variation = &"Nombre"
			ligne.add_child(nombre)
		bouton.toggle_mode = true
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.set_pressed_no_signal(id == _selection)
		%Pieces.add_child(bouton)
		Interface.preparer_bouton(bouton)
		bouton.pressed.connect(Events.tuile_choisie.emit.bind(id))
		bouton.gui_input.connect(_clic_piece.bind(id, bouton))
		_boutons[id] = bouton
	_actualiser_phase(Run.phase)


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		for id: StringName in _boutons:
			_actualiser_texte(_boutons[id], Run.reserve.trouver(id), Run.reserve.quantite(id))


func _actualiser_texte(bouton: Button, objet: Resource, quantite: int) -> void:
	var nombre: Label = bouton.find_child("Nombre", true, false)
	if nombre != null:
		nombre.text = "×%d" % quantite
	else:
		bouton.text = tr("%s ×%d") % [tr(objet.get("nom")), quantite]
	bouton.tooltip_text = tr(objet.get("nom")) + "\n" + tr(objet.get("description"))
	var valeur: int = Run.valeur_demontage(objet)
	if Run.phase == Run.Phase.CONSTRUCTION and valeur > 0:
		bouton.tooltip_text += "\n" + tr("Clic droit : démonter (+%d ressorts)") % valeur
	bouton.accessibility_name = tr("%s ×%d") % [tr(objet.get("nom")), quantite]


func _actualiser_phase(phase: int) -> void:
	for id: StringName in _boutons:
		_actualiser_texte(_boutons[id], Run.reserve.trouver(id), Run.reserve.quantite(id))
	var possible: bool = false
	for recette: RecetteDef in _actions:
		var disponible: bool = Run.peut_assembler(recette)
		_actions[recette].disabled = not disponible
		possible = possible or disponible
	%Assembler.visible = phase == Run.Phase.CONSTRUCTION
	%Assembler.disabled = not possible
	if not possible:
		%Assembler.button_pressed = false
	var afficher: bool = phase == Run.Phase.CONSTRUCTION or (phase == Run.Phase.VAGUE and not _boutons.is_empty())
	if afficher and not visible:
		show()
		Interface.apparaitre(%Panneau)
	else:
		visible = afficher


func _afficher_selection(id: StringName) -> void:
	_selection = id
	for cle: StringName in _boutons:
		_boutons[cle].set_pressed_no_signal(cle == id)


func _clic_piece(evenement: InputEvent, id: StringName, bouton: Button) -> void:
	var clic := evenement as InputEventMouseButton
	if clic != null and clic.pressed and clic.button_index == MOUSE_BUTTON_RIGHT:
		bouton.accept_event()
		Run.demonter(id)


func _image(texture: Texture2D, taille: int) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = Vector2(taille, taille)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _texte_papier(ligne: HBoxContainer, texte: String) -> void:
	var etiquette := Label.new()
	etiquette.theme_type_variation = &"CarteTexte"
	etiquette.text = texte
	ligne.add_child(etiquette)


func _ajouter_lot(ligne: HBoxContainer, lot: Lot) -> void:
	var texture: Texture2D = Interface.vignette_de(lot.objet)
	var nom: String = lot.objet.get("nom")
	if texture != null:
		var image: TextureRect = _image(texture, 44)
		image.tooltip_text = nom
		image.mouse_filter = Control.MOUSE_FILTER_PASS
		ligne.add_child(image)
	else:
		_texte_papier(ligne, nom)
	_texte_papier(ligne, "×%d" % lot.quantite)


func _ajouter_recette(recette: RecetteDef) -> void:
	var ligne := HBoxContainer.new()
	%Recettes.add_child(ligne)
	for lot: Lot in recette.entrees:
		_ajouter_lot(ligne, lot)
	_texte_papier(ligne, "→")
	_ajouter_lot(ligne, recette.sortie)
	var bouton := Button.new()
	bouton.text = "Assembler"
	bouton.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	ligne.add_child(bouton)
	Interface.preparer_bouton(bouton)
	bouton.pressed.connect(Run.assembler.bind(recette))
	_actions[recette] = bouton
