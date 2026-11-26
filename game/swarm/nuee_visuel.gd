extends Node3D
## Affiche les deux camps et les chapeaux des jouets à partir de la simulation.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Materiaux = preload("res://game/core/materiaux.gd")
const TEINTES := ["jouet_rouge", "jouet_bleu", "jouet_vert", "jouet_prune"]

var sim: SwarmSim
var _lots: Array[MultiMesh] = []
var _chapeaux: MultiMesh


func _ready() -> void:
	var bois := StandardMaterial3D.new()
	bois.vertex_color_use_as_albedo = true
	var soldat := BoxMesh.new()
	soldat.size = Vector3(0.52, 0.4, 0.34)
	soldat.material = bois
	var jouets: MultiMesh = _creer_lot(soldat, true)
	for i: int in SwarmSim.CAPACITE:
		var teinte: String = TEINTES[i % TEINTES.size()]
		jouets.set_instance_color(i, Color(Materiaux.COULEURS[teinte]))
	var scarabee := SphereMesh.new()
	scarabee.radius = 0.26
	scarabee.height = 0.32
	scarabee.radial_segments = 12
	scarabee.rings = 5
	scarabee.material = Materiaux.obtenir("laiton")
	_lots = [jouets, _creer_lot(scarabee, false)]
	var chapeau := CylinderMesh.new()
	chapeau.top_radius = 0.13
	chapeau.bottom_radius = 0.13
	chapeau.height = 0.14
	chapeau.material = Materiaux.obtenir("chapeau")
	_chapeaux = _creer_lot(chapeau, false, false)


func _creer_lot(forme: Mesh, couleurs: bool, projette_ombres: bool = true) -> MultiMesh:
	var lot := MultiMesh.new()
	lot.transform_format = MultiMesh.TRANSFORM_3D
	lot.use_colors = couleurs
	lot.mesh = forme
	lot.instance_count = SwarmSim.CAPACITE
	lot.visible_instance_count = 0
	var volume := MultiMeshInstance3D.new()
	volume.multimesh = lot
	if not projette_ombres:
		volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(volume)
	return lot


func _process(_delta: float) -> void:
	if sim == null:
		return
	for camp: int in _lots.size():
		var lot: MultiMesh = _lots[camp]
		var lieux: PackedVector2Array = sim.positions(camp)
		var angles: PackedFloat32Array = sim.caps(camp)
		lot.visible_instance_count = lieux.size()
		if camp != SwarmSim.ENNEMI:
			_chapeaux.visible_instance_count = lieux.size()
		for i: int in lieux.size():
			var base := Basis(Vector3.UP, -angles[i])
			var hauteur: float = 0.2
			if camp == SwarmSim.ENNEMI:
				base = base.scaled_local(Vector3(1.25, 1.0, 0.85))
				hauteur = 0.16
			else:
				var centre := Vector3(lieux[i].x, hauteur + 0.2 + 0.07, lieux[i].y)
				_chapeaux.set_instance_transform(i, Transform3D(base, centre))
			lot.set_instance_transform(i, Transform3D(base, Vector3(lieux[i].x, hauteur, lieux[i].y)))
