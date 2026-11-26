extends Node3D
## Affiche le sol, les ports fixes et les rotors du plateau à partir du modèle.

const GrilleMonde = preload("res://game/board/grille_monde.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const ExtensionDef = preload("res://game/board/extension_def.gd")
const Extension = preload("res://game/board/extension.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const Materiaux = preload("res://game/core/materiaux.gd")
const MODELE_HORLOGE := "res://assets/final/horloge/horloge.glb"

# Masques des rigoles mesurées sur les socles exportés (N, E, S, O).
const PORTS_DU_KIT := {&"engrenage_droit": 5, &"engrenage_coude": 3, &"engrenage_t": 11, &"engrenage_croix": 15}
const VOISINS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const ECHELLE_PLATEAU := GrilleMonde.TAILLE_CASE / 2.0

@onready var _source: PlateauNoeud = get_parent()
var _ateliers: Dictionary[Vector2i, Node3D] = {}
var _rebonds_ateliers: Dictionary[Vector2i, Tween] = {}
var _rotors: Array[Node3D] = []
var _pieces: Node3D
## Sol affiché par case (vrai = chemin) et dalle correspondante : une case d'herbe pavée par un raccord est reconstruite.
var _cases_construites: Dictionary[Vector2i, bool] = {}
var _dalles: Dictionary[Vector2i, Node3D] = {}
var _bords: Dictionary[Vector3i, Node3D] = {}
var _poteaux: Dictionary[Vector2i, MeshInstance3D] = {}
var _horloge: Node3D
var _rebond: Tween
var _marqueurs: Node3D
var _sol: Node3D
var _gris: StandardMaterial3D = StandardMaterial3D.new()


func _ready() -> void:
	_gris.albedo_color = Color("#97958f", 0.58)
	_gris.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_regler_lumiere.call_deferred()
	Events.horloge_touchee.connect(_sur_horloge_touchee)
	Events.plateau_modifie.connect(_actualiser)
	Events.energie_recalculee.connect(_energie)
	_poser_table()


## Grande table d'établi sous la maquette : sans elle, le plateau flotte sur un fond uni (DA v2, « maquette posée »).
func _poser_table() -> void:
	var bois := StandardMaterial3D.new()
	var texture_bois := "res://assets/final/kit_v2/bord_plateau/bord_plateau_tex_bois_miel.png"
	bois.albedo_color = Color("#F2D2A8")
	if ResourceLoader.exists(texture_bois):
		bois.albedo_texture = load(texture_bois)
		bois.uv1_triplanar = true
		bois.uv1_scale = Vector3.ONE * 0.018
	bois.roughness = 0.5
	var plateau_table := BoxMesh.new()
	plateau_table.size = Vector3(140, 1, 140)
	_ajouter_forme(self, plateau_table, Vector3(0, -0.75, 0), bois)


# La scène d'ambiance est partagée ; ces réglages s'appliquent à la vue du plateau.
func _regler_lumiere() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var soleil := scene.find_child("SoleilBas", true, false) as DirectionalLight3D
	if soleil != null:
		soleil.rotation.x = deg_to_rad(-35.0)
		soleil.light_color = Color("#FFF0D4")
		soleil.light_angular_distance = 1.5
		soleil.shadow_blur = 1.2
	var ambiance: Environment = get_world_3d().environment
	if ambiance != null:
		ambiance.ssao_intensity = 3.5


func _instancier(nom: StringName) -> Node3D:
	var scene: PackedScene = Materiaux.scene_du_kit(nom)
	return scene.instantiate() as Node3D if scene != null else null


## Renvoie le matériau partagé pour cette teinte du plateau.
func materiau(nom: String) -> Material:
	return Materiaux.obtenir(nom)


func _actualiser() -> void:
	if _sol == null:
		_sol = Node3D.new()
		add_child(_sol)
	var nouvelles: Array[Vector2i] = []
	for c: Vector2i in _source.plateau.coords_sols():
		var chemin: bool = _source.plateau.sol_de(c) == _source.Plateau.Sol.CHEMIN
		if _cases_construites.has(c):
			if _cases_construites[c] == chemin:
				continue
			if is_instance_valid(_dalles.get(c)):
				_dalles[c].queue_free()
			_dalles[c] = _creer_sol(_sol, c, chemin)
			_cases_construites[c] = chemin
			continue
		_dalles[c] = _creer_sol(_sol, c, chemin)
		_cases_construites[c] = chemin
		nouvelles.append(c)
	for c: Vector2i in nouvelles:
		_actualiser_bords(c)
	var entrees: Array[Vector2i] = ChampFlux.entrees(_source.plateau, ChampFlux.calculer(_source.plateau))
	for case: Vector2i in _poteaux.keys():
		if case not in entrees:
			_poteaux[case].queue_free()
			_poteaux.erase(case)
	for case: Vector2i in entrees:
		if not _poteaux.has(case):
			var pied: Vector3 = GrilleMonde.vers_monde(case) + Vector3(0.72, 0.3, 0.72)
			_poteaux[case] = _boite(_sol, Vector3(0.16, 0.6, 0.16), pied, materiau("pastel_rose"))


# Un côté se crée à la première dalle et disparaît dès que la dalle voisine arrive.
func _actualiser_bords(case: Vector2i) -> void:
	for i: int in VOISINS.size():
		var voisin: Vector2i = case + VOISINS[i]
		if _cases_construites.has(voisin):
			var oppose := Vector3i(voisin.x, voisin.y, (i + 2) % 4)
			if _bords.has(oppose):
				_bords[oppose].queue_free()
				_bords.erase(oppose)
			continue
		var bord: Node3D = _instancier(&"bord_plateau")
		var hauteur_origine: float = -0.264
		# La moulure carrée de 1,98 m est ramenée à une bande de 16 cm.
		if bord != null:
			_sol.add_child(bord)
			bord.scale = Vector3(GrilleMonde.TAILLE_CASE / 1.98, ECHELLE_PLATEAU,
					0.16 * ECHELLE_PLATEAU / 1.98)
		else:
			hauteur_origine = -0.132
			bord = _boite(_sol, Vector3(2.0, 0.264, 0.16) * ECHELLE_PLATEAU,
					Vector3.ZERO, materiau("bois_plateau"))
		bord.rotation.y = -i * PI / 2.0
		var direction := Vector3(VOISINS[i].x, 0, VOISINS[i].y)
		bord.position = GrilleMonde.vers_monde(case) + direction * 1.06 * ECHELLE_PLATEAU
		# Le GLB a son origine au pied, la boîte de secours en son centre.
		bord.position.y = hauteur_origine * ECHELLE_PLATEAU
		_bords[Vector3i(case.x, case.y, i)] = bord


func _creer_sol(parent: Node3D, case: Vector2i, chemin: bool) -> Node3D:
	var variante: bool = (hash(case) & 1) != 0
	var nom: StringName = &"tuile_chemin" if chemin else (&"tuile_herbe_b" if variante else &"tuile_herbe")
	var dalle: Node3D = _instancier(nom)
	if dalle == null:
		var couleur: String = "pierre_creme" if chemin else ("herbe_sombre" if variante else "herbe")
		return _boite(parent, Vector3(1.94, 0.2, 1.94) * ECHELLE_PLATEAU,
				GrilleMonde.vers_monde(case) + Vector3.DOWN * 0.1 * ECHELLE_PLATEAU, materiau(couleur))
	parent.add_child(dalle)
	dalle.scale = Vector3.ONE * ECHELLE_PLATEAU
	# Le coussin d'herbe et le haut des pavés sont à 0,29 m ; les fleurs dépassent.
	dalle.position = GrilleMonde.vers_monde(case) + Vector3.DOWN * 0.29 * ECHELLE_PLATEAU
	return dalle


func _superposer(noeud: Node, teinte: Material) -> void:
	if noeud is GeometryInstance3D:
		noeud.material_overlay = teinte
	for enfant: Node in noeud.get_children():
		_superposer(enfant, teinte)


## Plante un fanion sur chaque pose d'extension possible.
func afficher_marqueurs(cases: Array[Vector2i]) -> void:
	if _marqueurs != null:
		_marqueurs.hide()
		_marqueurs.queue_free()
		_marqueurs = null
	if cases.is_empty():
		return
	_marqueurs = Node3D.new()
	add_child(_marqueurs)
	var bleu := StandardMaterial3D.new()
	bleu.albedo_color = Color("#3D8FD9", 0.7)
	bleu.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bleu.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var disque := CylinderMesh.new()
	disque.top_radius = 0.28
	disque.bottom_radius = 0.28
	disque.height = 0.04
	for case: Vector2i in cases:
		var marqueur: Node3D = _instancier(&"marqueur_extension")
		if marqueur != null:
			_marqueurs.add_child(marqueur)
			marqueur.position = GrilleMonde.vers_monde(case)
			var fanion := marqueur.find_child("Fanion*", true, false) as Node3D
			if fanion != null:
				var repos: float = fanion.rotation.z
				var vent: Tween = fanion.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
				vent.tween_property(fanion, "rotation:z", repos + 0.05, 0.7)
				vent.tween_property(fanion, "rotation:z", repos, 0.7)
			continue
		_ajouter_forme(_marqueurs, disque, GrilleMonde.vers_monde(case) + Vector3.UP * 0.04, bleu)


## Construit un aperçu orienté dont la teinte se superpose à l'herbe et au chemin.
## `raccord` : cases pavées en plus pour rejoindre la route, relatives au centre de l'extension.
func creer_extension(def: ExtensionDef, rotation: int, teinte: Material, raccord: Array[Vector2i] = []) -> Node3D:
	var racine := Node3D.new()
	var sols: Dictionary = Extension.cases(def, Vector2i.ZERO, rotation)
	for case: Vector2i in raccord:
		sols[case] = _source.Plateau.Sol.CHEMIN
	for case: Vector2i in sols:
		var dalle: Node3D = _creer_sol(racine, case, sols[case] == _source.Plateau.Sol.CHEMIN)
		dalle.scale *= Vector3(0.97, 1, 0.97)
		_superposer(dalle, teinte)
	return racine


func _energie(_alimentees: Array[Vector2i]) -> void:
	_reconstruire()


func _reconstruire() -> void:
	if _rebond:
		_rebond.kill()
	_horloge = null
	for animation: Tween in _rebonds_ateliers.values():
		animation.kill()
	_rebonds_ateliers.clear()
	_ateliers.clear()
	_rotors.clear()
	if _pieces != null:
		remove_child(_pieces)
		_pieces.queue_free()
	_pieces = Node3D.new()
	add_child(_pieces)
	for c: Vector2i in _source.plateau.coords_pieces():
		var piece: PieceDef = _source.plateau.piece_de(c)
		var racine: Node3D = creer_piece(piece, _source.plateau.ports_de(c),
				null if _source.alimentees.has(c) else _gris)
		_pieces.add_child(racine)
		racine.position = GrilleMonde.vers_monde(c)
		if piece.type == PieceDef.Type.ATELIER:
			_ateliers[c] = racine
		if piece.type == PieceDef.Type.HORLOGE:
			_horloge = racine
			if racine.get_child_count() > 0:
				racine.get_child(0).rotation.y = -_cote_porte(c) * PI / 2.0
		if piece.type == PieceDef.Type.ENGRENAGE and _source.alimentees.has(c):
			var rotor := racine.find_child("Rotor", true, false) as Node3D
			if rotor != null:
				_rotors.append(rotor)


# Le modèle de l'horloge a sa porte (cadran + arche) vers le nord (-Z). On la tourne vers la case de chemin qui la touche
# (premier côté trouvé dans l'ordre N, E, S, O) : la route mène toujours à la porte (playtest 1).
func _cote_porte(case: Vector2i) -> int:
	for i: int in VOISINS.size():
		if _source.plateau.sol_de(case + VOISINS[i]) == _source.Plateau.Sol.CHEMIN:
			return i
	return 0


## Anime la sortie d’un jouet si son atelier est au repos.
func rebondir(case: Vector2i) -> void:
	var atelier: Node3D = _ateliers.get(case)
	var precedent: Tween = _rebonds_ateliers.get(case)
	if atelier == null or (precedent != null and precedent.is_valid()):
		return
	var animation: Tween = atelier.create_tween().set_trans(Tween.TRANS_SINE)
	_rebonds_ateliers[case] = animation
	animation.tween_property(atelier, "scale", Vector3.ONE * 1.1, 0.08)
	animation.tween_property(atelier, "scale", Vector3.ONE, 0.08)


## Construit la même silhouette pour une pièce posée et pour son fantôme.
func creer_piece(piece: PieceDef, ports: int, teinte: Material = null) -> Node3D:
	var racine := Node3D.new()
	var modele: Node3D
	if piece.type == PieceDef.Type.HORLOGE:
		if ResourceLoader.exists(MODELE_HORLOGE):
			modele = (load(MODELE_HORLOGE) as PackedScene).instantiate() as Node3D
	else:
		modele = _instancier(piece.id)
	if modele != null:
		racine.add_child(modele)
		var ports_origine: int = PORTS_DU_KIT.get(piece.id, piece.ports)
		for tour: int in 4:
			if PieceDef.tourner_ports(ports_origine, tour) == ports:
				modele.rotate_y(-tour * PI / 2.0)
				break
		if piece.type == PieceDef.Type.TOURELLE:
			_colorer_rarete(modele, piece.rarete)
	else:
		_creer_piece_de_repli(racine, piece)
	var hauteur_dent: float = 0.26 if modele != null and piece.type != PieceDef.Type.HORLOGE else 0.15
	for i: int in 4:
		if ports & (1 << i):
			var dent: MeshInstance3D = _boite(racine, Vector3(0.32, 0.24, 0.43),
					Vector3.FORWARD.rotated(Vector3.UP, -i * PI / 2) * 0.77 + Vector3.UP * hauteur_dent,
					materiau("laiton"))
			dent.rotation.y = -i * PI / 2
	if teinte != null:
		_superposer(racine, teinte)
	return racine


func _colorer_rarete(noeud: Node, rarete: PieceDef.Rarete) -> void:
	if noeud is MeshInstance3D and noeud.mesh != null:
		for i: int in noeud.mesh.get_surface_count():
			var origine := noeud.get_active_material(i) as StandardMaterial3D
			if origine != null and origine.resource_name == "Rarete":
				var finition := origine.duplicate() as StandardMaterial3D
				finition.albedo_color = PieceDef.TEINTES_RARETE[rarete]
				noeud.set_surface_override_material(i, finition)
	for enfant: Node in noeud.get_children():
		_colorer_rarete(enfant, rarete)


func _creer_piece_de_repli(racine: Node3D, piece: PieceDef) -> void:
	match piece.type:
		PieceDef.Type.HORLOGE:
			_cylindre(racine, 0.72, 1.5, materiau("bois_clair"))
		PieceDef.Type.ENGRENAGE:
			var rotor := Node3D.new()
			rotor.name = "Rotor"
			racine.add_child(rotor)
			_cylindre(rotor, 0.65, 0.3, materiau("laiton"))
			_boite(rotor, Vector3(0.94, 0.09, 0.14), Vector3.UP * 0.34,
					materiau("bois_plateau"))
		PieceDef.Type.TOURELLE:
			_cylindre(racine, 0.62, 0.38, materiau("bois_clair"))
			var finition := StandardMaterial3D.new()
			finition.albedo_color = PieceDef.TEINTES_RARETE[piece.rarete]
			var fut := CylinderMesh.new()
			fut.bottom_radius = 0.22
			fut.top_radius = 0.22
			fut.height = 0.95
			var inclinaison: float = 65.0
			match piece.rarete:
				PieceDef.Rarete.RARE:
					# La cloche s'évase au-dessus du socle.
					fut.bottom_radius = 0.46
					fut.height = 0.55
					inclinaison = 0.0
				PieceDef.Rarete.EPIQUE:
					fut.top_radius = 0.35
					inclinaison = 35.0
			var canon: MeshInstance3D = _ajouter_forme(racine, fut, Vector3.UP * 0.61,
					finition)
			canon.rotation.x = deg_to_rad(inclinaison)
		PieceDef.Type.ATELIER:
			var a_billes: bool = piece.id == &"atelier_billes"
			_boite(racine, Vector3(1.18, 0.85, 1.18), Vector3.UP * 0.425,
					materiau("pastel_vert" if a_billes else "pastel_bleu"))
			if a_billes:
				var tour := Node3D.new()
				racine.add_child(tour)
				tour.position.y = 0.85
				_cylindre(tour, 0.34, 0.48, materiau("jouet_menthe"))
				var bille := SphereMesh.new()
				bille.radius = 0.23
				bille.height = 0.46
				_ajouter_forme(tour, bille, Vector3.UP * 0.66, materiau("laiton"))
			else:
				# Atelier de soldats : toit à deux pans rouge jouet + clé de remontoir en laiton sur le faîte.
				# Vu de dessus, le faîte et les deux pans ombrés le distinguent tout de suite d'une simple caisse.
				var toit := PrismMesh.new()
				toit.size = Vector3(1.34, 0.5, 1.3)
				_ajouter_forme(racine, toit, Vector3.UP * 1.1, materiau("jouet_rouge"))
				_boite(racine, Vector3(0.08, 0.3, 0.08), Vector3(0, 1.48, 0.25), materiau("laiton"))
				_boite(racine, Vector3(0.36, 0.2, 0.06), Vector3(0, 1.68, 0.25), materiau("laiton"))


func _boite(parent: Node3D, taille: Vector3, centre: Vector3, mat: Material) -> MeshInstance3D:
	var forme := BoxMesh.new()
	forme.size = taille
	return _ajouter_forme(parent, forme, centre, mat)


func _cylindre(parent: Node3D, rayon: float, hauteur: float, mat: Material) -> void:
	var forme := CylinderMesh.new()
	forme.top_radius = rayon
	forme.bottom_radius = rayon
	forme.height = hauteur
	_ajouter_forme(parent, forme, Vector3.UP * hauteur / 2, mat)


func _ajouter_forme(parent: Node3D, forme: Mesh, centre: Vector3, mat: Material) -> MeshInstance3D:
	var volume := MeshInstance3D.new()
	volume.mesh = forme
	volume.material_override = mat
	volume.position = centre
	parent.add_child(volume)
	return volume


func _sur_horloge_touchee(_pv_restants: int) -> void:
	if _horloge == null:
		return
	if _rebond:
		_rebond.kill()
	_horloge.scale = Vector3.ONE
	_rebond = _horloge.create_tween().set_trans(Tween.TRANS_SINE)
	_rebond.tween_property(_horloge, "scale", Vector3.ONE * 1.08, 0.08)
	_rebond.tween_property(_horloge, "scale", Vector3.ONE, 0.17)


func _process(delta: float) -> void:
	for rotor: Node3D in _rotors:
		rotor.rotate_y(delta * 2.0)
