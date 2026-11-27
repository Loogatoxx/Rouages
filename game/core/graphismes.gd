extends Node
## Réglages graphiques et de performance (autoload « Graphismes »), enregistrés dans `user://reglages.cfg`.
##
## Pourquoi (playtest 2) : sur le PC Windows de Carlos, le jeu faisait chauffer la machine. Un écran à 144 Hz ou plus
## (ou une synchro verticale coupée par le pilote) fait calculer au jeu des centaines d'images par seconde, chacune avec
## ombres temps réel, occlusion ambiante (SSAO) et anticrénelage. On plafonne donc à 60 images/s par défaut, on ralentit
## à 15 images/s quand la fenêtre n'est plus au premier plan, et le joueur choisit lui-même ce qu'il garde.
##
## Les réglages s'appliquent à tout nœud qui entre dans l'arbre (lumières, environnements, particules, sous-vues) :
## aucune scène n'a besoin de connaître cet autoload.

signal change

const REGLAGES := "user://reglages.cfg"
const SECTION := "graphismes"
## Choix proposés pour le plafond d'images par seconde (0 = illimité).
const CHOIX_FPS: Array[int] = [30, 60, 120, 0]
## Choix proposés pour l'échelle de rendu 3D (le texte de l'interface reste net).
const CHOIX_ECHELLE: Array[float] = [0.5, 0.75, 1.0]
const FPS_ARRIERE_PLAN := 15
const MSAA: Array[Viewport.MSAA] = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X]
## Préréglages : [fps, vsync, ombres, ssao, lueur, particules, msaa, échelle].
const PRESETS: Dictionary = {
	&"economie": [30, true, 0, false, false, false, 0, 0.75],
	&"equilibre": [60, true, 1, false, true, true, 1, 1.0],
	&"qualite": [60, true, 2, true, true, true, 2, 1.0],
}

var fps: int = 60
var vsync: bool = true
## 0 = aucune, 1 = basses, 2 = hautes.
var ombres: int = 2
var ssao: bool = true
var lueur: bool = true
var particules: bool = true
## Indice dans `MSAA` (0 = désactivé, 1 = 2×, 2 = 4×).
var msaa: int = 1
var echelle: float = 1.0
var _arriere_plan: bool = false


func _ready() -> void:
	lire()
	get_tree().node_added.connect(_regler_noeud)
	appliquer()


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_arriere_plan = true
		_appliquer_fps()
	elif quoi == NOTIFICATION_APPLICATION_FOCUS_IN:
		_arriere_plan = false
		_appliquer_fps()


## Applique tous les réglages à la fenêtre et aux nœuds déjà présents.
func appliquer() -> void:
	_appliquer_fps()
	var rendu: bool = DisplayServer.get_name() != "headless"
	if rendu:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
		RenderingServer.directional_shadow_atlas_set_size(2048 if ombres == 1 else 4096, true)
	var racine: Window = get_tree().root
	racine.msaa_3d = MSAA[msaa]
	racine.scaling_3d_scale = echelle
	# Sous 100 %, FSR 1 agrandit l'image 3D plus proprement qu'un simple étirement, pour un coût minime.
	racine.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if echelle < 1.0 else Viewport.SCALING_3D_MODE_BILINEAR
	_parcourir(racine)
	change.emit()


## Applique un préréglage (« economie », « equilibre » ou « qualite »), l'enregistre et le diffuse.
func prereglage(nom: StringName) -> void:
	var valeurs: Array = PRESETS.get(nom, PRESETS[&"qualite"])
	fps = valeurs[0]
	vsync = valeurs[1]
	ombres = valeurs[2]
	ssao = valeurs[3]
	lueur = valeurs[4]
	particules = valeurs[5]
	msaa = valeurs[6]
	echelle = valeurs[7]
	enregistrer()
	appliquer()


## Nom du préréglage qui correspond exactement aux réglages actuels, ou &"" (réglages personnalisés).
func prereglage_actuel() -> StringName:
	var actuels: Array = [fps, vsync, ombres, ssao, lueur, particules, msaa, echelle]
	for nom: StringName in PRESETS:
		if PRESETS[nom] == actuels:
			return nom
	return &""


func _appliquer_fps() -> void:
	Engine.max_fps = FPS_ARRIERE_PLAN if _arriere_plan else fps


func _parcourir(noeud: Node) -> void:
	_regler_noeud(noeud)
	for enfant: Node in noeud.get_children():
		_parcourir(enfant)


# Chaque nœud garde sa valeur d'origine (méta) : couper puis rallumer un effet rend exactement le réglage de la scène.
func _regler_noeud(noeud: Node) -> void:
	if noeud is DirectionalLight3D or noeud is OmniLight3D or noeud is SpotLight3D:
		var lumiere: Light3D = noeud
		if not lumiere.has_meta(&"ombre_origine"):
			lumiere.set_meta(&"ombre_origine", lumiere.shadow_enabled)
		lumiere.shadow_enabled = ombres > 0 and lumiere.get_meta(&"ombre_origine")
	elif noeud is WorldEnvironment:
		var ambiance: Environment = (noeud as WorldEnvironment).environment
		if ambiance != null:
			if not ambiance.has_meta(&"ssao_origine"):
				ambiance.set_meta(&"ssao_origine", ambiance.ssao_enabled)
				ambiance.set_meta(&"lueur_origine", ambiance.glow_enabled)
			ambiance.ssao_enabled = ssao and ambiance.get_meta(&"ssao_origine")
			ambiance.glow_enabled = lueur and ambiance.get_meta(&"lueur_origine")
	elif noeud is GPUParticles3D or noeud is CPUParticles3D:
		noeud.visible = particules
		noeud.set(&"emitting", particules)
	elif noeud is SubViewport:
		(noeud as SubViewport).msaa_3d = MSAA[msaa]


## Lit les réglages enregistrés (valeurs par défaut sinon).
func lire() -> void:
	var fichier := ConfigFile.new()
	fichier.load(REGLAGES)
	fps = fichier.get_value(SECTION, "fps", 60)
	vsync = fichier.get_value(SECTION, "vsync", true)
	ombres = clampi(fichier.get_value(SECTION, "ombres", 2), 0, 2)
	ssao = fichier.get_value(SECTION, "ssao", true)
	lueur = fichier.get_value(SECTION, "lueur", true)
	particules = fichier.get_value(SECTION, "particules", true)
	msaa = clampi(fichier.get_value(SECTION, "msaa", 1), 0, MSAA.size() - 1)
	echelle = clampf(fichier.get_value(SECTION, "echelle", 1.0), 0.5, 1.0)


## Enregistre les réglages sans toucher aux autres sections du fichier (son, langue, plein écran…).
func enregistrer() -> void:
	var fichier := ConfigFile.new()
	var erreur: Error = fichier.load(REGLAGES)
	if erreur != OK and erreur != ERR_FILE_NOT_FOUND:
		push_warning("Lecture des réglages impossible : " + error_string(erreur))
		return
	for cle: String in ["fps", "vsync", "ombres", "ssao", "lueur", "particules", "msaa", "echelle"]:
		fichier.set_value(SECTION, cle, get(cle))
	erreur = fichier.save(REGLAGES)
	if erreur != OK:
		push_warning("Enregistrement des réglages graphiques impossible : " + error_string(erreur))
