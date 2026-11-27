extends PanelContainer
## Présente les actions et leurs prix à côté de la pièce choisie sur le plateau.

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const GrilleMonde = preload("res://game/board/grille_monde.gd")

const Placement = preload("res://game/workshops/placement.gd")
const DOSSIER_ICONES := "res://assets/ui/icones/%s.png"

var _plateau: Plateau
var _case: Vector2i
var _titre: Label = Label.new()
var _niveau: Label = Label.new()
var _colonne: VBoxContainer = VBoxContainer.new()
var _stats: HBoxContainer = HBoxContainer.new()
var _ameliorer: Button
var _tourner: Button
var _reprendre: Button
var _prix: Dictionary[Button, Label] = {}


# Playtest 2 : « aller à l'essentiel ». Une ligne de statistiques en icône + valeur, des actions en icônes avec leur
# prix ; les explications (effets de placement, avertissements) passent dans les infobulles.
func _ready() -> void:
	hide()
	theme = preload("res://game/ui/theme_rouages.tres")
	theme_type_variation = &"Fiche"
	add_child(_colonne)
	_colonne.add_theme_constant_override(&"separation", 6)
	var entete := HBoxContainer.new()
	_colonne.add_child(entete)
	# Encre foncée sur le papier (le style crème à contour est réservé aux textes posés sur le bois).
	_titre.theme_type_variation = &"CarteNom"
	_titre.add_theme_font_size_override(&"font_size", 19)
	_titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(_titre)
	_niveau.theme_type_variation = &"Badge"
	_niveau.add_theme_font_size_override(&"font_size", 15)
	_niveau.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	entete.add_child(_niveau)
	_stats.add_theme_constant_override(&"separation", 12)
	_colonne.add_child(_stats)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 8)
	_colonne.add_child(actions)
	_ameliorer = _ajouter_action(actions, preload("res://assets/ui/icones/ameliorer.png"), _acheter_niveau)
	_tourner = _ajouter_action(actions, preload("res://assets/ui/icones/tourner.png"), _tourner_piece)
	_reprendre = _ajouter_action(actions, preload("res://assets/ui/icones/deplacer.png"), _reprendre_piece)
	Events.ressorts_changes.connect(_solde_change)
	Events.plateau_modifie.connect(_actualiser)


func _ajouter_action(parent: HBoxContainer, icone: Texture2D, action: Callable) -> Button:
	var bouton: Button = Button.new()
	bouton.icon = icone
	bouton.expand_icon = true
	bouton.custom_minimum_size = Vector2(76, 44)
	bouton.add_theme_constant_override(&"icon_max_width", 26)
	bouton.pressed.connect(action)
	parent.add_child(bouton)
	# Prix dans le bouton, à droite de l'icône : on lit l'action et son coût d'un coup d'œil.
	var prix: Label = Label.new()
	prix.theme_type_variation = &"Nombre"
	prix.add_theme_font_size_override(&"font_size", 16)
	prix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bouton.add_child(prix)
	prix.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE, 10)
	prix.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_prix[bouton] = prix
	return bouton


# Une statistique : icône (ou repli lisible si l'icône manque encore) + valeur, détail au survol.
func _ajouter_stat(icone: String, repli: String, valeur: String, detail: String) -> void:
	var puce := HBoxContainer.new()
	puce.add_theme_constant_override(&"separation", 3)
	puce.tooltip_text = detail
	puce.mouse_filter = Control.MOUSE_FILTER_STOP
	var chemin: String = DOSSIER_ICONES % icone
	if ResourceLoader.exists(chemin):
		var image := TextureRect.new()
		image.texture = load(chemin)
		image.custom_minimum_size = Vector2(24, 24)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		puce.add_child(image)
	else:
		valeur = repli + " " + valeur
	var texte := Label.new()
	texte.theme_type_variation = &"Nombre"
	texte.add_theme_font_size_override(&"font_size", 17)
	texte.text = valeur
	texte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	puce.add_child(texte)
	_stats.add_child(puce)


## Ouvre la fiche pour la case choisie et suit sa position à l'écran.
func ouvrir(plateau: Plateau, case: Vector2i) -> void:
	_plateau = plateau
	_case = case
	if not visible:
		add_to_group(&"panneau_piece_ouvert")
	show()
	_actualiser()
	_positionner()


## Ferme la fiche et libère la sélection de la case.
func fermer() -> void:
	if visible:
		remove_from_group(&"panneau_piece_ouvert")
		hide()
	_plateau = null


func _solde_change(_solde: int) -> void:
	_actualiser()


func _actualiser() -> void:
	if not visible:
		return
	var piece: PieceDef = _plateau.piece_de(_case)
	if piece == null:
		fermer()
		return
	var niveau: int = _plateau.niveau_de(_case)
	var mobile: bool = piece.type != PieceDef.Type.HORLOGE
	_titre.text = tr(piece.nom)
	_niveau.text = tr("Niv. %d/%d") % [niveau, piece.niveau_max]
	_niveau.visible = piece.niveau_max > 1
	_remplir_stats(piece)
	_afficher_prix(_ameliorer, Run.prix_amelioration(_plateau, _case), mobile and niveau < piece.niveau_max)
	_afficher_prix(_tourner, Run.prix_rotation, mobile)
	_afficher_prix(_reprendre, Run.prix_deplacement, mobile)
	_ameliorer.tooltip_text = tr("Améliorer") if niveau < piece.niveau_max else tr("Niveau maximal")
	_tourner.tooltip_text = tr("Tourner")
	_reprendre.tooltip_text = tr("Reprendre la pièce") + ("\n" + tr("Reprendre ramène la pièce au niveau 1.") if niveau > 1 else "")
	reset_size()


func _remplir_stats(piece: PieceDef) -> void:
	for ancienne: Node in _stats.get_children():
		_stats.remove_child(ancienne)
		ancienne.queue_free()
	var noeud: Node = get_tree().get_first_node_in_group(&"plateau_noeud")
	var alimentees: Dictionary = noeud.alimentees if noeud != null else {}
	var regles = Run.regles
	var effets: String = "\n".join(Placement.effets(_plateau, alimentees, _case, piece, regles))
	match piece.type:
		PieceDef.Type.ATELIER:
			var plafond: int = regles.plafond_allies_par_atelier + Placement.plafond_atelier(_plateau, alimentees, _case, regles)
			var partie: Node = get_tree().get_first_node_in_group(&"partie")
			var vivants: String = "%d/" % partie.sim.effectif(_case) if partie != null and Run.phase == Run.Phase.VAGUE else ""
			_ajouter_stat("plafond_jouets", "👥", vivants + str(plafond), tr("Jouets en jeu / plafond de cet atelier"))
			var cadence: float = piece.cadence_production * Run.bonus_cadence \
					* Placement.cadence_atelier(_plateau, alimentees, _case, regles)
			_ajouter_stat("cadence", "⏱", tr("%s/s") % String.num(cadence, 1), tr("Jouets remontés par seconde") + "\n" + effets)
			if piece.unite_produite != null:
				var unite = piece.unite_produite
				_ajouter_stat("degats", "✸", String.num(unite.degats, 0), tr("Dégâts par coup d’un jouet"))
				if unite.portee >= 1.0:
					_ajouter_stat("portee", "◎", tr("%s m") % String.num(unite.portee, 1), tr("Portée de tir des jouets"))
		PieceDef.Type.TOURELLE:
			var degats: float = piece.degats_tir * Placement.degats_tourelle(_plateau, _case, regles)
			_ajouter_stat("degats", "✸", String.num(degats, 0), tr("Dégâts par tir") + "\n" + effets)
			var tirs: float = piece.cadence_tir * Placement.cadence_tourelle(_plateau, alimentees, _case, regles)
			_ajouter_stat("cadence", "⏱", tr("%s/s") % String.num(tirs, 2), tr("Tirs par seconde"))
			_ajouter_stat("portee", "◎", tr("%s m") % String.num(piece.portee_tir, 0), tr("Portée de tir"))
		PieceDef.Type.ENGRENAGE:
			# Bonus donné aux voisins, multiplié par le niveau de l'engrenage.
			var facteur: float = 1.0 + (_plateau.niveau_de(_case) - 1) * regles.gain_niveau_engrenage
			var detail: String = tr(piece.description) + ("\n" + effets if effets != "" else "")
			if piece.bonus_voisins_cadence > 0.0:
				_ajouter_stat("cadence", "⏱", "+%d %%" % roundi(piece.bonus_voisins_cadence * facteur * 100.0), detail)
			if piece.bonus_voisins_plafond > 0:
				_ajouter_stat("plafond_jouets", "👥", "+%d" % roundi(piece.bonus_voisins_plafond * facteur), detail)
			if piece.bonus_voisins_tourelle > 0.0:
				_ajouter_stat("cadence", "⏱", "+%d %%" % roundi(piece.bonus_voisins_tourelle * facteur * 100.0), detail)
	if piece.type == PieceDef.Type.GENERATEUR:
		var Energie = preload("res://game/board/energie.gd")
		var capacite: int = Energie.capacite_du_generateur(_plateau, _case)
		_ajouter_stat("engrenage_or", "⚙", "%d/%d" % [Energie.consommateurs_du_generateur(_plateau, _case), capacite],
				tr("Pièces alimentées / capacité du générateur") + "\n" + tr(piece.description))
	if piece.type != PieceDef.Type.HORLOGE:
		_ajouter_stat("revendre", "↺", str(Run.valeur_demontage(piece)), tr("Valeur de revente (en ressorts) une fois reprise"))


func _afficher_prix(bouton: Button, prix: int, possible: bool) -> void:
	_prix[bouton].text = str(prix) if possible else "—"
	bouton.disabled = not possible or Run.ressorts < prix


func _process(_delta: float) -> void:
	if visible:
		_positionner()


func _positionner() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var centre: Vector3 = GrilleMonde.vers_monde(_case)
	if camera == null or camera.is_position_behind(centre):
		fermer()
		return
	var cadre: Rect2 = get_viewport_rect()
	var ancre: Vector2 = camera.unproject_position(centre)
	var x: float = ancre.x + 16.0
	if x + size.x > cadre.end.x:
		x = ancre.x - size.x - 16.0
	position = Vector2(x, ancre.y - size.y * 0.5).clamp(cadre.position, (cadre.end - size).max(cadre.position))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("annuler"):
		fermer()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event.is_action_pressed("poser_tuile") or event.is_action_pressed("tourner_tuile")) \
			and not get_global_rect().has_point(event.position):
		fermer()


func _acheter_niveau() -> void:
	if Run.ameliorer_piece(_plateau, _case):
		Sons.jouer(&"pose")
	fermer()


func _tourner_piece() -> void:
	if Run.tourner_piece(_plateau, _case):
		Sons.jouer(&"rotation")
	fermer()


func _reprendre_piece() -> void:
	var piece: PieceDef = _plateau.piece_de(_case)
	if Run.reprendre_piece(_plateau, _case):
		Sons.jouer(&"pose")
		Events.tuile_choisie.emit(piece.id)
	fermer()
