class_name Materiaux extends RefCounted
## Partage les matériaux du plateau et des nuées.

const COULEURS := {
	"herbe": "#A9C98B", "pierre_creme": "#EFE3C8", "bois_plateau": "#B9773E",
	"bois_clair": "#E2BE8C", "laiton": "#D4A84B", "pastel_bleu": "#9EC3E6",
	"pastel_rose": "#F2B5C4", "pastel_vert": "#B8E0B0", "pastel_jaune": "#F5DC8A",
	"jouet_rouge": "#C8553D", "jouet_bleu": "#3D6FA8", "jouet_vert": "#4F8A5B",
	"jouet_prune": "#8A5A9E", "chapeau": "#4A3426",
}

static var _materiaux: Dictionary[String, Material] = {}


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
