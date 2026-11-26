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
			var image := TextureRect.new()
			image.texture = vignette
			image.custom_minimum_size = Vector2(60, 60)
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ligne.add_child(image)
			var nombre := Label.new()
			nombre.name = "Nombre"
			nombre.theme_type_variation = &"Nombre"
			ligne.add_child(nombre)
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
	var nombre: Label = bouton.find_child("Nombre", true, false)
	if nombre != null:
		nombre.text = "×%d" % quantite
	else:
		bouton.text = tr("%s ×%d") % [tr(objet.get("nom")), quantite]
	bouton.tooltip_text = tr(objet.get("nom")) + "\n" + tr(objet.get("description"))
	bouton.accessibility_name = tr("%s ×%d") % [tr(objet.get("nom")), quantite]


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
