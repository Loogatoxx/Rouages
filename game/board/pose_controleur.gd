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
## Anneau de portée au sol (P2-21) : à la pose d'une tourelle, sur la tourelle choisie ou survolée.
var _portee: Node3D = Node3D.new()
var _rayon_portee: float = -1.0
## Playtest 3 : atelier dont on choisit le poste de garde (le prochain clic sur une route à portée y plante son
## drapeau), et repères au sol des cases possibles.
const SANS_ATELIER := Vector2i(-99999, -99999)
var _atelier_drapeau: Vector2i = SANS_ATELIER
var _reperes_drapeau: Node3D
## Coup de carillon : vrai pendant que le joueur vise (un anneau suit la souris, le clic fait sonner l'Horloge).
var _vise_carillon: bool = false
var _anneau_carillon: MeshInstance3D


func _ready() -> void:
	var couche: CanvasLayer = CanvasLayer.new()
	couche.layer = 6
	add_child(couche)
	couche.add_child(_panneau)
	add_child(_portee)
	_portee.hide()
	_teinte.no_depth_test = true
	_teinte.render_priority = 1
	_teinte.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_teinte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_panneau.poste_demande.connect(_choisir_poste)
	Events.carillon_vise.connect(_viser_carillon)
	Events.tuile_choisie.connect(_choisir)
	Events.phase_changee.connect(_changer_phase)
	Events.plateau_modifie.connect(_actualiser_marqueurs)
	Run.reserve.modifiee.connect(_verifier_stock)


func _pose_autorisee(phase: int) -> bool:
	return phase == Run.Phase.CONSTRUCTION or phase == Run.Phase.VAGUE


# Entre dans le choix du poste de garde de l'atelier `case` : les cases de route à portée sont surlignées.
func _choisir_poste(case: Vector2i) -> void:
	_quitter_poste()
	Events.tuile_choisie.emit(&"")
	_atelier_drapeau = case
	_reperes_drapeau = Node3D.new()
	add_child(_reperes_drapeau)
	var bleu := StandardMaterial3D.new()
	bleu.albedo_color = Color("#6FB1E8", 0.6)
	bleu.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bleu.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var dalle := BoxMesh.new()
	dalle.size = Vector3(GrilleMonde.TAILLE_CASE * 0.82, 0.04, GrilleMonde.TAILLE_CASE * 0.82)
	var portee: int = _source.plateau.PORTEE_POSTE
	for dx: int in range(-portee, portee + 1):
		for dy: int in range(-portee, portee + 1):
			var route: Vector2i = case + Vector2i(dx, dy)
			if _source.plateau.poste_possible(case, route):
				var repere := MeshInstance3D.new()
				repere.mesh = dalle
				repere.material_override = bleu
				repere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				repere.position = GrilleMonde.vers_monde(route) + Vector3.UP * 0.07
				_reperes_drapeau.add_child(repere)
	Events.message_joueur.emit(tr("Clique sur une case de route en bleu : l’escouade ira tenir ce poste."))


# Entre (ou sort) du mode « viser le coup de carillon », s'il est prêt.
func _viser_carillon() -> void:
	var partie: Node = get_tree().get_first_node_in_group(&"partie")
	if _vise_carillon or partie == null or Run.phase != Run.Phase.VAGUE:
		_quitter_carillon()
		return
	if partie.carillon_attente > 0.0:
		Events.message_joueur.emit(tr("Le carillon se remonte : encore %d s.") % ceili(partie.carillon_attente))
		return
	_quitter_poste()
	Events.tuile_choisie.emit(&"")
	_vise_carillon = true
	if _anneau_carillon == null:
		_anneau_carillon = MeshInstance3D.new()
		var disque := CylinderMesh.new()
		disque.top_radius = Run.regles.carillon_rayon
		disque.bottom_radius = Run.regles.carillon_rayon
		disque.height = 0.03
		disque.radial_segments = 48
		_anneau_carillon.mesh = disque
		var voile := StandardMaterial3D.new()
		voile.albedo_color = Color(1.0, 0.82, 0.3, 0.32)
		voile.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		voile.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_anneau_carillon.material_override = voile
		_anneau_carillon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_anneau_carillon)
	_anneau_carillon.show()


func _quitter_carillon() -> void:
	_vise_carillon = false
	if _anneau_carillon != null:
		_anneau_carillon.hide()


# Point du plateau sous la souris, en mètres (sans arrondir à la case) ; `Vector2.INF` hors du plateau ou sur l'interface.
func _point_souris() -> Vector2:
	var vue: Viewport = get_viewport()
	var souris: Vector2 = vue.get_mouse_position()
	var camera: Camera3D = vue.get_camera_3d()
	if camera == null or not vue.get_visible_rect().has_point(souris) or vue.gui_get_hovered_control() != null:
		return Vector2.INF
	var point: Variant = Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(souris), camera.project_ray_normal(souris))
	# Hors du plateau (sur l'établi) : pas de cible, la recharge n'est pas consommée (relecture T14c).
	if point == null or not _source.plateau.a_sol(GrilleMonde.vers_case(point)):
		return Vector2.INF
	return Vector2(point.x, point.z)


func _quitter_poste() -> void:
	_atelier_drapeau = SANS_ATELIER
	if _reperes_drapeau != null:
		_reperes_drapeau.queue_free()
		_reperes_drapeau = null


func _changer_phase(phase: int) -> void:
	_quitter_poste()
	_quitter_carillon()
	_panneau.fermer()
	if not _pose_autorisee(phase):
		Events.tuile_choisie.emit(&"")


func _verifier_stock() -> void:
	if _choix != null and Run.reserve.quantite(_choix.get("id")) == 0:
		Events.tuile_choisie.emit(&"")


func _choisir(id: StringName) -> void:
	if id != &"":
		_quitter_poste()
		_quitter_carillon()  # relecture T14c : une pièce prise en main annule la visée
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
	if _vise_carillon and _anneau_carillon != null:
		var point: Vector2 = _point_souris()
		_anneau_carillon.visible = point != Vector2.INF
		if point != Vector2.INF:
			_anneau_carillon.position = Vector3(point.x, 0.09, point.y)
	_afficher_portee()
	if _fantome == null:
		return
	_fantome.visible = _pose_autorisee(Run.phase) and _survoler()
	if _fantome.visible:
		var libre: bool
		if _choix is ExtensionDef:
			libre = _orienter_extension()
			_actualiser_fantome_extension(libre)
		else:
			libre = _source.plateau.peut_poser(_case, _choix)
		_teinte.albedo_color = Color("#3D8FD9", 0.62) if libre else Color(1, 0.2, 0.19, 0.65)
		_fantome.position = GrilleMonde.vers_monde(_case) + Vector3.UP * 0.05
		# L'aperçu d'extension est déjà construit dans son orientation (raccord compris).
		_fantome.rotation.y = 0.0 if _choix is ExtensionDef else -_rotation * PI / 2


# Montre la portée de la tourelle concernée : celle qu'on pose, sinon celle du panneau ouvert, sinon celle survolée.
func _afficher_portee() -> void:
	var piece: PieceDef = null
	var case: Vector2i
	if _fantome != null and _fantome.visible and _choix is PieceDef:
		piece = _choix
		case = _case
	elif _panneau.visible and _source.plateau.piece_de(_panneau._case) != null:
		piece = _source.plateau.piece_de(_panneau._case)
		case = _panneau._case
	elif _choix == null and _survoler():
		piece = _source.plateau.piece_de(_case)
		case = _case
	if piece == null or piece.type != PieceDef.Type.TOURELLE or piece.portee_tir <= 0.0:
		_portee.hide()
		return
	if not is_equal_approx(_rayon_portee, piece.portee_tir):
		_construire_portee(piece.portee_tir)
	_portee.position = GrilleMonde.vers_monde(case) + Vector3.UP * 0.12
	_portee.show()


# Disque translucide + liseré : lisible en vue de dessus comme en vue inclinée, sans masquer les unités.
func _construire_portee(rayon: float) -> void:
	_rayon_portee = rayon
	for ancien: Node in _portee.get_children():
		ancien.queue_free()
	var disque := MeshInstance3D.new()
	var cylindre := CylinderMesh.new()
	cylindre.top_radius = rayon
	cylindre.bottom_radius = rayon
	cylindre.height = 0.02
	cylindre.radial_segments = 64
	disque.mesh = cylindre
	var voile := StandardMaterial3D.new()
	voile.albedo_color = Color(1, 0.93, 0.7, 0.16)
	voile.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	voile.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	voile.cull_mode = BaseMaterial3D.CULL_DISABLED
	disque.material_override = voile
	disque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_portee.add_child(disque)
	var bord := MeshInstance3D.new()
	var tore := TorusMesh.new()
	tore.inner_radius = rayon - 0.07
	tore.outer_radius = rayon
	tore.rings = 96
	tore.ring_segments = 6
	bord.mesh = tore
	var laiton := StandardMaterial3D.new()
	laiton.albedo_color = Color(0.83, 0.66, 0.29, 0.85)
	laiton.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	laiton.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bord.material_override = laiton
	bord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bord.scale = Vector3(1, 0.15, 1)
	_portee.add_child(bord)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("coup_carillon"):
		_viser_carillon()
		get_viewport().set_input_as_handled()
		return
	if _vise_carillon:
		if event.is_action_pressed("annuler") or event.is_action_pressed("tourner_tuile"):
			_quitter_carillon()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("poser_tuile"):
			var point: Vector2 = _point_souris()
			var partie: Node = get_tree().get_first_node_in_group(&"partie")
			if point != Vector2.INF and partie != null and partie.sonner_carillon(point):
				_quitter_carillon()
			get_viewport().set_input_as_handled()
		return
	if _atelier_drapeau != SANS_ATELIER:
		if event.is_action_pressed("annuler") or event.is_action_pressed("tourner_tuile"):
			_quitter_poste()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("poser_tuile") and _survoler():
			if _source.plateau.definir_poste(_atelier_drapeau, _case):
				Sons.jouer(&"pose", 0.05)
				_quitter_poste()
			else:
				Events.message_joueur.emit(tr("Le poste doit être une case de route à 3 cases de l’atelier au plus."))
			get_viewport().set_input_as_handled()
		return
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
		elif _choix is PieceDef and _choix.unique and _source.plateau.coords_pieces().any(
				func(c: Vector2i) -> bool: return _source.plateau.piece_de(c) == _choix):
			Events.message_joueur.emit(tr("Un seul Générateur par plateau."))
