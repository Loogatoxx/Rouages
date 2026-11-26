extends Node
## Joue les sons et la musique (autoload « Sons »).
##
## Pourquoi un autoload qui écoute `Events` : les systèmes de jeu n'ont pas à connaître l'audio ; la plupart des sons
## découlent d'un signal déjà existant. Les rares sons sans signal (pose, rotation, clic) s'appellent par `Sons.jouer()`.
## Les réglages (volumes de la musique et des effets) sont gardés dans `user://reglages.cfg`.

const DOSSIER := "res://assets/audio/"
const REGLAGES := "user://reglages.cfg"
const VOIES := 10
## Intervalle minimal entre deux lectures du même son (secondes) : évite la mitraillette quand 50 scarabées cassent.
const ANTI_REPETITION := {&"scarabee_casse": 0.07, &"jouet_sort": 0.25, &"horloge_touchee": 0.3, &"rotation": 0.05}
## Volume propre à chaque son (dB) : les sons fréquents restent discrets.
const VOLUMES := {&"scarabee_casse": -14.0, &"jouet_sort": -12.0, &"clic": -8.0, &"ressorts": -4.0, &"rotation": -6.0}

const MUSIQUE := &"Musique"
const EFFETS := &"Effets"
const VOLUME_DEFAUT := 0.8

var _chemin_reglages: String = REGLAGES
var musique_active: bool:
	get:
		return volume(MUSIQUE) > 0.0
var effets_actifs: bool:
	get:
		return volume(EFFETS) > 0.0
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
		voie.bus = EFFETS
		add_child(voie)
		_voies.append(voie)
	var flux: AudioStream = _charger(&"musique")
	if flux is AudioStreamOggVorbis:
		(flux as AudioStreamOggVorbis).loop = true
	_musique.stream = flux
	_musique.volume_db = VOLUME_MUSIQUE
	_musique.bus = MUSIQUE
	add_child(_musique)
	var flux_vague: AudioStream = _charger(&"musique_vague")
	if flux_vague is AudioStreamOggVorbis:
		(flux_vague as AudioStreamOggVorbis).loop = true
	_musique_vague.stream = flux_vague
	_musique_vague.volume_db = SILENCE
	_musique_vague.bus = MUSIQUE
	add_child(_musique_vague)
	Events.phase_changee.connect(_changer_ambiance)
	_lire_reglages()
	Events.horloge_touchee.connect(func(_pv: int) -> void: jouer(&"horloge_touchee"))
	Events.vague_commencee.connect(func(_n: int) -> void: jouer(&"vague_debut"))
	Events.vague_terminee.connect(func(_n: int) -> void: jouer(&"ressorts"))
	Events.ennemi_casse.connect(func(_p: Vector2) -> void: jouer(&"scarabee_casse", 0.15))
	Events.run_terminee.connect(func(victoire: bool) -> void: jouer(&"victoire" if victoire else &"defaite"))
	if not _sans_audio():
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
	regler_volume(MUSIQUE, VOLUME_DEFAUT if active else 0.0)


## Active ou coupe les effets sonores.
func regler_effets(actifs: bool) -> void:
	regler_volume(EFFETS, VOLUME_DEFAUT if actifs else 0.0)


## Applique et mémorise le volume linéaire du bus choisi.
func regler_volume(bus: StringName, lineaire: float) -> void:
	if bus != MUSIQUE and bus != EFFETS:
		return
	var niveau: float = clampf(lineaire, 0.0, 1.0)
	_appliquer_volume(bus, niveau)
	var fichier := ConfigFile.new()
	var lecture: Error = fichier.load(_chemin_reglages)
	if lecture != OK and lecture != ERR_FILE_NOT_FOUND:
		push_warning("Lecture des réglages impossible : " + error_string(lecture))
		return
	fichier.set_value("son", _cle_volume(bus), niveau)
	var ecriture: Error = fichier.save(_chemin_reglages)
	if ecriture != OK:
		push_warning("Écriture des réglages impossible : " + error_string(ecriture))


## Renvoie le volume linéaire audible sur le bus.
func volume(bus: StringName) -> float:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func _appliquer_volume(bus: StringName, niveau: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if niveau > 0.0:
		AudioServer.set_bus_volume_db(index, linear_to_db(niveau))
	AudioServer.set_bus_mute(index, niveau == 0.0)


func _cle_volume(bus: StringName) -> String:
	return "volume_" + String(bus).to_lower()


# Vague → musique rythmée ; sinon musique calme. Fondu de 1,2 s pour ne jamais couper net.
func _changer_ambiance(phase: int) -> void:
	if _sans_audio() or _musique_vague.stream == null:
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
	fichier.load(_chemin_reglages)
	for bus: StringName in [MUSIQUE, EFFETS]:
		var ancienne_cle: String = "musique_active" if bus == MUSIQUE else "effets_actifs"
		var actif: bool = fichier.get_value("son", ancienne_cle,
				fichier.get_value("son", String(bus).to_lower(), true))
		var niveau: float = fichier.get_value("son", _cle_volume(bus), VOLUME_DEFAUT if actif else 0.0)
		_appliquer_volume(bus, clampf(niveau, 0.0, 1.0))
