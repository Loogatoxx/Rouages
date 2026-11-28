extends Node3D
## Cosmétiques de l'Établi (P2-40) : du décor pour la maquette, acheté avec des engrenages d'or, sans aucun effet
## sur le jeu. Nappe à carreaux sous la maquette, guirlande de fanions pastel tendue entre quatre mâts, lanternes de
## papier aux coins. Tout est placé d'après les bornes ACTUELLES du terrain : une extension agrandit la maquette, le
## décor suit (`actualiser`).
##
## Pourquoi du procédural : de petites formes simples (cylindres, triangles, sphères) suffisent à ces objets de
## décor, et elles restent dans la DA (laiton doux, pastels, lumière chaude) sans crédit de génération.

const Progression = preload("res://game/core/progression.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")
const Materiaux = preload("res://game/core/materiaux.gd")

const PASTELS: Array[Color] = [Color("#F2B5C4"), Color("#F5DC8A"), Color("#B8E0B0"), Color("#9EC3E6"), Color("#FFF3DE")]
## Recul des mâts et des lanternes depuis le bord du terrain (m), hauteur des mâts.
const RECUL := 0.7
const HAUTEUR_MAT := 2.0
## Écart entre deux fanions le long de la ficelle (m) et creux de la ficelle au milieu d'un côté.
const PAS_FANION := 0.8
const CREUX := 0.45

var _bornes := Rect2i()
var _lanternes: Array[Node3D] = []
var _temps: float = 0.0


## Reconstruit le décor acheté si les bornes du terrain ont changé.
func actualiser(sols: Array[Vector2i]) -> void:
	if sols.is_empty():
		return
	var mini := Vector2i(1 << 20, 1 << 20)
	var maxi := Vector2i(-(1 << 20), -(1 << 20))
	for case: Vector2i in sols:
		mini = mini.min(case)
		maxi = maxi.max(case)
	var bornes := Rect2i(mini, maxi - mini + Vector2i.ONE)
	if bornes == _bornes:
		return
	_bornes = bornes
	for enfant: Node in get_children():
		enfant.queue_free()
	_lanternes.clear()
	var demi: float = GrilleMonde.TAILLE_CASE / 2.0
	var rect := Rect2(Vector2(bornes.position) * GrilleMonde.TAILLE_CASE - Vector2.ONE * demi,
			Vector2(bornes.size) * GrilleMonde.TAILLE_CASE)
	if Progression.niveau(&"nappe") > 0:
		_poser_nappe(rect)
	var coins: Array[Vector2] = [rect.position + Vector2(-RECUL, -RECUL), Vector2(rect.end.x + RECUL, rect.position.y - RECUL),
			rect.end + Vector2(RECUL, RECUL), Vector2(rect.position.x - RECUL, rect.end.y + RECUL)]
	if Progression.niveau(&"guirlande") > 0:
		_poser_guirlande(coins)
	if Progression.niveau(&"lanternes") > 0:
		for coin: Vector2 in coins:
			_poser_lanterne(coin + (coin - rect.get_center()).normalized() * 0.5)


# Nappe : un drap fin qui dépasse de la maquette, à carreaux rose pâle et crème (calculés dans le shader).
func _poser_nappe(rect: Rect2) -> void:
	var drap := MeshInstance3D.new()
	var forme := BoxMesh.new()
	forme.size = Vector3(rect.size.x + 4.0, 0.03, rect.size.y + 4.0)
	drap.mesh = forme
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_back;
uniform vec3 creme = vec3(1.0, 0.95, 0.87);
uniform vec3 rose = vec3(0.90, 0.52, 0.60);
varying vec3 monde;
void vertex() { monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// Vichy : deux bandes croisées de 0,5 m ; leur croisement est plus soutenu.
	float a = step(0.5, fract(monde.x)) ;
	float b = step(0.5, fract(monde.z));
	ALBEDO = mix(creme, rose, 0.5 * (a + b));
	ROUGHNESS = 0.9;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	drap.material_override = mat
	drap.position = Vector3(rect.get_center().x, -0.235, rect.get_center().y)
	add_child(drap)


# Guirlande : un mât de laiton à chaque coin, une ficelle qui pend entre deux mâts, des fanions triangulaires pastel.
func _poser_guirlande(coins: Array[Vector2]) -> void:
	var laiton: Material = Materiaux.obtenir("laiton")
	for coin: Vector2 in coins:
		var mat_ := MeshInstance3D.new()
		var tige := CylinderMesh.new()
		tige.top_radius = 0.045
		tige.bottom_radius = 0.06
		tige.height = HAUTEUR_MAT
		mat_.mesh = tige
		mat_.material_override = laiton
		mat_.position = Vector3(coin.x, -0.25 + HAUTEUR_MAT / 2.0, coin.y)
		add_child(mat_)
		var pommeau := MeshInstance3D.new()
		var boule := SphereMesh.new()
		boule.radius = 0.08
		boule.height = 0.16
		pommeau.mesh = boule
		pommeau.material_override = laiton
		pommeau.position = Vector3(coin.x, -0.25 + HAUTEUR_MAT + 0.05, coin.y)
		add_child(pommeau)
	var fanion := PrismMesh.new()
	fanion.size = Vector3(0.42, 0.48, 0.015)
	var couleurs: Array[StandardMaterial3D] = []
	for c: Color in PASTELS:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		couleurs.append(m)
	var haut: float = -0.25 + HAUTEUR_MAT - 0.08
	var n: int = 0
	for k: int in coins.size():
		var a: Vector2 = coins[k]
		var b: Vector2 = coins[(k + 1) % coins.size()]
		var longueur: float = a.distance_to(b)
		var nombre: int = maxi(2, int(longueur / PAS_FANION))
		var cap: float = atan2(-(b.x - a.x), -(b.y - a.y))
		for i: int in range(1, nombre):
			var t: float = float(i) / nombre
			var lieu: Vector2 = a.lerp(b, t)
			var drapeau := MeshInstance3D.new()
			drapeau.mesh = fanion
			drapeau.material_override = couleurs[n % couleurs.size()]
			drapeau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Pointe en bas, à plat dans le plan de la ficelle, accroché sous la ficelle qui pend.
			drapeau.position = Vector3(lieu.x, haut - CREUX * sin(PI * t) - 0.24, lieu.y)
			drapeau.rotation = Vector3(0.0, cap + PI / 2.0, PI)
			add_child(drapeau)
			n += 1


# Lanterne de papier : un petit mât, une boule chaude qui luit, une lumière douce qui ne porte pas d'ombre.
func _poser_lanterne(lieu: Vector2) -> void:
	var support := Node3D.new()
	support.position = Vector3(lieu.x, -0.25, lieu.y)
	add_child(support)
	var tige := MeshInstance3D.new()
	var forme := CylinderMesh.new()
	forme.top_radius = 0.03
	forme.bottom_radius = 0.05
	forme.height = 1.6
	tige.mesh = forme
	tige.material_override = Materiaux.obtenir("bois_clair")
	tige.position.y = 0.8
	support.add_child(tige)
	var balancier := Node3D.new()
	balancier.position.y = 1.6
	support.add_child(balancier)
	var papier := StandardMaterial3D.new()
	papier.albedo_color = Color("#FFD9A0")
	papier.emission_enabled = true
	papier.emission = Color("#FFB866")
	papier.emission_energy_multiplier = 3.0
	var globe := MeshInstance3D.new()
	var boule := SphereMesh.new()
	boule.radius = 0.32
	boule.height = 0.52
	globe.mesh = boule
	globe.material_override = papier
	globe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	globe.position.y = -0.3
	balancier.add_child(globe)
	var lumiere := OmniLight3D.new()
	lumiere.light_color = Color("#FFC27A")
	lumiere.light_energy = 1.0
	lumiere.omni_range = 3.5
	lumiere.position.y = -0.2
	balancier.add_child(lumiere)
	_lanternes.append(balancier)


# Les lanternes se balancent doucement, chacune à son rythme.
func _process(delta: float) -> void:
	_temps += delta
	for k: int in _lanternes.size():
		_lanternes[k].rotation.z = 0.06 * sin(_temps * 1.3 + k * 1.7)
		_lanternes[k].rotation.x = 0.04 * sin(_temps * 0.9 + k)
