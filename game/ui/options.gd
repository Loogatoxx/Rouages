extends CanvasLayer
## Rassemble les préférences accessibles depuis le titre et la pause.

signal ferme

const Langue = preload("res://game/ui/langue.gd")
const REGLAGES := "user://reglages.cfg"


func _ready() -> void:
	%Musique.value_changed.connect(func(niveau: float) -> void: Sons.regler_volume(&"Musique", niveau))
	%Effets.value_changed.connect(func(niveau: float) -> void: Sons.regler_volume(&"Effets", niveau))
	%PleinEcran.toggled.connect(_regler_affichage)
	%ChoixLangue.pressed.connect(Langue.suivante)
	%Retour.pressed.connect(_fermer)


## Affiche les préférences actuelles et place le focus sur le premier curseur.
func ouvrir() -> void:
	%Musique.set_value_no_signal(Sons.volume(&"Musique"))
	%Effets.set_value_no_signal(Sons.volume(&"Effets"))
	%PleinEcran.set_pressed_no_signal(_lire_plein_ecran())
	show()
	%Musique.grab_focus()


func _input(evenement: InputEvent) -> void:
	if visible and (evenement.is_action_pressed(&"annuler") or evenement.is_action_pressed(&"pause")):
		get_viewport().set_input_as_handled()
		_fermer()


func _fermer() -> void:
	hide()
	ferme.emit()


static func _lire_plein_ecran() -> bool:
	var fichier := ConfigFile.new()
	fichier.load(REGLAGES)
	return fichier.get_value("affichage", "plein_ecran", false)


## Rétablit le mode de fenêtre enregistré au lancement du jeu.
static func appliquer_affichage() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _lire_plein_ecran() else DisplayServer.WINDOW_MODE_WINDOWED)


func _regler_affichage(plein_ecran: bool) -> void:
	var fichier := ConfigFile.new()
	var erreur: Error = fichier.load(REGLAGES)
	if erreur == OK or erreur == ERR_FILE_NOT_FOUND:
		fichier.set_value("affichage", "plein_ecran", plein_ecran)
		erreur = fichier.save(REGLAGES)
	if erreur != OK:
		push_warning("Réglage du plein écran impossible : " + error_string(erreur))
		%PleinEcran.set_pressed_no_signal(_lire_plein_ecran())
		return
	appliquer_affichage()
