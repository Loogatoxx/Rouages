extends Camera3D
## Cadre le plateau autour d'une cible mobile et interpole entre ses deux vues.

const DUREE_SECOUSSE := 0.25

var _secousse: float = 0.0
var _cible := Vector3.ZERO
var _cadre: float = 21.0
var _inclinee: bool = false
var _melange: float = 0.0
var _transition: Tween


func _ready() -> void:
	Events.horloge_touchee.connect(_sur_horloge_touchee)
	near = 0.5
	_appliquer_vue()


func _process(delta: float) -> void:
	_secousse = maxf(0.0, _secousse - delta)
	var mouvement: Vector2 = Input.get_vector("camera_gauche", "camera_droite", "camera_haut", "camera_bas")
	_cible += Vector3(mouvement.x, 0, mouvement.y) * _cadre * 0.55 * delta
	_cible = _cible.clamp(Vector3(-24, 0, -24), Vector3(24, 0, 24))
	_appliquer_vue()


func _appliquer_vue() -> void:
	var angle: float = deg_to_rad(lerpf(80.0, 50.0, _melange))
	var distance: float = _cadre
	if _melange <= 0:
		projection = PROJECTION_ORTHOGONAL
		size = _cadre
	else:
		projection = PROJECTION_PERSPECTIVE
		# Un champ très étroit rejoint la vue orthographique sans saut de cadrage.
		fov = lerpf(1.0, 48.0, _melange)
		distance = _cadre / (2 * tan(deg_to_rad(fov) / 2))
	position = _cible + Vector3(0, sin(angle), cos(angle)) * distance
	rotation.x = -angle
	if _secousse > 0.0:
		var reste: float = _secousse / DUREE_SECOUSSE
		var phase: float = (1.0 - reste) * TAU * 2.0
		position += basis * Vector3(sin(phase), 0.35 * sin(phase * 1.5), 0) * 0.15 * reste


func _sur_horloge_touchee(_pv_restants: int) -> void:
	_secousse = DUREE_SECOUSSE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("basculer_camera"):
		_inclinee = not _inclinee
		if _transition:
			_transition.kill()
		_transition = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_transition.tween_property(self, "_melange", 1.0 if _inclinee else 0.0, 0.4)
	elif event.is_action_pressed("camera_zoom_avant"):
		_cadre = maxf(8, _cadre / 1.15)
	elif event.is_action_pressed("camera_zoom_arriere"):
		_cadre = minf(34, _cadre * 1.15)
