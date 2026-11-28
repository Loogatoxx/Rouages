extends Node3D
## Affiche le sol, les ports fixes et les rotors du plateau à partir du modèle.

const GrilleMonde = preload("res://game/board/grille_monde.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const ExtensionDef = preload("res://game/board/extension_def.gd")
const Extension = preload("res://game/board/extension.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const Materiaux = preload("res://game/core/materiaux.gd")
const DecoupeTourelle = preload("res://game/board/decoupe_tourelle.gd")
const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const MODELE_HORLOGE := "res://assets/final/horloge/horloge.glb"

# Masques des rigoles mesurées sur les socles exportés (N, E, S, O).
const PORTS_DU_KIT := {&"engrenage_droit": 5, &"engrenage_coude": 3, &"engrenage_t": 11, &"engrenage_croix": 15,
		&"pont": 10, &"generateur": 15}
const VOISINS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## Tourelles dont la tête pivote seule (playtest 3) : [seuil de coupe (fraction de la hauteur), découpe par morceaux,
## le fût regarde vers +Z dans le modèle]. Une tourelle absente d'ici ne pivote pas (le carillon est un clocher).
const TETES := {&"tourelle_canon": [0.2, false, true], &"tourelle_mortier": [0.22, false, true]}
static var _decoupes: Dictionary[StringName, DecoupeTourelle.Decoupe] = {}
## Pièces qui bougent seules (P3-43, vie ambiante), détachées une fois du modèle d'un seul bloc : nom du modèle →
## [nom, zone (fractions de l'AABB du maillage), pivot en haut, axe (repère du maillage), mouvement]. « tic » : la clé
## de remontoir avance d'un huitième de tour à chaque seconde, comme un échappement d'horloge ; « balance » : la
## cloche se balance (plus fort au coup de carillon). Les clés des ateliers ne tournent que s'ils sont alimentés.
const PIECES_MOBILES := {
	&"horloge": [
		[&"Cle", AABB(Vector3(0.0, 0.56, 0.0), Vector3(0.185, 0.11, 1.0)), false, Vector3.RIGHT, &"tic"],
		[&"Cloche", AABB(Vector3(0.485, 0.772, 0.445), Vector3(0.12, 0.098, 0.11)), true, Vector3.BACK, &"balance"],
	],
	&"atelier_soldats": [[&"Cle", AABB(Vector3(0.0, 0.86, 0.0), Vector3(1.0, 0.14, 1.0)), false, Vector3.UP, &"tic"]],
	&"atelier_soldats_n3": [[&"Cle", AABB(Vector3(0.25, 0.835, 0.0), Vector3(0.45, 0.165, 1.0)), false, Vector3.UP, &"tic"]],
}
## Résultat des extractions par modèle : [socle restant, Array des découpes (null si la zone était vide)].
static var _pieces_detachees: Dictionary[StringName, Array] = {}
var _mobiles: Array[Node3D] = []
var _temps_vie: float = 0.0
var _volee: float = 0.0
const ECHELLE_PLATEAU := GrilleMonde.TAILLE_CASE / 2.0

@onready var _source: PlateauNoeud = get_parent()
var _ateliers: Dictionary[Vector2i, Node3D] = {}
## Tourelles posées (P2-34) : elles pivotent vers leur cible et reculent à chaque tir.
var _tourelles: Dictionary[Vector2i, Node3D] = {}
var _tirs_tourelles: Dictionary[Vector2i, Tween] = {}
var _rebonds_ateliers: Dictionary[Vector2i, Tween] = {}
var _rotors: Array[Node3D] = []
var _insignes: Dictionary[Vector2i, Node3D] = {}
var _pieces: Node3D
## Sol affiché par case (vrai = chemin) et dalle correspondante : une case d'herbe pavée par un raccord est reconstruite.
var _cases_construites: Dictionary[Vector2i, int] = {}
## Décors posés (playtest 3), matériaux teintés par la palette de la carte, voile de marée sur les routes inondées.
var _decors_poses: Dictionary[Vector2i, Node3D] = {}
var _teintes: Dictionary = {}
var _voile_maree: Node3D
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
	Events.carillon_sonne.connect(_sur_carillon)
	Events.phase_changee.connect(_montrer_maree)
	Events.train_part.connect(_faire_rouler_train)
	# Une extension peut changer les entrées : la marée et les objets d'établi suivent (relecture T14c).
	Events.plateau_modifie.connect(func() -> void:
		if Run.depart.maree and Run.phase == Run.Phase.CONSTRUCTION:
			_montrer_maree(Run.phase, false)
		_placer_objets_etabli())
	Events.plateau_modifie.connect(_actualiser)
	Events.energie_recalculee.connect(_energie)
	_poser_table()
	_ecouter_tirs.call_deferred()
	# Micro-détails d'ambiance (poussière dorée, pétales) : seulement avec un vrai rendu, pas en headless.
	if DisplayServer.get_name() != "headless":
		add_child(preload("res://game/board/ambiance_plateau.gd").new())


# Les tirs viennent de la simulation de la partie (signal `tir`) ; le visuel ne fait que les montrer.
func _ecouter_tirs() -> void:
	var partie: Node = get_tree().get_first_node_in_group(&"partie")
	if partie != null and not partie.sim.tir.is_connected(_sur_tir):
		partie.sim.tir.connect(_sur_tir)


# Visée et recul (playtest 3) : seule la tête de la tourelle (nœud « Tete », voir `_separer_tete`) pivote vers
# l'impact ; le socle reste fixe. Puis la tête se tasse et revient comme un ressort. Une tourelle sans tête séparée
# (carillon) ne pivote pas : elle se tasse seulement.
func _sur_tir(depart: Vector2, arrivee: Vector2) -> void:
	var case := Vector2i((depart / GrilleMonde.TAILLE_CASE).round())
	var racine: Node3D = _tourelles.get(case)
	if racine == null or racine.get_child_count() == 0 or not depart.is_equal_approx(Vector2(case) * GrilleMonde.TAILLE_CASE):
		return
	var modele: Node3D = racine.get_child(0) as Node3D
	if modele == null:
		return
	var precedent: Tween = _tirs_tourelles.get(case)
	if precedent != null and precedent.is_valid():
		precedent.kill()
	# Impact visible selon la tourelle : onde bleue du carillon, souffle de l'obus, étincelle du boulet.
	var piece: PieceDef = _source.plateau.piece_de(case)
	if piece != null and piece.ralentissement > 0.0:
		_onde(arrivee, maxf(1.0, piece.zone_tir), Color(0.55, 0.78, 1.0, 0.75))
	elif piece != null and piece.zone_tir > 0.0:
		_onde(arrivee, piece.zone_tir, Color(1.0, 0.9, 0.7, 0.85), 0.35)
	else:
		_onde(arrivee, 0.5, Color(1.0, 0.95, 0.8, 0.9), 0.2)
	var tete: Node3D = modele.find_child("Tete", true, false) as Node3D
	var mobile: Node3D = tete if tete != null else modele
	var repos: Vector3 = mobile.get_meta(&"echelle_repos", mobile.scale)
	mobile.set_meta(&"echelle_repos", repos)
	var animation: Tween = mobile.create_tween()
	_tirs_tourelles[case] = animation
	if tete != null:
		var direction: Vector2 = arrivee - depart
		# Lacet (dans le repère de la case) qui aligne le fût sur la cible, selon que le modèle regarde vers +Z ou −Z.
		var cap: float = atan2(direction.x, direction.y) if tete.get_meta(&"avant_plus_z", false) \
				else atan2(-direction.x, -direction.y)
		cap -= modele.rotation.y  # la tête est un enfant du modèle, déjà tourné selon ses ports
		var actuel: float = tete.rotation.y
		cap = actuel + wrapf(cap - actuel, -PI, PI)
		animation.tween_property(tete, "rotation:y", cap, 0.08).set_trans(Tween.TRANS_SINE)
	animation.tween_property(mobile, "scale", repos * Vector3(1.08, 0.86, 1.08), 0.05)
	animation.tween_property(mobile, "scale", repos, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Sépare le maillage d'une tourelle en socle fixe + tête pivotante (une seule découpe par modèle, gardée en mémoire).
func _separer_tete(modele: Node3D, id: StringName, nom_modele: StringName) -> void:
	if not TETES.has(id):
		return
	var volume: MeshInstance3D = _premier_maillage(modele)
	if volume == null:
		return
	var reglage: Array = TETES.get(nom_modele, TETES[id])
	# Découpe mémorisée par modèle : le palier « _n3 » a son propre maillage, il ne réutilise pas celle du niveau 1.
	if not _decoupes.has(nom_modele):
		_decoupes[nom_modele] = DecoupeTourelle.decouper(volume.mesh, reglage[0], reglage[1])
	var decoupe: DecoupeTourelle.Decoupe = _decoupes[nom_modele]
	if decoupe == null:
		return
	volume.mesh = decoupe.socle
	var tete := Node3D.new()
	tete.name = "Tete"
	tete.set_meta(&"avant_plus_z", reglage[2])
	volume.get_parent().add_child(tete)
	# Même repère que le socle, déplacé sur le pivot : la tête tourne autour de son propre axe.
	tete.transform = volume.transform.translated_local(decoupe.pivot)
	var haut := MeshInstance3D.new()
	haut.mesh = decoupe.tete
	haut.position = -decoupe.pivot
	tete.add_child(haut)


# Vie ambiante (P3-43) : détache les pièces mobiles du modèle (voir PIECES_MOBILES). Chaque pièce devient un nœud
# « Mobile<nom> » posé sur son pivot ; `_process` le fait tourner autour de son axe. Sans géométrie lisible (rendu
# sans fenêtre), le modèle reste entier et immobile.
func _detacher_pieces(modele: Node3D, nom_modele: StringName) -> void:
	if not PIECES_MOBILES.has(nom_modele):
		return
	var volume: MeshInstance3D = _premier_maillage(modele)
	if volume == null:
		return
	if not _pieces_detachees.has(nom_modele):
		var reference: AABB = volume.mesh.get_aabb()
		var reste: Mesh = volume.mesh
		var decoupes: Array = []
		for reglage: Array in PIECES_MOBILES[nom_modele]:
			var decoupe: DecoupeTourelle.Decoupe = DecoupeTourelle.extraire(reste, reglage[1], reglage[2], reference)
			decoupes.append(decoupe)
			if decoupe != null:
				reste = decoupe.socle
		_pieces_detachees[nom_modele] = [reste, decoupes]
	var chaine: Array = _pieces_detachees[nom_modele]
	volume.mesh = chaine[0]
	for k: int in (chaine[1] as Array).size():
		var decoupe: DecoupeTourelle.Decoupe = chaine[1][k]
		if decoupe == null:
			continue
		var reglage: Array = PIECES_MOBILES[nom_modele][k]
		var mobile := Node3D.new()
		mobile.name = "Mobile%s" % reglage[0]
		volume.get_parent().add_child(mobile)
		mobile.transform = volume.transform.translated_local(decoupe.pivot)
		mobile.set_meta(&"base", mobile.transform)
		mobile.set_meta(&"axe", reglage[3])
		mobile.set_meta(&"mouvement", reglage[4])
		var piece := MeshInstance3D.new()
		piece.mesh = decoupe.tete
		piece.position = -decoupe.pivot
		mobile.add_child(piece)


# Playtest 3 (« les troupes traversent le Pont ») : le tablier est tourné dans le sens de la route et élargi, les
# unités marchent dessus (`SwarmSim.relief`) ; l'arbre de laiton, lui, passe dessous, d'une rive d'herbe à l'autre.
# Le dessus du tablier est dégagé (paliers et arceaux de l'ancien arbre) pour que rien ne traverse les jouets.
static var _tablier_degage: Mesh

func _amenager_pont(modele: Node3D) -> void:
	# Pont Hyper3D (playtest 3) : son tablier long est tourné dans le sens de la route (perpendiculaire aux ports,
	# qui regardent l'herbe des deux côtés), et sa hauteur est calée sur celle où marchent les unités.
	if modele.get_meta(&"face_plus_z", false):
		var volume: MeshInstance3D = _premier_maillage(modele)
		if volume != null:
			var boite: AABB = volume.mesh.get_aabb()
			if boite.size.x > boite.size.z:
				var pivot := Node3D.new()
				pivot.rotation.y = PI / 2.0
				modele.add_child(pivot)
				volume.reparent(pivot, false)
			# Hauteur du tablier : on aplatit le modèle pour que son dessus soit à la hauteur du relief des unités.
			var hauteur: float = boite.size.y * volume.scale.y
			if hauteur > 0.01:
				modele.scale.y = clampf(SwarmSim.HAUTEUR_PONT * 1.15 / hauteur, 0.4, 1.6)
		return
	var structure := modele.find_child("Pont_Structure", true, false) as MeshInstance3D
	var arbre := modele.find_child("Arbre_Engrenage", true, false) as Node3D
	if structure == null or arbre == null:
		return
	if _tablier_degage == null:
		_tablier_degage = DecoupeTourelle.degager(structure.mesh, 0.57, 0.36)
	structure.mesh = _tablier_degage
	structure.rotation.y = PI / 2.0
	structure.scale = Vector3(1.0, 1.0, 1.6)
	arbre.position.y = 0.2
	arbre.scale = Vector3(1.0, 0.9, 0.9)


func _premier_maillage(noeud: Node) -> MeshInstance3D:
	if noeud is MeshInstance3D and (noeud as MeshInstance3D).mesh != null:
		return noeud
	for enfant: Node in noeud.get_children():
		var trouve: MeshInstance3D = _premier_maillage(enfant)
		if trouve != null:
			return trouve
	return null


## Grande table d'établi sous la maquette : sans elle, le plateau flotte sur un fond uni (DA v2, « maquette posée »).
func _poser_table() -> void:
	# Bois procédural (PT-56) : planches, joints, fil et nœuds calculés dans l'espace du monde (`table_bois.gdshader`).
	var bois := ShaderMaterial.new()
	bois.shader = preload("res://game/board/table_bois.gdshader")
	# Palette de la carte : le bois de la table prend la teinte du plateau choisi.
	var teinte: Color = Run.depart.teinte_table
	if teinte != Color.WHITE:
		bois.set_shader_parameter(&"miel", Vector3(0.70, 0.46, 0.25) * Vector3(teinte.r, teinte.g, teinte.b))
		bois.set_shader_parameter(&"noyer", Vector3(0.50, 0.30, 0.15) * Vector3(teinte.r, teinte.g, teinte.b))
		bois.set_shader_parameter(&"clair", Vector3(0.80, 0.58, 0.36) * Vector3(teinte.r, teinte.g, teinte.b))
	var plateau_table := BoxMesh.new()
	plateau_table.size = Vector3(140, 1, 140)
	_ajouter_forme(self, plateau_table, Vector3(0, -0.75, 0), bois)
	_poser_objets_etabli()


## Objets géants de l'établi autour de la maquette (playtest 3, « la table est déserte ») : tasse, bobine, loupe,
## tournevis, carnet (kit Blender de Gemini). Ils donnent l'échelle « jouet » et occupent le cadre sans jamais
## recouvrir le plateau : chacun est placé par rapport au bord du terrain de la carte.
## [modèle, côté (-1 ouest / +1 est), position le long du bord (0 = nord, 1 = sud), recul depuis le bord, lacet en degrés].
const OBJETS_ETABLI := [
	[&"table_tasse", 1, 0.12, 6.5, 20.0], [&"table_loupe", -1, 0.3, 7.5, -35.0], [&"table_bobine", 1, 0.78, 5.5, 60.0],
	[&"table_carnet", -1, 0.92, 8.0, 12.0], [&"table_tournevis", 1, 0.48, 9.5, 80.0],
]

var _objets_etabli: Array[Node3D] = []
var _bornes_etabli: Rect2i

func _poser_objets_etabli() -> void:
	for objet: Array in OBJETS_ETABLI:
		var modele: Node3D = _instancier(objet[0])
		if modele != null:
			add_child(modele)
			modele.rotation.y = deg_to_rad(objet[4])
		_objets_etabli.append(modele)
	_placer_objets_etabli.call_deferred()


# Place les objets d'après les bornes ACTUELLES du terrain (une extension peut l'agrandir vers un objet).
func _placer_objets_etabli() -> void:
	if _source == null or _source.plateau == null or _objets_etabli.is_empty():
		return
	var mini := Vector2i(1 << 20, 1 << 20)
	var maxi := Vector2i(-(1 << 20), -(1 << 20))
	for case: Vector2i in _source.plateau.coords_sols():
		mini = mini.min(case)
		maxi = maxi.max(case)
	var bornes := Rect2i(mini, maxi - mini + Vector2i.ONE)
	if bornes == _bornes_etabli:
		return
	_bornes_etabli = bornes
	var ouest: float = (bornes.position.x - 0.5) * GrilleMonde.TAILLE_CASE
	var est: float = (bornes.end.x - 0.5) * GrilleMonde.TAILLE_CASE
	var nord: float = (bornes.position.y - 0.5) * GrilleMonde.TAILLE_CASE
	var sud: float = (bornes.end.y - 0.5) * GrilleMonde.TAILLE_CASE
	for k: int in OBJETS_ETABLI.size():
		var modele: Node3D = _objets_etabli[k]
		if modele == null:
			continue
		var objet: Array = OBJETS_ETABLI[k]
		var x: float = (est + objet[3]) if objet[1] > 0 else (ouest - objet[3])
		# La table est à 0,25 m sous le dessus de l'herbe : les objets y reposent.
		modele.position = Vector3(x, -0.25, lerpf(nord, sud, objet[2]))


# La scène d'ambiance est partagée ; ces réglages s'appliquent à la vue du plateau.
func _regler_lumiere() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var soleil := scene.find_child("SoleilBas", true, false) as DirectionalLight3D
	if soleil != null:
		soleil.rotation.x = deg_to_rad(-35.0)
		soleil.light_color = Color("#FFF0D4") * Run.depart.lumiere
		soleil.light_angular_distance = 1.5
		soleil.shadow_blur = 1.2
	var ambiance: Environment = get_world_3d().environment
	if ambiance != null:
		ambiance.ssao_intensity = 3.5


func _instancier(nom: StringName) -> Node3D:
	var hyper3d: Node3D = _modele_hyper3d(nom)
	if hyper3d != null:
		return hyper3d
	var scene: PackedScene = Materiaux.scene_du_kit(nom)
	var noeud: Node3D = scene.instantiate() as Node3D if scene != null else null
	if noeud != null:
		_jouer_animation(noeud)
	return noeud


## Modèle Hyper3D allégé d'un bâtiment (`assets/final/<nom>/<nom>_h3d.res`, PT-51), prioritaire sur le kit Blender.
## Mis à l'échelle d'une case (emprise de 1,9 m sur 2 m), recentré sur la case, pivot au sol ; sa face avant (+Z)
## correspond au port sud du kit, donc la même rotation par ports s'applique.
const EMPRISE_H3D := 1.9
const MODELE_BATIMENT_H3D := "res://assets/final/%s/%s_h3d.res"
var _maillages_h3d: Dictionary[StringName, Mesh] = {}


func _modele_hyper3d(nom: StringName) -> Node3D:
	if not _maillages_h3d.has(nom):
		var chemin: String = MODELE_BATIMENT_H3D % [nom, nom]
		_maillages_h3d[nom] = load(chemin) as Mesh if ResourceLoader.exists(chemin) else null
	var maillage: Mesh = _maillages_h3d[nom]
	if maillage == null:
		return null
	var boite: AABB = maillage.get_aabb()
	var echelle: float = EMPRISE_H3D / maxf(boite.size.x, boite.size.z)
	var racine := Node3D.new()
	var volume := MeshInstance3D.new()
	volume.mesh = maillage
	volume.scale = Vector3.ONE * echelle
	var centre: Vector3 = boite.get_center()
	volume.position = Vector3(-centre.x, -boite.position.y, -centre.z) * echelle
	racine.add_child(volume)
	# Face avant vers +Z (le kit regarde vers −Z) : la visée des tourelles en tient compte.
	racine.set_meta(&"face_plus_z", true)
	return racine


## Pont vers les modèles animés (PT-53, Hyper3D) : si un modèle du kit arrive avec un AnimationPlayer, on joue en boucle
## son animation « travail » (ou « idle », sinon la première). Le kit actuel n'en a pas : rien ne change aujourd'hui.
static func _jouer_animation(noeud: Node) -> void:
	var lecteur := noeud.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if lecteur == null or lecteur.get_animation_list().is_empty():
		return
	var nom: StringName = lecteur.get_animation_list()[0]
	for prefere: StringName in [&"travail", &"idle"]:
		if lecteur.has_animation(prefere):
			nom = prefere
			break
	var animation: Animation = lecteur.get_animation(nom)
	animation.loop_mode = Animation.LOOP_LINEAR
	lecteur.play(nom)


## Renvoie le matériau partagé pour cette teinte du plateau.
func materiau(nom: String) -> Material:
	return Materiaux.obtenir(nom)


func _actualiser() -> void:
	_actualiser_insignes()
	if _sol == null:
		_sol = Node3D.new()
		add_child(_sol)
	var nouvelles: Array[Vector2i] = []
	for c: Vector2i in _source.plateau.coords_sols():
		var sol: int = _source.plateau.sol_de(c)
		var chemin: bool = sol == _source.Plateau.Sol.CHEMIN
		var eau: bool = sol == _source.Plateau.Sol.EAU
		if _cases_construites.has(c):
			if _cases_construites[c] == sol:
				continue
			if is_instance_valid(_dalles.get(c)):
				_dalles[c].queue_free()
			_dalles[c] = _creer_sol(_sol, c, chemin, eau)
			_cases_construites[c] = sol
			continue
		_dalles[c] = _creer_sol(_sol, c, chemin, eau)
		_cases_construites[c] = sol
		nouvelles.append(c)
	for c: Vector2i in nouvelles:
		_actualiser_bords(c)
	# Décors de la carte (bosquet, rocher, mare…) : posés une fois, tournés d'un quart de tour choisi par la case.
	# Une plaque de manège qui redevient route disparaît.
	for c: Vector2i in _decors_poses.keys():
		if _source.plateau.decor_de(c) == &"":
			if is_instance_valid(_decors_poses[c]):
				_decors_poses[c].queue_free()
			_decors_poses.erase(c)
	_poser_voie_ferree()
	for c: Vector2i in _source.plateau.coords_decors():
		if _decors_poses.has(c):
			continue
		var nom_decor: StringName = _source.plateau.decor_de(c)
		if nom_decor == &"decor_rail":
			continue  # dessiné avec toute la voie par `_poser_voie_ferree`
		if nom_decor == &"decor_plaque":
			_decors_poses[c] = _plaque_tournante(c)
			continue
		var decor: Node3D = _instancier(nom_decor)
		if decor == null:
			continue
		_sol.add_child(decor)
		decor.position = GrilleMonde.vers_monde(c)
		decor.rotation.y = (hash(c) % 4) * PI / 2.0
		_decors_poses[c] = decor
	var entrees: Array[Vector2i] = ChampFlux.entrees(_source.plateau, ChampFlux.calculer(_source.plateau))
	for case: Vector2i in _poteaux.keys():
		if case not in entrees:
			_poteaux[case].queue_free()
			_poteaux.erase(case)
	for case: Vector2i in entrees:
		if not _poteaux.has(case):
			var pied: Vector3 = GrilleMonde.vers_monde(case) + Vector3(0.72, 0.3, 0.72)
			_poteaux[case] = _boite(_sol, Vector3(0.16, 0.6, 0.16), pied, materiau("pastel_rose"))


# Les insignes restent sur le socle pendant que le rotor tourne ou que l'atelier rebondit.
func _actualiser_insignes() -> void:
	for case: Vector2i in _insignes.keys():
		if _source.plateau.niveau_de(case) != _insignes[case].get_meta(&"niveau"):
			_insignes[case].queue_free()
			_insignes.erase(case)
	for case: Vector2i in _source.plateau.coords_pieces():
		var niveau: int = _source.plateau.niveau_de(case)
		if niveau > 1 and not _insignes.has(case):
			var socle: Node3D = Node3D.new()
			add_child(socle)
			socle.position = GrilleMonde.vers_monde(case)
			socle.set_meta(&"niveau", niveau)
			_insignes[case] = socle
			_decorer_niveau(socle, niveau)


func _decorer_niveau(socle: Node3D, niveau: int) -> void:
	var laiton: Material = materiau("laiton")
	var bille: SphereMesh = SphereMesh.new()
	bille.radius = 0.09
	bille.height = 0.18
	bille.radial_segments = 12
	bille.rings = 6
	for i: int in range(niveau - 1):
		var x: float = (i - (niveau - 2) * 0.5) * 0.22
		_ajouter_forme(socle, bille, Vector3(x, 0.37, 0.86), laiton)
	if niveau >= 3:
		var anneau: TorusMesh = TorusMesh.new()
		anneau.inner_radius = 0.85
		anneau.outer_radius = 0.94
		anneau.rings = 36
		anneau.ring_segments = 8
		_ajouter_forme(socle, anneau, Vector3.UP * 0.19, laiton)
	if niveau >= 5:
		_boite(socle, Vector3(0.045, 1.65, 0.045), Vector3(-0.7, 0.825, 0.6), laiton)
		var fanion: PrismMesh = PrismMesh.new()
		fanion.size = Vector3(0.31, 0.46, 0.055)
		var tissu: MeshInstance3D = _ajouter_forme(socle, fanion, Vector3(-0.47, 1.49, 0.6), laiton)
		tissu.rotation.z = -PI / 2.0


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


func _creer_sol(parent: Node3D, case: Vector2i, chemin: bool, eau: bool = false) -> Node3D:
	var variante: bool = (hash(case) & 1) != 0
	var nom: StringName = &"tuile_chemin" if chemin else (&"tuile_herbe_b" if variante else &"tuile_herbe")
	if eau:
		nom = &"tuile_eau"
	var dalle: Node3D = _instancier(nom)
	if dalle == null and eau:
		# Repli : une plaque d'émail bleu, un peu plus basse que l'herbe (en attendant le modèle `tuile_eau`).
		var email := StandardMaterial3D.new()
		email.albedo_color = Color("#8FC3E8")
		email.roughness = 0.12
		email.metallic = 0.15
		return _boite(parent, Vector3(1.98, 0.14, 1.98) * ECHELLE_PLATEAU,
				GrilleMonde.vers_monde(case) + Vector3.DOWN * 0.2 * ECHELLE_PLATEAU, email)
	if dalle == null:
		var couleur: String = "pierre_creme" if chemin else ("herbe_sombre" if variante else "herbe")
		return _boite(parent, Vector3(1.94, 0.2, 1.94) * ECHELLE_PLATEAU,
				GrilleMonde.vers_monde(case) + Vector3.DOWN * 0.1 * ECHELLE_PLATEAU, materiau(couleur))
	parent.add_child(dalle)
	dalle.scale = Vector3.ONE * ECHELLE_PLATEAU
	# Le coussin d'herbe et le haut des pavés sont à 0,29 m ; les fleurs dépassent.
	dalle.position = GrilleMonde.vers_monde(case) + Vector3.DOWN * 0.29 * ECHELLE_PLATEAU
	if not eau:
		_teinter(dalle, Run.depart.teinte_route if chemin else Run.depart.teinte_herbe)
	return dalle


# Palette de la carte (playtest 3) : multiplie la couleur des matériaux de la dalle par la teinte de la carte.
# Une copie par couple (matériau, teinte), gardée en mémoire : des centaines de dalles partagent quelques matériaux.
func _teinter(noeud: Node, teinte: Color) -> void:
	if teinte == Color.WHITE:
		return
	if noeud is MeshInstance3D and (noeud as MeshInstance3D).mesh != null:
		var maille: MeshInstance3D = noeud
		for i: int in maille.mesh.get_surface_count():
			var origine := maille.get_active_material(i) as StandardMaterial3D
			if origine == null:
				continue
			var cle: Array = [origine, teinte]
			if not _teintes.has(cle):
				var copie := origine.duplicate() as StandardMaterial3D
				copie.albedo_color = origine.albedo_color * teinte
				_teintes[cle] = copie
			maille.set_surface_override_material(i, _teintes[cle])
	for enfant: Node in noeud.get_children():
		_teinter(enfant, teinte)


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
	# Un repère tous les 3 cases au plus (règle R3 : détail sans surcharge) ; la pose reste permise partout où c'est valide.
	var gardes: Array[Vector2i] = []
	var tries: Array[Vector2i] = cases.duplicate()
	tries.sort()
	for candidat: Vector2i in tries:
		var libre: bool = true
		for garde: Vector2i in gardes:
			if maxi(absi(garde.x - candidat.x), absi(garde.y - candidat.y)) < 3:
				libre = false
				break
		if libre:
			gardes.append(candidat)
	for case: Vector2i in gardes:
		# Petit chantier de maquette (playtest 1 : les fanions étaient trop discrets), flèche vers l'extérieur.
		var marqueur: Node3D = _instancier(&"chantier_extension")
		if marqueur == null:
			marqueur = _instancier(&"marqueur_extension")
		if marqueur != null:
			_marqueurs.add_child(marqueur)
			marqueur.position = GrilleMonde.vers_monde(case)
			marqueur.rotation.y = -_cote_exterieur(case) * PI / 2.0
			var panneau := marqueur.find_child("Panneau*", true, false) as Node3D
			if panneau == null:
				panneau = marqueur.find_child("Fanion*", true, false) as Node3D
			if panneau != null:
				var repos: float = panneau.rotation.z
				var vent: Tween = panneau.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
				vent.tween_property(panneau, "rotation:z", repos + 0.05, 0.9)
				vent.tween_property(panneau, "rotation:z", repos - 0.03, 0.9)
			continue
		_ajouter_forme(_marqueurs, disque, GrilleMonde.vers_monde(case) + Vector3.UP * 0.04, bleu)


# Côté (N, E, S, O) qui s'éloigne le plus du plateau depuis une case hors terrain : la flèche du chantier y pointe.
# Le modèle a sa flèche vers -Z (nord) : un quart de tour par côté, comme les ports.
func _cote_exterieur(case: Vector2i) -> int:
	var proche: Vector2i = case
	var meilleure: int = -1
	for sol: Vector2i in _source.plateau.coords_sols():
		var d: int = absi(sol.x - case.x) + absi(sol.y - case.y)
		if meilleure < 0 or d < meilleure:
			meilleure = d
			proche = sol
	var ecart: Vector2i = case - proche
	if absi(ecart.x) >= absi(ecart.y):
		return 1 if ecart.x > 0 else 3
	return 2 if ecart.y > 0 else 0


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
	_tourelles.clear()
	_tirs_tourelles.clear()
	_rotors.clear()
	_mobiles.clear()
	if _pieces != null:
		remove_child(_pieces)
		_pieces.queue_free()
	_pieces = Node3D.new()
	add_child(_pieces)
	for c: Vector2i in _source.plateau.coords_pieces():
		var piece: PieceDef = _source.plateau.piece_de(c)
		var racine: Node3D = creer_piece(piece, _source.plateau.ports_de(c),
				null if _source.alimentees.has(c) else _gris, _source.plateau.niveau_de(c))
		_pieces.add_child(racine)
		racine.position = GrilleMonde.vers_monde(c)
		if _source.surcharge.has(c):
			_marquer_plein(racine)
		if piece.type == PieceDef.Type.ATELIER and _source.alimentees.has(c):
			_planter_drapeau(c)
			if DisplayServer.get_name() != "headless":
				racine.add_child(_vapeur())
		if piece.type == PieceDef.Type.ATELIER:
			_ateliers[c] = racine
		elif piece.type == PieceDef.Type.TOURELLE:
			_tourelles[c] = racine
		if piece.type == PieceDef.Type.HORLOGE:
			_horloge = racine
			if racine.get_child_count() > 0:
				racine.get_child(0).rotation.y = -_cote_porte(c) * PI / 2.0
		if piece.type == PieceDef.Type.HORLOGE or _source.alimentees.has(c):
			for mobile: Node in racine.find_children("Mobile*", "Node3D", true, false):
				_mobiles.append(mobile as Node3D)
		if piece.type == PieceDef.Type.ENGRENAGE and _source.alimentees.has(c):
			var rotor := racine.find_child("Rotor", true, false) as Node3D
			if rotor != null:
				_rotors.append(rotor)


# Onde au sol qui s'élargit puis s'efface (playtest 3, « des impacts qui se sentent ») : coup de carillon, tourelle
# carillon, obus de mortier, boulet de canon. Un anneau plat, sans ombre ni éclairage.
var _tore_onde: TorusMesh

func _onde(point: Vector2, rayon: float, couleur: Color, duree: float = 0.45) -> void:
	if _tore_onde == null:
		_tore_onde = TorusMesh.new()
		_tore_onde.inner_radius = 0.84
		_tore_onde.outer_radius = 1.0
		_tore_onde.rings = 48
		_tore_onde.ring_segments = 6
	var onde := MeshInstance3D.new()
	onde.mesh = _tore_onde
	var voile := StandardMaterial3D.new()
	voile.albedo_color = couleur
	voile.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	voile.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	onde.material_override = voile
	onde.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	onde.position = Vector3(point.x, 0.12, point.y)
	onde.scale = Vector3(rayon * 0.2, 0.25, rayon * 0.2)
	add_child(onde)
	var animation: Tween = onde.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.tween_property(onde, "scale", Vector3(rayon, 0.25, rayon), duree)
	animation.tween_property(voile, "albedo_color:a", 0.0, duree * 1.3)
	animation.chain().tween_callback(onde.queue_free)


# Voie ferrée (carte « Le Rail ») : traverses de bois et deux rails de laiton sur chaque case de la voie, routes
# comprises (le train les traverse). Dessinée une seule fois.
var _voie_posee: bool = false

func _poser_voie_ferree() -> void:
	if _voie_posee or Run.depart.rail.is_empty():
		return
	_voie_posee = true
	var voie: Array[Vector2i] = Run.depart.rail
	var traverse := BoxMesh.new()
	traverse.size = Vector3(1.5, 0.08, 0.26)
	var rail := BoxMesh.new()
	var bois: Material = materiau("bois_plateau")
	var laiton: Material = materiau("laiton")
	for k: int in voie.size():
		var case: Vector2i = voie[k]
		var suivante: Vector2i = voie[mini(k + 1, voie.size() - 1)] if k + 1 < voie.size() else case + (case - voie[maxi(0, k - 1)])
		var axe: Vector2 = Vector2(suivante - case).normalized()
		var centre: Vector3 = GrilleMonde.vers_monde(case) + Vector3.UP * 0.06
		var lacet: float = atan2(axe.x, axe.y)
		for t: int in 3:
			var piece: MeshInstance3D = _ajouter_forme(_sol, traverse, centre + Vector3(axe.x, 0, axe.y) * (t - 1) * 0.62, bois)
			piece.rotation.y = lacet
		rail.size = Vector3(0.08, 0.1, GrilleMonde.TAILLE_CASE)
		for cote: float in [-0.45, 0.45]:
			var normale := Vector2(-axe.y, axe.x) * cote
			var barre: MeshInstance3D = _ajouter_forme(_sol, rail, centre + Vector3(normale.x, 0.06, normale.y), laiton)
			barre.rotation.y = lacet


# Plaque tournante du Manège : disque de laiton cerclé de rouge cerise, sur une case qu'on ne peut pas construire.
func _plaque_tournante(case: Vector2i) -> Node3D:
	var racine := Node3D.new()
	_sol.add_child(racine)
	racine.position = GrilleMonde.vers_monde(case)
	var cerise := StandardMaterial3D.new()
	cerise.albedo_color = Color("#C8484F")
	var disque := CylinderMesh.new()
	disque.top_radius = 0.86
	disque.bottom_radius = 0.86
	disque.height = 0.06
	_ajouter_forme(racine, disque, Vector3.UP * 0.04, cerise)
	var centre := CylinderMesh.new()
	centre.top_radius = 0.7
	centre.bottom_radius = 0.7
	centre.height = 0.08
	_ajouter_forme(racine, centre, Vector3.UP * 0.07, materiau("laiton"))
	var fleche := BoxMesh.new()
	fleche.size = Vector3(0.18, 0.04, 1.1)
	_ajouter_forme(racine, fleche, Vector3.UP * 0.12, materiau("pierre_creme"))
	return racine


# Le train du Rail : une locomotive cerise et deux wagons qui roulent le long de la voie, à la vitesse du jeu.
func _faire_rouler_train() -> void:
	var voie: Array[Vector2i] = Run.depart.rail
	if voie.size() < 2:
		return
	var train := Node3D.new()
	add_child(train)
	var cerise := StandardMaterial3D.new()
	cerise.albedo_color = Color("#C8484F")
	var vert := StandardMaterial3D.new()
	vert.albedo_color = Color("#3F6B4E")
	_boite(train, Vector3(1.0, 0.7, 1.5), Vector3(0, 0.45, 0), cerise)
	_boite(train, Vector3(0.6, 0.5, 0.5), Vector3(0, 0.95, -0.35), materiau("laiton"))
	for k: int in 2:
		_boite(train, Vector3(0.95, 0.55, 1.3), Vector3(0, 0.38, 1.6 + k * 1.45), vert)
	var debut: Vector2 = Vector2(voie[0]) * GrilleMonde.TAILLE_CASE
	var direction: Vector2 = (Vector2(voie[1]) - Vector2(voie[0])).normalized()
	var fin: Vector2 = Vector2(voie[-1]) * GrilleMonde.TAILLE_CASE
	var depart: Vector2 = debut - direction * 2.0 * GrilleMonde.TAILLE_CASE
	var arrivee: Vector2 = fin + direction * 2.0 * GrilleMonde.TAILLE_CASE
	train.position = Vector3(depart.x, 0.05, depart.y)
	train.rotation.y = atan2(-direction.x, -direction.y)
	var duree: float = (voie.size() + 4) / (preload("res://game/core/partie.gd").VITESSE_TRAIN * maxf(0.5, Run.vitesse))
	var trajet: Tween = train.create_tween()
	trajet.tween_property(train, "position", Vector3(arrivee.x, 0.05, arrivee.y), duree)
	trajet.tween_callback(train.queue_free)
	Sons.jouer(&"train")


# Marée (carte « Le Quai ») : les routes par où la prochaine vague n'arrivera PAS sont recouvertes d'un voile d'eau,
# et un bandeau dit par où elle vient. Recalculé à chaque changement de phase.
func _montrer_maree(phase: int, annoncer: bool = true) -> void:
	if _voile_maree != null:
		_voile_maree.queue_free()
		_voile_maree = null
	if not Run.depart.maree or phase == Run.Phase.FIN:
		return
	var partie: Node = get_tree().get_first_node_in_group(&"partie")
	if partie == null:
		return
	var numero: int = Run.vague_actuelle if phase == Run.Phase.VAGUE else Run.vague_actuelle + 1
	var ouvertes: Array[Vector2i] = partie.entrees_de_la_vague(numero)
	var distances: Dictionary = ChampFlux.calculer(_source.plateau)
	var seches: Dictionary = {}
	var inondees: Dictionary = {}
	for entree: Vector2i in ChampFlux.entrees(_source.plateau, distances):
		var case: Vector2i = entree
		var garde_fou: int = 0
		while distances.get(case, 0) > 0 and garde_fou < 400:
			if entree in ouvertes:
				seches[case] = true
			else:
				inondees[case] = true
			var suivante: Vector2i = case
			for direction: Vector2i in VOISINS:
				if distances.get(case + direction, 1 << 30) < distances[suivante]:
					suivante = case + direction
			if suivante == case:
				break
			case = suivante
			garde_fou += 1
	_voile_maree = Node3D.new()
	add_child(_voile_maree)
	var eau := StandardMaterial3D.new()
	eau.albedo_color = Color(0.42, 0.68, 0.9, 0.55)
	eau.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	eau.roughness = 0.1
	var nappe := BoxMesh.new()
	nappe.size = Vector3(GrilleMonde.TAILLE_CASE, 0.06, GrilleMonde.TAILLE_CASE)
	for case: Vector2i in inondees:
		if not seches.has(case):
			var flaque: MeshInstance3D = _ajouter_forme(_voile_maree, nappe, GrilleMonde.vers_monde(case) + Vector3.UP * 0.06, eau)
			flaque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if annoncer and phase == Run.Phase.CONSTRUCTION and not ouvertes.is_empty():
		var ecart: Vector2i = ouvertes[0] - Run.depart.horloge
		var cote: String = ("l’est" if ecart.x > 0 else "l’ouest") if absi(ecart.x) >= absi(ecart.y) else ("le sud" if ecart.y > 0 else "le nord")
		Events.message_joueur.emit(tr("Marée : la vague %d arrivera par %s.") % [numero, tr(cote)])


# Pièces mobiles (P3-43) : clés de remontoir par à-coups d'un huitième de tour chaque seconde (tic-tac), cloche de
# l'Horloge qui se balance ; un coup de carillon la fait sonner à la volée quelques secondes.
func _animer_mobiles(delta: float) -> void:
	if _mobiles.is_empty():
		return
	_temps_vie += delta
	_volee = maxf(0.0, _volee - delta * 0.4)
	var tic: float = floorf(_temps_vie) + smoothstep(0.0, 0.18, fposmod(_temps_vie, 1.0))
	for mobile: Node3D in _mobiles:
		if not is_instance_valid(mobile):
			continue
		var angle: float = tic * PI / 4.0
		if mobile.get_meta(&"mouvement") == &"balance":
			angle = 0.1 * (1.0 + 2.0 * _volee) * sin(_temps_vie * PI * (1.0 + _volee))
		var base: Transform3D = mobile.get_meta(&"base")
		mobile.transform = base * Transform3D(Basis(mobile.get_meta(&"axe"), angle), Vector3.ZERO)


# Coup de carillon : une onde dorée part du point visé et s'élargit jusqu'au rayon d'effet, l'Horloge tressaute.
func _sur_carillon(point: Vector2) -> void:
	_volee = 1.0
	_onde(point, Run.regles.carillon_rayon, Color(1.0, 0.84, 0.36, 0.9), 0.5)
	Sons.jouer(&"carillon")
	if _horloge != null:
		var saut: Tween = _horloge.create_tween().set_trans(Tween.TRANS_SINE)
		saut.tween_property(_horloge, "scale", Vector3(1.06, 0.94, 1.06), 0.06)
		saut.tween_property(_horloge, "scale", Vector3.ONE, 0.2)


# Vie ambiante (P3-43) : un filet de vapeur blanche s'échappe du toit d'un atelier alimenté, même pendant la pause.
func _vapeur() -> CPUParticles3D:
	var fumee := CPUParticles3D.new()
	fumee.amount = 6
	fumee.lifetime = 2.4
	fumee.preprocess = 2.4
	fumee.position = Vector3(0.35, 1.6, 0.2)
	fumee.direction = Vector3(0.15, 1, 0)
	fumee.spread = 12.0
	fumee.gravity = Vector3(0.05, 0.25, 0)
	fumee.initial_velocity_min = 0.25
	fumee.initial_velocity_max = 0.4
	fumee.scale_amount_min = 0.6
	fumee.scale_amount_max = 1.1
	var courbe := Curve.new()
	courbe.add_point(Vector2(0, 0.4))
	courbe.add_point(Vector2(1, 1.6))
	fumee.scale_amount_curve = courbe
	var boule := SphereMesh.new()
	boule.radius = 0.1
	boule.height = 0.2
	boule.radial_segments = 8
	boule.rings = 4
	var blanc := StandardMaterial3D.new()
	blanc.albedo_color = Color(1, 1, 1, 0.55)
	blanc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blanc.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	boule.material = blanc
	fumee.mesh = boule
	var fondu := Gradient.new()
	fondu.set_color(0, Color(1, 1, 1, 0.6))
	fondu.set_color(1, Color(1, 1, 1, 0.0))
	fumee.color_ramp = fondu
	return fumee


# Playtest 3 (postes de garde) : un petit fanion sur la route, là où l'escouade de cet atelier se range. Planté au
# bord de la case, du côté de l'atelier, pour ne pas gêner les jouets ; il flotte doucement.
func _planter_drapeau(case: Vector2i) -> void:
	var partie: Node = get_tree().get_first_node_in_group(&"partie")
	if partie == null:
		return
	var poste: Vector2 = partie.sim.poste(case)
	if poste == Vector2.INF:
		return
	var fanion: Node3D = _instancier(&"marqueur_extension")
	if fanion == null:
		return
	_pieces.add_child(fanion)
	var vers_atelier: Vector2 = Vector2(case) * GrilleMonde.TAILLE_CASE - poste
	var decalage: Vector2 = Vector2.ZERO
	if vers_atelier.length() > 0.01:
		# Vers le bord de la case le plus proche de l'atelier (axe dominant), à 0,8 m du centre.
		decalage = Vector2(signf(vers_atelier.x), 0.0) if absf(vers_atelier.x) >= absf(vers_atelier.y) \
				else Vector2(0.0, signf(vers_atelier.y))
	fanion.position = Vector3(poste.x + decalage.x * 0.8, 0.0, poste.y + decalage.y * 0.8)
	fanion.scale = Vector3.ONE * 0.7
	var toile := fanion.find_child("Fanion*", true, false) as Node3D
	if toile != null:
		var repos: float = toile.rotation.z
		var vent: Tween = toile.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		vent.tween_property(toile, "rotation:z", repos + 0.06, 0.8)
		vent.tween_property(toile, "rotation:z", repos - 0.04, 0.8)


# Playtest 3 : bâtiment relié à un générateur déjà plein. Il reste gris, avec un écriteau « Plein » qui flotte et un
# liseré rouge au sol : on comprend tout de suite que c'est LUI qui ne tourne pas, et pourquoi.
func _marquer_plein(racine: Node3D) -> void:
	var rouge := StandardMaterial3D.new()
	rouge.albedo_color = Color("#D9483B")
	rouge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var anneau := TorusMesh.new()
	anneau.inner_radius = 0.84
	anneau.outer_radius = 0.96
	_ajouter_forme(racine, anneau, Vector3.UP * 0.05, rouge).scale.y = 0.2
	var ecriteau := Label3D.new()
	ecriteau.text = tr("Plein")
	ecriteau.font = preload("res://game/ui/theme_rouages.tres").default_font
	ecriteau.font_size = 96
	ecriteau.pixel_size = 0.006
	ecriteau.modulate = Color("#D9483B")
	ecriteau.outline_modulate = Color("#FFF6E2")
	ecriteau.outline_size = 28
	ecriteau.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ecriteau.no_depth_test = true
	ecriteau.position.y = 2.2
	racine.add_child(ecriteau)
	var flottement: Tween = ecriteau.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	flottement.tween_property(ecriteau, "position:y", 2.45, 0.6)
	flottement.tween_property(ecriteau, "position:y", 2.2, 0.6)


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
## Paliers d'évolution (PT-51, lot 4) : à partir de ce niveau, un bâtiment prend son modèle « _n3 » s'il existe
## (`assets/final/<id>_n3/<id>_n3_h3d.res`) ; sinon il garde le sien, avec ses insignes de niveau.
const NIVEAU_PALIER := 3

func creer_piece(piece: PieceDef, ports: int, teinte: Material = null, niveau: int = 1) -> Node3D:
	var racine := Node3D.new()
	var modele: Node3D
	var nom_modele: StringName = piece.id
	if piece.type == PieceDef.Type.HORLOGE:
		if ResourceLoader.exists(MODELE_HORLOGE):
			modele = (load(MODELE_HORLOGE) as PackedScene).instantiate() as Node3D
	else:
		modele = _modele_hyper3d(StringName(String(piece.id) + "_n3")) if niveau >= NIVEAU_PALIER else null
		if modele == null:
			modele = _instancier(piece.id)
		else:
			nom_modele = StringName(String(piece.id) + "_n3")
	if modele != null:
		_detacher_pieces(modele, nom_modele)
		racine.add_child(modele)
		var ports_origine: int = PORTS_DU_KIT.get(piece.id, piece.ports)
		for tour: int in 4:
			if PieceDef.tourner_ports(ports_origine, tour) == ports:
				modele.rotate_y(-tour * PI / 2.0)
				break
		if piece.sur_route and piece.type != PieceDef.Type.TOURELLE:
			_amenager_pont(modele)
		if piece.type == PieceDef.Type.TOURELLE:
			_separer_tete(modele, piece.id, nom_modele)
			_colorer_rarete(modele, piece.rarete)
			# Tourelle Hyper3D : au repos, le fût regarde vers l'extérieur (dos au port), comme le kit.
			if modele.get_meta(&"face_plus_z", false):
				modele.rotate_y(PI)
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
		PieceDef.Type.TOURELLE when piece.sur_route:
			# Piège à ressort : plaque de laiton ronde au ras de la route, ressort spiralé et cerclage corail.
			var corail := StandardMaterial3D.new()
			corail.albedo_color = Color("#E0795C")
			var plaque := CylinderMesh.new()
			plaque.top_radius = 0.62
			plaque.bottom_radius = 0.66
			plaque.height = 0.08
			_ajouter_forme(racine, plaque, Vector3.UP * 0.05, corail)
			var dessus := CylinderMesh.new()
			dessus.top_radius = 0.5
			dessus.bottom_radius = 0.5
			dessus.height = 0.1
			_ajouter_forme(racine, dessus, Vector3.UP * 0.1, materiau("laiton"))
			for k: int in 3:
				var spire := TorusMesh.new()
				spire.inner_radius = 0.16 - k * 0.03
				spire.outer_radius = 0.22 - k * 0.03
				_ajouter_forme(racine, spire, Vector3.UP * (0.18 + k * 0.07), materiau("laiton"))
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
	_animer_mobiles(delta)
