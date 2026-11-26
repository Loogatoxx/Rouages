extends PanelContainer
## Décrit la case sous la souris et indique si son atelier reçoit de l'énergie.

const GrilleMonde = preload("res://game/board/grille_monde.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")
const PieceDef = preload("res://game/board/piece_def.gd")

@export var plateau_noeud: NodePath
@onready var _source: PlateauNoeud = get_node(plateau_noeud)
@onready var _texte: Label = $Texte
var _selection: StringName = &""


func _ready() -> void:
	Events.tuile_choisie.connect(_choisir)


func _choisir(id: StringName) -> void:
	_selection = id


func _process(_delta: float) -> void:
	var vue: Viewport = get_viewport()
	var souris: Vector2 = vue.get_mouse_position()
	var cadre: Rect2 = vue.get_visible_rect()
	if (not _selection.is_empty() or get_tree().paused or Run.phase == Run.Phase.FIN
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
	var conseil: String = _decrire(GrilleMonde.vers_case(point))
	if conseil.is_empty():
		hide()
		return
	if _texte.text != conseil:
		_texte.text = conseil
		reset_size()
	show()
	position = (souris + Vector2(18, 20)).clamp(cadre.position, cadre.end - size)


func _decrire(case_plateau: Vector2i) -> String:
	if not _source.plateau.a_sol(case_plateau):
		return ""
	var piece: PieceDef = _source.plateau.piece_de(case_plateau)
	if piece == null:
		if _source.plateau.sol_de(case_plateau) == _source.Plateau.Sol.CHEMIN:
			return tr("Chemin des scarabées")
		return ""
	var texte: String = tr("%s\n%s") % [tr(piece.nom), tr(piece.description)]
	if piece.type == PieceDef.Type.ATELIER:
		var etat: String = tr("Alimenté") if case_plateau in _source.alimentees else tr("Pas alimenté : relie-le à l’horloge")
		texte += "\n" + etat
	return texte
