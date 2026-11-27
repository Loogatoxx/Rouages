extends Node
## Touches réassignables (autoload « Touches », playtest 2) : chaque action de l'InputMap peut recevoir une autre touche
## ou un autre bouton de souris ; le choix est enregistré dans `user://reglages.cfg` (section « touches »).
##
## Pourquoi : la liste des commandes n'était qu'un texte. Un joueur gaucher, ou sur un clavier QWERTY/AZERTY différent,
## doit pouvoir changer ses touches. On ne remplace que le PREMIER événement de l'action : les autres (pavé tactile,
## raccourcis secondaires) restent.

const REGLAGES := "user://reglages.cfg"
const SECTION := "touches"
## Actions proposées dans les Options, dans l'ordre d'affichage, avec leur libellé (clé de traduction).
const ACTIONS: Array[Array] = [
	[&"poser_tuile", "Poser / choisir"], [&"tourner_tuile", "Tourner"], [&"annuler", "Annuler"],
	[&"pause", "Pause"], [&"accelerer", "Vitesse ×2"], [&"boutique", "Boutique"],
	[&"basculer_camera", "Vue de dessus / inclinée"], [&"camera_haut", "Caméra : haut"],
	[&"camera_bas", "Caméra : bas"], [&"camera_gauche", "Caméra : gauche"], [&"camera_droite", "Caméra : droite"],
	[&"camera_zoom_avant", "Zoom avant"], [&"camera_zoom_arriere", "Zoom arrière"],
	[&"camera_redresser", "Redresser la caméra"], [&"camera_coucher", "Coucher la caméra"],
	[&"plein_ecran", "Plein écran"],
]

## Fichier des réglages (remplaçable par les tests, pour ne jamais toucher aux vrais réglages du joueur).
var chemin_reglages: String = REGLAGES
## Événements d'origine (projet), pour « Réinitialiser ».
var _origines: Dictionary[StringName, InputEvent] = {}


# Dès la création (avant tout `_ready`) : les touches du projet sont déjà chargées dans l'InputMap.
func _init() -> void:
	for ligne: Array in ACTIONS:
		var evenements: Array[InputEvent] = InputMap.action_get_events(ligne[0])
		if not evenements.is_empty():
			_origines[ligne[0]] = evenements[0]
	lire()


## Texte lisible de la touche principale d'une action (« Espace », « Clic gauche »…).
func nom_touche(action: StringName) -> String:
	var evenements: Array[InputEvent] = InputMap.action_get_events(action)
	if evenements.is_empty():
		return "—"
	return decrire(evenements[0])


## Décrit un événement clavier ou souris en clair.
static func decrire(evenement: InputEvent) -> String:
	if evenement is InputEventKey:
		var touche: InputEventKey = evenement
		var code: Key = touche.physical_keycode if touche.physical_keycode != KEY_NONE else touche.keycode
		# Libellé selon la disposition du clavier du joueur (A sur AZERTY, Q sur QWERTY pour la même touche physique).
		var affichee: Key = DisplayServer.keyboard_get_label_from_physical(code) if touche.physical_keycode != KEY_NONE \
				and DisplayServer.get_name() != "headless" else code
		return OS.get_keycode_string(touche.get_modifiers_mask() | affichee)
	if evenement is InputEventMouseButton:
		match (evenement as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return TranslationServer.translate("Clic gauche")
			MOUSE_BUTTON_RIGHT:
				return TranslationServer.translate("Clic droit")
			MOUSE_BUTTON_MIDDLE:
				return TranslationServer.translate("Clic molette")
			MOUSE_BUTTON_WHEEL_UP:
				return TranslationServer.translate("Molette haut")
			MOUSE_BUTTON_WHEEL_DOWN:
				return TranslationServer.translate("Molette bas")
		return TranslationServer.translate("Bouton %d") % (evenement as InputEventMouseButton).button_index
	return evenement.as_text()


## Remplace la touche principale de l'action et enregistre. Une touche déjà prise par une autre action lui est retirée
## (deux actions sur la même touche se contrediraient).
func assigner(action: StringName, evenement: InputEvent) -> void:
	for ligne: Array in ACTIONS:
		var autre: StringName = ligne[0]
		if autre != action and _principale_egale(autre, evenement):
			_remplacer(autre, null)
	_remplacer(action, evenement)
	enregistrer()


## Rend à toutes les actions leurs touches d'origine.
func reinitialiser() -> void:
	for action: StringName in _origines:
		_remplacer(action, _origines[action])
	var fichier := ConfigFile.new()
	if fichier.load(chemin_reglages) == OK and fichier.has_section(SECTION):
		fichier.erase_section(SECTION)
		fichier.save(chemin_reglages)


func _principale_egale(action: StringName, evenement: InputEvent) -> bool:
	var evenements: Array[InputEvent] = InputMap.action_get_events(action)
	return not evenements.is_empty() and evenements[0].is_match(evenement, true)


func _remplacer(action: StringName, evenement: InputEvent) -> void:
	var evenements: Array[InputEvent] = InputMap.action_get_events(action)
	InputMap.action_erase_events(action)
	if evenement != null:
		InputMap.action_add_event(action, evenement)
	for i: int in range(1, evenements.size()):
		InputMap.action_add_event(action, evenements[i])


## Relit les touches enregistrées (événements sérialisés par ConfigFile).
func lire() -> void:
	var fichier := ConfigFile.new()
	if fichier.load(chemin_reglages) != OK or not fichier.has_section(SECTION):
		return
	for cle: String in fichier.get_section_keys(SECTION):
		var evenement = fichier.get_value(SECTION, cle)
		if evenement is InputEvent and InputMap.has_action(StringName(cle)):
			_remplacer(StringName(cle), evenement)


func enregistrer() -> void:
	var fichier := ConfigFile.new()
	var erreur: Error = fichier.load(chemin_reglages)
	if erreur != OK and erreur != ERR_FILE_NOT_FOUND:
		push_warning("Lecture des réglages impossible : " + error_string(erreur))
		return
	for ligne: Array in ACTIONS:
		var evenements: Array[InputEvent] = InputMap.action_get_events(ligne[0])
		var origine: InputEvent = _origines.get(ligne[0])
		if not evenements.is_empty() and (origine == null or not evenements[0].is_match(origine, true)):
			fichier.set_value(SECTION, String(ligne[0]), evenements[0])
		elif fichier.has_section_key(SECTION, String(ligne[0])):
			fichier.erase_section_key(SECTION, String(ligne[0]))
	erreur = fichier.save(chemin_reglages)
	if erreur != OK:
		push_warning("Enregistrement des touches impossible : " + error_string(erreur))
