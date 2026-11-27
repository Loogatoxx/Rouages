extends PanelContainer
## Décrit la case sous la souris et indique si son atelier reçoit de l'énergie.

const GrilleMonde = preload("res://game/board/grille_monde.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const Interface = preload("res://game/ui/menu_titre.gd")
const Placement = preload("res://game/workshops/placement.gd")

@export var plateau_noeud: NodePath
@onready var _source: PlateauNoeud = get_node(plateau_noeud)
@onready var _texte: Label = $Texte
var _selection: StringName = &""


func _ready() -> void:
	theme = preload("res://game/ui/theme_rouages.tres")
	theme_type_variation = &"Fiche"
	_texte.theme_type_variation = &"CarteTexte"
	Events.tuile_choisie.connect(_choisir)


func _choisir(id: StringName) -> void:
	_selection = id


func _process(_delta: float) -> void:
	var vue: Viewport = get_viewport()
	var souris: Vector2 = vue.get_mouse_position()
	var cadre: Rect2 = vue.get_visible_rect()
	if (get_tree().paused or Run.phase == Run.Phase.FIN
			or get_tree().has_group(&"panneau_piece_ouvert")
			or not cadre.has_point(souris) or vue.gui_get_hovered_control() != null):
		hide()
		return
	var camera: Camera3D = vue.get_camera_3d()
	if camera == null:
		hide()
		return
	var point: Variant = Plane(Vector3.UP, 0).intersects_ray(
			camera.project_ray_origin(souris), camera.project_ray_normal(souris))
	if point == null:
		hide()
		return
	var case_visee: Vector2i = GrilleMonde.vers_case(point)
	var conseil: String = _apercu(case_visee) if not _selection.is_empty() else _decrire(case_visee)
	if conseil.is_empty():
		hide()
		return
	if _texte.text != conseil:
		_texte.text = conseil
		# Largeur fixe (300 px moins les marges du papier), hauteur mesurée : la fiche épouse son texte.
		Interface.caler_hauteur(_texte, 252.0)
		reset_size()
	show()
	position = (souris + Vector2(18, 20)).clamp(cadre.position, cadre.end - size)


# Aperçu de pose (benchmark D1) : effets de la place visée pour la pièce en main, seulement s'il y en a.
func _apercu(case_plateau: Vector2i) -> String:
	var piece: PieceDef = Run.reserve.trouver(_selection) as PieceDef
	if piece == null or not _source.plateau.peut_poser(case_plateau, piece):
		return ""
	var copie = _source.plateau.dupliquer()
	copie.poser(case_plateau, piece)
	var effets: PackedStringArray = Placement.effets(copie, _source.alimentees, case_plateau, piece, Run.regles)
	return "" if effets.is_empty() else tr("Aperçu de pose") + "\n" + "\n".join(effets)


func _decrire(case_plateau: Vector2i) -> String:
	if not _source.plateau.a_sol(case_plateau):
		return ""
	var piece: PieceDef = _source.plateau.piece_de(case_plateau)
	if piece == null:
		if _source.plateau.sol_de(case_plateau) == _source.Plateau.Sol.CHEMIN:
			return tr("Chemin des scarabées")
		return ""
	var texte: String = tr("%s\n%s") % [tr(piece.nom), PieceDef.decrire(piece)]
	if piece.type == PieceDef.Type.TOURELLE:
		var degats: float = piece.degats_tir * Placement.degats_tourelle(_source.plateau, case_plateau, Run.regles)
		texte += "\n" + tr("Portée %s m · Dégâts %s") % [String.num(piece.portee_tir), String.num(degats, 2)]
		texte += "\n" + (tr("Alimentée") if case_plateau in _source.alimentees else tr("Relie la tourelle à l’horloge"))
	if piece.type == PieceDef.Type.ATELIER:
		var etat: String = tr("Alimenté") if case_plateau in _source.alimentees else tr("Pas alimenté : relie-le à l’horloge")
		texte += "\n" + etat
	for effet: String in Placement.effets(_source.plateau, _source.alimentees, case_plateau, piece, Run.regles):
		texte += "\n" + effet
	if piece.type != PieceDef.Type.HORLOGE:
		texte += "\n" + (tr("R / clic droit : tourner (gratuit avant la vague 1)") if Run.prix_rotation == 0
				else tr("R / clic droit : tourner (%d ressorts)") % Run.prix_rotation)
		texte += "\n" + tr("Clic : ouvrir les actions de la pièce")
	return texte
