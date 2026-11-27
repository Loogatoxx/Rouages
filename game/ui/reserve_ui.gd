extends CenterContainer
## Affiche la réserve de construction et transmet la pièce choisie au plateau.

const Interface = preload("res://game/ui/menu_titre.gd")

const RecetteDef = preload("res://game/core/recette_def.gd")
const Lot = preload("res://game/core/lot.gd")

## Côté d'une case de la réserve, en pixels.
const TAILLE_CASE := 72
const ICONE_REVENDRE: Texture2D = preload("res://assets/ui/icones/revendre.png")

var _actions: Dictionary[RecetteDef, Button] = {}
var _boutons: Dictionary[StringName, Button] = {}
var _selection: StringName = &""


func _ready() -> void:
	# Icône « assembler » (Gemini, registre v3) : le mot passe dans l'infobulle (chasse au texte, P2-22).
	%Assembler.text = ""
	%Assembler.icon = preload("res://assets/ui/icones/assembler.png")
	%Assembler.expand_icon = true
	%Assembler.custom_minimum_size = Vector2(TAILLE_CASE, TAILLE_CASE)
	%Assembler.tooltip_text = tr("Assembler")
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
		# Playtest 2 : case carrée au liseré fin (les plaques de laiton à rivets étaient trop massives), vignette
		# centrée de la même façon pour toutes les pièces, quantité en pastille dans le coin, bouton « revendre ».
		bouton.theme_type_variation = &"CaseReserve"
		bouton.custom_minimum_size = Vector2(TAILLE_CASE, TAILLE_CASE)
		var vignette: Texture2D = Interface.vignette_de(objet)
		if vignette != null:
			var image: TextureRect = _image(vignette, TAILLE_CASE - 10)
			image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
			bouton.add_child(image)
			var nombre := Label.new()
			nombre.name = "Nombre"
			nombre.theme_type_variation = &"Badge"
			nombre.add_theme_font_size_override(&"font_size", 15)
			nombre.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 2)
			nombre.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			nombre.grow_vertical = Control.GROW_DIRECTION_BEGIN
			nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bouton.add_child(nombre)
		var revendre := Button.new()
		revendre.name = "Revendre"
		revendre.theme_type_variation = &"CaseReserve"
		revendre.icon = ICONE_REVENDRE
		revendre.expand_icon = true
		revendre.custom_minimum_size = Vector2(26, 26)
		revendre.focus_mode = Control.FOCUS_NONE
		revendre.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, -6)
		revendre.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		revendre.pressed.connect(_revendre.bind(id))
		revendre.visible = false
		bouton.add_child(revendre)
		# Le bouton « revendre » n'apparaît qu'au survol de la case : la barre reste calme.
		bouton.mouse_entered.connect(_montrer_revente.bind(bouton, true))
		bouton.mouse_exited.connect(_montrer_revente.bind(bouton, false))
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
	var vendable: bool = Run.phase == Run.Phase.CONSTRUCTION and valeur > 0
	if vendable:
		bouton.tooltip_text += "\n" + tr("Clic droit : démonter (+%d ressorts)") % valeur
	var revendre: Button = bouton.get_node_or_null(^"Revendre")
	if revendre != null:
		revendre.set_meta(&"vendable", vendable)
		revendre.visible = vendable and bouton.is_hovered()
		revendre.tooltip_text = tr("Revendre : +%d ressorts") % valeur
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


func _montrer_revente(bouton: Button, survol: bool) -> void:
	var revendre: Button = bouton.get_node_or_null(^"Revendre")
	if revendre == null:
		return
	# Quitter la case pour entrer sur le petit bouton ne doit pas le cacher.
	var dedans: bool = survol or revendre.get_global_rect().has_point(revendre.get_global_mouse_position())
	revendre.visible = dedans and revendre.get_meta(&"vendable", false)


# Revendre une pièce de la réserve (P2-35) : même effet que le clic droit, mais visible.
func _revendre(id: StringName) -> void:
	Sons.jouer(&"clic")
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
