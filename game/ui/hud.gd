extends CanvasLayer
## Présente les ressources de la partie, les choix de construction et le bilan.

const Interface = preload("res://game/ui/menu_titre.gd")
const Lot = preload("res://game/core/lot.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const Reperes = preload("res://game/ui/reperes.gd")
const Astuces = preload("res://game/ui/astuces.gd")
const THEME_UI: Theme = preload("res://game/ui/theme_rouages.tres")
const NOMS_RARETE: Array[String] = ["Commune", "Rare", "Épique", "Légendaire"]

const ICONE_RESSORT: Texture2D = preload("res://assets/ui/icones/ressort.png")
const ICONE_PV: Texture2D = preload("res://assets/ui/icones/horloge_pv.png")
const ICONE_CHANCE: Texture2D = preload("res://assets/ui/icones/chance.png")
const ICONE_DENTS: Texture2D = preload("res://assets/ui/icones/engrenage_or.png")
const VITESSE_NORMALE: Texture2D = preload("res://assets/ui/icones/vitesse_x1.png")
const VITESSE_DOUBLE: Texture2D = preload("res://assets/ui/icones/vitesse_x2.png")
const MEDAILLONS: Array[Texture2D] = [
	preload("res://assets/ui/icones/rarete_commune.png"),
	preload("res://assets/ui/icones/rarete_rare.png"),
	preload("res://assets/ui/icones/rarete_epique.png"),
	preload("res://assets/ui/icones/rarete_legendaire.png")
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
var _plaque_chance: PanelContainer
## Tic-tac (playtest 3) : jauge « dents utilisées / dents de l'Horloge » dans la barre du haut.
var _bouton_carillon: Button
var _plaque_dents: PanelContainer
var _dents: Label
var _chance: Label
var _porte_bonheur: Button
var _apercu_vague: PanelContainer
var _apercu_ligne: HBoxContainer
var _prix_porte_bonheur: Label


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
	_creer_chance()
	_creer_dents()
	_creer_carillon()
	_creer_apercu_vague()
	var astuces := Astuces.new()
	astuces.plateau_noeud = get_parent().get_node_or_null("PlateauNoeud")
	add_child(astuces)
	var reperes := Reperes.new()
	reperes.plateau_noeud = get_parent().get_node_or_null("PlateauNoeud")
	reperes.partie = get_parent().get_node_or_null("Partie")
	add_child(reperes)
	move_child(reperes, 0)
	if not Run.nouveautes.is_empty() and Run.vague_actuelle == 0:
		_annoncer_nouveautes.call_deferred()


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


# Coup de carillon (pilier 4) : bouton-cloche dans la barre du haut pendant une vague. Prêt : il brille ; sinon il
# affiche les secondes qui restent. Un clic (ou la touche du carillon) fait viser, le clic suivant sur le plateau sonne.
func _creer_carillon() -> void:
	_bouton_carillon = Button.new()
	_bouton_carillon.icon = preload("res://assets/ui/icones/carillon.png")
	_bouton_carillon.expand_icon = true
	_bouton_carillon.custom_minimum_size = Vector2(92, 0)
	_bouton_carillon.add_theme_constant_override(&"icon_max_width", 34)
	_bouton_carillon.visible = false
	_bouton_carillon.pressed.connect(func() -> void: Events.carillon_vise.emit())
	Interface.preparer_bouton(_bouton_carillon)
	%Tableau.add_child(_bouton_carillon)
	%Tableau.move_child(_bouton_carillon, %Vitesse.get_index())
	Events.phase_changee.connect(func(phase: int) -> void: _bouton_carillon.visible = phase == Run.Phase.VAGUE)
	var horloge := Timer.new()
	horloge.wait_time = 0.2
	horloge.autostart = true
	horloge.timeout.connect(_actualiser_carillon)
	add_child(horloge)


func _actualiser_carillon() -> void:
	if not _bouton_carillon.visible:
		return
	var partie: Node = get_tree().get_first_node_in_group(&"partie")
	var attente: float = partie.carillon_attente if partie != null else 0.0
	_bouton_carillon.text = "" if attente <= 0.0 else str(ceili(attente))
	_bouton_carillon.modulate = Color.WHITE if attente <= 0.0 else Color(1, 1, 1, 0.6)
	_bouton_carillon.tooltip_text = tr("Coup de carillon : clique ici puis sur la route pour étourdir les ennemis proches (touche %s)") % Touches.nom_touche(&"coup_carillon") \
			if attente <= 0.0 else tr("Le carillon se remonte : encore %d s.") % ceili(attente)


# Jauge d'énergie de l'Horloge, juste après les PV : dents consommées par les ateliers et tourelles / dents
# disponibles. Elle passe au rouge quand un bâtiment reste éteint faute de dents.
func _creer_dents() -> void:
	_plaque_dents = PanelContainer.new()
	_plaque_dents.theme_type_variation = &"Plaque"
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override(&"separation", 4)
	_plaque_dents.add_child(ligne)
	ligne.add_child(_icone(ICONE_DENTS, 34))
	_dents = Label.new()
	_dents.theme_type_variation = &"Nombre"
	ligne.add_child(_dents)
	%Tableau.add_child(_plaque_dents)
	%Tableau.move_child(_plaque_dents, %PV.get_parent().get_parent().get_index() + 1)
	Events.energie_recalculee.connect(func(_cases: Array[Vector2i]) -> void: _actualiser_dents())
	_actualiser_dents.call_deferred()


func _actualiser_dents() -> void:
	var noeud: Node = get_tree().get_first_node_in_group(&"plateau_noeud")
	if noeud == null or noeud.dents < 0:
		_plaque_dents.visible = false  # bac à sable : énergie illimitée
		return
	_plaque_dents.visible = true
	var pleine: bool = not noeud.surcharge_horloge.is_empty()
	_dents.text = "%d / %d" % [noeud.charge_horloge, noeud.dents]
	_dents.add_theme_color_override(&"font_color", Color("#C0392B") if pleine else Color("#3B2A1A"))
	_plaque_dents.tooltip_text = tr("Énergie de l’Horloge : %d dents utilisées sur %d.\nUn atelier en consomme 2, une petite tourelle 1. Les engrenages n’en consomment pas.\nL’Horloge gagne une dent après les vagues 2, 4, 6 et 8.") % [noeud.charge_horloge, noeud.dents]


# Compteur de chance (trèfle) dans la barre du haut, et porte-bonheur dans la boutique (benchmark D4).
func _creer_chance() -> void:
	_plaque_chance = PanelContainer.new()
	_plaque_chance.theme_type_variation = &"Plaque"
	_plaque_chance.visible = false
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override(&"separation", 4)
	_plaque_chance.add_child(ligne)
	ligne.add_child(_icone(ICONE_CHANCE, 34))
	_chance = Label.new()
	_chance.theme_type_variation = &"Nombre"
	ligne.add_child(_chance)
	%Tableau.add_child(_plaque_chance)
	%Tableau.move_child(_plaque_chance, %Ressorts.get_parent().get_parent().get_index() + 1)
	var rangee := HBoxContainer.new()
	_porte_bonheur = Button.new()
	_porte_bonheur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_porte_bonheur.icon = ICONE_CHANCE
	_porte_bonheur.expand_icon = true
	_porte_bonheur.add_theme_constant_override(&"icon_max_width", 30)
	_porte_bonheur.text = "+%d" % Run.regles.chance_porte_bonheur
	_porte_bonheur.pressed.connect(Run.acheter_porte_bonheur)
	Interface.preparer_bouton(_porte_bonheur)
	rangee.add_child(_porte_bonheur)
	rangee.add_child(_icone(ICONE_RESSORT, 24))
	_prix_porte_bonheur = Label.new()
	_prix_porte_bonheur.theme_type_variation = &"Badge"
	_prix_porte_bonheur.text = str(Run.regles.prix_porte_bonheur)
	_caler_prix(_prix_porte_bonheur)
	rangee.add_child(_prix_porte_bonheur)
	%Reparer.get_parent().add_sibling(rangee)


# Aperçu de la vague suivante pendant la construction (benchmark D8, Legion TD 2) : on prépare sa défense en connaissant
# la composition (vignette + effectif par type d'ennemi, libellules et boss compris).
func _creer_apercu_vague() -> void:
	_apercu_vague = PanelContainer.new()
	_apercu_vague.theme_type_variation = &"Plaque"
	_apercu_vague.size_flags_horizontal = Control.SIZE_SHRINK_END
	_apercu_vague.visible = false
	_apercu_ligne = HBoxContainer.new()
	_apercu_ligne.add_theme_constant_override(&"separation", 6)
	_apercu_vague.add_child(_apercu_ligne)
	%Lancer.add_sibling(_apercu_vague)


func _actualiser_apercu_vague() -> void:
	var visible_apercu: bool = Run.phase == Run.Phase.CONSTRUCTION and Run.vague_actuelle < Run.nb_vagues
	_apercu_vague.visible = visible_apercu
	if not visible_apercu:
		return
	for ancien: Node in _apercu_ligne.get_children():
		ancien.queue_free()
	var vague: Resource = Run.vagues[Run.vague_actuelle]
	_apercu_ligne.add_child(_icone(preload("res://assets/ui/icones/vague.png"), 30))
	var groupes: Array = [[vague.unite, vague.nombre], [vague.renfort, vague.nombre_renforts],
			[vague.get("volants"), vague.get("nombre_volants")], [vague.boss, 1 if vague.boss != null else 0]]
	var infobulle: PackedStringArray = [tr("Prochaine vague")]
	for groupe: Array in groupes:
		if groupe[0] == null or int(groupe[1]) <= 0:
			continue
		var image := _icone(Interface.vignette_de(groupe[0]), 38)
		_apercu_ligne.add_child(image)
		var nombre := Label.new()
		nombre.theme_type_variation = &"Nombre"
		nombre.add_theme_font_size_override(&"font_size", 18)
		nombre.text = "×%d" % int(groupe[1])
		_apercu_ligne.add_child(nombre)
		infobulle.append("%s ×%d" % [tr(groupe[0].nom), int(groupe[1])])
	_apercu_vague.tooltip_text = "\n".join(infobulle)


func _icone(texture: Texture2D, cote: float) -> TextureRect:
	var icone := TextureRect.new()
	icone.texture = texture
	icone.custom_minimum_size = Vector2(cote, cote)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icone


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
	if _apercu_vague != null:
		_actualiser_apercu_vague()


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
	if _chance != null:
		_plaque_chance.visible = Run.chance > 0
		_chance.text = str(Run.chance)
		_plaque_chance.tooltip_text = tr("Chance : les coffres montrent plus de raretés")
		_porte_bonheur.disabled = total < Run.regles.prix_porte_bonheur or Run.chance >= Run.regles.chance_max \
				or Run.get("_porte_bonheur_achete")
		_porte_bonheur.tooltip_text = tr("Porte-bonheur : +%d chance (une fois par pause)") % Run.regles.chance_porte_bonheur
	for i: int in _ventes.size():
		var lot: Lot = Run.regles.boutique[i]
		# Campagne (P2-50) : une pièce pas encore débloquée n'apparaît pas en boutique.
		_ventes[i].visible = Run.autorise(lot.objet)
		var verrouille: bool = lot.vague_min > Run.vague_actuelle + 1
		_ventes[i].disabled = verrouille or total < lot.prix
		# Tuile trop chère ou verrouillée : grisée (audit UI : coûts inabordables lisibles d'un coup d'œil).
		_ventes[i].modulate = Color(1, 1, 1, 0.55) if _ventes[i].disabled else Color.WHITE
		var entete: String = tr("%s ×%d — %d ressorts") % [tr(lot.objet.get("nom")), lot.quantite, lot.prix]
		_ventes[i].tooltip_text = entete + "\n" + (tr("Disponible à la vague %d") % lot.vague_min
				if verrouille else PieceDef.decrire(lot.objet))


# Début de chapitre (P2-50) : fiche « Nouveau ! » avec la vignette et le nom de chaque pièce débloquée.
# Elle se ferme au clic ou seule après 7 s.
func _annoncer_nouveautes() -> void:
	var fiche := PanelContainer.new()
	fiche.theme = THEME_UI
	fiche.theme_type_variation = &"Fiche"
	fiche.mouse_filter = Control.MOUSE_FILTER_STOP
	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	fiche.add_child(colonne)
	var titre := Label.new()
	titre.theme_type_variation = &"CarteNom"
	titre.text = tr("Nouveau dans ce chapitre !")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colonne.add_child(titre)
	var rangee := HBoxContainer.new()
	rangee.alignment = BoxContainer.ALIGNMENT_CENTER
	rangee.add_theme_constant_override(&"separation", 18)
	colonne.add_child(rangee)
	for piece: Resource in Run.nouveautes:
		var case := VBoxContainer.new()
		rangee.add_child(case)
		var image := TextureRect.new()
		image.texture = Interface.vignette_de(piece)
		image.custom_minimum_size = Vector2(96, 96)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		case.add_child(image)
		var nom := Label.new()
		nom.theme_type_variation = &"CarteTexte"
		nom.text = tr(piece.get("nom"))
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		case.add_child(nom)
		case.tooltip_text = PieceDef.decrire(piece)
	add_child(fiche)
	fiche.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 70)
	fiche.grow_horizontal = Control.GROW_DIRECTION_BOTH
	Interface.apparaitre(fiche)
	var fermer := func() -> void:
		if is_instance_valid(fiche):
			fiche.queue_free()
	fiche.gui_input.connect(func(evenement: InputEvent) -> void:
		if evenement is InputEventMouseButton and evenement.pressed:
			fermer.call())
	get_tree().create_timer(7.0).timeout.connect(fermer)


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
		var entete: String = tr("%s ×%d") % [carte.nom.text, lot.quantite]
		var piece: PieceDef = lot.objet as PieceDef
		if piece != null and (Run.offre_coffre or piece.rarete != PieceDef.Rarete.COMMUNE):
			entete = tr("%s · %s") % [entete, tr(NOMS_RARETE[piece.rarete])]
		# Playtest 2 : la carte ne montre que l'image et le nom ; tout le détail passe dans l'infobulle.
		carte.tooltip_text = entete + "\n" + PieceDef.decrire(lot.objet)
		carte.accessibility_name = entete
		carte.accessibility_description = tr(lot.objet.get("description"))


# Playtest 2 (zéro défilement) : la taille des cartes et le nombre de colonnes se calculent pour que toute l'offre
# tienne dans la fenêtre, même avec beaucoup de choix (paliers d'extension, cartes bonus).
func _dimensionner_tirage() -> void:
	if not $Draft.visible or %Lots.get_child_count() == 0:
		return
	var ecran: Vector2 = get_viewport().get_visible_rect().size
	var n: int = %Lots.get_child_count()
	var ecart: float = 16.0
	var cadre: float = 18.0 + 56.0 + 24.0
	var largeur_dispo: float = ecran.x * 0.88 - cadre
	var hauteur_dispo: float = ecran.y * 0.58
	var meilleure := Vector2.ZERO
	var colonnes_retenues: int = n
	for colonnes: int in range(1, n + 1):
		var lignes: int = ceili(n / float(colonnes))
		var largeur: float = minf(Carte.LARGEUR_MAX, (largeur_dispo - ecart * (colonnes - 1)) / colonnes)
		var hauteur: float = largeur * Carte.PROPORTION
		var hauteur_totale: float = lignes * hauteur + 18.0 * (lignes - 1)
		if hauteur_totale > hauteur_dispo:
			hauteur = (hauteur_dispo - 18.0 * (lignes - 1)) / lignes
			largeur = hauteur / Carte.PROPORTION
		# À taille égale, plus de colonnes = moins de rangées (3 cartes sur une seule ligne).
		if largeur >= meilleure.x - 0.5:
			meilleure = Vector2(largeur, largeur * Carte.PROPORTION)
			colonnes_retenues = colonnes
	var lignes: int = ceili(n / float(colonnes_retenues))
	for carte: Carte in %Lots.get_children():
		carte.regler_taille(meilleure)
	var largeur_cartes: float = colonnes_retenues * meilleure.x + ecart * (colonnes_retenues - 1) + cadre
	var retrait: float = maxf(0.0, (ecran.x * 0.88 - largeur_cartes) / 2.0)
	$Draft.offset_left = retrait
	$Draft.offset_right = -retrait
	%DefilementLots.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	%DefilementLots.custom_minimum_size.y = lignes * meilleure.y + 18.0 * (lignes - 1) + 28.0 + 12.0


func _ajuster_hauteur() -> void:
	pass


## Carte de tirage : une fiche de papier avec la grande vignette de la pièce, son nom et un insigne (quantité ou
## rareté). Le cadre se teinte selon la rareté. Le détail est dans l'infobulle (playtest 2 : minimum de texte).
class Carte extends Button:
	const LARGEUR_MAX := 210.0
	## Hauteur / largeur de la carte.
	const PROPORTION := 1.18
	var nom: Label = Label.new()
	var _papier: PanelContainer = PanelContainer.new()
	var _vignette: TextureRect = TextureRect.new()
	var _mouvement: Tween

	func _init(lot: Lot, indice: int, coffre: bool) -> void:
		theme_type_variation = &"Carte"
		_papier.theme_type_variation = &"Fiche"
		_papier.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		add_child(_papier)
		var colonne := VBoxContainer.new()
		colonne.add_theme_constant_override(&"separation", 2)
		_papier.add_child(colonne)
		var insigne := HBoxContainer.new()
		colonne.add_child(insigne)
		var piece: PieceDef = lot.objet as PieceDef
		var rarete: int = piece.rarete if piece != null else PieceDef.Rarete.COMMUNE
		if rarete != PieceDef.Rarete.COMMUNE or coffre:
			var medaillon := TextureRect.new()
			medaillon.texture = MEDAILLONS[rarete]
			medaillon.custom_minimum_size = Vector2(28, 28)
			medaillon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			medaillon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			insigne.add_child(medaillon)
		if lot.quantite > 1 or not coffre:
			var badge := Label.new()
			badge.theme_type_variation = &"Badge"
			badge.text = "×%d" % lot.quantite
			insigne.add_child(badge)
		# Tic-tac (playtest 3) : le coût en dents d'énergie se lit sur la carte, à droite (icône du réseau + nombre).
		if piece != null and piece.consomme():
			var ressort := Control.new()
			ressort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			insigne.add_child(ressort)
			var dent := TextureRect.new()
			dent.texture = ICONE_DENTS
			dent.custom_minimum_size = Vector2(26, 26)
			dent.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			dent.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			insigne.add_child(dent)
			var cout := Label.new()
			cout.theme_type_variation = &"Badge"
			cout.text = str(piece.cout_energie)
			insigne.add_child(cout)
		# Grande vignette : elle remplit l'espace libre en gardant ses proportions (jamais rognée).
		_vignette.texture = Interface.vignette_de(lot.objet)
		_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_vignette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_vignette.size_flags_vertical = Control.SIZE_EXPAND_FILL
		colonne.add_child(_vignette)
		nom.theme_type_variation = &"CarteNom"
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nom.custom_minimum_size.x = LARGEUR_MAX - 40.0
		colonne.add_child(nom)
		_papier.clip_contents = true
		# Cadre teinté par rareté : la rareté se lit à la couleur, sans lire un mot.
		if rarete == PieceDef.Rarete.RARE:
			_papier.self_modulate = Color("#D3E4F7")
		elif rarete == PieceDef.Rarete.EPIQUE:
			_papier.self_modulate = Color("#F7E2A6")
		elif rarete == PieceDef.Rarete.LEGENDAIRE:
			_papier.self_modulate = Color("#F8C9B8")
		_papier.rotation_degrees = -1.5 if indice % 2 == 0 else 1.5
		resized.connect(_ajuster_papier)

	## Fixe la taille de la carte (calculée par le HUD pour que toute l'offre tienne à l'écran).
	func regler_taille(taille: Vector2) -> void:
		custom_minimum_size = taille
		nom.add_theme_font_size_override(&"font_size", clampi(roundi(taille.x / 9.5), 16, 23))
		# Largeur fixée : un texte à retour à la ligne sans largeur réclame une hauteur immense (une lettre par ligne).
		nom.custom_minimum_size.x = taille.x - 40.0
		nom.max_lines_visible = 2
		_ajuster_papier()

	func _ready() -> void:
		_papier.scale = Vector2.ONE * 1.06
		var rebond: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rebond.tween_property(_papier, "scale", Vector2.ONE, 0.28)
		mouse_entered.connect(_soulever)
		mouse_exited.connect(_soulever)
		focus_entered.connect(_soulever)
		focus_exited.connect(_soulever)
		button_down.connect(_soulever)
		button_up.connect(_soulever)

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
	if _victoire and Run.chapitre >= 0:
		%Bilan.text = "Chapitre terminé !"
	var tenues: int = Run.vague_actuelle if _victoire else maxi(0, Run.vague_actuelle - 1)
	%Stats.text = tr("Vagues tenues : %d / %d\nScarabées endormis : %d\nRessorts gagnés : %d") % [
		tenues, Run.nb_vagues, Run.ennemis_casses, Run.ressorts_gagnes]
	%PrimeOr.text = tr("+%d engrenages d’or") % Run.engrenages_gagnes
