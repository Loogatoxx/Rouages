class_name Materiaux extends RefCounted
## Partage les matériaux et les scènes du kit entre le plateau et les nuées.

const KIT := "res://assets/final/kit_v2/"

const COULEURS := {
	"herbe": "#A9C98B", "herbe_sombre": "#A0C283", "pierre_creme": "#EFE3C8", "bois_plateau": "#B9773E",
	"bois_clair": "#E2BE8C", "laiton": "#D4A84B", "pastel_bleu": "#9EC3E6",
	"pastel_rose": "#F2B5C4", "pastel_vert": "#B8E0B0", "pastel_jaune": "#F5DC8A",
	"jouet_rouge": "#C8553D", "jouet_bleu": "#3D6FA8", "jouet_vert": "#4F8A5B",
	"jouet_menthe": "#6FB59A", "menthe_soutenue": "#467F6B", "cuivre": "#B0643A",
	"jouet_prune": "#8A5A9E", "chapeau": "#4A3426",
}

static var _materiaux: Dictionary[String, Material] = {}
static var _scenes: Dictionary[StringName, PackedScene] = {}


## Charge une scène du kit une seule fois, y compris si le modèle est absent.
static func scene_du_kit(nom: StringName) -> PackedScene:
	if not _scenes.has(nom):
		var chemin: String = KIT + "%s/%s.glb" % [nom, nom]
		_scenes[nom] = (load(chemin) as PackedScene) if ResourceLoader.exists(chemin) else null
	return _scenes[nom]


## Calcule le ratio de contraste WCAG entre deux couleurs sRGB.
static func contraste(a: Color, b: Color) -> float:
	var luminance_a: float = a.srgb_to_linear().get_luminance()
	var luminance_b: float = b.srgb_to_linear().get_luminance()
	return (maxf(luminance_a, luminance_b) + 0.05) / (minf(luminance_a, luminance_b) + 0.05)


## Charge le matériau artistique ou fabrique et mémorise sa couleur de secours.
static func obtenir(nom: String) -> Material:
	if not _materiaux.has(nom):
		var chemin: String = "res://assets/materials/%s.tres" % nom
		var mat: Material
		if ResourceLoader.exists(chemin):
			mat = load(chemin) as Material
		if mat == null:
			var secours := StandardMaterial3D.new()
			secours.albedo_color = Color(COULEURS[nom])
			secours.metallic = 0.8 if nom == "laiton" else 0.0
			mat = secours
		_materiaux[nom] = mat
	return _materiaux[nom]
