extends Node3D
## Projette la souris sur le plateau et applique la pose ou la rotation demandée.

const GrilleMonde = preload("res://game/board/grille_monde.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")
const PlateauVisuel = preload("res://game/board/plateau_visuel.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const ExtensionDef = preload("res://game/board/extension_def.gd")
const Extension = preload("res://game/board/extension.gd")

@onready var _source: PlateauNoeud = get_parent()
@onready var _visuel: PlateauVisuel = $"../PlateauVisuel"
var _choix: Resource
var _rotation: int = 0
var _fantome: Node3D
var _teinte := StandardMaterial3D.new()
var _case: Vector2i
var _case_verifiee: Vector2i
var _rotation_verifiee: int = -1


func _ready() -> void:
	_teinte.no_depth_test = true
	_teinte.render_priority = 1
	_teinte.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_teinte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Events.tuile_choisie.connect(_choisir)
	Events.phase_changee.connect(_changer_phase)
	Run.reserve.modifiee.connect(_verifier_stock)


func _changer_phase(phase: int) -> void:
	if phase != Run.Phase.CONSTRUCTION:
		Events.tuile_choisie.emit(&"")


func _verifier_stock() -> void:
	if _choix != null and Run.reserve.quantite(_choix.get("id")) == 0:
		Events.tuile_choisie.emit(&"")


func _choisir(id: StringName) -> void:
	if _fantome != null:
		_fantome.hide()
		_fantome.queue_free()
		_fantome = null
	_rotation = 0
	_rotation_verifiee = -1
	_choix = null
	if not id.is_empty() and Run.phase == Run.Phase.CONSTRUCTION:
		_choix = Run.reserve.trouver(id)
	if _choix is ExtensionDef:
		_fantome = _visuel.creer_extension(_choix, 0, _teinte)
	elif _choix is PieceDef:
		_fantome = _visuel.creer_piece(_choix, _choix.ports, _teinte)
	if _fantome != null:
		add_child(_fantome)
		_fantome.hide()


func _survoler() -> bool:
	var vue: Viewport = get_viewport()
	var souris: Vector2 = vue.get_mouse_position()
	if not vue.get_visible_rect().has_point(souris) or vue.gui_get_hovered_control() != null:
		return false
	var camera: Camera3D = vue.get_camera_3d()
	if camera == null:
		return false
	var point: Variant = Plane(Vector3.UP, 0).intersects_ray(
			camera.project_ray_origin(souris), camera.project_ray_normal(souris))
	if point == null:
		return false
	_case = GrilleMonde.vers_case(point)
	return true


func _process(_delta: float) -> void:
	if _fantome == null:
		return
	_fantome.visible = Run.phase == Run.Phase.CONSTRUCTION and _survoler()
	if _fantome.visible:
		var libre: bool
		if _choix is ExtensionDef:
			if _case == _case_verifiee and _rotation == _rotation_verifiee:
				return
			libre = Extension.est_valide(_source.plateau, _choix, _case, _rotation)
			_case_verifiee = _case
			_rotation_verifiee = _rotation
		else:
			libre = (_source.plateau.sol_de(_case) == _source.Plateau.Sol.HERBE
					and _source.plateau.piece_de(_case) == null)
		_teinte.albedo_color = Color("#3D8FD9", 0.62) if libre else Color(1, 0.2, 0.19, 0.65)
		_fantome.position = GrilleMonde.vers_monde(_case) + Vector3.UP * 0.05
		_fantome.rotation.y = -_rotation * PI / 2


func _unhandled_input(event: InputEvent) -> void:
	if Run.phase != Run.Phase.CONSTRUCTION:
		return
	if event.is_action_pressed("annuler"):
		Events.tuile_choisie.emit(&"")
	elif event.is_action_pressed("tourner_tuile"):
		if _choix != null:
			_rotation = (_rotation + 1) % 4
		elif _survoler():
			_source.plateau.tourner(_case)
	elif event.is_action_pressed("poser_tuile") and _choix != null and _survoler():
		var id: StringName = _choix.get("id")
		if Run.reserve.quantite(id) == 0:
			return
		if _choix is ExtensionDef:
			# Le retrait du dernier exemplaire peut effacer la sélection par signal.
			var extension: ExtensionDef = _choix
			if Extension.appliquer(_source.plateau, extension, _case, _rotation):
				_rotation_verifiee = -1
				Run.reserve.retirer(id)
				Run.reserve.ajouter_lots(extension.bonus)
		elif _choix is PieceDef and _source.plateau.poser(_case, _choix, _rotation):
			Run.reserve.retirer(id)
