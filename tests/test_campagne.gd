extends RefCounted
## Vérifie les dioramas, leurs déblocages et les difficultés sur une sauvegarde isolée.

const Partie = preload("res://game/core/run.gd")
const Progression = preload("res://game/core/progression.gd")
const DirecteurVagues = preload("res://game/waves/directeur_vagues.gd")
const AmeliorationDef = preload("res://game/core/amelioration_def.gd")
const REGLES = preload("res://data/regles.tres")


func _isoler(scenario: Callable) -> String:
	var chemin_initial: String = Progression.chemin
	Progression.chemin = "user://test_campagne_%d.cfg" % OS.get_process_id()
	Progression.reinitialiser_tout()
	var partie := Partie.new()
	var resultat: String = scenario.call(partie)
	partie.free()
	Progression.reinitialiser_tout()
	Progression.chemin = chemin_initial
	return resultat


## Joue les six chapitres dans l'ordre et vérifie le palier du troisième.
func test_campagne_et_deblocage() -> String:
	return _isoler(_campagne)


func _campagne(partie: Partie) -> String:
	if REGLES.chapitres.size() != 6 or Progression.libre_debloque():
		return "Il faut six chapitres et une partie libre verrouillée au départ."
	Progression.finir_chapitre(3)
	partie.preparer_chapitre(0)
	partie.reinitialiser()
	partie.choisir_lot(0)
	partie.lancer_vague()
	partie.subir_degats(partie.pv_max)
	if Progression.chapitres_finis() != 0:
		return "Un saut de chapitre ou une défaite a avancé le récit."
	for i: int in REGLES.chapitres.size():
		partie.preparer_chapitre(i)
		# Playtest 2 : plus de carte répétée après le chapitre 3 (un plateau par chapitre).
		if partie.chapitre != i or partie.depart != REGLES.departs[i] or partie.difficulte != floori(i / 2.0):
			return "Le chapitre %d ne prépare pas le bon diorama." % (i + 1)
		partie.reinitialiser()
		for vague: int in partie.nb_vagues:
			partie.choisir_lot(0)
			partie.lancer_vague()
			partie.terminer_vague()
		Progression.finir_chapitre(i + 1)
		if Progression.chapitres_finis() != i + 1 or Progression.libre_debloque() != (i >= 2):
			return "Progression ou déblocage incorrect après le chapitre %d." % (i + 1)
		if Progression.record(partie.depart.nom, partie.difficulte) != partie.nb_vagues:
			return "La victoire n'a pas inscrit son record."
	partie.choisir_depart(0)
	if partie.chapitre != -1 or partie.defi_du_jour:
		return "La partie libre conserve un mode précédent."
	partie.preparer_defi("2026-11-27")
	if partie.chapitre != -1 or partie.difficulte != 1 or not partie.defi_du_jour:
		return "Le défi doit garder sa difficulté normale."
	return ""


## Préserve l’accès des deux types d’anciens profils, même après une nouvelle sauvegarde.
func test_anciens_profils() -> String:
	return _isoler(_anciens_profils)


func _anciens_profils(_partie: Partie) -> String:
	for section: String in ["monnaie", "niveaux"]:
		var ancien := ConfigFile.new()
		var cle: String = "engrenages" if section == "monnaie" else "pv_horloge"
		ancien.set_value(section, cle, 1)
		if ancien.save(Progression.chemin) != OK:
			return "Impossible de préparer l'ancienne sauvegarde."
		if not Progression.libre_debloque() or Progression.chapitres_finis() != 0:
			return "L'ancien profil perd le libre ou reçoit des chapitres indus."
		Progression.finir_chapitre(1)
		if not Progression.ancien_joueur() or not Progression.libre_debloque():
			return "La migration oublie le statut d'ancien joueur."
		for def: AmeliorationDef in REGLES.ameliorations:
			if def.etat(1, Progression.ancien_joueur()) != AmeliorationDef.Etat.DISPONIBLE:
				return "Une amélioration reste cachée à l'ancien joueur."
	return ""


## Contrôle les paliers des trois surprises et l'accès immédiat aux outils de base.
func test_paliers_etabli() -> String:
	var paliers: Dictionary = {&"trefle": 3, &"relance_offerte": 2, &"choix_draft": 4, &"dent_horloge": 3, &"carillon_huile": 2,
			&"guirlande": 1, &"lanternes": 2}
	for def: AmeliorationDef in REGLES.ameliorations:
		var palier: int = paliers.get(def.id, 0)
		for finis: int in range(5):
			var attendu: AmeliorationDef.Etat = AmeliorationDef.Etat.DISPONIBLE
			if finis + 1 < palier:
				attendu = AmeliorationDef.Etat.MASQUEE
			elif finis + 1 == palier:
				attendu = AmeliorationDef.Etat.VERROUILLEE
			if def.etat(finis, false) != attendu:
				return "État incorrect pour %s après %d chapitres." % [def.id, finis]
	return ""


## Vérifie les PV initiaux, le plafond de réparation et l’indépendance des records.
func test_horloge_et_records() -> String:
	return _isoler(_horloge_et_records)


func _horloge_et_records(partie: Partie) -> String:
	var bonus: Array[int] = [10, 0, -5]
	for i: int in bonus.size():
		partie.difficulte = i
		partie.reinitialiser()
		if partie.pv_max != REGLES.pv_horloge + bonus[i] or partie.pv_horloge != partie.pv_max:
			return "PV de l'horloge incorrects à la difficulté %d." % i
		Progression.noter_record("Prairie", i, i + 3)
		Progression.noter_record("Prairie", i, 1)
	Progression.noter_record("Fourche", 1, 8)
	for i: int in bonus.size():
		if Progression.record("Prairie", i) != i + 3:
			return "Un autre score a écrasé le record du plateau à cette difficulté."
	Progression.gagner(1)
	if Progression.libre_debloque():
		return "Un nouveau profil est devenu ancien après son premier gain."
	return ""


## Mesure les PV du boss apparu en simulation, en cumulant vague, boss et difficulté.
func test_pv_ennemis_par_difficulte() -> String:
	var directeur := DirecteurVagues.new()
	if not is_equal_approx(directeur.facteur_pv, 1.0):
		return "Le banc doit garder le facteur neutre."
	var vague: DirecteurVagues.VagueDef = REGLES.vagues[-1].duplicate()
	vague.nombre = 0
	vague.nombre_renforts = 0
	vague.nombre_volants = 0
	var facteurs: Array[float] = [0.8, 1.0, 1.3]
	for i: int in facteurs.size():
		var sim := DirecteurVagues.SwarmSim.new()
		directeur.facteur_pv = REGLES.difficultes_pv_ennemis[i]
		directeur.commencer(vague, [Vector2i.ZERO])
		directeur.avancer(0.0, sim)
		var attendu: float = vague.boss.pv * vague.pv_boss_facteur * vague.multiplicateur_pv * facteurs[i]
		if not is_equal_approx(sim.pv_boss().x, attendu):
			return "PV du boss incorrects à la difficulté %d." % i
	return ""


## Bâtiments débloqués par chapitre (P2-50) : peu de pièces au chapitre 1, le cumul grandit, rien d'interdit hors
## campagne ; les tirages et la boutique respectent la liste.
func test_pieces_par_chapitre() -> String:
	return _isoler(_pieces_par_chapitre)


func _pieces_par_chapitre(partie: Partie) -> String:
	var mortier: Resource = load("res://data/tuiles/tourelle_mortier.tres")
	var billes: Resource = load("res://data/tuiles/atelier_billes.tres")
	partie.preparer_chapitre(0)
	if partie.pieces_autorisees.is_empty() or partie.autorise(mortier) or partie.autorise(billes):
		return "Le chapitre 1 doit réduire le pool (pas de mortier ni de lance-billes)."
	if partie.nouveautes.is_empty():
		return "Le chapitre 1 doit annoncer ses pièces."
	partie.reinitialiser()
	for essai: int in 30:
		partie.vague_actuelle = 3 + essai % 6
		partie._tirer_offre()
		for lot in partie.offre:
			if not partie.autorise(lot.objet):
				return "Un tirage du chapitre 1 a proposé une pièce verrouillée."
	Progression.finir_chapitre(1)
	Progression.finir_chapitre(2)
	Progression.finir_chapitre(3)
	Progression.finir_chapitre(4)
	partie.preparer_chapitre(4)
	if not partie.autorise(mortier) or not partie.autorise(billes):
		return "Au chapitre 5, le cumul des déblocages doit inclure mortier et lance-billes."
	partie.choisir_depart(0)
	return "" if partie.autorise(mortier) and partie.pieces_autorisees.is_empty() else "La partie libre doit tout permettre."


## Difficile optionnel (P2-51) : ouvert seulement sur un chapitre terminé, plus de butin, aucun blocage.
func test_difficile_optionnel() -> String:
	return _isoler(_difficile)


func _difficile(partie: Partie) -> String:
	partie.preparer_chapitre(0, true)
	if partie.chapitre_difficile:
		return "Le Difficile ne doit pas s'ouvrir sur un chapitre pas encore terminé."
	Progression.finir_chapitre(1)
	partie.preparer_chapitre(0, true)
	if not partie.chapitre_difficile:
		return "Un chapitre terminé doit ouvrir son Difficile."
	partie.reinitialiser()
	if partie.chance < REGLES.chance_difficile:
		return "Le Difficile doit offrir de la chance au départ."
	for vague: int in partie.nb_vagues:
		partie.choisir_lot(0)
		partie.lancer_vague()
		partie.terminer_vague()
	if not Progression.chapitre_difficile_fini(1) or Progression.chapitres_finis() != 1:
		return "La victoire en Difficile doit être notée sans toucher à l'avancée du récit."
	partie.preparer_chapitre(1)
	return "" if not partie.chapitre_difficile and partie.chapitre == 1 else "Le chapitre suivant doit rester libre d'accès."


## Bac à sable (P2-53) : tout est en réserve, rien ne coûte, l'horloge ne perd rien et la progression ne bouge pas.
func test_bac_a_sable() -> String:
	return _isoler(_bac_a_sable)


func _bac_a_sable(partie: Partie) -> String:
	partie.preparer_bac_a_sable(0)
	partie.reinitialiser()
	if partie.reserve.quantite(&"tourelle_mortier") <= 0 or partie.reserve.quantite(&"pont") <= 0:
		return "Le bac à sable doit fournir tout le contenu."
	if not partie.depenser(9999):
		return "Le bac à sable doit avoir des ressources illimitées."
	partie.choisir_lot(0)
	partie.lancer_vague()
	partie.subir_degats(1000.0)
	if partie.pv_horloge != partie.pv_max or partie.phase != Partie.Phase.VAGUE:
		return "L'horloge du bac à sable doit être invincible."
	partie.terminer_vague()
	return "" if Progression.engrenages() == 0 else "Le bac à sable ne doit rien changer à la progression."
