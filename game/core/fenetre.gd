extends Node
## Garde le mode de la fenêtre (plein écran ou fenêtré) d'un bout à l'autre de la session (autoload « Fenetre »).
##
## Pourquoi : avant, l'écran titre réappliquait le réglage enregistré à chaque retour au menu. Si le joueur était passé
## en plein écran autrement que par la case des options (bouton vert macOS, raccourci), le réglage disait « fenêtré »
## et le retour au menu quittait le plein écran (playtest 1). Désormais le mode n'est appliqué qu'au lancement,
## et tout changement de la vraie fenêtre est enregistré.

const REGLAGES := "user://reglages.cfg"

var _plein_ecran: bool = false


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Captures et tests : `-- --fenetre` après les arguments du moteur garde la fenêtre telle quelle, sans rien enregistrer.
	# (Godot retire `--windowed` des arguments visibles par le jeu, d'où cet argument à nous.)
	if OS.get_cmdline_user_args().has("--fenetre"):
		return
	_plein_ecran = lire()
	_appliquer()
	get_tree().root.size_changed.connect(_suivre_fenetre)


func _unhandled_input(evenement: InputEvent) -> void:
	if evenement.is_action_pressed(&"plein_ecran"):
		get_viewport().set_input_as_handled()
		regler(not est_plein_ecran())


## Indique si la fenêtre est réellement en plein écran (quelle que soit la façon dont elle y est passée).
func est_plein_ecran() -> bool:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## Passe en plein écran ou en fenêtré et enregistre ce choix.
func regler(plein_ecran: bool) -> void:
	_plein_ecran = plein_ecran
	_enregistrer()
	_appliquer()


func _appliquer() -> void:
	if DisplayServer.get_name() == "headless" or est_plein_ecran() == _plein_ecran:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _plein_ecran
			else DisplayServer.WINDOW_MODE_WINDOWED)


# La fenêtre a changé de taille : si c'est un passage en plein écran (ou une sortie) venu du système, on le mémorise.
func _suivre_fenetre() -> void:
	var reel: bool = est_plein_ecran()
	if reel != _plein_ecran:
		_plein_ecran = reel
		_enregistrer()


func _enregistrer() -> void:
	var fichier := ConfigFile.new()
	var erreur: Error = fichier.load(REGLAGES)
	if erreur != OK and erreur != ERR_FILE_NOT_FOUND:
		push_warning("Lecture des réglages impossible : " + error_string(erreur))
		return
	fichier.set_value("affichage", "plein_ecran", _plein_ecran)
	erreur = fichier.save(REGLAGES)
	if erreur != OK:
		push_warning("Réglage du plein écran impossible : " + error_string(erreur))


## Lit le mode enregistré (fenêtré si rien n'est enregistré).
static func lire() -> bool:
	var fichier := ConfigFile.new()
	fichier.load(REGLAGES)
	return fichier.get_value("affichage", "plein_ecran", false)
