extends CanvasLayer
## Lore en BD (P2-58) : les cases d'un chapitre, une à une, avec leur bulle traduite sous l'image.
##
## Pourquoi une case à la fois, en grand : la BD se lit comme un livre d'images (façon Plants vs. Zombies) ; très peu
## de texte, c'est l'image qui raconte. Le texte n'est jamais dans l'image : il reste traduisible (FR, EN, PT).
## Clic sur l'image, Espace ou Entrée : case suivante ; Échap ou « Passer » : on va directement au jeu.

signal finie

const Interface = preload("res://game/ui/menu_titre.gd")
const Progression = preload("res://game/core/progression.gd")

var _cases: Array[Texture2D] = []
var _bulles: PackedStringArray = []
var _indice: int = 0
var _titre := Label.new()
var _image := TextureRect.new()
var _bulle := Label.new()
var _points := Label.new()
var _suite := Button.new()
var _passer := Button.new()
var _panneau := PanelContainer.new()


## Au premier lancement d'un chapitre qui a une BD : la montre, puis rend la main (à attendre avec `await`).
## Déjà vue ou sans case : rend la main tout de suite. La BD reste visible ensuite par « Revoir l'histoire ».
static func montrer_si_nouvelle(parent: Node, chapitre: Resource) -> void:
	if chapitre == null or chapitre.bd.is_empty() or Progression.bd_vue(chapitre.id):
		return
	Progression.noter_bd_vue(chapitre.id)
	await montrer_dans(parent, chapitre)


## Montre la BD du chapitre par-dessus `parent` et attend qu'elle soit finie ou passée.
static func montrer_dans(parent: Node, chapitre: Resource) -> void:
	var bd: CanvasLayer = (load("res://game/ui/bd_chapitre.gd") as GDScript).new()
	parent.add_child(bd)
	bd.montrer(chapitre)
	await bd.finie
	bd.queue_free()


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var voile := ColorRect.new()
	voile.color = Color(0.12, 0.08, 0.04, 0.85)
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
	# Image en 3:2, à la taille de l'écran (sans déborder sur les petites fenêtres).
	_image.custom_minimum_size = Vector2(810, 540)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.mouse_filter = Control.MOUSE_FILTER_STOP
	_image.gui_input.connect(_sur_clic_image)
	colonne.add_child(_image)
	var fiche := PanelContainer.new()
	fiche.theme_type_variation = &"Fiche"
	colonne.add_child(fiche)
	_bulle.theme_type_variation = &"CarteTexte"
	_bulle.add_theme_font_size_override(&"font_size", 24)
	_bulle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bulle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bulle.custom_minimum_size = Vector2(780, 40)
	fiche.add_child(_bulle)
	var pied := HBoxContainer.new()
	pied.alignment = BoxContainer.ALIGNMENT_CENTER
	pied.add_theme_constant_override(&"separation", 24)
	colonne.add_child(pied)
	_passer.custom_minimum_size = Vector2(180, 50)
	_passer.pressed.connect(_terminer)
	pied.add_child(_passer)
	_points.theme_type_variation = &"CarteTexte"
	_points.add_theme_font_size_override(&"font_size", 22)
	_points.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pied.add_child(_points)
	_suite.custom_minimum_size = Vector2(220, 50)
	_suite.pressed.connect(_avancer)
	pied.add_child(_suite)
	Interface.preparer_boutons(self)


## Montre les cases du chapitre ; émet `finie` après la dernière (ou si on passe). Sans case, émet tout de suite.
func montrer(chapitre: Resource) -> void:
	_cases = chapitre.bd
	_bulles = chapitre.bulles
	if _cases.is_empty():
		finie.emit.call_deferred()
		return
	_titre.text = tr("Chapitre %d : %s") % [chapitre.id, tr(chapitre.titre)]
	_passer.text = tr("Passer")
	_indice = 0
	show()
	_afficher_case()
	Interface.apparaitre(_panneau)
	_suite.grab_focus()


func _afficher_case() -> void:
	_image.texture = _cases[_indice]
	_bulle.text = tr(_bulles[_indice]) if _indice < _bulles.size() else ""
	var points := PackedStringArray()
	for i: int in _cases.size():
		points.append("●" if i == _indice else "○")
	_points.text = " ".join(points)
	_suite.text = tr("Jouer") if _indice == _cases.size() - 1 else tr("Suite")
	# Fondu court d'une case à l'autre, comme une page qu'on tourne.
	_image.modulate.a = 0.0
	_bulle.modulate.a = 0.0
	var fondu: Tween = create_tween().set_parallel()
	fondu.tween_property(_image, "modulate:a", 1.0, 0.25)
	fondu.tween_property(_bulle, "modulate:a", 1.0, 0.25).set_delay(0.15)


func _avancer() -> void:
	_indice += 1
	if _indice >= _cases.size():
		_terminer()
	else:
		_afficher_case()


func _terminer() -> void:
	if not visible:
		return
	hide()
	finie.emit()


func _sur_clic_image(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton and evenement.pressed and evenement.button_index == MOUSE_BUTTON_LEFT:
		_avancer()


func _unhandled_input(evenement: InputEvent) -> void:
	if visible and evenement.is_action_pressed(&"annuler"):
		get_viewport().set_input_as_handled()
		_terminer()
