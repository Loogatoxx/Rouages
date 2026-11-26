extends SceneTree
## Rend une vignette 128 px (fond transparent, vue 3/4) de chaque pièce et extension depuis le kit 3D.
## Pourquoi : boutique et réserve passent aux icônes (playtest 1 : « icônes au premier plan, texte au survol ») ;
## rendre les vrais modèles garantit la cohérence avec le plateau, sans dessin ni crédit Hyper3D.
## Lancer en fenêtré (le rendu exige un écran) :
##   Godot --path . --windowed --script res://scripts/generer_vignettes.gd -- --fenetre

const KIT := "res://assets/final/kit_v2/%s/%s.glb"
const SORTIE := "res://assets/ui/vignettes/"
const PIECES: Array[StringName] = [&"atelier_soldats", &"atelier_billes", &"engrenage_droit", &"engrenage_coude",
		&"engrenage_t", &"engrenage_croix", &"tourelle_canon", &"tourelle_carillon", &"tourelle_mortier"]
## Ports (N, E, S, O) des socles du kit, comme `PlateauVisuel.PORTS_DU_KIT` : on y pose les dents de laiton du jeu.
const PORTS := {&"engrenage_droit": 5, &"engrenage_coude": 3, &"engrenage_t": 11, &"engrenage_croix": 15}
const EXTENSIONS := {&"extension_sentier": "res://data/extensions/sentier.tres",
		&"extension_carrefour": "res://data/extensions/carrefour.tres"}


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
		var modele: Node3D = (load(KIT % [id, id]) as PackedScene).instantiate()
		if PORTS.has(id):
			_dents(modele, PORTS[id])
		await _rendre(vue, camera, modele, String(id))
	for id: StringName in EXTENSIONS:
		await _rendre(vue, camera, _extension(load(EXTENSIONS[id])), String(id))
	quit()


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
	camera.size = rayon * 1.6
	camera.near = 0.05
	camera.far = rayon * 10.0
	for i: int in 6:
		await process_frame
	var image: Image = vue.get_texture().get_image()
	image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	image.save_png(SORTIE + nom + ".png")
	modele.queue_free()
	await process_frame
