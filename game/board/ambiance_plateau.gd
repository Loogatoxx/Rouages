extends Node3D
## Micro-détails d'ambiance au-dessus du plateau (playtest 1, PT-54 : « rien ne semble vivant autour du combat »).
##
## Poussière dorée qui flotte dans la lumière de fin d'après-midi et quelques pétales pastel qui dérivent lentement.
## Pourquoi par particules (règle R1, exception b) : un nuage de poussière est un phénomène de calcul, pas un objet à
## modéliser. Règle R3 : peu nombreux, lents, translucides ; ils ne doivent jamais gêner la lecture des nuées.

const PASTELS: Array[Color] = [Color("#F2B5C4"), Color("#F5DC8A"), Color("#B8E0B0"), Color("#FFF3DE")]


## Papillons (playtest 3, « aucune vie ambiante ») : quelques ailes pastel qui volettent au-dessus de l'herbe.
const NOMBRE_PAPILLONS := 5
var _papillons: Array[Node3D] = []
var _caps: PackedVector2Array = []
var _temps: float = 0.0


func _ready() -> void:
	add_child(_poussiere())
	add_child(_petales())
	for k: int in NOMBRE_PAPILLONS:
		_papillons.append(_papillon(PASTELS[k % PASTELS.size()]))
		_caps.append(Vector2(randf_range(-9, 9), randf_range(-9, 9)))


# Deux ailes plates articulées sur un corps minuscule ; l'ensemble est petit (40 cm d'envergure) pour rester un détail.
func _papillon(couleur: Color) -> Node3D:
	var corps := Node3D.new()
	add_child(corps)
	corps.position = Vector3(randf_range(-9, 9), randf_range(0.8, 1.6), randf_range(-9, 9))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var forme := QuadMesh.new()
	forme.size = Vector2(0.2, 0.16)
	for cote: float in [-1.0, 1.0]:
		var charniere := Node3D.new()
		charniere.name = "Aile%d" % int(cote)
		corps.add_child(charniere)
		var aile := MeshInstance3D.new()
		aile.mesh = forme
		aile.material_override = mat
		aile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		aile.rotation.x = -PI / 2.0
		aile.position = Vector3(0.1 * cote, 0, 0)
		charniere.add_child(aile)
	return corps


# Chaque papillon vole vers un point au hasard en ondulant, puis en choisit un autre ; ses ailes battent.
func _process(delta: float) -> void:
	_temps += delta
	for k: int in _papillons.size():
		var papillon: Node3D = _papillons[k]
		var ici := Vector2(papillon.position.x, papillon.position.z)
		var cible: Vector2 = _caps[k]
		if ici.distance_to(cible) < 0.4:
			_caps[k] = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var pas: Vector2 = ici.move_toward(cible, delta * 1.1)
		papillon.position = Vector3(pas.x, 1.2 + 0.35 * sin(_temps * 1.7 + k), pas.y)
		papillon.rotation.y = atan2(-(cible.x - ici.x), -(cible.y - ici.y))
		var battement: float = 0.9 * sin(_temps * 16.0 + k * 1.3)
		papillon.get_child(0).rotation.z = battement
		papillon.get_child(1).rotation.z = -battement


func _materiau(couleur: Color, additif: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additif else BaseMaterial3D.BLEND_MODE_MIX
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = couleur
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _poussiere() -> GPUParticles3D:
	var particules := GPUParticles3D.new()
	particules.amount = 70
	particules.lifetime = 9.0
	particules.preprocess = 9.0
	particules.position = Vector3(0, 2.4, 0)
	particules.visibility_aabb = AABB(Vector3(-16, -3, -16), Vector3(32, 6, 32))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(13, 1.6, 13)
	process.gravity = Vector3(0, 0.02, 0)
	process.direction = Vector3(1, 0.2, 0.3)
	process.spread = 180.0
	process.initial_velocity_min = 0.03
	process.initial_velocity_max = 0.12
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.4
	process.turbulence_noise_speed_random = 0.2
	process.scale_min = 0.6
	process.scale_max = 1.3
	var fondu := Gradient.new()
	fondu.set_color(0, Color(1, 1, 1, 0))
	fondu.set_color(1, Color(1, 1, 1, 0))
	fondu.add_point(0.25, Color(1, 1, 1, 0.55))
	fondu.add_point(0.75, Color(1, 1, 1, 0.55))
	var rampe := GradientTexture1D.new()
	rampe.gradient = fondu
	process.color_ramp = rampe
	particules.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.07, 0.07)
	quad.material = _materiau(Color("#FFE6A8"), true)
	particules.draw_pass_1 = quad
	return particules


func _petales() -> GPUParticles3D:
	var particules := GPUParticles3D.new()
	particules.amount = 10
	particules.lifetime = 14.0
	particules.preprocess = 14.0
	particules.position = Vector3(0, 6.0, 0)
	particules.visibility_aabb = AABB(Vector3(-18, -7, -18), Vector3(36, 9, 36))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(15, 0.3, 15)
	process.gravity = Vector3(0.05, -0.32, 0.02)
	process.initial_velocity_min = 0.0
	process.initial_velocity_max = 0.1
	process.angular_velocity_min = -40.0
	process.angular_velocity_max = 40.0
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.8
	var couleurs := Gradient.new()
	couleurs.set_color(0, PASTELS[0])
	couleurs.set_color(1, PASTELS[3])
	couleurs.add_point(0.33, PASTELS[1])
	couleurs.add_point(0.66, PASTELS[2])
	var aleatoire := GradientTexture1D.new()
	aleatoire.gradient = couleurs
	process.color_initial_ramp = aleatoire
	var fondu := Gradient.new()
	fondu.set_color(0, Color(1, 1, 1, 0))
	fondu.set_color(1, Color(1, 1, 1, 0))
	fondu.add_point(0.15, Color(1, 1, 1, 0.85))
	fondu.add_point(0.8, Color(1, 1, 1, 0.85))
	var rampe := GradientTexture1D.new()
	rampe.gradient = fondu
	process.color_ramp = rampe
	particules.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.11)
	quad.material = _materiau(Color.WHITE, false)
	particules.draw_pass_1 = quad
	return particules
