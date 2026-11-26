extends Node3D
## Projette la souris sur le plateau et applique la pose ou la rotation demandée.

const PanneauPiece = preload("res://game/ui/panneau_piece.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")
const PlateauVisuel = preload("res://game/board/plateau_visuel.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const ExtensionDef = preload("res://game/board/extension_def.gd")
const Extension = preload("res://game/board/extension.gd")

@onready var _source: PlateauNoeud = get_parent()
@onready var _visuel: PlateauVisuel = $"../PlateauVisuel"
var _panneau: PanneauPiece = PanneauPiece.new()
var _choix: Resource
var _rotation: int = 0
var _fantome: Node3D
var _teinte := StandardMaterial3D.new()
var _case: Vector2i
var _rotations_valides: Dictionary[Vector2i, int] = {}


func _ready() -> void:
	var couche: CanvasLayer = CanvasLayer.new()
	couche.layer = 6
	add_child(couche)
	couche.add_child(_panneau)
	_teinte.no_depth_test = true
	_teinte.render_priority = 1
	_teinte.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_teinte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Events.tuile_choisie.connect(_choisir)
	Events.phase_changee.connect(_changer_phase)
	Events.plateau_modifie.connect(_actualiser_marqueurs)
	Run.reserve.modifiee.connect(_verifier_stock)


func _pose_autorisee(phase: int) -> bool:
	return phase == Run.Phase.CONSTRUCTION or phase == Run.Phase.VAGUE


func _changer_phase(phase: int) -> void:
	_panneau.fermer()
	if not _pose_autorisee(phase):
		Events.tuile_choisie.emit(&"")


func _verifier_stock() -> void:
	if _choix != null and Run.reserve.quantite(_choix.get("id")) == 0:
		Events.tuile_choisie.emit(&"")


func _choisir(id: StringName) -> void:
	_panneau.fermer()
	if _fantome != null:
		_fantome.hide()
		_fantome.queue_free()
		_fantome = null
	_rotation = 0
	_choix = null
	if not id.is_empty() and _pose_autorisee(Run.phase):
		_choix = Run.reserve.trouver(id)
	_actualiser_marqueurs()
	if _choix is ExtensionDef:
		_fantome = _visuel.creer_extension(_choix, 0, _teinte)
	elif _choix is PieceDef:
		_fantome = _visuel.creer_piece(_choix, _choix.ports, _teinte)
	if _fantome != null:
		add_child(_fantome)
		_fantome.hide()


func _actualiser_marqueurs() -> void:
	if not _choix is ExtensionDef and _rotations_valides.is_empty():
		return
	_rotations_valides.clear()
	var cases: Array[Vector2i] = []
	if _choix is ExtensionDef:
		var plateau: Extension.Plateau = _source.plateau
		var candidats: Dictionary[Vector2i, bool] = {}
		for sol: Vector2i in plateau.coords_sols():
			if plateau.a_sol(sol + Vector2i.UP) and plateau.a_sol(sol + Vector2i.DOWN) \
					and plateau.a_sol(sol + Vector2i.LEFT) and plateau.a_sol(sol + Vector2i.RIGHT):
				continue
			for x: int in range(-2, 3):
				for y: int in range(-2, 3):
					var centre: Vector2i = sol + Vector2i(x, y)
					if not plateau.a_sol(centre):
						candidats[centre] = true
		for centre: Vector2i in candidats:
			var masque: int = 0
			for tour: int in 4:
				if Extension.est_valide(plateau, _choix, centre, tour):
					masque |= 1 << tour
			if masque != 0:
				_rotations_valides[centre] = masque
				cases.append(centre)
	_visuel.afficher_marqueurs(cases)


func _orienter_extension() -> bool:
	var masque: int = _rotations_valides.get(_case, 0)
	if masque == 0:
		return false
	if not (masque & (1 << _rotation)):
		for tour: int in 4:
			if masque & (1 << tour):
				_rotation = tour
				break
	return true


# Reconstruit l'aperçu d'extension quand la case ou l'orientation change, avec le raccord pavé jusqu'à la route.
func _actualiser_fantome_extension(valide: bool) -> void:
	var cle := Vector3i(_case.x, _case.y, _rotation if valide else -1)
	if _fantome.get_meta(&"cle", Vector3i(0, 0, -2)) == cle:
		return
	var raccord: Array[Vector2i] = []
	if valide:
		for case: Vector2i in Extension.raccord(_source.plateau, _choix, _case, _rotation):
			raccord.append(case - _case)
	var nouveau: Node3D = _visuel.creer_extension(_choix, _rotation if valide else 0, _teinte, raccord)
	nouveau.set_meta(&"cle", cle)
	_fantome.queue_free()
	_fantome = nouveau
	add_child(_fantome)


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
	_fantome.visible = _pose_autorisee(Run.phase) and _survoler()
	if _fantome.visible:
		var libre: bool
		if _choix is ExtensionDef:
			libre = _orienter_extension()
			_actualiser_fantome_extension(libre)
		else:
			libre = (_source.plateau.sol_de(_case) == _source.Plateau.Sol.HERBE
					and _source.plateau.piece_de(_case) == null)
		_teinte.albedo_color = Color("#3D8FD9", 0.62) if libre else Color(1, 0.2, 0.19, 0.65)
		_fantome.position = GrilleMonde.vers_monde(_case) + Vector3.UP * 0.05
		# L'aperçu d'extension est déjà construit dans son orientation (raccord compris).
		_fantome.rotation.y = 0.0 if _choix is ExtensionDef else -_rotation * PI / 2


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("annuler"):
		if _choix != null:
			Events.tuile_choisie.emit(&"")
			get_viewport().set_input_as_handled()
		else:
			Events.pause_demandee.emit()
		return
	if not _pose_autorisee(Run.phase):
		return
	if event.is_action_pressed("tourner_tuile"):
		if _choix != null:
			_rotation = (_rotation + 1) % 4
			if _choix is ExtensionDef and _survoler() and _rotations_valides.has(_case):
				while not (_rotations_valides[_case] & (1 << _rotation)):
					_rotation = (_rotation + 1) % 4
			Sons.jouer(&"rotation")
		elif _survoler() and _source.plateau.piece_de(_case) != null:
			if Run.tourner_piece(_source.plateau, _case):
				_panneau.fermer()
				Sons.jouer(&"rotation")
			elif _source.plateau.piece_de(_case).type != PieceDef.Type.HORLOGE:
				Events.message_joueur.emit(tr("Tourner coûte %d ressorts") % Run.prix_rotation)
	elif event.is_action_pressed("poser_tuile") and _survoler():
		if _choix == null:
			if _source.plateau.piece_de(_case) != null:
				_panneau.ouvrir(_source.plateau, _case)
			return
		var id: StringName = _choix.get("id")
		if Run.reserve.quantite(id) == 0:
			return
		if _choix is ExtensionDef:
			# Le retrait du dernier exemplaire peut effacer la sélection par signal.
			var extension: ExtensionDef = _choix
			if not _orienter_extension():
				Events.message_joueur.emit(tr("Pose l’extension contre le bord sur un repère"))
			elif Extension.appliquer(_source.plateau, extension, _case, _rotation):
				Run.reserve.retirer(id)
				Run.reserve.ajouter_lots(extension.bonus)
				Run.poser_extension(extension.ressorts, extension.revenu)
				Sons.jouer(&"pose", 0.05)
		elif _choix is PieceDef and _source.plateau.poser(_case, _choix, _rotation):
			Run.reserve.retirer(id)
			Sons.jouer(&"pose", 0.05)
