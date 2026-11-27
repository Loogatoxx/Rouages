extends CanvasLayer
## Rassemble les préférences accessibles depuis le titre et la pause.

signal ferme

const Langue = preload("res://game/ui/langue.gd")
const REGLAGES := "user://reglages.cfg"
const NOMS_PRESETS: Dictionary = {&"economie": "Économie", &"equilibre": "Équilibré", &"qualite": "Qualité"}

## Onglets (playtest 2) : le panneau unique devenait trop haut avec les réglages graphiques.
var _general: Array[Control] = []
var _page_graphismes: VBoxContainer
var _onglets: Array[Button] = []
var _choix: Dictionary[StringName, Button] = {}
var _page_touches: VBoxContainer
var _boutons_touches: Dictionary[StringName, Button] = {}
## Action en attente d'une nouvelle touche (vide si aucune).
var _ecoute: StringName = &""


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
	_creer_onglets()


# Onglets « Général » et « Graphismes » sous le titre ; la page générale reprend les contrôles de la scène.
func _creer_onglets() -> void:
	var colonne: VBoxContainer = $Voile/Centre/Panneau/Colonne
	_general = [$Voile/Centre/Panneau/Colonne/LibelleMusique, %Musique, $Voile/Centre/Panneau/Colonne/LibelleEffets,
			%Effets, %PleinEcran, %ChoixLangue]
	var barre := HBoxContainer.new()
	barre.alignment = BoxContainer.ALIGNMENT_CENTER
	barre.add_theme_constant_override(&"separation", 10)
	var groupe := ButtonGroup.new()
	for i: int in 3:
		var onglet := Button.new()
		onglet.text = ["Général", "Graphismes", "Touches"][i]
		onglet.toggle_mode = true
		onglet.button_group = groupe
		onglet.custom_minimum_size = Vector2(180, 0)
		onglet.pressed.connect(_montrer_page.bind(i))
		barre.add_child(onglet)
		_onglets.append(onglet)
	colonne.add_child(barre)
	colonne.move_child(barre, 1)
	_page_graphismes = VBoxContainer.new()
	_page_graphismes.add_theme_constant_override(&"separation", 8)
	colonne.add_child(_page_graphismes)
	colonne.move_child(_page_graphismes, 2)
	_ajouter_choix(_page_graphismes, &"preset", "Choisis « Économie » si l’ordinateur chauffe ou ventile fort.")
	var grille := GridContainer.new()
	grille.columns = 2
	grille.add_theme_constant_override(&"h_separation", 8)
	grille.add_theme_constant_override(&"v_separation", 8)
	_page_graphismes.add_child(grille)
	_ajouter_choix(grille, &"fps", "Nombre maximal d’images calculées par seconde : moins = moins de chauffe.")
	_ajouter_choix(grille, &"vsync", "Cale les images sur l’écran : évite les déchirures et les images inutiles.")
	_ajouter_choix(grille, &"ombres", "Ombres du soleil sur le plateau : l’effet le plus coûteux.")
	_ajouter_choix(grille, &"ssao", "Ombres douces dans les recoins (occlusion ambiante).")
	_ajouter_choix(grille, &"lueur", "Léger halo autour des parties brillantes.")
	_ajouter_choix(grille, &"particules", "Poussière dorée et pétales qui flottent au-dessus du plateau.")
	_ajouter_choix(grille, &"msaa", "Lisse les bords des objets 3D (anticrénelage).")
	_ajouter_choix(grille, &"echelle", "Résolution de la scène 3D : plus basse = beaucoup moins de calcul.")
	Graphismes.change.connect(_ecrire_graphismes)
	_creer_page_touches(colonne)
	_montrer_page(0)


# Page « Touches » (P2-13) : chaque action, sa touche ; un clic puis une touche (ou un bouton de souris) la remplace.
func _creer_page_touches(colonne: VBoxContainer) -> void:
	_page_touches = VBoxContainer.new()
	_page_touches.add_theme_constant_override(&"separation", 8)
	colonne.add_child(_page_touches)
	colonne.move_child(_page_touches, 3)
	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override(&"h_separation", 10)
	grille.add_theme_constant_override(&"v_separation", 6)
	_page_touches.add_child(grille)
	for ligne: Array in Touches.ACTIONS:
		var libelle := Label.new()
		libelle.text = ligne[1]
		libelle.custom_minimum_size.x = 210
		libelle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		libelle.add_theme_font_size_override(&"font_size", 16)
		grille.add_child(libelle)
		var bouton := Button.new()
		bouton.custom_minimum_size = Vector2(130, 0)
		bouton.add_theme_font_size_override(&"font_size", 16)
		bouton.pressed.connect(_ecouter.bind(ligne[0]))
		grille.add_child(bouton)
		_boutons_touches[ligne[0]] = bouton
	var remettre := Button.new()
	remettre.text = "Touches d’origine"
	remettre.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	remettre.pressed.connect(func() -> void:
		Touches.reinitialiser()
		_ecrire_touches())
	_page_touches.add_child(remettre)


func _ecouter(action: StringName) -> void:
	_ecoute = action
	_ecrire_touches()


func _ecrire_touches() -> void:
	for action: StringName in _boutons_touches:
		_boutons_touches[action].text = tr("Appuie…") if action == _ecoute else Touches.nom_touche(action)


func _ajouter_choix(parent: Container, cle: StringName, aide: String) -> void:
	var bouton := Button.new()
	bouton.tooltip_text = aide
	bouton.custom_minimum_size = Vector2(330 if parent is GridContainer else 0, 0)
	bouton.pressed.connect(_changer.bind(cle))
	parent.add_child(bouton)
	_choix[cle] = bouton


func _montrer_page(indice: int) -> void:
	for controle: Control in _general:
		controle.visible = indice == 0
	_page_graphismes.visible = indice == 1
	if _page_touches != null:
		_page_touches.visible = indice == 2
		_ecoute = &""
		_ecrire_touches()
	_onglets[indice].set_pressed_no_signal(true)
	_ecrire_graphismes()


# Chaque clic fait passer le réglage à sa valeur suivante (même geste que le choix de la langue).
func _changer(cle: StringName) -> void:
	match cle:
		&"preset":
			var noms: Array = Graphismes.PRESETS.keys()
			Graphismes.prereglage(noms[(noms.find(Graphismes.prereglage_actuel()) + 1) % noms.size()])
			return
		&"fps":
			var choix: Array[int] = Graphismes.CHOIX_FPS
			Graphismes.fps = choix[(choix.find(Graphismes.fps) + 1) % choix.size()]
		&"vsync":
			Graphismes.vsync = not Graphismes.vsync
		&"ombres":
			Graphismes.ombres = (Graphismes.ombres + 1) % 3
		&"ssao":
			Graphismes.ssao = not Graphismes.ssao
		&"lueur":
			Graphismes.lueur = not Graphismes.lueur
		&"particules":
			Graphismes.particules = not Graphismes.particules
		&"msaa":
			Graphismes.msaa = (Graphismes.msaa + 1) % Graphismes.MSAA.size()
		&"echelle":
			var echelles: Array[float] = Graphismes.CHOIX_ECHELLE
			Graphismes.echelle = echelles[(echelles.find(Graphismes.echelle) + 1) % echelles.size()]
	Graphismes.enregistrer()
	Graphismes.appliquer()


func _ecrire_graphismes() -> void:
	if _choix.is_empty():
		return
	var actuel: StringName = Graphismes.prereglage_actuel()
	_choix[&"preset"].text = tr("Préréglage : %s") % tr(NOMS_PRESETS.get(actuel, "Personnalisé"))
	_choix[&"fps"].text = tr("Images/s : %s") % (str(Graphismes.fps) if Graphismes.fps > 0 else tr("illimité"))
	_choix[&"vsync"].text = tr("Synchro verticale : %s") % _etat(Graphismes.vsync)
	_choix[&"ombres"].text = tr("Ombres : %s") % tr(["aucune", "basses", "hautes"][Graphismes.ombres])
	_choix[&"ssao"].text = tr("Occlusion : %s") % _etat(Graphismes.ssao)
	_choix[&"lueur"].text = tr("Lueur : %s") % _etat(Graphismes.lueur)
	_choix[&"particules"].text = tr("Particules : %s") % _etat(Graphismes.particules)
	_choix[&"msaa"].text = tr("Anticrénelage : %s") % tr(["aucun", "2×", "4×"][Graphismes.msaa])
	_choix[&"echelle"].text = tr("Résolution 3D : %d %%") % roundi(Graphismes.echelle * 100.0)


func _etat(actif: bool) -> String:
	return tr("oui") if actif else tr("non")


## Affiche les préférences actuelles et place le focus sur le premier curseur.
func ouvrir() -> void:
	%Musique.set_value_no_signal(Sons.volume(&"Musique"))
	%Effets.set_value_no_signal(Sons.volume(&"Effets"))
	%PleinEcran.set_pressed_no_signal(_lire_plein_ecran())
	_ecrire_plein_ecran()
	_montrer_page(0)
	show()
	%Musique.grab_focus()


func _input(evenement: InputEvent) -> void:
	if visible and _ecoute != &"":
		# En attente d'une touche : Échap annule, toute autre touche ou bouton de souris devient la nouvelle touche.
		var touche := evenement as InputEventKey
		var clic := evenement as InputEventMouseButton
		if (touche != null and touche.pressed and not touche.echo) or (clic != null and clic.pressed):
			get_viewport().set_input_as_handled()
			if touche != null and touche.keycode == KEY_ESCAPE:
				_ecoute = &""
			else:
				Touches.assigner(_ecoute, evenement)
				_ecoute = &""
			_ecrire_touches()
		return
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
		_ecrire_graphismes()
