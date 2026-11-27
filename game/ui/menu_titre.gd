extends Control
## Présente le jeu et partage les interactions visuelles des menus.

const APERCU := "res://assets/final/horloge/apercu.png"
const Langue = preload("res://game/ui/langue.gd")
const Progression = preload("res://game/core/progression.gd")
const MODELE := "res://assets/final/horloge/horloge.glb"

var _vitrine: Node3D
const PARTIE := "res://game/main.tscn"
const TITRE := "res://game/ui/menu_titre.tscn"
const REGLAGES := "user://reglages.cfg"


func _ready() -> void:
	Langue.appliquer(Langue.lire())
	# Vitrine 3D : le vrai modèle de l'horloge tourne sur fond transparent (plus vivant qu'une image à fond gris).
	# Repli sur l'image fixe si le modèle manque.
	if ResourceLoader.exists(MODELE):
		var illustration: TextureRect = %Illustration
		illustration.replace_by(_creer_vitrine())
		illustration.queue_free()
	elif ResourceLoader.exists(APERCU):
		%Illustration.texture = load(APERCU)
	preparer_boutons(self)
	# Le titre et la vitrine se cachent aussi : sinon le ruban « Rouages » restait visible derrière l'écran ouvert (audit UI).
	%BoutonEtabli.pressed.connect(func() -> void:
		$Centre.hide()
		%Etabli.ouvrir())
	%Etabli.ferme.connect(func() -> void:
		_afficher_or()
		$Centre.show()
		%BoutonEtabli.grab_focus())
	_afficher_or()
	%Options.pressed.connect(func() -> void:
		$Centre.hide()
		%Reglages.ouvrir())
	%Reglages.ferme.connect(func() -> void:
		$Centre.show()
		%Options.grab_focus())
	%Jouer.pressed.connect(_jouer)
	%Plateau.pressed.connect(_plateau_suivant)
	%Defi.pressed.connect(_lancer_defi)
	_afficher_plateau()
	%Tutoriel.pressed.connect(_revoir_tutoriel)
	%Quitter.pressed.connect(get_tree().quit)
	%Panneau.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	apparaitre(%Panneau)
	%Jouer.grab_focus()


func _process(delta: float) -> void:
	if _vitrine != null:
		_vitrine.rotate_y(delta * 0.35)


func _creer_vitrine() -> SubViewportContainer:
	var cadre := SubViewportContainer.new()
	cadre.custom_minimum_size = Vector2(420, 520)
	cadre.stretch = true
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vue := SubViewport.new()
	vue.own_world_3d = true
	vue.transparent_bg = true
	vue.msaa_3d = Viewport.MSAA_4X
	cadre.add_child(vue)
	var camera := Camera3D.new()
	camera.fov = 30.0
	camera.position = Vector3(0, 2.6, 9.6)
	camera.rotation_degrees.x = -10.0
	vue.add_child(camera)
	var soleil := DirectionalLight3D.new()
	soleil.light_color = Color(1, 0.9, 0.74)
	soleil.light_energy = 1.3
	soleil.rotation_degrees = Vector3(-40, 35, 0)
	soleil.shadow_enabled = true
	vue.add_child(soleil)
	var monde := WorldEnvironment.new()
	monde.environment = Environment.new()
	monde.environment.background_mode = Environment.BG_CLEAR_COLOR
	monde.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	monde.environment.ambient_light_color = Color(1, 0.92, 0.8)
	monde.environment.ambient_light_energy = 0.6
	monde.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	vue.add_child(monde)
	_vitrine = Node3D.new()
	_vitrine.rotation_degrees.y = -30.0
	vue.add_child(_vitrine)
	# Socle en bois clair sous l'horloge : on la présente comme une pièce de maquette.
	var socle := MeshInstance3D.new()
	var disque := CylinderMesh.new()
	disque.top_radius = 1.5
	disque.bottom_radius = 1.6
	disque.height = 0.18
	socle.mesh = disque
	socle.position.y = -0.09
	var bois := StandardMaterial3D.new()
	bois.albedo_color = Color("#B9773E")
	bois.roughness = 0.55
	socle.material_override = bois
	_vitrine.add_child(socle)
	_vitrine.add_child((load(MODELE) as PackedScene).instantiate())
	return cadre


# Plateau choisi dans le menu (mémorisé dans Run : « Rejouer » relance le même plateau).
func _plateau_suivant() -> void:
	var i: int = (Run.regles.departs.find(Run.depart) + 1) % Run.regles.departs.size()
	Run.choisir_depart(i)
	_afficher_plateau()


func _afficher_plateau() -> void:
	%Plateau.text = tr("Plateau : %s") % tr(Run.depart.nom)
	%DescriptionPlateau.text = tr(Run.depart.description)
	var record: int = record_defi(_date())
	%Defi.text = tr("Défi du jour") if record < 0 else tr("Défi du jour — record : %d / %d") % [record, Run.nb_vagues]


func _afficher_or() -> void:
	# Icône + nombre, légende au survol (« icônes au premier plan, texte au survol ») : la ligne tient dans toutes les langues.
	%Or.text = str(Progression.engrenages())
	%Or.tooltip_text = tr("Engrenages d’or : %d") % Progression.engrenages()
	%Or.mouse_filter = Control.MOUSE_FILTER_PASS


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_afficher_plateau()
		_afficher_or()


func _jouer() -> void:
	Run.choisir_depart(maxi(0, Run.regles.departs.find(Run.depart)))
	commencer_partie(get_tree())


# Défi du jour : même plateau et même graine pour tout le monde à cette date.
func _lancer_defi() -> void:
	Run.preparer_defi(_date())
	commencer_partie(get_tree())


static func _date() -> String:
	return Time.get_date_string_from_system()


## Meilleur nombre de vagues tenues au défi de cette date, ou -1 s'il n'a pas été joué.
static func record_defi(date: String) -> int:
	var fichier := ConfigFile.new()
	fichier.load(REGLAGES)
	return fichier.get_value("defi", date, -1)


## Mémorise le résultat du défi du jour s'il bat le record (appelé par l'écran de fin).
static func noter_defi(vagues: int) -> void:
	if not Run.defi_du_jour:
		return
	var fichier := ConfigFile.new()
	fichier.load(REGLAGES)
	var date: String = _date()
	if vagues > fichier.get_value("defi", date, -1):
		fichier.set_value("defi", date, vagues)
		fichier.save(REGLAGES)


func _revoir_tutoriel() -> void:
	if regler_tutoriel(false):
		%Tutoriel.text = "Tutoriel activé pour la prochaine partie"
		%Tutoriel.disabled = true


## Met à jour le drapeau du tutoriel en conservant tous les autres réglages.
static func regler_tutoriel(vu: bool) -> bool:
	var fichier := ConfigFile.new()
	var lecture: Error = fichier.load(REGLAGES)
	if lecture != OK and lecture != ERR_FILE_NOT_FOUND:
		push_warning("Lecture des réglages impossible : " + error_string(lecture))
		return false
	if vu:
		fichier.set_value("tutoriel", "vu", true)
	elif fichier.has_section_key("tutoriel", "vu") or fichier.has_section("astuces"):
		# Revoir le tutoriel réaffiche aussi les astuces contextuelles (game/ui/astuces.gd).
		if fichier.has_section_key("tutoriel", "vu"):
			fichier.erase_section_key("tutoriel", "vu")
		if fichier.has_section("astuces"):
			fichier.erase_section("astuces")
	else:
		return true
	var ecriture: Error = fichier.save(REGLAGES)
	if ecriture != OK:
		push_warning("Écriture des réglages impossible : " + error_string(ecriture))
	return ecriture == OK


## Ouvre le plateau avec une horloge et une réserve neuves.
static func commencer_partie(arbre: SceneTree) -> void:
	arbre.paused = false
	Run.reinitialiser()
	arbre.change_scene_to_file(PARTIE)


## Revient à l'écran titre et rend son activité à l'arbre de scène.
static func ouvrir_titre(arbre: SceneTree) -> void:
	arbre.paused = false
	arbre.change_scene_to_file(TITRE)


## Anime l'entrée du panneau autour de son centre après sa mise en page.
static func apparaitre(panneau: Control) -> void:
	_arreter_animation(panneau)
	panneau.pivot_offset = panneau.size / 2.0
	panneau.modulate.a = 0.0
	panneau.scale = Vector2.ONE * 0.96
	var animation: Tween = panneau.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	panneau.set_meta(&"animation_interface", animation)
	animation.tween_property(panneau, "modulate:a", 1.0, 0.18)
	animation.tween_property(panneau, "scale", Vector2.ONE, 0.18)


## Prépare tous les boutons déjà présents dans un écran.
static func preparer_boutons(racine: Node) -> void:
	for bouton: BaseButton in racine.find_children("*", "BaseButton", true, false):
		preparer_bouton(bouton)


## Associe le clic sonore au bouton et laisse le thème décaler son contenu à la pression.
static func preparer_bouton(bouton: BaseButton) -> void:
	bouton.pressed.connect(Sons.jouer.bind(&"clic"))


static func _arreter_animation(controle: Control) -> void:
	if controle.has_meta(&"animation_interface"):
		var animation: Tween = controle.get_meta(&"animation_interface")
		animation.kill()


## Fixe la largeur d'un texte à retour à la ligne et lui réserve la hauteur de toutes ses lignes, mesurée sur sa police.
## Pourquoi : un Label à retour automatique calcule sa hauteur sur sa largeur du moment, nulle ou provisoire tant qu'il
## n'a pas été mis en page ; les fiches se retrouvaient immenses ou le texte traduit débordait (playtest 1).
static func caler_hauteur(texte: Label, largeur: float) -> void:
	texte.custom_minimum_size.x = largeur
	# Donner aussi la vraie largeur : le Label recalcule ses lignes sur elle (et non sur sa taille minimale).
	texte.size.x = largeur
	var police: Font = texte.get_theme_font(&"font")
	var taille: int = texte.get_theme_font_size(&"font_size")
	var mesure: Vector2 = police.get_multiline_string_size(texte.tr(texte.text), HORIZONTAL_ALIGNMENT_LEFT, largeur,
			taille, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)
	var lignes: int = maxi(1, roundi(mesure.y / police.get_height(taille)))
	texte.custom_minimum_size.y = mesure.y + (lignes - 1) * texte.get_theme_constant(&"line_spacing") + 6


## Vignette d'une pièce ou d'une extension, rendue depuis le kit 3D (`scripts/generer_vignettes.gd`), ou null.
static func vignette_de(objet: Resource) -> Texture2D:
	var chemin: String = "res://assets/ui/vignettes/%s.png" % objet.get("id")
	return load(chemin) as Texture2D if ResourceLoader.exists(chemin) else null
