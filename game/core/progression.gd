class_name Progression extends RefCounted
## Conserve les engrenages d'or et les niveaux achetés d'une partie à l'autre.

const AmeliorationDef = preload("res://game/core/amelioration_def.gd")
const REGLES = preload("res://data/regles.tres")

static var chemin: String = "user://progression.cfg"


static func _lire() -> ConfigFile:
	var fichier := ConfigFile.new()
	var erreur: Error = fichier.load(chemin)
	if erreur == OK or erreur == ERR_FILE_NOT_FOUND:
		if not fichier.has_section("campagne"):
			# Reconnaître l'ancien profil avant d'y inscrire son prochain gain.
			var ancien: bool = fichier.get_value("monnaie", "engrenages", 0) > 0
			if fichier.has_section("niveaux"):
				for id: String in fichier.get_section_keys("niveaux"):
					if fichier.get_value("niveaux", id) > 0:
						ancien = true
						break
			fichier.set_value("campagne", "ancien_joueur", ancien)
		return fichier
	push_warning("Lecture de la progression impossible : " + error_string(erreur))
	return null


static func _sauver(fichier: ConfigFile) -> bool:
	# Le solde et le niveau remplacent ensemble la dernière sauvegarde complète.
	var temporaire: String = chemin + ".tmp"
	var erreur: Error = fichier.save(temporaire)
	if erreur == OK:
		erreur = DirAccess.rename_absolute(temporaire, chemin)
	if erreur != OK:
		push_warning("Sauvegarde de la progression impossible : " + error_string(erreur))
	return erreur == OK


## Indique si le profil possédait déjà des engrenages ou des améliorations avant la campagne.
static func ancien_joueur() -> bool:
	var fichier: ConfigFile = _lire()
	return fichier != null and fichier.get_value("campagne", "ancien_joueur", false)


## Renvoie le nombre de chapitres consécutifs terminés.
static func chapitres_finis() -> int:
	var fichier: ConfigFile = _lire()
	return fichier.get_value("campagne", "finis", 0) if fichier else 0


## Valide le prochain chapitre dans l'ordre du récit, numéroté à partir de un.
static func finir_chapitre(n: int) -> void:
	var fichier: ConfigFile = _lire()
	if fichier == null or n < 1 or n > REGLES.chapitres.size():
		return
	if n == int(fichier.get_value("campagne", "finis", 0)) + 1:
		fichier.set_value("campagne", "finis", n)
		_sauver(fichier)


## Vrai si la BD du chapitre `n` a déjà été montrée (P2-58) : elle ne s'impose qu'au premier lancement.
static func bd_vue(n: int) -> bool:
	var fichier: ConfigFile = _lire()
	return fichier != null and fichier.get_value("bd", "chapitre_%d" % n, false)


static func noter_bd_vue(n: int) -> void:
	var fichier: ConfigFile = _lire()
	if fichier == null or bd_vue(n):
		return
	fichier.set_value("bd", "chapitre_%d" % n, true)
	_sauver(fichier)


## Note un chapitre terminé en Difficile (affiché d'une étoile ; aucun blocage, P2-51).
static func finir_chapitre_difficile(n: int) -> void:
	var fichier: ConfigFile = _lire()
	if fichier == null:
		return
	var faits: Array = fichier.get_value("campagne", "difficiles", [])
	if not faits.has(n):
		faits.append(n)
		fichier.set_value("campagne", "difficiles", faits)
		_sauver(fichier)


## Indique si le chapitre `n` (à partir de un) a été terminé en Difficile.
static func chapitre_difficile_fini(n: int) -> bool:
	var fichier: ConfigFile = _lire()
	return fichier != null and fichier.get_value("campagne", "difficiles", []).has(n)


## Ouvre la partie libre et le défi du jour au même palier de campagne.
static func libre_debloque() -> bool:
	return chapitres_finis() >= REGLES.chapitre_deblocage_libre or ancien_joueur()


## Renvoie le meilleur nombre de vagues tenues sur ce plateau à cette difficulté.
static func record(depart_nom: String, difficulte: int) -> int:
	var fichier: ConfigFile = _lire()
	return fichier.get_value("records_" + depart_nom, str(difficulte), 0) if fichier else 0


## Conserve le meilleur résultat du couple plateau et difficulté.
static func noter_record(depart_nom: String, difficulte: int, vagues: int) -> void:
	var fichier: ConfigFile = _lire()
	var section: String = "records_" + depart_nom
	if fichier != null and vagues > int(fichier.get_value(section, str(difficulte), 0)):
		fichier.set_value(section, str(difficulte), vagues)
		_sauver(fichier)


## Renvoie le nombre d'engrenages d'or disponibles.
static func engrenages() -> int:
	var fichier: ConfigFile = _lire()
	return fichier.get_value("monnaie", "engrenages", 0) if fichier else 0


## Renvoie le nombre de niveaux achetés pour cette amélioration.
static func niveau(id: StringName) -> int:
	var fichier: ConfigFile = _lire()
	return fichier.get_value("niveaux", id, 0) if fichier else 0


## Achète le niveau suivant si son prix est couvert et enregistre le nouveau solde.
static func acheter(def: AmeliorationDef) -> bool:
	if def == null:
		return false
	var fichier: ConfigFile = _lire()
	if fichier == null:
		return false
	var acquis: int = fichier.get_value("niveaux", def.id, 0)
	if acquis < 0 or acquis >= def.niveaux_max or acquis >= def.prix.size():
		return false
	var prix: int = def.prix[acquis]
	var solde: int = fichier.get_value("monnaie", "engrenages", 0)
	if prix < 0 or solde < prix:
		return false
	fichier.set_value("monnaie", "engrenages", solde - prix)
	fichier.set_value("niveaux", def.id, acquis + 1)
	return _sauver(fichier)


## Additionne les effets des niveaux acquis pour une caractéristique.
static func bonus(effet: StringName) -> float:
	var total: float = 0.0
	for def: AmeliorationDef in REGLES.ameliorations:
		if def.effet == effet:
			total += clampi(niveau(def.id), 0, def.niveaux_max) * def.valeur_par_niveau
	return total


## Ajoute les engrenages gagnés au solde et indique si le versement a abouti.
static func gagner(n: int) -> bool:
	if n <= 0:
		return n == 0
	var fichier: ConfigFile = _lire()
	if fichier == null:
		return false
	var solde: int = fichier.get_value("monnaie", "engrenages", 0)
	fichier.set_value("monnaie", "engrenages", solde + n)
	return _sauver(fichier)


## Efface la progression au chemin choisi, notamment entre deux tests.
static func reinitialiser_tout() -> void:
	if FileAccess.file_exists(chemin):
		var erreur: Error = DirAccess.remove_absolute(chemin)
		if erreur != OK:
			push_warning("Effacement de la progression impossible : " + error_string(erreur))
