extends SceneTree
## Mini-lanceur de tests sans fenêtre (headless). Lancer : ./scripts/tests.sh
##
## Pourquoi pas un addon de tests : zéro dépendance, et ça suffit pour tester la logique pure
## (grille, énergie, champ de flux, nuées).
## Convention : chaque fichier tests/test_*.gd étend RefCounted et expose des méthodes test_*()
## qui retournent "" si tout va bien, ou un message d'erreur sinon.

func _initialize() -> void:
	var echecs := 0
	var total := 0
	var dossier := DirAccess.open("res://tests")
	for fichier in dossier.get_files():
		if not (fichier.begins_with("test_") and fichier.ends_with(".gd")):
			continue
		var suite: RefCounted = load("res://tests/" + fichier).new()
		for methode in suite.get_method_list():
			var nom: String = methode["name"]
			if not nom.begins_with("test_"):
				continue
			total += 1
			var erreur: String = suite.call(nom)
			if erreur == "":
				print("  ok    %s :: %s" % [fichier, nom])
			else:
				echecs += 1
				print("  ÉCHEC %s :: %s -> %s" % [fichier, nom, erreur])
	print("%d test(s), %d échec(s)" % [total, echecs])
	quit(1 if echecs > 0 or total == 0 else 0)
