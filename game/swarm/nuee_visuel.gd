extends Node3D
## Affiche les silhouettes des unités vivantes et les copeaux des ennemis cassés.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Materiaux = preload("res://game/core/materiaux.gd")
const TEINTES := ["jouet_rouge", "jouet_bleu", "jouet_vert", "jouet_prune"]

const DUREE_VOL := 0.18
const NOMBRE_BILLES := 48
const CREME := Color("#FFF3D6")
const BLEU_RALENTI := Color(0.62, 0.8, 1.0)

var sim: SwarmSim:
	set(valeur):
		if sim == valeur:
			return
		if sim != null:
			sim.tir.disconnect(_sur_tir)
		sim = valeur
		if sim != null:
			sim.tir.connect(_sur_tir)
var _phase_vol: float = 0.0
var _billes: Array[MeshInstance3D] = []
var _departs := PackedVector2Array()
var _arrivees := PackedVector2Array()
var _ages := PackedFloat32Array()
var _prochaine_bille: int = 0
var _shader_carapace := Shader.new()
## Même rôle que la carapace pour les modèles Hyper3D texturés : la texture reste, l'impact la blanchit (crème).
var _shader_texture := Shader.new()
## Modèles Hyper3D allégés (`scripts/alleger_modele.gd`) ; prioritaires sur le kit Blender quand ils existent.
const MODELE_H3D := "res://assets/final/%s/%s_h3d.res"
## Exceptions d'orientation (demi-tour) pour un futur modèle Hyper3D livré dos à sa marche. Le lot 1 a la même face
## avant que le kit Blender (vérifié par capture, `art_refs/playtest2/apres/31_galerie.jpg`).
const DEMI_TOUR_H3D: Dictionary = {}
## Ennemis sans modèle propre (playtest 2) : ils empruntent un modèle Hyper3D existant, teinté pour rester distincts.
const EMPRUNTS_H3D: Dictionary = {&"taupe": [&"fourmi", Color(0.62, 0.45, 0.32)],
		&"porte_bouclier": [&"scarabee_cuirasse", Color(0.62, 0.78, 0.95)]}
var _lots: Dictionary[StringName, MultiMesh] = {}
var _bases: Dictionary[StringName, Basis] = {}
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
			// Ralenti par un carillon (rouge de l'instance baissé, bleu intact) : voile bleu pâle.
			if (couleur.r < 0.9 && couleur.b >= 0.99) { ALBEDO = mix(ALBEDO, vec3(0.5, 0.72, 1.0), 0.5); }
			METALLIC = metal;
			ROUGHNESS = rugosite;
		}
	"""
	_shader_texture.code = """
		shader_type spatial;
		uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
		uniform vec4 creme : source_color;
		uniform vec4 teinte : source_color = vec4(1.0);
		uniform float metal;
		uniform float rugosite;
		varying vec3 couleur;
		void vertex() {
			couleur = COLOR.rgb;
		}
		void fragment() {
			vec3 texte = texture(albedo_tex, UV).rgb * teinte.rgb;
			ALBEDO = couleur.b < 0.99 ? mix(texte, creme.rgb, 0.75) : texte;
			if (couleur.r < 0.9 && couleur.b >= 0.99) { ALBEDO = mix(ALBEDO, vec3(0.5, 0.72, 1.0), 0.5); }
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


func _forme_de_repli(id: StringName, camp: int) -> ArrayMesh:
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
	return forme


# Modèle Hyper3D allégé de l'unité, mis à l'échelle de son rayon (pivot au pied, comme le kit).
func _forme_hyper3d(def: SwarmSim.UniteDef, camp: int) -> Mesh:
	var nom: StringName = &"soldat" if def.id == &"soldat_remontoir" else def.id
	var teinte: Color = Color.WHITE
	# Un modèle propre (playtest 3 : taupe et porte-bouclier générés) passe avant l'emprunt.
	if EMPRUNTS_H3D.has(nom) and not ResourceLoader.exists(MODELE_H3D % [nom, nom]):
		teinte = EMPRUNTS_H3D[nom][1]
		nom = EMPRUNTS_H3D[nom][0]
	var chemin: String = MODELE_H3D % [nom, nom]
	if not ResourceLoader.exists(chemin):
		return null
	var forme: Mesh = (load(chemin) as Mesh).duplicate()
	var taille: Vector3 = forme.get_aabb().size
	var largeur: float = maxf(taille.x, taille.z)
	if largeur <= 0.0:
		return null
	var echelle: float = 2.0 * def.rayon / largeur
	# Tous les modèles Hyper3D ont la même face avant (contrairement au kit, où jouets et insectes différaient).
	var orientation: float = PI / 2.0
	var demi_tour: float = PI if DEMI_TOUR_H3D.get(nom, false) else 0.0
	_bases[def.id] = Basis(Vector3.UP, orientation + demi_tour).scaled(Vector3.ONE * echelle)
	if camp == SwarmSim.ENNEMI:
		for i: int in forme.get_surface_count():
			var origine := forme.surface_get_material(i) as StandardMaterial3D
			var peau := ShaderMaterial.new()
			peau.shader = _shader_texture
			peau.set_shader_parameter("albedo_tex", origine.albedo_texture if origine != null else null)
			peau.set_shader_parameter("creme", CREME)
			peau.set_shader_parameter("teinte", teinte)
			peau.set_shader_parameter("metal", origine.metallic if origine != null else 0.3)
			peau.set_shader_parameter("rugosite", origine.roughness if origine != null else 0.5)
			forme.surface_set_material(i, peau)
	return forme


func _forme_du_kit(def: SwarmSim.UniteDef, camp: int) -> Mesh:
	var nom: StringName = &"soldat" if def.id == &"soldat_remontoir" else def.id
	if def.volant:
		nom = &"fourmi"
	elif def.boss:
		nom = &"scarabee_cuirasse"  # même silhouette, agrandie par son rayon et assombrie
	var scene: PackedScene = Materiaux.scene_du_kit(nom)
	if scene == null:
		return null
	var racine := scene.instantiate() as Node3D
	var volume := racine as MeshInstance3D
	if volume == null:
		var volumes: Array[Node] = racine.find_children("*", "MeshInstance3D", true, false)
		if not volumes.is_empty():
			volume = volumes[0] as MeshInstance3D
	var forme: Mesh
	if volume != null and volume.mesh != null:
		# Les cinq figurines ont un seul maillage, en mètres, avec le pivot au pied.
		var taille: Vector3 = volume.mesh.get_aabb().size
		var largeur: float = maxf(taille.x, taille.z)
		if largeur > 0.0:
			var echelle: float = 2.0 * def.rayon / largeur
			var orientation: float = PI / 2.0 if camp == SwarmSim.ENNEMI else -PI / 2.0
			_bases[def.id] = Basis(Vector3.UP, orientation).scaled(Vector3.ONE * echelle)
			forme = volume.mesh.duplicate() as Mesh
			if nom == &"soldat":
				for i: int in forme.get_surface_count():
					var mat := forme.surface_get_material(i) as StandardMaterial3D
					if mat != null and mat.resource_name == "PastelBleu":
						var veste := mat.duplicate() as StandardMaterial3D
						veste.albedo_color = Color.WHITE
						veste.vertex_color_use_as_albedo = true
						forme.surface_set_material(i, veste)
	racine.free()
	return forme


func _creer_lot(def: SwarmSim.UniteDef, camp: int) -> MultiMesh:
	var id: StringName = def.id
	var soldat: bool = camp == SwarmSim.ALLIE and id != &"lance_bille"
	var forme: Mesh = _forme_hyper3d(def, camp)
	var hyper3d: bool = forme != null
	if hyper3d:
		soldat = false  # le modèle Hyper3D porte déjà ses couleurs (pas de veste teintée par instance)
	else:
		forme = _forme_du_kit(def, camp)
	if forme == null:
		forme = _forme_de_repli(id, camp)
		_bases[id] = Basis.from_scale(Vector3(1.25, 1.0, 0.85)) if camp == SwarmSim.ENNEMI else Basis.IDENTITY
	if camp == SwarmSim.ENNEMI and not hyper3d:
		for i: int in forme.get_surface_count():
			var origine: StandardMaterial3D = forme.surface_get_material(i) as StandardMaterial3D
			var carapace := ShaderMaterial.new()
			carapace.shader = _shader_carapace
			var teinte: Color = origine.albedo_color.darkened(0.35) if def.boss else origine.albedo_color
			carapace.set_shader_parameter("teinte", Color("#5FA8A0") if def.volant else teinte)
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


## Animations procédurales des nuées (PT-53). Pourquoi des maths plutôt qu'Hyper3D ici (règle R1, exception b) : des
## centaines d'unités en MultiMesh ne peuvent pas porter chacune un squelette animé ; un dandinement de jouet à
## remontoir, un trottinement d'insecte et un battement d'ailes calculés par instance coûtent presque rien et se lisent
## bien de haut. Les modèles Hyper3D animés passeront par le même point d'entrée (`_pose_animee`).
var _temps: float = 0.0
var _precedents: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array()]
## Dernier état « en marche » connu : la simulation avance au pas physique, l'affichage parfois plus vite ; sans mémoire,
## une image sans pas physique figerait toute la nuée (clignotement de la démarche).
var _en_marche: Array[PackedByteArray] = [PackedByteArray(), PackedByteArray()]


# Transforme la base d'une unité selon sa démarche : dandinement (jouets), trottinement (insectes), ailes (volants).
func _pose_animee(base: Basis, def: SwarmSim.UniteDef, camp: int, i: int, en_marche: bool) -> Array:
	var hauteur: float = 0.0
	var phase: float = _temps * (11.0 if camp == SwarmSim.ALLIE else 17.0) + i * 1.7
	if def.volant:
		hauteur = 0.9 + 0.05 * sin(_phase_vol + i)
		# Battement d'ailes : le corps « respire » en largeur très vite (le modèle n'a pas d'ailes séparées).
		base = base.scaled_local(Vector3(1.0 + 0.18 * sin(_temps * 26.0 + i), 1.0, 1.0))
	elif en_marche and camp == SwarmSim.ALLIE:
		# Jouet à remontoir : il se balance d'un pied sur l'autre en sautillant.
		base = base * Basis(Vector3.FORWARD, 0.13 * sin(phase))
		hauteur = 0.045 * absf(sin(phase))
	elif en_marche:
		# Insecte mécanique : petits sauts rapides et léger lacet.
		base = Basis(Vector3.UP, 0.06 * sin(phase * 0.5)) * base
		hauteur = 0.02 * absf(sin(phase))
	return [base, hauteur]


func _process(delta: float) -> void:
	_temps += delta
	_phase_vol = fmod(_phase_vol + delta * 10.0, TAU)
	_avancer_billes(delta)
	if sim == null:
		return
	for id: StringName in _lots:
		_effectifs[id] = 0
	for camp: int in [SwarmSim.ALLIE, SwarmSim.ENNEMI]:
		var lieux: PackedVector2Array = sim.positions(camp)
		var touches: PackedFloat32Array = sim.touches(camp)
		var ralentis: PackedFloat32Array = sim.ralentis(camp)
		var angles: PackedFloat32Array = sim.caps(camp)
		var modeles: Array[SwarmSim.UniteDef] = sim.modeles(camp)
		var precedents: PackedVector2Array = _precedents[camp]
		var pas_physique: bool = lieux != precedents
		# Playtest 3 : sur un Pont, les unités au sol montent sur le tablier au lieu de le traverser.
		var relief: bool = sim.a_du_relief()
		if pas_physique:
			var marche := PackedByteArray()
			marche.resize(lieux.size())
			for j: int in lieux.size():
				marche[j] = 1 if precedents.size() == lieux.size() and not precedents[j].is_equal_approx(lieux[j]) else 0
			_en_marche[camp] = marche
		for i: int in lieux.size():
			var id: StringName = modeles[i].id
			var lot: MultiMesh = _lots.get(id)
			if lot == null:
				lot = _creer_lot(modeles[i], camp)
			var base: Basis = Basis(Vector3.UP, -angles[i]) * _bases[id]
			var indice: int = _effectifs[id]
			if camp == SwarmSim.ENNEMI:
				var touche: bool = touches[i] > 0.0
				# Ennemi ralenti par un carillon : teinte bleu pâle, pour voir d'un coup d'œil qui est pris.
				var givre: bool = i < ralentis.size() and ralentis[i] > 0.0
				lot.set_instance_color(indice, CREME if touche else (BLEU_RALENTI if givre else Color.WHITE))
				if touche:
					base = base.scaled_local(Vector3.ONE * 1.12)
			var en_marche: bool = i < _en_marche[camp].size() and _en_marche[camp][i] == 1
			var pose: Array = _pose_animee(base, modeles[i], camp, i, en_marche)
			var hauteur: float = pose[1]
			if relief and not modeles[i].volant:
				hauteur += sim.relief(lieux[i])
			lot.set_instance_transform(indice, Transform3D(pose[0], Vector3(lieux[i].x, hauteur, lieux[i].y)))
			_effectifs[id] = indice + 1
		_precedents[camp] = lieux.duplicate()
	for id: StringName in _lots:
		_lots[id].visible_instance_count = _effectifs[id]
