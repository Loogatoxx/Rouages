class_name Progression extends RefCounted
## Conserve les engrenages d'or et les niveaux achetés d'une partie à l'autre.

const AmeliorationDef = preload("res://game/core/amelioration_def.gd")
const REGLES = preload("res://data/regles.tres")

static var chemin: String = "user://progression.cfg"


static func _lire() -> ConfigFile:
	var fichier := ConfigFile.new()
	var erreur: Error = fichier.load(chemin)
	if erreur == OK or erreur == ERR_FILE_NOT_FOUND:
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
