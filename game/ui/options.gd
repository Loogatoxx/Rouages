extends CanvasLayer
## Rassemble les préférences accessibles depuis le titre et la pause.

signal ferme

const Langue = preload("res://game/ui/langue.gd")
const REGLAGES := "user://reglages.cfg"


func _ready() -> void:
	%Musique.value_changed.connect(func(niveau: float) -> void: Sons.regler_volume(&"Musique", niveau))
	%Effets.value_changed.connect(func(niveau: float) -> void: Sons.regler_volume(&"Effets", niveau))
	%PleinEcran.toggled.connect(_regler_affichage)
	# Curseurs et libellés en retrait du cadre de bois (ils touchaient la rainure intérieure : audit UI).
	for controle: Control in [%Musique, %Effets, $Voile/Centre/Panneau/Colonne/LibelleMusique, $Voile/Centre/Panneau/Colonne/LibelleEffets]:
		controle.custom_minimum_size.x = 372
		controle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	%ChoixLangue.pressed.connect(Langue.suivante)
	%Retour.pressed.connect(_fermer)


## Affiche les préférences actuelles et place le focus sur le premier curseur.
func ouvrir() -> void:
	%Musique.set_value_no_signal(Sons.volume(&"Musique"))
	%Effets.set_value_no_signal(Sons.volume(&"Effets"))
	%PleinEcran.set_pressed_no_signal(_lire_plein_ecran())
	_ecrire_plein_ecran()
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
	_ecrire_plein_ecran()


# L'interrupteur seul ne laissait pas lire l'état (audit UI) : l'état est écrit dans le libellé.
func _ecrire_plein_ecran() -> void:
	%PleinEcran.text = tr("Plein écran : activé") if %PleinEcran.button_pressed else tr("Plein écran : désactivé")


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_ecrire_plein_ecran()
