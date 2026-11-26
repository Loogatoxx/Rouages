extends Node3D
## Affiche les silhouettes des unités vivantes et les copeaux des ennemis cassés.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Materiaux = preload("res://game/core/materiaux.gd")
const TEINTES := ["jouet_rouge", "jouet_bleu", "jouet_vert", "jouet_prune"]

const DUREE_VOL := 0.18
const NOMBRE_BILLES := 48
const CREME := Color("#FFF3D6")

var sim: SwarmSim:
	set(valeur):
		if sim == valeur:
			return
		if sim != null:
			sim.tir.disconnect(_sur_tir)
		sim = valeur
		if sim != null:
			sim.tir.connect(_sur_tir)
var _billes: Array[MeshInstance3D] = []
var _departs := PackedVector2Array()
var _arrivees := PackedVector2Array()
var _ages := PackedFloat32Array()
var _prochaine_bille: int = 0
var _shader_carapace := Shader.new()
var _lots: Dictionary[StringName, MultiMesh] = {}
var _effectifs: Dictionary[StringName, int] = {}
var _eclats: Array[CPUParticles3D] = []
var _prochain_eclat: int = 0


func _ready() -> void:
	# Le blanc conserve le matériau de chaque surface, la couleur d’impact le remplace.
	_shader_carapace.code = """
		shader_type spatial;
		uniform vec4 teinte : source_color;
		uniform vec4 creme : source_color;
		uniform float metal;
		uniform float rugosite;
		varying vec3 couleur;
		void vertex() {
			couleur = COLOR.rgb;
		}
		void fragment() {
			ALBEDO = couleur.b < 0.99 ? creme.rgb : teinte.rgb;
			METALLIC = metal;
			ROUGHNESS = rugosite;
		}
	"""
	var sphere: SphereMesh = _sphere(0.12, 0.24)
	sphere.material = Materiaux.obtenir("laiton")
	_departs.resize(NOMBRE_BILLES)
	_arrivees.resize(NOMBRE_BILLES)
	_ages.resize(NOMBRE_BILLES)
	for i: int in NOMBRE_BILLES:
		var bille := MeshInstance3D.new()
		bille.mesh = sphere
		bille.hide()
		add_child(bille)
		_billes.append(bille)
	var copeau := BoxMesh.new()
	copeau.size = Vector3(0.08, 0.045, 0.12)
	var bois := StandardMaterial3D.new()
	bois.vertex_color_use_as_albedo = true
	copeau.material = bois
	var teintes := Gradient.new()
	teintes.colors = PackedColorArray([Color(Materiaux.COULEURS.pierre_creme), Color(Materiaux.COULEURS.laiton)])
	for i: int in 24:
		var eclat := CPUParticles3D.new()
		eclat.emitting = false
		eclat.one_shot = true
		eclat.amount = 10
		eclat.lifetime = 0.4
		eclat.explosiveness = 1.0
		eclat.direction = Vector3.UP
		eclat.spread = 65.0
		eclat.initial_velocity_min = 1.2
		eclat.initial_velocity_max = 2.6
		eclat.gravity = Vector3.DOWN * 8.0
		eclat.color_initial_ramp = teintes
		eclat.mesh = copeau
		add_child(eclat)
		_eclats.append(eclat)
	Events.ennemi_casse.connect(_sur_ennemi_casse)


func _sur_tir(depart: Vector2, arrivee: Vector2) -> void:
	if _billes.is_empty():
		return
	var i: int = _prochaine_bille
	_prochaine_bille = (i + 1) % NOMBRE_BILLES
	_departs[i] = depart
	_arrivees[i] = arrivee
	_ages[i] = 0.0
	_billes[i].position = Vector3(depart.x, 0.46, depart.y)
	_billes[i].show()


func _avancer_billes(delta: float) -> void:
	for i: int in _billes.size():
		var bille: MeshInstance3D = _billes[i]
		if not bille.visible:
			continue
		_ages[i] += delta
		var t: float = _ages[i] / DUREE_VOL
		if t >= 1.0:
			bille.hide()
			continue
		var lieu: Vector2 = _departs[i].lerp(_arrivees[i], t)
		var hauteur: float = lerpf(0.46, 0.22, t) + 0.5 * 4.0 * t * (1.0 - t)
		bille.position = Vector3(lieu.x, hauteur, lieu.y)


func _sur_ennemi_casse(lieu: Vector2) -> void:
	var eclat: CPUParticles3D = _eclats[_prochain_eclat]
	_prochain_eclat = (_prochain_eclat + 1) % _eclats.size()
	eclat.position = Vector3(lieu.x, 0.2, lieu.y)
	eclat.restart()
	eclat.emitting = true


# Chaque pièce garde son matériau, mais toutes partagent la transformation de l'unité.
func _ajouter_piece(forme: ArrayMesh, piece: PrimitiveMesh, hauteur: float, mat: Material) -> void:
	var surface: Array = piece.get_mesh_arrays()
	var sommets: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
	for i: int in sommets.size():
		sommets[i].y += hauteur
	surface[Mesh.ARRAY_VERTEX] = sommets
	forme.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	forme.surface_set_material(forme.get_surface_count() - 1, mat)


func _cylindre(rayon: float, hauteur: float) -> CylinderMesh:
	var volume := CylinderMesh.new()
	volume.top_radius = rayon
	volume.bottom_radius = rayon
	volume.height = hauteur
	volume.radial_segments = 16
	volume.rings = 0
	return volume


func _sphere(rayon: float, hauteur: float) -> SphereMesh:
	var volume := SphereMesh.new()
	volume.radius = rayon
	volume.height = hauteur
	volume.radial_segments = 12
	volume.rings = 5
	return volume


func _creer_lot(id: StringName, camp: int) -> MultiMesh:
	var forme := ArrayMesh.new()
	var soldat: bool = camp == SwarmSim.ALLIE and id != &"lance_bille"
	if soldat:
		var bois := StandardMaterial3D.new()
		bois.vertex_color_use_as_albedo = true
		var corps := BoxMesh.new()
		corps.size = Vector3(0.46, 0.36, 0.3)
		_ajouter_piece(forme, corps, 0.18, bois)
		_ajouter_piece(forme, _cylindre(0.13, 0.14), 0.43, Materiaux.obtenir("chapeau"))
	elif id == &"lance_bille":
		# Le socle dessine un liseré contrasté autour du cylindre menthe vu de dessus.
		if Materiaux.contraste(Color(Materiaux.COULEURS.jouet_menthe), Color(Materiaux.COULEURS.pierre_creme)) < 3.0:
			_ajouter_piece(forme, _cylindre(0.31, 0.1), 0.05, Materiaux.obtenir("menthe_soutenue"))
		_ajouter_piece(forme, _cylindre(0.25, 0.38), 0.19, Materiaux.obtenir("jouet_menthe"))
		_ajouter_piece(forme, _sphere(0.13, 0.26), 0.46, Materiaux.obtenir("laiton"))
	else:
		var cuirasse: bool = id == &"scarabee_cuirasse"
		var taille: float = 1.6 if cuirasse else 1.0
		_ajouter_piece(forme, _sphere(0.26 * taille, 0.32 * taille), 0.16 * taille,
				Materiaux.obtenir("cuivre" if cuirasse else "laiton"))
		if cuirasse:
			var crete := BoxMesh.new()
			crete.size = Vector3(0.46, 0.12, 0.1)
			_ajouter_piece(forme, crete, 0.50, Materiaux.obtenir("pierre_creme"))
	if camp == SwarmSim.ENNEMI:
		for i: int in forme.get_surface_count():
			var origine: StandardMaterial3D = forme.surface_get_material(i) as StandardMaterial3D
			var carapace := ShaderMaterial.new()
			carapace.shader = _shader_carapace
			carapace.set_shader_parameter("teinte", origine.albedo_color)
			carapace.set_shader_parameter("creme", CREME)
			carapace.set_shader_parameter("metal", origine.metallic)
			carapace.set_shader_parameter("rugosite", origine.roughness)
			forme.surface_set_material(i, carapace)
	var lot := MultiMesh.new()
	lot.transform_format = MultiMesh.TRANSFORM_3D
	lot.use_colors = soldat or camp == SwarmSim.ENNEMI
	lot.mesh = forme
	lot.instance_count = SwarmSim.CAPACITE
	lot.visible_instance_count = 0
	if soldat:
		for i: int in SwarmSim.CAPACITE:
			lot.set_instance_color(i, Color(Materiaux.COULEURS[TEINTES[i % TEINTES.size()]]))
	var volume := MultiMeshInstance3D.new()
	volume.multimesh = lot
	add_child(volume)
	_lots[id] = lot
	_effectifs[id] = 0
	return lot


func _process(delta: float) -> void:
	_avancer_billes(delta)
	if sim == null:
		return
	for id: StringName in _lots:
		_effectifs[id] = 0
	for camp: int in [SwarmSim.ALLIE, SwarmSim.ENNEMI]:
		var hauteur: float = 0.04 if camp == SwarmSim.ENNEMI else 0.0
		var lieux: PackedVector2Array = sim.positions(camp)
		var touches: PackedFloat32Array = sim.touches(camp)
		var angles: PackedFloat32Array = sim.caps(camp)
		var modeles: Array[SwarmSim.UniteDef] = sim.modeles(camp)
		for i: int in lieux.size():
			var id: StringName = modeles[i].id
			var lot: MultiMesh = _lots.get(id)
			if lot == null:
				lot = _creer_lot(id, camp)
			var base := Basis(Vector3.UP, -angles[i])
			var indice: int = _effectifs[id]
			if camp == SwarmSim.ENNEMI:
				var touche: bool = touches[i] > 0.0
				lot.set_instance_color(indice, CREME if touche else Color.WHITE)
				if touche:
					base = base.scaled_local(Vector3.ONE * 1.12)
				base = base.scaled_local(Vector3(1.25, 1.0, 0.85))
			lot.set_instance_transform(indice, Transform3D(base, Vector3(lieux[i].x, hauteur, lieux[i].y)))
			_effectifs[id] = indice + 1
	for id: StringName in _lots:
		_lots[id].visible_instance_count = _effectifs[id]
