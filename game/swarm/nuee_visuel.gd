extends Node3D
## Affiche chaque camp en une seule série d'instances pilotées par la simulation.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Materiaux = preload("res://game/core/materiaux.gd")
const PASTELS := ["pastel_bleu", "pastel_rose", "pastel_vert", "pastel_jaune"]

var sim: SwarmSim
var _lots: Array[MultiMesh] = []


func _ready() -> void:
	var bois := StandardMaterial3D.new()
	bois.vertex_color_use_as_albedo = true
	var soldat := BoxMesh.new()
	soldat.size = Vector3(0.52, 0.4, 0.34)
	soldat.material = bois
	var jouets: MultiMesh = _lot(soldat, true)
	for i: int in SwarmSim.CAPACITE:
		jouets.set_instance_color(i, Color(Materiaux.COULEURS[PASTELS[i % PASTELS.size()]]))
	var scarabee := SphereMesh.new()
	scarabee.radius = 0.26
	scarabee.height = 0.32
	scarabee.radial_segments = 12
	scarabee.rings = 5
	scarabee.material = Materiaux.obtenir("laiton")
	_lot(scarabee, false)


func _lot(forme: Mesh, couleurs: bool) -> MultiMesh:
	var lot := MultiMesh.new()
	lot.transform_format = MultiMesh.TRANSFORM_3D
	lot.use_colors = couleurs
	lot.mesh = forme
	lot.instance_count = SwarmSim.CAPACITE
	lot.visible_instance_count = 0
	var volume := MultiMeshInstance3D.new()
	volume.multimesh = lot
	add_child(volume)
	_lots.append(lot)
	return lot


func _process(_delta: float) -> void:
	if sim == null:
		return
	for camp: int in _lots.size():
		var lot: MultiMesh = _lots[camp]
		var lieux: PackedVector2Array = sim.positions(camp)
		var angles: PackedFloat32Array = sim.caps(camp)
		lot.visible_instance_count = lieux.size()
		for i: int in lieux.size():
			var base := Basis(Vector3.UP, -angles[i])
			var hauteur: float = 0.2
			if camp == SwarmSim.ENNEMI:
				base = base.scaled_local(Vector3(1.25, 1.0, 0.85))
				hauteur = 0.16
			lot.set_instance_transform(i, Transform3D(base, Vector3(lieux[i].x, hauteur, lieux[i].y)))
