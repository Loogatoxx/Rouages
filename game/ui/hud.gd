extends CanvasLayer
## Présente les ressources de la partie, les choix de construction et le bilan.

const Interface = preload("res://game/ui/menu_titre.gd")
const Lot = preload("res://game/core/lot.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const NOMS_RARETE: Array[String] = ["Commune", "Rare", "Épique"]

@onready var _pv: Label = %PV
@onready var _ressorts: Label = %Ressorts
@onready var _bandeau: PanelContainer = %Bandeau
@onready var _flash: ColorRect = %Flash
@onready var _gain: Label = %Gain
var _ventes: Array[Button] = []
var _noms_lots: Array[Label] = []
var _solde: int
var _cle_annonce: String
var _valeur_annonce: int
var _victoire: bool
var _animation_bandeau: Tween
var _animation_choc: Tween
var _animation_gain: Tween


func _ready() -> void:
	Interface.preparer_boutons(self)
	%Lancer.pressed.connect(Run.lancer_vague)
	%Relancer.pressed.connect(Run.relancer_offre)
	%Reparer.pressed.connect(Run.reparer_horloge)
	%Vitesse.pressed.connect(_basculer_vitesse)
	%Pause.pressed.connect(Events.pause_demandee.emit)
	%Rejouer.pressed.connect(Interface.commencer_partie.bind(get_tree()))
	%MenuTitre.pressed.connect(Interface.ouvrir_titre.bind(get_tree()))
	Events.phase_changee.connect(_actualiser_phase)
	Events.horloge_touchee.connect(_recevoir_choc)
	Events.ressorts_changes.connect(_actualiser_solde)
	Events.vague_commencee.connect(_debut_vague)
	Events.vague_terminee.connect(_fin_vague)
	Events.run_terminee.connect(_afficher_fin)
	_creer_boutique()
	_actualiser_prix()
	_solde = Run.ressorts
	_actualiser_phase(Run.phase)
	Interface.apparaitre(%Tableau)


func _notification(quoi: int) -> void:
	if quoi != NOTIFICATION_TRANSLATION_CHANGED or not is_node_ready():
		return
	_actualiser_prix()
	_actualiser_compteurs(Run.phase)
	_actualiser_solde(Run.ressorts)
	if $Draft.visible:
		_actualiser_noms_lots()
	if _bandeau.visible:
		%Annonce.text = tr(_cle_annonce) % _valeur_annonce
	if $Fin.visible:
		_actualiser_bilan()


func _input(evenement: InputEvent) -> void:
	if Run.phase != Run.Phase.FIN and evenement.is_action_pressed(&"accelerer"):
		get_viewport().set_input_as_handled()
		_basculer_vitesse()


func _basculer_vitesse() -> void:
	Run.basculer_vitesse()
	%Vitesse.text = tr("x%d") % int(Run.vitesse)


func _creer_boutique() -> void:
	for i: int in Run.regles.boutique.size():
		var bouton := Button.new()
		%Achats.add_child(bouton)
		Interface.preparer_bouton(bouton)
		bouton.pressed.connect(Run.acheter.bind(i))
		_ventes.append(bouton)


func _actualiser_prix() -> void:
	for i: int in _ventes.size():
		var lot: Lot = Run.regles.boutique[i]
		_ventes[i].text = tr("%s ×%d — %d") % [tr(lot.objet.get("nom")), lot.quantite, lot.prix]
	%Reparer.text = tr("Réparer l’horloge (+%d PV) — %d") % [Run.regles.pv_reparation, Run.regles.prix_reparation]
	%Relancer.text = tr("Relancer le tirage — %d") % Run.regles.prix_relance


func _actualiser_phase(phase: int) -> void:
	var construction: bool = phase == Run.Phase.CONSTRUCTION
	$Colonne.visible = phase != Run.Phase.FIN
	%Lancer.visible = construction
	%Boutique.visible = construction
	$Draft.visible = phase == Run.Phase.DRAFT
	$Fin.visible = phase == Run.Phase.FIN
	if construction:
		Interface.apparaitre(%Boutique)
	elif $Draft.visible:
		_afficher_lots()
		Interface.apparaitre(%PanneauDraft)
	_actualiser_compteurs(phase)
	_actualiser_solde(Run.ressorts)


func _actualiser_compteurs(phase: int) -> void:
	var numero: int = Run.vague_actuelle + int(phase in [Run.Phase.CONSTRUCTION, Run.Phase.DRAFT])
	%Vague.text = tr("Vague %d / %d") % [numero, Run.nb_vagues]
	%Vitesse.text = tr("x%d") % int(Run.vitesse)


func _actualiser_solde(total: int) -> void:
	if total > _solde:
		_faire_flotter_gain(total - _solde)
	_solde = total
	_ressorts.text = tr("Ressorts : %d") % total
	_pv.text = tr("Horloge · %d / %d PV") % [Run.pv_horloge, Run.regles.pv_horloge]
	%Relancer.disabled = total < Run.regles.prix_relance
	%Reparer.disabled = total < Run.regles.prix_reparation or Run.pv_horloge >= Run.regles.pv_horloge
	for i: int in _ventes.size():
		var lot: Lot = Run.regles.boutique[i]
		var verrouille: bool = lot.vague_min > Run.vague_actuelle + 1
		_ventes[i].disabled = verrouille or total < lot.prix
		_ventes[i].tooltip_text = (tr("Disponible à la vague %d") % lot.vague_min
				if verrouille else tr(lot.objet.get("description")))


func _afficher_lots() -> void:
	_noms_lots.clear()
	for ancien: Node in %Lots.get_children():
		%Lots.remove_child(ancien)
		ancien.queue_free()
	for i: int in Run.offre.size():
		var lot: Lot = Run.offre[i]
		%Lots.add_child(_creer_carte(lot))
		var bouton: Button = %Lots.get_child(-1)
		Interface.preparer_bouton(bouton)
		bouton.pressed.connect(Run.choisir_lot.bind(i))
		if Run.offre_coffre:
			var piece: PieceDef = lot.objet as PieceDef
			_colorier_bordure(bouton, PieceDef.TEINTES_RARETE[piece.rarete])
	_actualiser_noms_lots()


func _actualiser_noms_lots() -> void:
	%TitreDraft.text = tr("Coffre !") if Run.offre_coffre else tr("Choisis un lot")
	for i: int in _noms_lots.size():
		var lot: Lot = Run.offre[i]
		if Run.offre_coffre:
			var piece: PieceDef = lot.objet as PieceDef
			_noms_lots[i].text = tr("%s · %s") % [tr(piece.nom), tr(NOMS_RARETE[piece.rarete])]
		else:
			_noms_lots[i].text = tr("%s  ×%d") % [tr(lot.objet.get("nom")), lot.quantite]


func _colorier_bordure(bouton: Button, teinte: Color) -> void:
	for etat: StringName in [&"normal", &"hover", &"pressed"]:
		var bordure: StyleBoxFlat = bouton.get_theme_stylebox(etat).duplicate() as StyleBoxFlat
		if bordure != null:
			bordure.set_border_width_all(3)
			bordure.border_color = teinte
			bouton.add_theme_stylebox_override(etat, bordure)


## Carte de lot : nom en demi-gras (ce qu'on gagne) au-dessus d'une description plus petite (à quoi ça sert).
## Pourquoi pas le texte du bouton : un seul style pour deux informations de poids différent noie le nom.
func _creer_carte(lot: Lot) -> Button:
	var bouton := Button.new()
	bouton.custom_minimum_size = Vector2(420, 84)
	var marges := MarginContainer.new()
	marges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for cote: String in ["left", "right"]:
		marges.add_theme_constant_override("margin_" + cote, 18)
	for cote: String in ["top", "bottom"]:
		marges.add_theme_constant_override("margin_" + cote, 10)
	var colonne := VBoxContainer.new()
	colonne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	colonne.add_theme_constant_override("separation", 2)
	var nom := Label.new()
	nom.theme_type_variation = &"CarteNom"
	_noms_lots.append(nom)
	var texte := Label.new()
	texte.theme_type_variation = &"CarteTexte"
	texte.text = lot.objet.get("description")
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for etiquette: Label in [nom, texte]:
		etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		colonne.add_child(etiquette)
	marges.add_child(colonne)
	bouton.add_child(marges)
	return bouton


func _debut_vague(numero: int) -> void:
	_annoncer("Vague %d", numero)


func _fin_vague(_numero: int) -> void:
	_annoncer("Vague tenue ! +%d ressorts", Run.derniere_recompense)


func _annoncer(cle: String, valeur: int) -> void:
	if _animation_bandeau:
		_animation_bandeau.kill()
	_cle_annonce = cle
	_valeur_annonce = valeur
	%Annonce.text = tr(cle) % valeur
	_bandeau.show()
	Interface.apparaitre(_bandeau)
	_animation_bandeau = create_tween()
	_animation_bandeau.tween_interval(1.05)
	_animation_bandeau.tween_property(_bandeau, "modulate:a", 0.0, 0.45)
	_animation_bandeau.tween_callback(_bandeau.hide)


func _recevoir_choc(pv: int) -> void:
	_pv.text = tr("Horloge · %d / %d PV") % [pv, Run.regles.pv_horloge]
	if _animation_choc:
		_animation_choc.kill()
	_flash.color.a = 0.24
	_animation_choc = create_tween()
	_animation_choc.tween_property(_flash, "color:a", 0.0, 0.35)
	# Le conteneur aligne le libellé à gauche, à l'origine de sa colonne.
	_pv.position.x = -4.0
	_animation_choc.parallel().tween_property(_pv, "position:x", 4.0, 0.07)
	_animation_choc.parallel().tween_property(_pv, "position:x", -2.0, 0.07).set_delay(0.07)
	_animation_choc.parallel().tween_property(_pv, "position:x", 0.0, 0.09).set_delay(0.14)


func _faire_flotter_gain(montant: int) -> void:
	if _animation_gain:
		_animation_gain.kill()
	_gain.text = tr("+%d") % montant
	_gain.position = _ressorts.global_position + Vector2(_ressorts.size.x - 64.0, 0.0)
	_gain.modulate.a = 1.0
	_gain.show()
	_animation_gain = create_tween().set_parallel()
	_animation_gain.tween_property(_gain, "position:y", _gain.position.y - 25.0, 0.65)
	_animation_gain.tween_property(_gain, "modulate:a", 0.0, 0.35).set_delay(0.3)
	_animation_gain.chain().tween_callback(_gain.hide)


func _afficher_fin(victoire: bool) -> void:
	_victoire = victoire
	_actualiser_bilan()
	Interface.noter_defi(Run.vague_actuelle if victoire else maxi(0, Run.vague_actuelle - 1))
	if _animation_bandeau:
		_animation_bandeau.kill()
	_bandeau.hide()
	Interface.apparaitre(%PanneauFin)
	%Rejouer.grab_focus()
	if victoire:
		var confettis: CPUParticles2D = %Confettis
		var largeur: float = get_viewport().get_visible_rect().size.x
		confettis.position = Vector2(largeur / 2.0, -20.0)
		confettis.emission_rect_extents.x = largeur / 2.0
		confettis.restart()
		confettis.emitting = true


func _actualiser_bilan() -> void:
	%Bilan.text = "Victoire !" if _victoire else "L’horloge s’est arrêtée…"
	var tenues: int = Run.vague_actuelle if _victoire else maxi(0, Run.vague_actuelle - 1)
	%Stats.text = tr("Vagues tenues : %d / %d\nScarabées cassés : %d\nRessorts gagnés : %d") % [
		tenues, Run.nb_vagues, Run.ennemis_casses, Run.ressorts_gagnes]
