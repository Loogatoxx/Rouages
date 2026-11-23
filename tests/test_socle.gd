extends RefCounted
## Tests du socle (étape 0) : configuration du projet.


func test_actions_inputmap_presentes() -> String:
	# Toutes les commandes passent par l'InputMap (exigence manette / Steam).
	for action in ["poser_tuile", "tourner_tuile", "annuler", "basculer_camera"]:
		if not InputMap.has_action(action):
			return "action manquante : %s" % action
	return ""


func test_renderer_forward_plus() -> String:
	var methode: String = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	return "" if methode == "forward_plus" else "renderer inattendu : %s" % methode
