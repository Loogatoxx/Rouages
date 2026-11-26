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


func _lire_plein_ecran() -> bool:
	return Fenetre.est_plein_ecran()


func _regler_affichage(plein_ecran: bool) -> void:
	Fenetre.regler(plein_ecran)
