extends RefCounted
## Vérifie le contraste des couleurs des jouets et de leurs chapeaux.

const Materiaux = preload("res://game/core/materiaux.gd")
const NueeVisuel = preload("res://game/swarm/nuee_visuel.gd")


## Vérifie que chaque peinture se détache du chemin crème.
func test_jouets_contrastent_avec_chemin() -> String:
	return _verifier_contraste("pierre_creme", 3.0)


## Vérifie que chaque peinture se détache de l'herbe.
func test_jouets_contrastent_avec_herbe() -> String:
	return _verifier_contraste("herbe", 1.6)


## Vérifie le seuil de repli, les quatre peintures prescrites restant sous 3,0.
func test_chapeau_contraste() -> String:
	return _verifier_contraste("chapeau", 1.8)


func _verifier_contraste(fond: String, seuil: float) -> String:
	var couleur_fond := Color(Materiaux.COULEURS[fond])
	for teinte: String in NueeVisuel.TEINTES:
		var ratio: float = Materiaux.contraste(Color(Materiaux.COULEURS[teinte]), couleur_fond)
		if ratio < seuil:
			return "contraste de %s avec %s : %.2f, minimum %.2f" % [teinte, fond, ratio, seuil]
	return ""
