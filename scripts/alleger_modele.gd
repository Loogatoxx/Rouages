extends SceneTree
## Allège un modèle Hyper3D (≈ 500 000 triangles, textures 2K) pour les nuées du jeu.
##
## Pourquoi : les unités sont dessinées par centaines en MultiMesh ; à 500 000 triangles par figurine, la carte
## graphique s'effondrerait. On simplifie le maillage avec meshoptimizer (la simplification intégrée à Godot,
## `ImporterMesh.generate_lods`), on ne garde que les sommets utilisés, on réduit les textures, puis on enregistre une
## ressource `ArrayMesh` prête à l'emploi (`assets/final/<nom>/<nom>_h3d.res`, textures incluses).
## Exception R1 (b) notée dans `assets/CREDITS_HYPER3D.md` : c'est Hyper3D qui modélise, le calcul ne fait que réduire.
##
## Usage : Godot --headless --path . --script res://scripts/alleger_modele.gd -- <modele.glb> <nom> [triangles] [texture]

const SORTIE := "res://assets/final/%s/%s_h3d.res"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage : -- <modele.glb> <nom> [triangles=4000] [texture=512]")
		quit(1)
		return
	var cible: int = int(args[2]) if args.size() > 2 else 4000
	var taille_texture: int = int(args[3]) if args.size() > 3 else 512
	var document := GLTFDocument.new()
	var etat := GLTFState.new()
	if document.append_from_file(args[0], etat) != OK:
		push_error("Lecture impossible : " + args[0])
		quit(1)
		return
	var scene: Node = document.generate_scene(etat)
	var volumes: Array[Node] = scene.find_children("*", "MeshInstance3D", true, false)
	if volumes.is_empty():
		push_error("Aucun maillage dans " + args[0])
		quit(1)
		return
	var source: MeshInstance3D = volumes[0]
	var resultat := ArrayMesh.new()
	for s: int in source.mesh.get_surface_count():
		var tableaux: Array = source.mesh.surface_get_arrays(s)
		var indices: PackedInt32Array = _simplifier(tableaux, cible)
		resultat.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _compacter(tableaux, indices))
		resultat.surface_set_material(s, _materiau(source.mesh.surface_get_material(s), taille_texture))
	var dossier: String = "res://assets/final/%s" % args[1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dossier))
	var chemin: String = SORTIE % [args[1], args[1]]
	var erreur: Error = ResourceSaver.save(resultat, chemin, ResourceSaver.FLAG_COMPRESS)
	var triangles: int = 0
	for s: int in resultat.get_surface_count():
		triangles += resultat.surface_get_arrays(s)[Mesh.ARRAY_INDEX].size() / 3
	print("ALLEGE %s : %d triangles, textures %d px, boîte %s → %s (%s)" % [args[1], triangles, taille_texture,
			resultat.get_aabb(), chemin, error_string(erreur)])
	scene.free()
	quit(0 if erreur == OK else 1)


# Garde le niveau de détail le plus proche de la cible parmi ceux calculés par meshoptimizer.
func _simplifier(tableaux: Array, cible: int) -> PackedInt32Array:
	var importe := ImporterMesh.new()
	importe.add_surface(Mesh.PRIMITIVE_TRIANGLES, tableaux)
	importe.generate_lods(60.0, 25.0, [])
	var meilleur: PackedInt32Array = tableaux[Mesh.ARRAY_INDEX]
	for i: int in importe.get_surface_lod_count(0):
		var lod: PackedInt32Array = importe.get_surface_lod_indices(0, i)
		if lod.size() / 3 >= cible * 0.6 and absi(lod.size() / 3 - cible) < absi(meilleur.size() / 3 - cible):
			meilleur = lod
	return meilleur


# Ne garde que les sommets référencés par les nouveaux triangles (le tampon d'origine en compte ~250 000).
func _compacter(tableaux: Array, indices: PackedInt32Array) -> Array:
	var correspondance: Dictionary = {}
	var anciens: PackedInt32Array = PackedInt32Array()
	var nouveaux := PackedInt32Array()
	nouveaux.resize(indices.size())
	for k: int in indices.size():
		var ancien: int = indices[k]
		if not correspondance.has(ancien):
			correspondance[ancien] = anciens.size()
			anciens.append(ancien)
		nouveaux[k] = correspondance[ancien]
	var sortie: Array = []
	sortie.resize(Mesh.ARRAY_MAX)
	for type: int in Mesh.ARRAY_MAX:
		var donnees = tableaux[type]
		if donnees == null or type == Mesh.ARRAY_INDEX:
			continue
		var largeur: int = 4 if type == Mesh.ARRAY_TANGENT else 1
		var copie = donnees.duplicate()
		copie.resize(anciens.size() * largeur)
		for n: int in anciens.size():
			for c: int in largeur:
				copie[n * largeur + c] = donnees[anciens[n] * largeur + c]
		sortie[type] = copie
	sortie[Mesh.ARRAY_INDEX] = nouveaux
	return sortie


# Même matériau, textures réduites (l'unité fait quelques dizaines de pixels à l'écran).
func _materiau(source: Material, taille: int) -> Material:
	var materiau := source as BaseMaterial3D
	if materiau == null:
		return source
	var copie: BaseMaterial3D = materiau.duplicate()
	for propriete: StringName in [&"albedo_texture", &"normal_texture", &"orm_texture", &"roughness_texture",
			&"metallic_texture", &"emission_texture", &"ao_texture"]:
		if not propriete in copie:
			continue
		var texture: Texture2D = copie.get(propriete)
		if texture == null:
			continue
		var image: Image = texture.get_image()
		if image.is_compressed():
			image.decompress()
		image.resize(taille, taille, Image.INTERPOLATE_LANCZOS)
		image.generate_mipmaps()
		copie.set(propriete, ImageTexture.create_from_image(image))
	return copie
