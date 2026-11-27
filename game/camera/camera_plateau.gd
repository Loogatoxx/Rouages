extends Camera3D
## Cadre le plateau autour d'une cible mobile : zoom, inclinaison réglable et bascule vue de dessus / vue inclinée.

const DUREE_SECOUSSE := 0.25
const CADRE_MIN := 6.0
const CADRE_MAX := 44.0
## Inclinaison de la vue « maquette » en degrés au-dessus du plateau : 30 = rasante, 80 = presque de dessus.
const INCLINAISON_MIN := 30.0
const INCLINAISON_MAX := 80.0

var _secousse: float = 0.0
var _cible := Vector3.ZERO
## Cadre visé (largeur de plateau visible, en mètres) et cadre affiché, qui le rejoint en douceur.
var _cadre_vise: float = 21.0
var _cadre: float = 21.0
var _inclinaison: float = 54.0
## Vue inclinée par défaut : le plateau est une maquette en volume (DA v2) ; la vue de dessus reste à un raccourci.
var _inclinee: bool = true
var _melange: float = 1.0
var _transition: Tween
var _glisse_inclinaison: bool = false


func _ready() -> void:
	Events.horloge_touchee.connect(_sur_horloge_touchee)
	near = 0.5
	_appliquer_vue()
	_cadrer_plateau.call_deferred()


# Playtest 3 (« le jeu paraît vide ») : le plateau n'occupait qu'un tiers de l'écran. Au lancement, la caméra se
# centre sur le terrain et choisit le cadre qui le fait tenir en hauteur (environ 80 % de l'écran), quelle que soit
# la taille de la carte. Le joueur garde ensuite la main (zoom, déplacement).
func _cadrer_plateau() -> void:
	var noeud: Node = get_tree().get_first_node_in_group(&"plateau_noeud")
	if noeud == null or noeud.plateau == null:
		return
	var mini := Vector2i(1 << 20, 1 << 20)
	var maxi := Vector2i(-(1 << 20), -(1 << 20))
	for case: Vector2i in noeud.plateau.coords_sols():
		mini = mini.min(case)
		maxi = maxi.max(case)
	if mini.x > maxi.x:
		return
	var taille: Vector2 = Vector2(maxi - mini + Vector2i.ONE) * 2.0
	var centre: Vector2 = Vector2(mini + maxi) * 1.0
	# En vue inclinée, la profondeur du plateau est vue en raccourci ; la largeur doit aussi tenir (écran 16:9).
	_cadre_vise = clampf(maxf(taille.y * 1.02, taille.x * 0.64), CADRE_MIN, CADRE_MAX)
	_cadre = _cadre_vise
	_cible = Vector3(centre.x, 0, centre.y + 0.6)
	_appliquer_vue()


func _process(delta: float) -> void:
	_secousse = maxf(0.0, _secousse - delta)
	var mouvement: Vector2 = Input.get_vector("camera_gauche", "camera_droite", "camera_haut", "camera_bas")
	_cible += Vector3(mouvement.x, 0, mouvement.y) * _cadre * 0.55 * delta
	_cible = _cible.clamp(Vector3(-24, 0, -24), Vector3(24, 0, 24))
	var tourner: float = Input.get_axis("camera_coucher", "camera_redresser")
	if tourner != 0.0:
		_inclinaison = clampf(_inclinaison + tourner * 45.0 * delta, INCLINAISON_MIN, INCLINAISON_MAX)
	# Lissage exponentiel : le zoom suit la molette sans à-coup, quelle que soit la cadence d'images.
	_cadre = lerpf(_cadre, _cadre_vise, 1.0 - exp(-12.0 * delta))
	_appliquer_vue()


func _appliquer_vue() -> void:
	var angle: float = deg_to_rad(lerpf(80.0, _inclinaison, _melange))
	var distance: float = _cadre
	if _melange <= 0:
		projection = PROJECTION_ORTHOGONAL
		size = _cadre
	else:
		projection = PROJECTION_PERSPECTIVE
		# Un champ très étroit rejoint la vue orthographique sans saut de cadrage.
		fov = lerpf(1.0, 40.0, _melange)
		distance = _cadre / (2 * tan(deg_to_rad(fov) / 2))
	position = _cible + Vector3(0, sin(angle), cos(angle)) * distance
	rotation.x = -angle
	if _secousse > 0.0:
		var reste: float = _secousse / DUREE_SECOUSSE
		var phase: float = (1.0 - reste) * TAU * 2.0
		position += basis * Vector3(sin(phase), 0.35 * sin(phase * 1.5), 0) * 0.15 * reste


func _sur_horloge_touchee(_pv_restants: int) -> void:
	_secousse = DUREE_SECOUSSE


## Zoome d'un facteur (< 1 = rapproche) en glissant vers le point visé : on zoome « là où on regarde ».
func zoomer(facteur: float, ecran: Vector2 = Vector2(-1, -1)) -> void:
	var avant: float = _cadre_vise
	_cadre_vise = clampf(_cadre_vise * facteur, CADRE_MIN, CADRE_MAX)
	if ecran.x < 0 or _cadre_vise >= avant:
		return
	var point: Variant = Plane(Vector3.UP, 0).intersects_ray(project_ray_origin(ecran), project_ray_normal(ecran))
	if point != null:
		_cible = _cible.lerp(point, 1.0 - _cadre_vise / avant)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("basculer_camera"):
		_inclinee = not _inclinee
		if _transition:
			_transition.kill()
		_transition = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_transition.tween_property(self, "_melange", 1.0 if _inclinee else 0.0, 0.4)
	elif event.is_action_pressed("camera_zoom_avant"):
		zoomer(1 / 1.15, get_viewport().get_mouse_position() if event is InputEventMouse else Vector2(-1, -1))
	elif event.is_action_pressed("camera_zoom_arriere"):
		zoomer(1.15)
	# Trackpad du Mac : le défilement à deux doigts et le pincement n'envoient pas d'événement molette.
	elif event is InputEventMagnifyGesture:
		zoomer(1.0 / event.factor, event.position)
	elif event is InputEventPanGesture:
		zoomer(1.0 + event.delta.y * 0.04, event.position)
	# Clic molette glissé verticalement : incline la maquette.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_glisse_inclinaison = event.pressed
	elif event is InputEventMouseMotion and _glisse_inclinaison:
		_inclinaison = clampf(_inclinaison + event.relative.y * 0.25, INCLINAISON_MIN, INCLINAISON_MAX)
