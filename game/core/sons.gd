extends Node
## Joue les sons et la musique (autoload « Sons »).
##
## Pourquoi un autoload qui écoute `Events` : les systèmes de jeu n'ont pas à connaître l'audio ; la plupart des sons
## découlent d'un signal déjà existant. Les rares sons sans signal (pose, rotation, clic) s'appellent par `Sons.jouer()`.
## Les réglages (musique et effets activés) sont gardés dans `user://reglages.cfg`.

const DOSSIER := "res://assets/audio/"
const REGLAGES := "user://reglages.cfg"
const VOIES := 10
## Intervalle minimal entre deux lectures du même son (secondes) : évite la mitraillette quand 50 scarabées cassent.
const ANTI_REPETITION := {&"scarabee_casse": 0.07, &"jouet_sort": 0.25, &"horloge_touchee": 0.3, &"rotation": 0.05}
## Volume propre à chaque son (dB) : les sons fréquents restent discrets.
const VOLUMES := {&"scarabee_casse": -14.0, &"jouet_sort": -12.0, &"clic": -8.0, &"ressorts": -4.0, &"rotation": -6.0}

var musique_active: bool = true
var effets_actifs: bool = true
var _flux: Dictionary[StringName, AudioStream] = {}
var _voies: Array[AudioStreamPlayer] = []
var _prochaine: int = 0
var _derniers: Dictionary[StringName, float] = {}
var _musique := AudioStreamPlayer.new()
## Deuxième boucle, plus rythmée, pendant les vagues ; on passe de l'une à l'autre en fondu enchaîné.
var _musique_vague := AudioStreamPlayer.new()
var _fondu: Tween
const VOLUME_MUSIQUE := -13.0
const SILENCE := -40.0


func _ready() -> void:
	# Les sons continuent pendant la pause (clics du menu pause).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in VOIES:
		var voie := AudioStreamPlayer.new()
		add_child(voie)
		_voies.append(voie)
	var flux: AudioStream = _charger(&"musique")
	if flux is AudioStreamOggVorbis:
		(flux as AudioStreamOggVorbis).loop = true
	_musique.stream = flux
	_musique.volume_db = VOLUME_MUSIQUE
	add_child(_musique)
	var flux_vague: AudioStream = _charger(&"musique_vague")
	if flux_vague is AudioStreamOggVorbis:
		(flux_vague as AudioStreamOggVorbis).loop = true
	_musique_vague.stream = flux_vague
	_musique_vague.volume_db = SILENCE
	add_child(_musique_vague)
	Events.phase_changee.connect(_changer_ambiance)
	_lire_reglages()
	Events.horloge_touchee.connect(func(_pv: int) -> void: jouer(&"horloge_touchee"))
	Events.vague_commencee.connect(func(_n: int) -> void: jouer(&"vague_debut"))
	Events.vague_terminee.connect(func(_n: int) -> void: jouer(&"ressorts"))
	Events.ennemi_casse.connect(func(_p: Vector2) -> void: jouer(&"scarabee_casse", 0.15))
	Events.run_terminee.connect(func(victoire: bool) -> void: jouer(&"victoire" if victoire else &"defaite"))
	if musique_active and not _sans_audio():
		_musique.play()


## Joue un son de `assets/audio/<nom>.ogg` ; `variation` décale la hauteur au hasard (0.1 = ±10 %).
func jouer(nom: StringName, variation: float = 0.0) -> void:
	if not effets_actifs or _sans_audio():
		return
	var maintenant: float = Time.get_ticks_msec() / 1000.0
	if maintenant - _derniers.get(nom, -10.0) < ANTI_REPETITION.get(nom, 0.0):
		return
	var flux: AudioStream = _charger(nom)
	if flux == null:
		return
	_derniers[nom] = maintenant
	var voie: AudioStreamPlayer = _voies[_prochaine]
	_prochaine = (_prochaine + 1) % VOIES
	voie.stream = flux
	voie.volume_db = VOLUMES.get(nom, 0.0)
	voie.pitch_scale = 1.0 + randf_range(-variation, variation)
	voie.play()


## Active ou coupe la musique de fond (réglage sauvegardé).
func regler_musique(active: bool) -> void:
	musique_active = active
	if active and not _musique.playing and not _sans_audio():
		_musique.play()
	elif not active:
		_musique.stop()
		_musique_vague.stop()
	_ecrire_reglages()


## Active ou coupe les effets sonores (réglage sauvegardé).
func regler_effets(actifs: bool) -> void:
	effets_actifs = actifs
	_ecrire_reglages()


# Vague → musique rythmée ; sinon musique calme. Fondu de 1,2 s pour ne jamais couper net.
func _changer_ambiance(phase: int) -> void:
	if not musique_active or _sans_audio() or _musique_vague.stream == null:
		return
	var en_vague: bool = phase == Run.Phase.VAGUE
	var entrant: AudioStreamPlayer = _musique_vague if en_vague else _musique
	var sortant: AudioStreamPlayer = _musique if en_vague else _musique_vague
	if not entrant.playing:
		entrant.volume_db = SILENCE
		entrant.play()
	if _fondu:
		_fondu.kill()
	_fondu = create_tween().set_parallel()
	_fondu.tween_property(entrant, "volume_db", VOLUME_MUSIQUE, 1.2)
	_fondu.tween_property(sortant, "volume_db", SILENCE, 1.2)


func _charger(nom: StringName) -> AudioStream:
	if not _flux.has(nom):
		var chemin: String = DOSSIER + String(nom) + ".ogg"
		_flux[nom] = load(chemin) if ResourceLoader.exists(chemin) else null
	return _flux[nom]


# En mode headless (tests, banc), pas de lecture : inutile et bruyant dans les journaux.
func _sans_audio() -> bool:
	return DisplayServer.get_name() == "headless"


func _lire_reglages() -> void:
	var fichier := ConfigFile.new()
	if fichier.load(REGLAGES) == OK:
		musique_active = fichier.get_value("son", "musique", true)
		effets_actifs = fichier.get_value("son", "effets", true)


func _ecrire_reglages() -> void:
	var fichier := ConfigFile.new()
	fichier.load(REGLAGES)  # garde les autres sections (ex. tutoriel vu)
	fichier.set_value("son", "musique", musique_active)
	fichier.set_value("son", "effets", effets_actifs)
	fichier.save(REGLAGES)
