extends RefCounted
## Lore en BD (P2-58) : chaque chapitre a ses cases, une bulle traduite par case, et la BD ne s'impose qu'une fois.

const Progression = preload("res://game/core/progression.gd")
const REGLES = preload("res://data/regles.tres")


## Chaque chapitre illustré a trois cases et autant de bulles, toutes traduites ; le chapitre 1 l'est forcément.
## (Chapitres 5 et 6 : cases en attente du quota de génération d'images, leur BD reste vide en attendant.)
func test_cases_et_bulles_des_chapitres() -> String:
	var cles: Dictionary = {}
	var fichier := FileAccess.open("res://traductions/textes.csv", FileAccess.READ)
	while not fichier.eof_reached():
		var ligne: PackedStringArray = fichier.get_csv_line()
		if ligne.size() >= 4:
			cles[ligne[0]] = ligne[2] != "" and ligne[3] != ""
	if REGLES.chapitres[0].bd.is_empty():
		return "le chapitre 1 doit avoir sa BD"
	for chapitre: Resource in REGLES.chapitres:
		if chapitre.bd.is_empty():
			continue
		if chapitre.bd.size() != 3:
			return "chapitre %d : %d case(s) de BD au lieu de 3" % [chapitre.id, chapitre.bd.size()]
		if chapitre.bulles.size() != chapitre.bd.size():
			return "chapitre %d : %d bulles pour %d cases" % [chapitre.id, chapitre.bulles.size(), chapitre.bd.size()]
		for case: Texture2D in chapitre.bd:
			if case == null:
				return "chapitre %d : une case ne se charge pas" % chapitre.id
		for bulle: String in chapitre.bulles:
			if not cles.get(bulle, false):
				return "chapitre %d : bulle sans traduction anglaise ou portugaise : %s" % [chapitre.id, bulle]
	return ""


## La BD d'un chapitre est notée vue une fois montrée : elle ne revient plus d'elle-même (sauvegarde isolée).
func test_bd_vue_une_seule_fois() -> String:
	var chemin_initial: String = Progression.chemin
	Progression.chemin = "user://test_bd_%d.cfg" % OS.get_process_id()
	Progression.reinitialiser_tout()
	var resultat: String = ""
	if Progression.bd_vue(1):
		resultat = "une sauvegarde neuve ne doit avoir vu aucune BD"
	else:
		Progression.noter_bd_vue(1)
		if not Progression.bd_vue(1) or Progression.bd_vue(2):
			resultat = "seule la BD du chapitre 1 doit être notée vue"
	Progression.reinitialiser_tout()
	Progression.chemin = chemin_initial
	return resultat
