extends Node3D
## Maintient deux populations sur les deux bras du serpentin et chronomètre la logique.

const SwarmSim = preload("res://game/swarm/swarm_sim.gd")
const Plateau = preload("res://game/board/plateau.gd")
const Materiaux = preload("res://game/core/materiaux.gd")
const HORLOGE = preload("res://data/tuiles/horloge.tres")
const SCARABEE = preload("res://data/unites/scarabee.tres")
const SOLDAT = preload("res://data/unites/soldat_remontoir.tres")
const BRAS := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 1),
	Vector2i(3, 2), Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 5)]
const EFFECTIF := 300

var _sim := SwarmSim.new()
var _hasard := RandomNumberGenerator.new()
var _duree_us: int = 0
var _pas: int = 0


func _ready() -> void:
	var plateau := Plateau.new()
	var sol := BoxMesh.new()
	sol.size = Vector3(2, 0.2, 2)
	for x: int in range(-4, 5):
		for y: int in range(-6, 7):
			var c := Vector2i(x, y)
			var chemin: bool = BRAS.has(c) or BRAS.has(-c)
			plateau.ajouter_sol(c, Plateau.Sol.CHEMIN if chemin else Plateau.Sol.HERBE)
			var dalle := MeshInstance3D.new()
			dalle.mesh = sol
			dalle.material_override = Materiaux.obtenir("pierre_creme" if chemin else "herbe")
			dalle.position = Vector3(x * 2, -0.1, y * 2)
			add_child(dalle)
	plateau.poser(Vector2i.ZERO, HORLOGE)
	var horloge := MeshInstance3D.new()
	var cadran := CylinderMesh.new()
	cadran.top_radius = 0.72
	cadran.bottom_radius = 0.72
	cadran.height = 1.5
	horloge.mesh = cadran
	horloge.material_override = Materiaux.obtenir("laiton")
	horloge.position.y = 0.75
	add_child(horloge)
	_sim.configurer(plateau)
	$Nuees.sim = _sim
	_hasard.seed = 314159
	for i: int in EFFECTIF:
		var signe_bras: int = 1 if i % 2 == 0 else -1
		var case: Vector2 = Vector2(BRAS[(i / 2) % BRAS.size()]) * signe_bras
		_sim.ajouter(SCARABEE, case * 2.0 + _dispersion())
		_sim.ajouter(SOLDAT, case * 2.0 + _dispersion() + Vector2.RIGHT)


func _dispersion() -> Vector2:
	return Vector2(_hasard.randf_range(-0.9, 0.9), _hasard.randf_range(-0.9, 0.9))


func _physics_process(delta: float) -> void:
	var debut: int = Time.get_ticks_usec()
	_sim.avancer(delta)
	_duree_us += Time.get_ticks_usec() - debut
	_pas += 1
	while _sim.nombre(SwarmSim.ENNEMI) < EFFECTIF:
		var entree: Vector2 = Vector2(BRAS.back()) * (2 if _hasard.randi() % 2 else -2)
		_sim.ajouter(SCARABEE, entree + _dispersion())
	while _sim.nombre(SwarmSim.ALLIE) < EFFECTIF:
		var naissance := Vector2(2, -2) if _hasard.randi() % 2 else Vector2(-2, 2)
		_sim.ajouter(SOLDAT, naissance + _dispersion())
	if _pas >= 15:
		$Mesures.text = "%d FPS\n%d scarabées · %d soldats\navancer : %.2f ms (moyenne)" % [
			Engine.get_frames_per_second(), _sim.nombre(SwarmSim.ENNEMI), _sim.nombre(SwarmSim.ALLIE),
			_duree_us / (1000.0 * _pas)]
		_duree_us = 0
		_pas = 0
