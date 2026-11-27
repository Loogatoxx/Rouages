extends RefCounted
## Vérifie les niveaux audio et la reprise des préférences des anciennes versions.


## Vérifie la sauvegarde, la relecture et le silence indépendant des deux bus.
func test_volumes_persistants() -> String:
	var chemin: String = _isoler_reglages()
	Sons._lire_reglages()
	var defaut: bool = is_equal_approx(Sons.volume(&"Musique"), 0.8)
	Sons.regler_volume(&"Musique", 0.35)
	Sons.regler_volume(&"Effets", 0.0)
	var fichier := ConfigFile.new()
	var sauvegarde: bool = fichier.load(chemin) == OK
	sauvegarde = sauvegarde and is_equal_approx(fichier.get_value("son", "volume_musique", -1.0), 0.35)
	sauvegarde = sauvegarde and fichier.get_value("son", "volume_effets", -1.0) == 0.0
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Effets"), false)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Musique"), 0.0)
	Sons._lire_reglages()
	var musique: bool = is_equal_approx(Sons.volume(&"Musique"), 0.35)
	var silence: bool = AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Effets"))
	_retablir_reglages(chemin)
	if not defaut or not sauvegarde or not musique:
		return "Le niveau par défaut, sauvegardé ou relu est incorrect."
	return "" if silence else "Les effets à zéro doivent rendre leur bus muet."


## Vérifie les anciens noms de clés et la priorité d'un volume choisi ensuite.
func test_anciens_interrupteurs() -> String:
	var chemin: String = _isoler_reglages()
	var fichier := ConfigFile.new()
	fichier.set_value("son", "musique_active", false)
	fichier.set_value("son", "effets", false)
	fichier.save(chemin)
	Sons._lire_reglages()
	var muets: bool = not Sons.musique_active and not Sons.effets_actifs
	Sons.regler_volume(&"Effets", 0.6)
	Sons._lire_reglages()
	var retabli: bool = is_equal_approx(Sons.volume(&"Effets"), 0.6)
	_retablir_reglages(chemin)
	return "" if muets and retabli else "Migration des anciens interrupteurs incorrecte."


func _isoler_reglages() -> String:
	Sons._chemin_reglages = OS.get_temp_dir().path_join("rouages-options-%d-%d.cfg" % [OS.get_process_id(), Time.get_ticks_usec()])
	return Sons._chemin_reglages


func _retablir_reglages(chemin: String) -> void:
	Sons._chemin_reglages = Sons.REGLAGES
	Sons._lire_reglages()
	DirAccess.remove_absolute(chemin)


## Réassignation des touches (P2-13) : la nouvelle touche remplace la principale, est retirée à l'action qui l'avait,
## survit à une relecture et « Touches d'origine » rend tout.
func test_reassignation_touches() -> String:
	var chemin: String = OS.get_temp_dir().path_join("rouages-touches-%d.cfg" % Time.get_ticks_usec())
	Touches.chemin_reglages = chemin
	var touche := InputEventKey.new()
	touche.physical_keycode = KEY_J
	Touches.assigner(&"boutique", touche)
	var ok_assigne: bool = InputMap.action_get_events(&"boutique")[0].is_match(touche, true)
	Touches.assigner(&"pause", touche)
	var retiree: bool = InputMap.action_get_events(&"boutique").is_empty() \
			or not InputMap.action_get_events(&"boutique")[0].is_match(touche, true)
	Touches.reinitialiser()
	var origine: bool = not InputMap.action_get_events(&"pause")[0].is_match(touche, true)
	Touches.chemin_reglages = Touches.REGLAGES
	DirAccess.remove_absolute(chemin)
	if not ok_assigne:
		return "La touche choisie doit devenir la touche principale."
	if not retiree:
		return "Une touche reprise par une autre action doit être retirée de la première."
	return "" if origine else "« Touches d'origine » doit rendre les touches du projet."
