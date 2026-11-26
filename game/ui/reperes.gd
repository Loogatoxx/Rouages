extends Control
## Repères au bord de l'écran : entrées des ennemis et ennemis hors champ (playtest 1 : « impossible de savoir où regarder »).
##
## Une entrée hors champ s'affiche en panneau fléché collé au bord, tourné vers elle ; pendant une vague, les ennemis hors
## champ sont regroupés par direction (16 secteurs) en pastilles rouges numérotées. Rien n'est dessiné pour ce qui est
## déjà visible : le plateau reste dégagé.

const GrilleMonde = preload("res://game/board/grille_monde.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const ICONE_ENTREE: Texture2D = preload("res://assets/ui/icones/entree.png")
const MARGE := 46.0
const SECTEURS := 16

var plateau_noeud: Node
var partie: Node
var _entrees: Array[Vector2i] = []
var _police: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_police = get_theme_default_font()
	Events.plateau_modifie.connect(_actualiser_entrees)
	_actualiser_entrees.call_deferred()


func _actualiser_entrees() -> void:
	if plateau_noeud != null and plateau_noeud.plateau != null:
		_entrees = ChampFlux.entrees(plateau_noeud.plateau, ChampFlux.calculer(plateau_noeud.plateau))


func _process(_delta: float) -> void:
	queue_redraw()


# Point du bord (cadre réduit de MARGE) dans la direction du point écran, depuis le centre ; null si déjà visible.
func _au_bord(camera: Camera3D, monde: Vector3) -> Variant:
	# Cadre intérieur qui évite la barre du haut et la réserve du bas.
	var cadre := Rect2(MARGE, MARGE + 60.0, size.x - MARGE * 2.0, size.y - MARGE * 2.0 - 160.0)
	var centre: Vector2 = cadre.get_center()
	var ecran: Vector2 = camera.unproject_position(monde)
	if camera.is_position_behind(monde):
		ecran = centre - (ecran - centre) * 1000.0
	elif cadre.has_point(ecran):
		return null
	var direction: Vector2 = (ecran - centre).normalized()
	var echelle: float = INF
	if absf(direction.x) > 0.001:
		echelle = minf(echelle, (cadre.size.x / 2.0) / absf(direction.x))
	if absf(direction.y) > 0.001:
		echelle = minf(echelle, (cadre.size.y / 2.0) / absf(direction.y))
	return centre + direction * echelle


func _draw() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or size.x <= MARGE * 2.0 or size.y <= MARGE * 2.0 + 160.0 \
			or not Run.phase in [Run.Phase.CONSTRUCTION, Run.Phase.VAGUE]:
		return
	var centre: Vector2 = Rect2(MARGE, MARGE + 60.0, size.x - MARGE * 2.0, size.y - MARGE * 2.0 - 160.0).get_center()
	for case: Vector2i in _entrees:
		var bord: Variant = _au_bord(camera, GrilleMonde.vers_monde(case))
		if bord == null:
			continue
		# Panneau toujours droit (pivoté, son poteau semblait couché : audit UI), flèche de laiton vers l'entrée.
		var direction: Vector2 = (bord - centre).normalized()
		var pointe: Vector2 = bord + direction * 6.0
		var cote: Vector2 = direction.orthogonal() * 9.0
		var base: Vector2 = pointe - direction * 14.0
		draw_colored_polygon(PackedVector2Array([pointe + direction * 2.0, base + cote * 1.25, base - cote * 1.25]), Color("#3B2618"))
		draw_colored_polygon(PackedVector2Array([pointe, base + cote, base - cote]), Color("#D9AE54"))
		draw_texture_rect(ICONE_ENTREE, Rect2(bord - direction * 30.0 - Vector2(22, 22), Vector2(44, 44)), false)
	if Run.phase != Run.Phase.VAGUE or partie == null:
		return
	var comptes: PackedInt32Array = PackedInt32Array()
	comptes.resize(SECTEURS)
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(SECTEURS)
	for position: Vector2 in partie.sim.positions(SwarmSim.ENNEMI):
		var bord: Variant = _au_bord(camera, Vector3(position.x, 0.0, position.y))
		if bord == null:
			continue
		var secteur: int = posmod(roundi((bord - centre).angle() / TAU * SECTEURS), SECTEURS)
		comptes[secteur] += 1
		points[secteur] = bord
	for i: int in SECTEURS:
		if comptes[i] == 0:
			continue
		var point: Vector2 = points[i] - (points[i] - centre).normalized() * 30.0
		draw_circle(point, 15.0, Color("#3B2618"))
		draw_circle(point, 13.0, Color("#D66355"))
		var texte: String = str(comptes[i])
		var largeur: float = _police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(_police, point + Vector2(-largeur / 2.0, 5.5), texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
