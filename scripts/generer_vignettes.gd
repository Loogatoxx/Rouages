extends SceneTree
## Rend une vignette 128 px (fond transparent, vue 3/4) de chaque pièce et extension depuis le kit 3D.
## Pourquoi : boutique et réserve passent aux icônes (playtest 1 : « icônes au premier plan, texte au survol ») ;
## rendre les vrais modèles garantit la cohérence avec le plateau, sans dessin ni crédit Hyper3D.
## Lancer en fenêtré (le rendu exige un écran) :
##   Godot --path . --windowed --script res://scripts/generer_vignettes.gd -- --fenetre

const KIT := "res://assets/final/kit_v2/%s/%s.glb"
const SORTIE := "res://assets/ui/vignettes/"
const PIECES: Array[StringName] = [&"atelier_soldats", &"atelier_billes", &"engrenage_droit", &"engrenage_coude",
		&"engrenage_t", &"engrenage_croix", &"tourelle_canon", &"tourelle_carillon", &"tourelle_mortier", &"pont", &"generateur"]
## Ports (N, E, S, O) des socles du kit, comme `PlateauVisuel.PORTS_DU_KIT` : on y pose les dents de laiton du jeu.
const PORTS := {&"engrenage_droit": 5, &"engrenage_coude": 3, &"engrenage_t": 11, &"engrenage_croix": 15, &"pont": 10,
		&"generateur": 15}
## Ennemis (aperçu de la vague suivante) : [modèle du kit, teinte superposée ou transparent], comme `NueeVisuel`.
const ENNEMIS := {&"scarabee": [&"scarabee", Color.TRANSPARENT], &"fourmi": [&"fourmi", Color.TRANSPARENT],
		&"scarabee_cuirasse": [&"scarabee_cuirasse", Color.TRANSPARENT],
		&"grand_scarabee": [&"scarabee_cuirasse", Color(0.35, 0.22, 0.08, 0.4)],
		&"libellule": [&"fourmi", Color(0.37, 0.66, 0.63, 0.65)]}
const EXTENSIONS := {&"extension_sentier": "res://data/extensions/sentier.tres",
		&"extension_carrefour": "res://data/extensions/carrefour.tres",
		&"extension_virage": "res://data/extensions/virage.tres",
		&"extension_grande_allee": "res://data/extensions/grande_allee.tres"}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SORTIE))
	var vue := SubViewport.new()
	vue.size = Vector2i(256, 256)
	vue.transparent_bg = true
	vue.own_world_3d = true
	vue.msaa_3d = Viewport.MSAA_4X
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vue)
	var monde := WorldEnvironment.new()
	monde.environment = Environment.new()
	monde.environment.background_mode = Environment.BG_CLEAR_COLOR
	monde.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	monde.environment.ambient_light_color = Color(1, 0.93, 0.82)
	monde.environment.ambient_light_energy = 0.75
	monde.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	vue.add_child(monde)
	var soleil := DirectionalLight3D.new()
	soleil.light_color = Color(1, 0.94, 0.83)
	soleil.light_energy = 1.25
	soleil.rotation_degrees = Vector3(-50, 35, 0)
	vue.add_child(soleil)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	vue.add_child(camera)
	camera.current = true
	await process_frame
	for id: StringName in PIECES:
		var modele: Node3D = _hyper3d(id)
		if modele == null:
			modele = (load(KIT % [id, id]) as PackedScene).instantiate()
		if PORTS.has(id):
			_dents(modele, PORTS[id])
		await _rendre(vue, camera, modele, String(id))
	# Piège à ressort (P2-40) : pas de modèle de kit, même dessin que `PlateauVisuel._creer_piece_de_repli`.
	await _rendre(vue, camera, _piege_ressort(), "piege_ressort")
	for id: StringName in ENNEMIS:
		var source: StringName = ENNEMIS[id][0]
		var ennemi: Node3D = (load(KIT % [source, source]) as PackedScene).instantiate()
		var teinte: Color = ENNEMIS[id][1]
		if teinte.a > 0.0:
			var voile := StandardMaterial3D.new()
			voile.albedo_color = teinte
			voile.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			for maille: Node in ennemi.find_children("*", "GeometryInstance3D", true, false):
				(maille as GeometryInstance3D).material_overlay = voile
		await _rendre(vue, camera, ennemi, String(id))
	for id: StringName in EXTENSIONS:
		await _rendre(vue, camera, _extension(load(EXTENSIONS[id])), String(id))
	quit()


# Bâtiment Hyper3D allégé (même mise à l'échelle que `PlateauVisuel._modele_hyper3d`), sinon null.
func _hyper3d(id: StringName) -> Node3D:
	var chemin: String = "res://assets/final/%s/%s_h3d.res" % [id, id]
	if not ResourceLoader.exists(chemin):
		return null
	var maillage: Mesh = load(chemin)
	var boite: AABB = maillage.get_aabb()
	var echelle: float = 1.9 / maxf(boite.size.x, boite.size.z)
	var racine := Node3D.new()
	var volume := MeshInstance3D.new()
	volume.mesh = maillage
	volume.scale = Vector3.ONE * echelle
	var centre: Vector3 = boite.get_center()
	volume.position = Vector3(-centre.x, -boite.position.y, -centre.z) * echelle
	racine.add_child(volume)
	return racine


# Dents de laiton sur les ports, mêmes dimensions que `PlateauVisuel.creer_piece` : la forme de l'engrenage se lit.
func _dents(modele: Node3D, ports: int) -> void:
	var laiton := StandardMaterial3D.new()
	laiton.albedo_color = Color("#D4A84B")
	laiton.metallic = 0.8
	laiton.roughness = 0.32
	for i: int in 4:
		if ports & (1 << i):
			var dent := MeshInstance3D.new()
			var boite := BoxMesh.new()
			boite.size = Vector3(0.32, 0.24, 0.43)
			dent.mesh = boite
			dent.material_override = laiton
			dent.rotation.y = -i * PI / 2
			dent.position = Vector3.FORWARD.rotated(Vector3.UP, -i * PI / 2) * 0.77 + Vector3.UP * 0.26
			modele.add_child(dent)


# Petit carré 3×3 de dalles du kit (chemin ou herbe) : la vignette montre la forme de l'extension.
func _extension(def: Resource) -> Node3D:
	var racine := Node3D.new()
	for x: int in def.taille:
		for y: int in def.taille:
			var nom: String = "tuile_chemin" if Vector2i(x, y) in def.chemins else "tuile_herbe"
			var dalle: Node3D = (load(KIT % [nom, nom]) as PackedScene).instantiate()
			dalle.position = Vector3(x - 1, 0, y - 1) * 2.0
			racine.add_child(dalle)
	return racine


func _rendre(vue: SubViewport, camera: Camera3D, modele: Node3D, nom: String) -> void:
	vue.add_child(modele)
	var boite := AABB()
	var premiere: bool = true
	for maille: Node in modele.find_children("*", "VisualInstance3D", true, false):
		var b: AABB = (maille as VisualInstance3D).global_transform * (maille as VisualInstance3D).get_aabb()
		boite = b if premiere else boite.merge(b)
		premiere = false
	var centre: Vector3 = boite.get_center()
	var rayon: float = boite.size.length() * 0.5
	var direction := Vector3(1, 1.05, 1.25).normalized()
	camera.look_at_from_position(centre + direction * rayon * 4.0, centre)
	# Cadrage sur les 8 coins de la boîte vus par la caméra, + 8 % de marge (playtest 2 : l'ancien cadrage
	# `rayon × 1,6` rognait la maison de l'atelier en bas et sur les côtés).
	var etendue: float = 0.0
	var inverse: Transform3D = camera.global_transform.affine_inverse()
	for coin: int in 8:
		var local: Vector3 = inverse * boite.get_endpoint(coin)
		etendue = maxf(etendue, maxf(absf(local.x), absf(local.y)))
	camera.size = etendue * 2.0 * 1.08
	camera.near = 0.05
	camera.far = rayon * 10.0
	for i: int in 6:
		await process_frame
	var image: Image = vue.get_texture().get_image()
	image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	image.save_png(SORTIE + nom + ".png")
	modele.queue_free()
	await process_frame


func _piege_ressort() -> Node3D:
	var racine := Node3D.new()
	var corail := StandardMaterial3D.new()
	corail.albedo_color = Color("#E0795C")
	var laiton := StandardMaterial3D.new()
	laiton.albedo_color = Color("#D4A84B")
	laiton.metallic = 0.8
	laiton.roughness = 0.35
	var socle := MeshInstance3D.new()
	var dalle := BoxMesh.new()
	dalle.size = Vector3(1.9, 0.1, 1.9)
	socle.mesh = dalle
	var pierre := StandardMaterial3D.new()
	pierre.albedo_color = Color("#EFE3C8")
	socle.material_override = pierre
	racine.add_child(socle)
	var formes: Array = [[CylinderMesh.new(), 0.62, 0.66, 0.08, 0.09, corail], [CylinderMesh.new(), 0.5, 0.5, 0.1, 0.14, laiton]]
	for f: Array in formes:
		var cylindre: CylinderMesh = f[0]
		cylindre.top_radius = f[1]
		cylindre.bottom_radius = f[2]
		cylindre.height = f[3]
		var maille := MeshInstance3D.new()
		maille.mesh = cylindre
		maille.position.y = f[4]
		maille.material_override = f[5]
		racine.add_child(maille)
	for k: int in 3:
		var spire := TorusMesh.new()
		spire.inner_radius = 0.16 - k * 0.03
		spire.outer_radius = 0.22 - k * 0.03
		var maille := MeshInstance3D.new()
		maille.mesh = spire
		maille.position.y = 0.22 + k * 0.07
		maille.material_override = laiton
		racine.add_child(maille)
	return racine
