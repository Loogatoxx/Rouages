extends CanvasLayer
## Écran « Partie libre » (playtest 3) : une liste claire des cartes avec, à côté, l'aperçu de la carte choisie
## (mini-plan, description, entrées, énergie, ennemis propres, record), puis la difficulté et le mode.
##
## Pourquoi : le menu faisait défiler six cartes en cliquant sur un seul bouton « Plateau : … ». Avec autant de
## choix, on ne voyait ni ce qu'on quittait ni ce qu'on choisissait. Règle retenue : jusqu'à trois valeurs, des
## boutons côte à côte ; au-delà, une liste et un aperçu.

signal ferme
signal lancee(plateau: int, difficulte: int, mode: int)

const Progression = preload("res://game/core/progression.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const Interface = preload("res://game/ui/menu_titre.gd")
const DIFFICULTES: Array[String] = ["Facile", "Normal", "Difficile"]
const MODES: Array[String] = ["Classique", "Longue route", "Bac à sable"]
const DETAILS_MODES: Array[String] = [
	"10 vagues : la partie de référence.",
	"15 vagues ; des tiroirs s’ouvrent en route et ajoutent des entrées.",
	"Tout est débloqué, ressources illimitées, l’Horloge ne peut pas s’arrêter : pour essayer librement.",
]


## Mini-plan d'une carte, dessiné d'après ses données : herbe, route, Horloge, entrées des ennemis.
class Plan extends Control:
	var depart: Resource:
		set(valeur):
			depart = valeur
			queue_redraw()

	func _draw() -> void:
		if depart == null:
			return
		var plateau = depart.creer_plateau()
		var terrain: Rect2i = depart.terrain
		var cote: float = floorf(minf(size.x / terrain.size.x, size.y / terrain.size.y))
		var origine: Vector2 = (size - Vector2(terrain.size) * cote) / 2.0
		# Bordure de bois autour de la maquette.
		draw_rect(Rect2(origine - Vector2(5, 5), Vector2(terrain.size) * cote + Vector2(10, 10)), Color("#B9773E"))
		for x: int in terrain.size.x:
			for y: int in terrain.size.y:
				var case: Vector2i = terrain.position + Vector2i(x, y)
				var rect := Rect2(origine + Vector2(x, y) * cote, Vector2(cote, cote))
				if plateau.sol_de(case) == plateau.Sol.CHEMIN:
					draw_rect(rect, Color("#EFE3C8"))
				else:
					draw_rect(rect.grow(-0.5), Color("#A9C98B") if (x + y) % 2 == 0 else Color("#A0C283"))
		var distances: Dictionary = ChampFlux.calculer(plateau)
		for entree: Vector2i in ChampFlux.entrees(plateau, distances):
			var centre: Vector2 = origine + (Vector2(entree - terrain.position) + Vector2(0.5, 0.5)) * cote
			draw_circle(centre, cote * 0.36, Color("#C8553D"))
			draw_circle(centre, cote * 0.16, Color("#FFF3D6"))
		var horloge: Vector2 = origine + (Vector2(depart.horloge - terrain.position) + Vector2(0.5, 0.5)) * cote
		draw_circle(horloge, cote * 0.46, Color("#7A4A21"))
		draw_circle(horloge, cote * 0.36, Color("#E8B04A"))
		draw_line(horloge, horloge + Vector2(0, -cote * 0.26), Color("#4A3426"), maxf(1.5, cote * 0.08))
		draw_line(horloge, horloge + Vector2(cote * 0.18, 0), Color("#4A3426"), maxf(1.5, cote * 0.08))


var _plateau: int = 0
var _difficulte: int = 1
var _mode: int = 0
var _boutons_cartes: Array[Button] = []
var _boutons_difficulte: Array[Button] = []
var _boutons_mode: Array[Button] = []
var _plan := Plan.new()
var _nom := Label.new()
var _description := Label.new()
var _faits := Label.new()
var _detail_mode := Label.new()
var _titre := Label.new()
var _liste_titre := Label.new()
var _lancer := Button.new()
var _retour := Button.new()
var _etiquette_difficulte := Label.new()
var _etiquette_mode := Label.new()
var _panneau := PanelContainer.new()


func _ready() -> void:
	layer = 5
	hide()
	var voile := ColorRect.new()
	voile.color = Color(0.16, 0.1, 0.05, 0.55)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	voile.theme = preload("res://game/ui/theme_rouages.tres")
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	voile.add_child(centre)
	centre.add_child(_panneau)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override(&"separation", 12)
	_panneau.add_child(colonne)
	_titre.theme_type_variation = &"TitreMenu"
	_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colonne.add_child(_titre)
	var corps := HBoxContainer.new()
	corps.add_theme_constant_override(&"separation", 18)
	colonne.add_child(corps)
	# Liste des cartes.
	var liste := VBoxContainer.new()
	liste.add_theme_constant_override(&"separation", 6)
	liste.custom_minimum_size.x = 290
	corps.add_child(liste)
	_liste_titre.theme_type_variation = &"CarteNom"
	liste.add_child(_liste_titre)
	var groupe := ButtonGroup.new()
	for i: int in Run.regles.departs.size():
		var bouton := Button.new()
		bouton.toggle_mode = true
		bouton.button_group = groupe
		bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bouton.custom_minimum_size.y = 46
		bouton.pressed.connect(_choisir_carte.bind(i))
		bouton.focus_entered.connect(_choisir_carte.bind(i))
		liste.add_child(bouton)
		_boutons_cartes.append(bouton)
	# Aperçu de la carte choisie.
	var fiche := PanelContainer.new()
	fiche.theme_type_variation = &"Fiche"
	fiche.custom_minimum_size = Vector2(600, 0)
	corps.add_child(fiche)
	var contenu := HBoxContainer.new()
	contenu.add_theme_constant_override(&"separation", 16)
	fiche.add_child(contenu)
	_plan.custom_minimum_size = Vector2(270, 270)
	contenu.add_child(_plan)
	var textes := VBoxContainer.new()
	textes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textes.add_theme_constant_override(&"separation", 8)
	contenu.add_child(textes)
	_nom.theme_type_variation = &"CarteNom"
	_nom.add_theme_font_size_override(&"font_size", 28)
	textes.add_child(_nom)
	for texte: Label in [_description, _faits]:
		texte.theme_type_variation = &"CarteTexte"
		texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texte.custom_minimum_size.x = 290
		textes.add_child(texte)
	# Difficulté et mode : trois valeurs chacun, donc des boutons côte à côte.
	_boutons_difficulte = _rangee(colonne, _etiquette_difficulte, DIFFICULTES.size(), func(i: int) -> void:
		_difficulte = i
		_actualiser())
	_boutons_mode = _rangee(colonne, _etiquette_mode, MODES.size(), func(i: int) -> void:
		_mode = i
		_actualiser())
	_detail_mode.theme_type_variation = &"CarteTexte"
	_detail_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_mode.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(_detail_mode)
	var pied := HBoxContainer.new()
	pied.alignment = BoxContainer.ALIGNMENT_CENTER
	pied.add_theme_constant_override(&"separation", 16)
	colonne.add_child(pied)
	_retour.custom_minimum_size = Vector2(200, 50)
	_retour.pressed.connect(_fermer)
	pied.add_child(_retour)
	_lancer.custom_minimum_size = Vector2(320, 50)
	_lancer.pressed.connect(func() -> void: lancee.emit(_plateau, _difficulte, _mode))
	pied.add_child(_lancer)
	Interface.preparer_boutons(self)


# Une ligne « étiquette + boutons à bascule » ; renvoie les boutons créés.
func _rangee(parent: Node, etiquette: Label, nombre: int, choisir: Callable) -> Array[Button]:
	var ligne := HBoxContainer.new()
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override(&"separation", 10)
	parent.add_child(ligne)
	etiquette.theme_type_variation = &"CarteNom"
	etiquette.custom_minimum_size.x = 130
	ligne.add_child(etiquette)
	var groupe := ButtonGroup.new()
	var boutons: Array[Button] = []
	for i: int in nombre:
		var bouton := Button.new()
		bouton.toggle_mode = true
		bouton.button_group = groupe
		bouton.custom_minimum_size = Vector2(230, 44)
		bouton.pressed.connect(choisir.bind(i))
		ligne.add_child(bouton)
		boutons.append(bouton)
	return boutons


## Ouvre l'écran sur la dernière sélection du joueur.
func ouvrir(plateau: int, difficulte: int, mode: int) -> void:
	_plateau = clampi(plateau, 0, Run.regles.departs.size() - 1)
	_difficulte = clampi(difficulte, 0, DIFFICULTES.size() - 1)
	_mode = clampi(mode, 0, MODES.size() - 1)
	show()
	_actualiser()
	Interface.apparaitre(_panneau)
	_boutons_cartes[_plateau].grab_focus()


func _fermer() -> void:
	hide()
	ferme.emit()


func _choisir_carte(i: int) -> void:
	if _plateau != i:
		_plateau = i
		_actualiser()


func _unhandled_input(evenement: InputEvent) -> void:
	if visible and evenement.is_action_pressed(&"annuler"):
		get_viewport().set_input_as_handled()
		_fermer()


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible:
		_actualiser()


func _actualiser() -> void:
	_titre.text = tr("Partie libre")
	_liste_titre.text = tr("Choisis une carte")
	_etiquette_difficulte.text = tr("Difficulté")
	_etiquette_mode.text = tr("Mode")
	_retour.text = tr("Retour")
	_lancer.text = tr("Lancer la partie")
	var vagues: int = Run.regles.vagues_longue_route if _mode == 1 else Run.regles.vagues.size()
	for i: int in _boutons_cartes.size():
		var carte: Resource = Run.regles.departs[i]
		var record: int = Progression.record(carte.nom, _difficulte)
		_boutons_cartes[i].text = "  %s" % tr(carte.nom) + ("   ★ %d" % record if record > 0 else "")
		_boutons_cartes[i].set_pressed_no_signal(i == _plateau)
	for i: int in _boutons_difficulte.size():
		_boutons_difficulte[i].text = tr(DIFFICULTES[i])
		_boutons_difficulte[i].set_pressed_no_signal(i == _difficulte)
	for i: int in _boutons_mode.size():
		_boutons_mode[i].text = tr(MODES[i])
		_boutons_mode[i].set_pressed_no_signal(i == _mode)
	_detail_mode.text = tr(DETAILS_MODES[_mode])
	var depart: Resource = Run.regles.departs[_plateau]
	_plan.depart = depart
	_nom.text = tr(depart.nom)
	_description.text = tr(depart.description)
	var plateau = depart.creer_plateau()
	var entrees: int = ChampFlux.entrees(plateau, ChampFlux.calculer(plateau)).size()
	var lignes := PackedStringArray()
	lignes.append(tr("Entrées des ennemis : %d") % entrees)
	if _mode == 2:
		lignes.append(tr("Énergie de l’Horloge : illimitée (bac à sable)"))
	else:
		lignes.append(tr("Énergie de l’Horloge au départ : %d dents") % (Run.regles.dents_depart + depart.dents_bonus))
	var speciaux := PackedStringArray()
	for ennemi: Resource in depart.ennemis_speciaux:
		speciaux.append(tr(ennemi.nom))
	if not speciaux.is_empty():
		lignes.append(tr("Ennemis propres à cette carte : %s") % ", ".join(speciaux))
	var record_carte: int = Progression.record(depart.nom, _difficulte)
	# Le record est partagé entre Classique et Longue route : on l'écrit sans dénominateur (relecture T14c).
	lignes.append(tr("Record : %d vagues tenues") % record_carte if record_carte > 0 else tr("Pas encore de record ici."))
	_faits.text = "\n".join(lignes)
