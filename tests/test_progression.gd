extends RefCounted
## Vérifie les achats persistants, les avantages en partie libre et l'égalité en défi.

const Progression = preload("res://game/core/progression.gd")
const AmeliorationDef = preload("res://game/core/amelioration_def.gd")
const Partie = preload("res://game/core/run.gd")
const BOITIER: AmeliorationDef = preload("res://data/ameliorations/pv_horloge.tres")


# Chaque scénario possède sa partie et sa sauvegarde, même lorsqu'une assertion échoue.
func _isoler(scenario: Callable) -> String:
	var ancien_chemin: String = Progression.chemin
	Progression.chemin = "user://test_progression_%d.cfg" % OS.get_process_id()
	Progression.reinitialiser_tout()
	var partie := Partie.new()
	var resultat: String = scenario.call(partie)
	partie.free()
	Progression.reinitialiser_tout()
	Progression.chemin = ancien_chemin
	return resultat


## Vérifie les prix successifs, le refus sans fonds et la relecture depuis le disque.
func test_achats_et_sauvegarde() -> String:
	return _isoler(_achats)


func _achats(_partie: Partie) -> String:
	if Progression.acheter(BOITIER) or Progression.niveau(BOITIER.id) != 0:
		return "Un achat sans fonds a été accepté."
	var total: int = 0
	for prix: int in BOITIER.prix:
		total += prix
	Progression.gagner(total)
	for rang: int in BOITIER.niveaux_max:
		if not Progression.acheter(BOITIER):
			return "Achat refusé au niveau %d." % (rang + 1)
		total -= BOITIER.prix[rang]
		if Progression.engrenages() != total or Progression.niveau(BOITIER.id) != rang + 1:
			return "Le solde ou le niveau relu est incorrect."
	# Il reste assez d'or pour que seul le plafond interdise l'achat.
	Progression.gagner(BOITIER.prix[-1])
	if Progression.acheter(BOITIER) or Progression.engrenages() != BOITIER.prix[-1]:
		return "Le plafond de niveau n'a pas protégé le solde."
	var fichier := ConfigFile.new()
	if fichier.load(Progression.chemin) != OK:
		return "La sauvegarde ne se relit pas sur disque."
	if not is_equal_approx(Progression.bonus(BOITIER.effet), BOITIER.niveaux_max * BOITIER.valeur_par_niveau):
		return "Le bonus cumulé ne correspond pas aux niveaux achetés."
	return ""


func _equiper(partie: Partie) -> bool:
	for def: AmeliorationDef in partie.regles.ameliorations:
		Progression.gagner(def.prix[0])
		if not Progression.acheter(def):
			return false
	return true


func _lancer(partie: Partie) -> void:
	partie.choisir_lot(0)
	partie.lancer_vague()


## Exerce les six bonus, les deux relances successives et le gain après une défaite.
func test_bonus_en_partie_libre() -> String:
	return _isoler(_partie_libre)


func _partie_libre(partie: Partie) -> String:
	if not _equiper(partie):
		return "Les améliorations de départ n'ont pas été achetées."
	var pv_base: int = partie.regles.pv_horloge
	var ressorts_base: int = partie.regles.ressorts_depart
	var choix_base: int = partie.regles.choix_par_draft
	partie.reinitialiser()
	if partie.pv_max != pv_base + 5 or partie.pv_horloge != partie.pv_max:
		return "Le boîtier n'augmente pas les PV de départ."
	if partie.ressorts != ressorts_base + 8 or partie.offre.size() != choix_base + 1:
		return "Les ressorts ou la carte supplémentaire manquent au départ."
	if not is_equal_approx(partie.bonus_cadence, 1.08):
		return "La cadence n'a pas reçu son multiplicateur."
	if partie.regles.pv_horloge != pv_base or partie.regles.choix_par_draft != choix_base or partie.regles.ressorts_depart != ressorts_base:
		return "La partie a modifié les règles partagées."
	var solde: int = partie.ressorts
	if not partie.relancer_offre() or partie.ressorts != solde:
		return "La première relance devrait être offerte."
	if not partie.relancer_offre() or partie.ressorts != solde - partie.regles.prix_relance:
		return "La seconde relance devrait être payante."
	_lancer(partie)
	partie.subir_degats(1)
	partie.terminer_vague()
	if partie.derniere_recompense != partie.regles.recompense_vague + 2 or partie.prix_relance != 0:
		return "La fin de vague doit verser la rente et renouveler la relance."
	partie.choisir_lot(0)
	partie.gagner(partie.regles.prix_reparation)
	if not partie.reparer_horloge() or partie.pv_horloge != partie.pv_max:
		return "La réparation doit respecter le plafond amélioré."
	partie.lancer_vague()
	partie.subir_degats(partie.pv_max)
	if partie.engrenages_gagnes != 1 or Progression.engrenages() != 1:
		return "La défaite doit rémunérer uniquement la vague tenue."
	return ""


## Vérifie le versement unique de la prime de victoire et sa remise à zéro au départ.
func test_prime_de_victoire() -> String:
	return _isoler(_victoire)


func _victoire(partie: Partie) -> String:
	partie.reinitialiser()
	for i: int in partie.nb_vagues:
		_lancer(partie)
		partie.terminer_vague()
	partie.terminer_vague()
	var attendu: int = partie.nb_vagues + 5
	if partie.engrenages_gagnes != attendu or Progression.engrenages() != attendu:
		return "La victoire doit verser une seule fois les vagues tenues et la prime."
	partie.reinitialiser()
	if partie.engrenages_gagnes != 0 or Progression.engrenages() != attendu:
		return "Le nouveau bilan doit repartir à zéro en conservant le solde."
	return ""


## Vérifie sur un profil équipé que le défi neutralise tous les bonus et tout gain.
func test_defi_sans_bonus_ni_gain() -> String:
	return _isoler(_defi)


func _defi(partie: Partie) -> String:
	if not _equiper(partie):
		return "Le profil du défi n'a pas été équipé."
	partie.reinitialiser()
	partie.preparer_defi("2026-11-26")
	partie.reinitialiser()
	if partie.pv_horloge != partie.regles.pv_horloge or partie.pv_max != partie.regles.pv_horloge:
		return "Le défi a conservé les PV de l'Établi."
	if partie.ressorts != partie.regles.ressorts_depart or partie.offre.size() != partie.regles.choix_par_draft:
		return "Le tirage ou les ressorts du défi dépendent du profil."
	if partie.bonus_cadence != 1.0 or partie.prix_relance != partie.regles.prix_relance:
		return "Le défi a conservé la cadence ou la relance offerte."
	for i: int in partie.nb_vagues:
		_lancer(partie)
		partie.terminer_vague()
		if i == 0 and partie.derniere_recompense != partie.regles.recompense_vague + partie.regles.bonus_sans_degat:
			return "Le défi a versé une rente permanente."
	if partie.phase != Partie.Phase.FIN or partie.engrenages_gagnes != 0 or Progression.engrenages() != 0:
		return "Le défi doit se terminer sans engrenages d'or."
	return ""
