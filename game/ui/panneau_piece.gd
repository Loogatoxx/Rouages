extends PanelContainer
## Présente les actions et leurs prix à côté de la pièce choisie sur le plateau.

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")
const RESSORT: Texture2D = preload("res://assets/ui/icones/ressort.png")

var _plateau: Plateau
var _case: Vector2i
var _titre: Label = Label.new()
var _colonne: VBoxContainer = VBoxContainer.new()
var _ameliorer: Button
var _tourner: Button
var _reprendre: Button
var _prix: Dictionary[Button, Label] = {}
var _avertissement: Label = Label.new()


func _ready() -> void:
	hide()
	theme = preload("res://game/ui/theme_rouages.tres")
	theme_type_variation = &"Fiche"
	add_child(_colonne)
	# Encre foncée sur le papier (le style crème à contour est réservé aux textes posés sur le bois).
	_titre.theme_type_variation = &"CarteNom"
	_avertissement.theme_type_variation = &"CarteTexte"
	_avertissement.add_theme_font_size_override(&"font_size", 15)
	_colonne.add_child(_titre)
	_ameliorer = _ajouter_action(tr("Améliorer"), preload("res://assets/ui/icones/ameliorer.png"), _acheter_niveau)
	_tourner = _ajouter_action(tr("Tourner"), preload("res://assets/ui/icones/tourner.png"), _tourner_piece)
	_reprendre = _ajouter_action(tr("Reprendre la pièce"), preload("res://assets/ui/icones/deplacer.png"), _reprendre_piece)
	_colonne.add_child(_avertissement)
	_avertissement.text = tr("Reprendre ramène la pièce au niveau 1.")
	Events.ressorts_changes.connect(_solde_change)
	Events.plateau_modifie.connect(_actualiser)


func _ajouter_action(nom: String, icone: Texture2D, action: Callable) -> Button:
	var ligne: HBoxContainer = HBoxContainer.new()
	_colonne.add_child(ligne)
	var bouton: Button = Button.new()
	bouton.text = nom
	bouton.icon = icone
	bouton.add_theme_constant_override("icon_max_width", 25)
	bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bouton.pressed.connect(action)
	ligne.add_child(bouton)
	var ressort: TextureRect = TextureRect.new()
	ressort.texture = RESSORT
	ressort.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ressort.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ressort.custom_minimum_size.x = 20
	ligne.add_child(ressort)
	var prix: Label = Label.new()
	prix.theme_type_variation = &"Nombre"
	prix.custom_minimum_size.x = 28
	ligne.add_child(prix)
	_prix[bouton] = prix
	return bouton


## Ouvre la fiche pour la case choisie et suit sa position à l'écran.
func ouvrir(plateau: Plateau, case: Vector2i) -> void:
	_plateau = plateau
	_case = case
	if not visible:
		add_to_group(&"panneau_piece_ouvert")
	show()
	_actualiser()
	_positionner()


## Ferme la fiche et libère la sélection de la case.
func fermer() -> void:
	if visible:
		remove_from_group(&"panneau_piece_ouvert")
		hide()
	_plateau = null


func _solde_change(_solde: int) -> void:
	_actualiser()


func _actualiser() -> void:
	if not visible:
		return
	var piece: PieceDef = _plateau.piece_de(_case)
	if piece == null:
		fermer()
		return
	var niveau: int = _plateau.niveau_de(_case)
	var mobile: bool = piece.type != PieceDef.Type.HORLOGE
	_titre.text = tr(piece.nom) + " · " + tr("Niveau %d / %d") % [niveau, piece.niveau_max]
	_afficher_prix(_ameliorer, Run.prix_amelioration(_plateau, _case), mobile and niveau < piece.niveau_max)
	_afficher_prix(_tourner, Run.prix_rotation, mobile)
	_afficher_prix(_reprendre, Run.prix_deplacement, mobile)
	_avertissement.visible = niveau > 1
	reset_size()


func _afficher_prix(bouton: Button, prix: int, possible: bool) -> void:
	_prix[bouton].text = str(prix) if possible else "—"
	bouton.disabled = not possible or Run.ressorts < prix


func _process(_delta: float) -> void:
	if visible:
		_positionner()


func _positionner() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var centre: Vector3 = GrilleMonde.vers_monde(_case)
	if camera == null or camera.is_position_behind(centre):
		fermer()
		return
	var cadre: Rect2 = get_viewport_rect()
	var ancre: Vector2 = camera.unproject_position(centre)
	var x: float = ancre.x + 16.0
	if x + size.x > cadre.end.x:
		x = ancre.x - size.x - 16.0
	position = Vector2(x, ancre.y - size.y * 0.5).clamp(cadre.position, (cadre.end - size).max(cadre.position))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("annuler"):
		fermer()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event.is_action_pressed("poser_tuile") or event.is_action_pressed("tourner_tuile")) \
			and not get_global_rect().has_point(event.position):
		fermer()


func _acheter_niveau() -> void:
	if Run.ameliorer_piece(_plateau, _case):
		Sons.jouer(&"pose")
	fermer()


func _tourner_piece() -> void:
	if Run.tourner_piece(_plateau, _case):
		Sons.jouer(&"rotation")
	fermer()


func _reprendre_piece() -> void:
	var piece: PieceDef = _plateau.piece_de(_case)
	if Run.reprendre_piece(_plateau, _case):
		Sons.jouer(&"pose")
		Events.tuile_choisie.emit(piece.id)
	fermer()
