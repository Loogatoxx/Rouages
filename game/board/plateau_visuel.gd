extends Node3D
## Affiche le sol, les ports fixes et les rotors du plateau à partir du modèle.

const GrilleMonde = preload("res://game/board/grille_monde.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const ExtensionDef = preload("res://game/board/extension_def.gd")
const Extension = preload("res://game/board/extension.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const Materiaux = preload("res://game/core/materiaux.gd")

@onready var _source: PlateauNoeud = get_parent()
var _rotors: Array[Node3D] = []
var _pieces: Node3D
var _cases_construites: Dictionary[Vector2i, bool] = {}
var _poteaux: Dictionary[Vector2i, MeshInstance3D] = {}
var _sol: Node3D
var _gris: StandardMaterial3D = StandardMaterial3D.new()


func _ready() -> void:
	_gris.albedo_color = Color("#97958f")
	Events.plateau_modifie.connect(_actualiser)
	Events.energie_recalculee.connect(_energie)


## Renvoie le matériau partagé pour cette teinte du plateau.
func materiau(nom: String) -> Material:
	return Materiaux.obtenir(nom)


func _actualiser() -> void:
	if _sol == null:
		_sol = Node3D.new()
		add_child(_sol)
	for c: Vector2i in _source.plateau.coords_sols():
		if _cases_construites.has(c):
			continue
		var chemin: bool = _source.plateau.sol_de(c) == _source.Plateau.Sol.CHEMIN
		_creer_sol(_sol, c, chemin)
		_cases_construites[c] = true
	var entrees: Array[Vector2i] = ChampFlux.entrees(_source.plateau, ChampFlux.calculer(_source.plateau))
	for case: Vector2i in _poteaux.keys():
		if case not in entrees:
			_poteaux[case].queue_free()
			_poteaux.erase(case)
	for case: Vector2i in entrees:
		if not _poteaux.has(case):
			var pied: Vector3 = GrilleMonde.vers_monde(case) + Vector3(0.72, 0.3, 0.72)
			_poteaux[case] = _boite(_sol, Vector3(0.16, 0.6, 0.16), pied, materiau("pastel_rose"))


func _creer_sol(parent: Node3D, case: Vector2i, chemin: bool) -> MeshInstance3D:
	return _boite(parent, Vector3(2, 0.2, 2), GrilleMonde.vers_monde(case) + Vector3.DOWN * 0.1,
			materiau("pierre_creme" if chemin else "herbe"))


## Construit un aperçu orienté dont la teinte se superpose à l'herbe et au chemin.
func creer_extension(def: ExtensionDef, rotation: int, teinte: Material) -> Node3D:
	var racine := Node3D.new()
	var sols: Dictionary = Extension.cases(def, Vector2i.ZERO, rotation)
	for case: Vector2i in sols:
		var dalle: MeshInstance3D = _creer_sol(racine, case, sols[case] == _source.Plateau.Sol.CHEMIN)
		dalle.scale = Vector3(0.97, 1, 0.97)
		dalle.material_overlay = teinte
	return racine


func _energie(_alimentees: Array[Vector2i]) -> void:
	_reconstruire()


func _reconstruire() -> void:
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
		if piece.type == PieceDef.Type.ENGRENAGE and _source.alimentees.has(c):
			_rotors.append(racine.get_node("Rotor"))


## Construit la même silhouette pour une pièce posée et pour son fantôme.
func creer_piece(piece: PieceDef, ports: int, teinte: Material = null) -> Node3D:
	var racine := Node3D.new()
	var metal: Material = teinte if teinte else materiau("laiton")
	match piece.type:
		PieceDef.Type.HORLOGE:
			_cylindre(racine, 0.72, 1.5, teinte if teinte else materiau("bois_clair"))
		PieceDef.Type.ENGRENAGE:
			var rotor := Node3D.new()
			rotor.name = "Rotor"
			racine.add_child(rotor)
			_cylindre(rotor, 0.65, 0.3, metal)
			_boite(rotor, Vector3(0.94, 0.09, 0.14), Vector3.UP * 0.34,
					teinte if teinte else materiau("bois_plateau"))
		PieceDef.Type.ATELIER:
			_boite(racine, Vector3(1.18, 0.85, 1.18), Vector3.UP * 0.425,
					teinte if teinte else materiau("pastel_bleu"))
	for i: int in range(4):
		if ports & (1 << i):
			var dent: MeshInstance3D = _boite(racine, Vector3(0.32, 0.24, 0.43),
					Vector3.FORWARD.rotated(Vector3.UP, -i * PI / 2) * 0.77 + Vector3.UP * 0.15, metal)
			dent.rotation.y = -i * PI / 2
	return racine


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


func _process(delta: float) -> void:
	for rotor: Node3D in _rotors:
		rotor.rotate_y(delta * 2.0)
