extends RefCounted
## Choisit la langue du jeu et la conserve avec les autres préférences.

const LANGUES: Array[String] = ["fr", "en", "pt"]
const REGLAGES := "user://reglages.cfg"


## Lit la préférence de langue, avec repli sur la langue du système puis l’anglais.
static func lire() -> String:
	var systeme: String = OS.get_locale_language()
	var defaut: String = systeme if systeme in LANGUES else "en"
	var fichier := ConfigFile.new()
	if fichier.load(REGLAGES) == OK:
		var code: Variant = fichier.get_value("langue", "code", defaut)
		if code in LANGUES:
			return code
	return defaut


## Applique une langue prise en charge et enregistre le choix dans les réglages.
static func appliquer(code: String) -> void:
	if code not in LANGUES:
		return
	TranslationServer.set_locale(code)
	var fichier := ConfigFile.new()
	var lecture: Error = fichier.load(REGLAGES)
	if lecture != OK and lecture != ERR_FILE_NOT_FOUND:
		push_warning("Lecture des réglages impossible : " + error_string(lecture))
		return
	if fichier.get_value("langue", "code", "") == code:
		return
	fichier.set_value("langue", "code", code)
	var ecriture: Error = fichier.save(REGLAGES)
	if ecriture != OK:
		push_warning("Écriture des réglages impossible : " + error_string(ecriture))


## Passe à la langue suivante, puis revient au français après le portugais.
static func suivante() -> void:
	var code: String = TranslationServer.get_locale().get_slice("_", 0)
	appliquer(LANGUES[(LANGUES.find(code) + 1) % LANGUES.size()])
