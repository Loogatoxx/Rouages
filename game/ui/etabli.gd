extends CanvasLayer
## Présente les améliorations permanentes et permet d'en acheter le niveau suivant.

signal ferme

const Progression = preload("res://game/core/progression.gd")
const AmeliorationDef = preload("res://game/core/amelioration_def.gd")


## Regroupe les contrôles d'une amélioration pour actualiser la ligne après un achat.
class Ligne extends HBoxContainer:
	var definition: AmeliorationDef
	var nom := Label.new()
	var description := Label.new()
	var pastilles := Label.new()
	var achat := Button.new()
	var prix := Label.new()

	func _init(def: AmeliorationDef) -> void:
		definition = def
		var textes := VBoxContainer.new()
		textes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textes.add_theme_constant_override("separation", 0)
		nom.theme_type_variation = &"CarteNom"
		pastilles.theme_type_variation = &"CarteTexte"
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.theme_type_variation = &"CarteTexte"
		textes.add_child(nom)
		textes.add_child(description)
		add_child(textes)
		add_child(pastilles)
		achat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(achat)
		prix.theme_type_variation = &"Badge"
		prix.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(prix)

	## Affiche le niveau acquis et le prix du prochain niveau dans la langue active.
	func actualiser(solde: int) -> void:
		var niveau: int = Progression.niveau(definition.id)
		var complet: bool = niveau >= definition.niveaux_max
		nom.text = tr(definition.nom)
		description.text = tr(definition.description)
		pastilles.text = "●".repeat(niveau) + "○".repeat(definition.niveaux_max - niveau)
		achat.text = tr("Niveau maximum") if complet else tr("Acheter")
		prix.visible = not complet
		if not complet:
			prix.text = str(definition.prix[niveau])
			achat.accessibility_name = tr("Acheter — %d") % definition.prix[niveau]
		else:
			achat.accessibility_name = tr("Niveau maximum")
		achat.disabled = complet or solde < definition.prix[niveau]


func _ready() -> void:
	for def: AmeliorationDef in Run.regles.ameliorations:
		var ligne := Ligne.new(def)
		%Lignes.add_child(ligne)
		ligne.achat.pressed.connect(_acheter.bind(def))
	%Retour.pressed.connect(_fermer)


## Ouvre l'Établi avec le solde à jour et donne le focus au premier achat possible.
func ouvrir() -> void:
	show()
	_actualiser()
	for ligne: Ligne in %Lignes.get_children():
		if not ligne.achat.disabled:
			ligne.achat.grab_focus()
			return
	%Retour.grab_focus()


func _acheter(def: AmeliorationDef) -> void:
	if Progression.acheter(def):
		_actualiser()
		if get_viewport().gui_get_focus_owner() == null:
			%Retour.grab_focus()


func _actualiser() -> void:
	var solde: int = Progression.engrenages()
	%Solde.text = tr("Engrenages d’or : %d") % solde
	for ligne: Ligne in %Lignes.get_children():
		ligne.actualiser(solde)


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible:
		_actualiser()


func _input(evenement: InputEvent) -> void:
	if visible and evenement.is_action_pressed(&"annuler"):
		get_viewport().set_input_as_handled()
		_fermer()


func _fermer() -> void:
	hide()
	ferme.emit()
