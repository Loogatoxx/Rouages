extends RefCounted
## Playtest 3 : l'aide « Aide et commandes » et les textes à plusieurs lignes passent bien par les traductions.

const MenuPause = preload("res://game/ui/menu_pause.gd")
const LANGUES := ["en", "pt"]


func _traduction(langue: String) -> Translation:
	return load("res://traductions/textes.%s.translation" % langue) as Translation


## Chaque ligne de l'aide a une traduction anglaise et portugaise, différente du français, avec le même nombre de %s.
func test_aide_traduite() -> String:
	for langue: String in LANGUES:
		var traduction: Translation = _traduction(langue)
		if traduction == null:
			return "Traduction « %s » introuvable." % langue
		for ligne: Array in MenuPause.LIGNES_AIDE:
			var texte: String = traduction.get_message(ligne[0])
			if texte == "" or texte == ligne[0]:
				return "Ligne d'aide non traduite en %s : %s" % [langue, ligne[0]]
			if texte.count("%s") != (ligne[1] as Array).size() or String(ligne[0]).count("%s") != (ligne[1] as Array).size():
				return "Nombre de touches incorrect dans la ligne d'aide : %s" % ligne[0]
	return ""


## L'aide suit la langue choisie (elle restait en français) et affiche la touche réellement assignée.
func test_aide_suit_la_langue_et_les_touches() -> String:
	var avant: String = TranslationServer.get_locale()
	TranslationServer.set_locale("fr")
	var francais: String = MenuPause.texte_aide()
	TranslationServer.set_locale("en")
	var anglais: String = MenuPause.texte_aide()
	TranslationServer.set_locale(avant)
	if francais == anglais or not anglais.contains("deselect"):
		return "L'aide doit changer avec la langue."
	if anglais.contains("%s") or francais.contains("%s"):
		return "Toutes les touches doivent être remplies dans l'aide."
	return "" if francais.split("\n").size() == MenuPause.LIGNES_AIDE.size() else "Une ligne d'aide par entrée."


## Aucune clé de traduction du code ne contient « \n » écrit en toutes lettres dans le fichier CSV : une telle clé ne
## correspond jamais au texte du jeu (c'était la cause du bug de l'aide).
func test_pas_de_retour_ligne_litteral_dans_les_cles() -> String:
	var fichier := FileAccess.open("res://traductions/textes.csv", FileAccess.READ)
	if fichier == null:
		return "Fichier de traductions introuvable."
	var numero: int = 0
	while not fichier.eof_reached():
		var ligne: PackedStringArray = fichier.get_csv_line()
		numero += 1
		if ligne.size() > 0 and ligne[0].contains("\\n"):
			return "Entrée %d : la clé contient « \\n » en toutes lettres (utiliser un vrai retour à la ligne entre guillemets)." % numero
	return ""


## P3-32 : tout texte affiché (tr(...) du code, textes des scènes, noms et descriptions des données) a son entrée
## dans le fichier de traductions. Les identifiants internes (minuscules et soulignés) ne sont pas des textes.
func test_aucun_texte_sans_traduction() -> String:
	var cles: Dictionary = {}
	var fichier := FileAccess.open("res://traductions/textes.csv", FileAccess.READ)
	while not fichier.eof_reached():
		var ligne: PackedStringArray = fichier.get_csv_line()
		if ligne.size() > 0:
			cles[ligne[0]] = true
	var manquants: PackedStringArray = []
	var motif_tr := RegEx.create_from_string("\\btr\\(\"((?:[^\"\\\\]|\\\\.)*)\"\\)")
	var motif_donnee := RegEx.create_from_string("(?m)^(?:nom|description|role|titre|recit) = \"((?:[^\"\\\\]|\\\\.)*)\"")
	var motif_scene := RegEx.create_from_string("(?m)^(?:text|tooltip_text) = \"((?:[^\"\\\\]|\\\\.)*)\"")
	var identifiant := RegEx.create_from_string("^[a-z0-9_]*$|^[\\d\\s%sdx×+/.:·—–()\\[\\]-]*$")
	for chemin: String in _fichiers("res://game", ["gd", "tscn"]) + _fichiers("res://data", ["tres"]):
		if chemin.contains("banc_nuees"):
			continue  # outil de mesure, jamais montré au joueur
		var texte: String = FileAccess.get_file_as_string(chemin)
		var motif: RegEx = motif_donnee
		if chemin.ends_with(".gd"):
			motif = motif_tr
		elif chemin.ends_with(".tscn"):
			motif = motif_scene
		if true:
			for trouve: RegExMatch in motif.search_all(texte):
				var cle: String = trouve.get_string(1).replace("\\n", "\n").replace("\\\"", "\"")
				if cle != "" and identifiant.search(cle) == null and not cles.has(cle):
					manquants.append("%s (%s)" % [cle.left(60), chemin.get_file()])
	return "" if manquants.is_empty() else "Textes sans traduction : %s" % ", ".join(manquants.slice(0, 6))


func _fichiers(dossier: String, extensions: Array) -> PackedStringArray:
	var resultat := PackedStringArray()
	var acces := DirAccess.open(dossier)
	if acces == null:
		return resultat
	for sous: String in acces.get_directories():
		resultat.append_array(_fichiers(dossier.path_join(sous), extensions))
	for nom: String in acces.get_files():
		if nom.get_extension() in extensions:
			resultat.append(dossier.path_join(nom))
	return resultat
