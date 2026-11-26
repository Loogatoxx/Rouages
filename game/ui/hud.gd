extends CanvasLayer
## Présente les ressources de la partie, les choix de construction et le bilan.

const Interface = preload("res://game/ui/menu_titre.gd")
const Lot = preload("res://game/core/lot.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const Reperes = preload("res://game/ui/reperes.gd")
const NOMS_RARETE: Array[String] = ["Commune", "Rare", "Épique"]

const ICONE_RESSORT: Texture2D = preload("res://assets/ui/icones/ressort.png")
const ICONE_PV: Texture2D = preload("res://assets/ui/icones/horloge_pv.png")
const VITESSE_NORMALE: Texture2D = preload("res://assets/ui/icones/vitesse_x1.png")
const VITESSE_DOUBLE: Texture2D = preload("res://assets/ui/icones/vitesse_x2.png")
const MEDAILLONS: Array[Texture2D] = [
	preload("res://assets/ui/icones/rarete_commune.png"),
	preload("res://assets/ui/icones/rarete_rare.png"),
	preload("res://assets/ui/icones/rarete_epique.png")
]

@onready var _pv: Label = %PV
@onready var _ressorts: Label = %Ressorts
@onready var _bandeau: PanelContainer = %Bandeau
@onready var _flash: ColorRect = %Flash
@onready var _gain: Label = %Gain
var _ventes: Array[Button] = []
var _prix_ventes: Array[Label] = []
var _solde: int
var _cle_annonce: String
var _valeur_annonce: int
var _victoire: bool
var _animation_bandeau: Tween
var _animation_choc: Tween
var _animation_gain: Tween
## Barre de vie du boss, construite en code (haut-centre) : visible seulement quand un boss vit.
var _barre_boss: ProgressBar
var _cadre_boss: VBoxContainer
var _animation_boss: Tween
var _boss_visible: bool = false
## Choix du joueur (bouton ou touche B) gardé toute la run : la boutique ne se rouvre pas toute seule s'il l'a fermée.
var _boutique_ouverte: bool = true


func _ready() -> void:
	Interface.preparer_boutons(self)
	get_viewport().size_changed.connect(_dimensionner_tirage)
	%Lots.resized.connect(_ajuster_hauteur)
	%Lancer.pressed.connect(Run.lancer_vague)
	%Relancer.pressed.connect(Run.relancer_offre)
	%Reparer.pressed.connect(Run.reparer_horloge)
	%Vitesse.pressed.connect(_basculer_vitesse)
	%Pause.pressed.connect(Events.pause_demandee.emit)
	%OuvrirBoutique.toggled.connect(_basculer_boutique)
	%Rejouer.pressed.connect(Interface.commencer_partie.bind(get_tree()))
	%MenuTitre.pressed.connect(Interface.ouvrir_titre.bind(get_tree()))
	Events.phase_changee.connect(_actualiser_phase)
	Events.horloge_touchee.connect(_recevoir_choc)
	Events.ressorts_changes.connect(_actualiser_solde)
	Events.vague_commencee.connect(_debut_vague)
	Events.vague_terminee.connect(_fin_vague)
	Events.run_terminee.connect(_afficher_fin)
	Events.message_joueur.connect(func(texte: String) -> void: _annoncer(texte, -1))
	_creer_boutique()
	_caler_prix(%PrixReparation)
	var ressort := TextureRect.new()
	ressort.texture = ICONE_RESSORT
	ressort.custom_minimum_size = Vector2(24, 24)
	ressort.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ressort.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	%PrixReparation.get_parent().add_child(ressort)
	%PrixReparation.get_parent().move_child(ressort, %PrixReparation.get_index())
	_actualiser_prix()
	_solde = Run.ressorts
	_actualiser_phase(Run.phase)
	Interface.apparaitre(%Tableau)
	_creer_barre_boss()
	var reperes := Reperes.new()
	reperes.plateau_noeud = get_parent().get_node_or_null("PlateauNoeud")
	reperes.partie = get_parent().get_node_or_null("Partie")
	add_child(reperes)
	move_child(reperes, 0)


func _creer_barre_boss() -> void:
	_cadre_boss = VBoxContainer.new()
	_cadre_boss.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_cadre_boss.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_cadre_boss.offset_top = 14
	_cadre_boss.alignment = BoxContainer.ALIGNMENT_CENTER
	_cadre_boss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cadre_boss.modulate.a = 0.0
	_cadre_boss.theme = preload("res://game/ui/theme_rouages.tres")
	_cadre_boss.hide()
	add_child(_cadre_boss)
	var nom := Label.new()
	nom.text = "Grand Scarabée"
	nom.theme_type_variation = &"Titre"
	nom.add_theme_font_size_override(&"font_size", 30)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cadre_boss.add_child(nom)
	_barre_boss = ProgressBar.new()
	_barre_boss.custom_minimum_size = Vector2(520, 22)
	_barre_boss.show_percentage = false
	_barre_boss.max_value = 1.0
	_barre_boss.step = 0.0
	_barre_boss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color("#5A3A22")
	fond.border_color = Color("#D9AE54")
	fond.set_border_width_all(3)
	fond.set_corner_radius_all(6)
	var plein := StyleBoxFlat.new()
	plein.bg_color = Color("#D66355")
	plein.set_corner_radius_all(4)
	plein.set_expand_margin_all(-3)
	_barre_boss.add_theme_stylebox_override(&"background", fond)
	_barre_boss.add_theme_stylebox_override(&"fill", plein)
	_cadre_boss.add_child(_barre_boss)


func _process(_delta: float) -> void:
	if _barre_boss == null:
		return
	var partie: Node = get_parent().get_node_or_null("Partie")
	# Compteur « ennemis restants » : visible seulement pendant une vague (playtest 1 : HUD clair).
	%EnnemisPlaque.visible = Run.phase == Run.Phase.VAGUE and partie != null
	if %EnnemisPlaque.visible:
		%Ennemis.text = "%d / %d" % [partie.directeur.restants(partie.sim), partie.directeur.total()]
	var pv: Vector2 = partie.sim.pv_boss() if partie != null else Vector2.ZERO
	var vivant: bool = pv.y > 0.0
	if vivant != _boss_visible:
		_boss_visible = vivant
		if _animation_boss:
			_animation_boss.kill()
		_animation_boss = create_tween()
		if vivant:
			_barre_boss.value = 1.0
			_cadre_boss.show()
			_animation_boss.tween_property(_cadre_boss, "modulate:a", 1.0, 0.3)
		else:
			_animation_boss.tween_property(_cadre_boss, "modulate:a", 0.0, 0.4)
			_animation_boss.tween_callback(_cadre_boss.hide)
	if vivant:
		# Descente douce : on rattrape la vraie valeur sans à-coup.
		_barre_boss.value = lerpf(_barre_boss.value, pv.x / pv.y, 0.2)


func _notification(quoi: int) -> void:
	if quoi != NOTIFICATION_TRANSLATION_CHANGED or not is_node_ready():
		return
	_actualiser_prix()
	_actualiser_compteurs(Run.phase)
	_actualiser_solde(Run.ressorts)
	if $Draft.visible:
		# Reconstruire les cartes : leur papier se redimensionne alors avec le texte traduit (sinon il débordait).
		_afficher_lots()
	if _bandeau.visible:
		%Annonce.text = tr(_cle_annonce) if _valeur_annonce < 0 else tr(_cle_annonce) % _valeur_annonce
	if $Fin.visible:
		_actualiser_bilan()


# La boutique se replie pour dégager le plateau (playtest 1 : « elle reste constamment dépliée »).
func _basculer_boutique(ouverte: bool) -> void:
	_boutique_ouverte = ouverte
	var construction: bool = Run.phase == Run.Phase.CONSTRUCTION
	%Boutique.visible = construction and ouverte
	if %Boutique.visible:
		Interface.apparaitre(%Boutique)


func _input(evenement: InputEvent) -> void:
	if Run.phase == Run.Phase.CONSTRUCTION and evenement.is_action_pressed(&"boutique") and not get_tree().paused:
		get_viewport().set_input_as_handled()
		%OuvrirBoutique.button_pressed = not %OuvrirBoutique.button_pressed
		return
	if Run.phase != Run.Phase.FIN and evenement.is_action_pressed(&"accelerer"):
		get_viewport().set_input_as_handled()
		_basculer_vitesse()


func _basculer_vitesse() -> void:
	Run.basculer_vitesse()
	_afficher_vitesse()


func _afficher_vitesse() -> void:
	%Vitesse.icon = VITESSE_DOUBLE if Run.vitesse == 2 else VITESSE_NORMALE
	# Le triangle seul se lisait « lecture / lancer » (audit UI) : on écrit la vitesse à côté.
	%Vitesse.text = "×%d" % int(Run.vitesse)
	%Vitesse.accessibility_name = tr("Changer la vitesse (Espace)") + " · " + tr("x%d") % int(Run.vitesse)


# Boutique en tuiles (playtest 1 : « icônes au premier plan, texte au survol ») : vignette de la pièce, quantité et prix
# avec l'icône ressort ; nom et effet passent dans l'infobulle.
func _creer_boutique() -> void:
	for i: int in Run.regles.boutique.size():
		var lot: Lot = Run.regles.boutique[i]
		var bouton := Button.new()
		bouton.custom_minimum_size = Vector2(112, 124)
		var colonne := VBoxContainer.new()
		colonne.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
		colonne.alignment = BoxContainer.ALIGNMENT_CENTER
		colonne.add_theme_constant_override(&"separation", 0)
		colonne.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bouton.add_child(colonne)
		var vignette := TextureRect.new()
		vignette.texture = Interface.vignette_de(lot.objet)
		vignette.custom_minimum_size = Vector2(78, 78)
		vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vignette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		colonne.add_child(vignette)
		var bas := HBoxContainer.new()
		bas.alignment = BoxContainer.ALIGNMENT_CENTER
		bas.add_theme_constant_override(&"separation", 2)
		bas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		colonne.add_child(bas)
		var quantite := Label.new()
		quantite.theme_type_variation = &"Nombre"
		quantite.add_theme_font_size_override(&"font_size", 17)
		quantite.text = "×%d " % lot.quantite
		bas.add_child(quantite)
		var ressort := TextureRect.new()
		ressort.texture = ICONE_RESSORT
		ressort.custom_minimum_size = Vector2(20, 20)
		ressort.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ressort.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bas.add_child(ressort)
		var prix := Label.new()
		prix.theme_type_variation = &"Nombre"
		prix.add_theme_font_size_override(&"font_size", 17)
		bas.add_child(prix)
		%Achats.add_child(bouton)
		_prix_ventes.append(prix)
		Interface.preparer_bouton(bouton)
		bouton.pressed.connect(Run.acheter.bind(i))
		_ventes.append(bouton)


# Colonne de prix de largeur fixe, chiffres centrés dans la pastille : tous les boutons de la boutique ont la même largeur,
# quel que soit le prix ou la langue (playtest 1 : « textes désalignés »).
func _caler_prix(prix: Label) -> void:
	prix.custom_minimum_size.x = 76
	prix.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prix.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _actualiser_prix() -> void:
	for i: int in _ventes.size():
		var lot: Lot = Run.regles.boutique[i]
		_prix_ventes[i].text = str(lot.prix)
		_ventes[i].accessibility_name = tr("%s ×%d — %d") % [tr(lot.objet.get("nom")), lot.quantite, lot.prix]
	# Réparer : cœur + gain de PV sur le bouton, libellé complet au survol.
	%Reparer.icon = ICONE_PV
	%Reparer.expand_icon = true
	%Reparer.add_theme_constant_override(&"icon_max_width", 30)
	%Reparer.text = "+%d" % Run.regles.pv_reparation
	%Reparer.tooltip_text = tr("Réparer l’horloge (+%d PV)") % Run.regles.pv_reparation
	%PrixReparation.text = str(Run.regles.prix_reparation)
	%Reparer.accessibility_name = tr("Réparer l’horloge (+%d PV) — %d") % [Run.regles.pv_reparation, Run.regles.prix_reparation]


func _actualiser_phase(phase: int) -> void:
	var construction: bool = phase == Run.Phase.CONSTRUCTION
	$Colonne.visible = phase != Run.Phase.FIN
	%Lancer.visible = construction
	%OuvrirBoutique.visible = construction
	%Boutique.visible = construction and _boutique_ouverte
	$Draft.visible = phase == Run.Phase.DRAFT
	$Fin.visible = phase == Run.Phase.FIN
	if construction and _boutique_ouverte:
		Interface.apparaitre(%Boutique)
	elif $Draft.visible:
		_afficher_lots()
		Interface.apparaitre(%PanneauDraft)
	_actualiser_compteurs(phase)
	_actualiser_solde(Run.ressorts)


func _actualiser_compteurs(phase: int) -> void:
	var numero: int = Run.vague_actuelle + int(phase in [Run.Phase.CONSTRUCTION, Run.Phase.DRAFT])
	# L'icône dit « vague », le nombre suffit ; le mot passe dans l'infobulle (audit UI : icônes d'abord).
	%Vague.text = "%d / %d" % [numero, Run.nb_vagues]
	%Vague.get_parent().get_parent().tooltip_text = tr("Vague %d / %d") % [numero, Run.nb_vagues]
	_afficher_vitesse()


func _actualiser_solde(total: int) -> void:
	if total > _solde:
		_faire_flotter_gain(total - _solde)
	_solde = total
	_ressorts.text = str(total)
	_ressorts.tooltip_text = tr("Ressorts : %d") % total
	_ressorts.accessibility_name = _ressorts.tooltip_text
	_afficher_pv(Run.pv_horloge)
	%Relancer.disabled = total < Run.prix_relance
	%Relancer.text = tr("Relancer gratuitement") if Run.prix_relance == 0 else tr("Relancer le tirage")
	%PrixRelance.visible = Run.prix_relance > 0
	%PrixRelance.text = str(Run.prix_relance)
	%Relancer.accessibility_name = tr("Relancer le tirage — %d") % Run.prix_relance if Run.prix_relance > 0 else tr("Relancer gratuitement")
	%Reparer.disabled = total < Run.regles.prix_reparation or Run.pv_horloge >= Run.pv_max
	for i: int in _ventes.size():
		var lot: Lot = Run.regles.boutique[i]
		var verrouille: bool = lot.vague_min > Run.vague_actuelle + 1
		_ventes[i].disabled = verrouille or total < lot.prix
		# Tuile trop chère ou verrouillée : grisée (audit UI : coûts inabordables lisibles d'un coup d'œil).
		_ventes[i].modulate = Color(1, 1, 1, 0.55) if _ventes[i].disabled else Color.WHITE
		var entete: String = tr("%s ×%d — %d ressorts") % [tr(lot.objet.get("nom")), lot.quantite, lot.prix]
		_ventes[i].tooltip_text = entete + "\n" + (tr("Disponible à la vague %d") % lot.vague_min
				if verrouille else tr(lot.objet.get("description")))


func _afficher_lots() -> void:
	for ancien: Node in %Lots.get_children():
		%Lots.remove_child(ancien)
		ancien.queue_free()
	for i: int in Run.offre.size():
		var carte := Carte.new(Run.offre[i], i, Run.offre_coffre)
		%Lots.add_child(carte)
		carte.pressed.connect(Sons.jouer.bind(&"clic"))
		carte.pressed.connect(Run.choisir_lot.bind(i))
	_actualiser_noms_lots()
	_dimensionner_tirage()


func _actualiser_noms_lots() -> void:
	%TitreDraft.text = tr("Coffre !") if Run.offre_coffre else tr("Choisis un lot")
	%Coffre.visible = Run.offre_coffre
	for i: int in %Lots.get_child_count():
		var lot: Lot = Run.offre[i]
		var carte: Carte = %Lots.get_child(i)
		carte.nom.text = tr(lot.objet.get("nom"))
		carte.accessibility_name = tr("%s ×%d") % [carte.nom.text, lot.quantite]
		if Run.offre_coffre:
			var piece: PieceDef = lot.objet as PieceDef
			carte.accessibility_name = tr("%s · %s") % [carte.nom.text, tr(NOMS_RARETE[piece.rarete])]
		carte.accessibility_description = tr(lot.objet.get("description"))


func _dimensionner_tirage() -> void:
	if not $Draft.visible:
		return
	var largeur: float = get_viewport().get_visible_rect().size.x
	# Les cartes de coffre portent un médaillon et une étiquette de rareté : elles sont plus larges.
	var par_carte: float = 345.0 if Run.offre_coffre else 300.0
	var retrait: float = maxf(0, (largeur * 0.92 - (Run.offre.size() * par_carte + 110)) / 2)
	$Draft.offset_left = retrait
	$Draft.offset_right = -retrait
	_ajuster_hauteur()


func _ajuster_hauteur() -> void:
	var hauteur: float = get_viewport().get_visible_rect().size.y
	%DefilementLots.custom_minimum_size.y = minf(%Lots.size.y + 28, hauteur * 0.42)


## Le bouton garde sa place dans la rangée pendant que sa fiche de papier bouge.
class Carte extends Button:
	var nom: Label = Label.new()
	var _papier: PanelContainer = PanelContainer.new()
	var _textes: Array[Label] = []
	var _mouvement: Tween

	func _init(lot: Lot, indice: int, coffre: bool) -> void:
		theme_type_variation = &"Carte"
		_papier.theme_type_variation = &"Fiche"
		_papier.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		add_child(_papier)
		var colonne := VBoxContainer.new()
		_papier.add_child(colonne)
		var insigne := HBoxContainer.new()
		colonne.add_child(insigne)
		var badge := Label.new()
		badge.theme_type_variation = &"Badge"
		if coffre:
			var piece: PieceDef = lot.objet as PieceDef
			var medaillon := TextureRect.new()
			medaillon.texture = MEDAILLONS[piece.rarete]
			medaillon.custom_minimum_size = Vector2(36, 36)
			medaillon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			medaillon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			insigne.add_child(medaillon)
			badge.text = NOMS_RARETE[piece.rarete]
		else:
			badge.text = "×%d" % lot.quantite
		insigne.add_child(badge)
		# Vignette de la pièce à droite de l'insigne : on reconnaît le lot avant de lire.
		var vignette := TextureRect.new()
		vignette.texture = Interface.vignette_de(lot.objet)
		vignette.custom_minimum_size = Vector2(64, 64)
		vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vignette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vignette.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
		insigne.add_child(vignette)
		nom.theme_type_variation = &"CarteNom"
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nom.custom_minimum_size.x = 206
		colonne.add_child(nom)
		var description := Label.new()
		description.theme_type_variation = &"CarteTexte"
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Même largeur fixe que le nom : un texte à retour à la ligne calcule sa hauteur sur sa largeur ; sans largeur
		# fixe, la hauteur venait d'une mise en page précédente et le texte portugais débordait du papier.
		description.custom_minimum_size.x = 206
		description.text = lot.objet.get("description")
		colonne.add_child(description)
		_textes = [nom, description]
		_papier.rotation_degrees = -1.5 if indice % 2 == 0 else 1.5
		_papier.minimum_size_changed.connect(_dimensionner)
		resized.connect(_ajuster_papier)

	func _ready() -> void:
		_caler_hauteurs()
		_dimensionner()
		_papier.scale = Vector2.ONE * 1.06
		var rebond: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rebond.tween_property(_papier, "scale", Vector2.ONE, 0.28)
		mouse_entered.connect(_soulever)
		mouse_exited.connect(_soulever)
		focus_entered.connect(_soulever)
		focus_exited.connect(_soulever)
		button_down.connect(_soulever)
		button_up.connect(_soulever)

	# Hauteur de chaque texte mesurée sur sa police (voir `Interface.caler_hauteur`).
	func _caler_hauteurs() -> void:
		for texte: Label in _textes:
			Interface.caler_hauteur(texte, 206.0)

	func _dimensionner() -> void:
		custom_minimum_size = _papier.get_combined_minimum_size()
		_ajuster_papier()

	func _ajuster_papier() -> void:
		_papier.size = size
		_papier.pivot_offset = size / 2

	func _soulever() -> void:
		if _mouvement:
			_mouvement.kill()
		var hauteur: float = -6.0 if is_hovered() or has_focus() else 0.0
		if is_pressed():
			hauteur += 2.0
		_mouvement = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_mouvement.tween_property(_papier, "position:y", hauteur, 0.1)


func _debut_vague(numero: int) -> void:
	_annoncer("Vague %d", numero)


func _fin_vague(_numero: int) -> void:
	_annoncer("Vague tenue ! +%d ressorts", Run.derniere_recompense)


func _annoncer(cle: String, valeur: int) -> void:
	if _animation_bandeau:
		_animation_bandeau.kill()
	_cle_annonce = cle
	_valeur_annonce = valeur
	%Annonce.text = tr(cle) if valeur < 0 else tr(cle) % valeur
	_bandeau.show()
	Interface.apparaitre(_bandeau)
	_animation_bandeau = create_tween()
	_animation_bandeau.tween_interval(1.05)
	_animation_bandeau.tween_property(_bandeau, "modulate:a", 0.0, 0.45)
	_animation_bandeau.tween_callback(_bandeau.hide)


func _afficher_pv(pv: int) -> void:
	_pv.text = "%d / %d" % [pv, Run.pv_max]
	_pv.tooltip_text = tr("Horloge · %d / %d PV") % [pv, Run.pv_max]
	_pv.accessibility_name = _pv.tooltip_text


func _recevoir_choc(pv: int) -> void:
	_afficher_pv(pv)
	if _animation_choc:
		_animation_choc.kill()
	_flash.color.a = 0.24
	_animation_choc = create_tween()
	_animation_choc.tween_property(_flash, "color:a", 0.0, 0.35)
	_pv.modulate = Color("#e88e70")
	_animation_choc.parallel().tween_property(_pv, "modulate", Color.WHITE, 0.32)


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
	%PrimeOr.text = tr("+%d engrenages d’or") % Run.engrenages_gagnes
