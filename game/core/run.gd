extends Node
## Conserve les PV de l'horloge et publie les transitions de la partie.

const Progression = preload("res://game/core/progression.gd")
const Plateau = preload("res://game/board/plateau.gd")
const Regles = preload("res://game/core/regles.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")

const DepartDef = preload("res://game/core/depart_def.gd")
const Reserve = preload("res://game/core/reserve.gd")
const RecetteDef = preload("res://game/core/recette_def.gd")
const Lot = preload("res://game/core/lot.gd")
const Draft = preload("res://game/draft/draft.gd")
const RouteLongue = preload("res://game/core/route_longue.gd")

enum Phase { DRAFT, CONSTRUCTION, VAGUE, FIN }

var regles: Regles = preload("res://data/regles.tres")
var depart: DepartDef = regles.departs[0]
## Indice du diorama en cours, ou -1 en partie libre et en défi.
var chapitre: int = -1
var difficulte: int = 1:
	set(valeur):
		difficulte = clampi(valeur, 0, 2)
var defi_du_jour: bool = false
var _graine_defi: int
var reserve: Reserve = Reserve.new()
var offre: Array[Lot] = []
var offre_coffre: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Vagues de la partie en cours : celles des règles, ou prolongées en Longue route (PT-60).
var vagues: Array[VagueDef]:
	get:
		return _vagues_partie if not _vagues_partie.is_empty() else regles.vagues
var _vagues_partie: Array[VagueDef] = []
## Longue route choisie en partie libre (le chapitre 6 l'impose).
var longue_route: bool = false
## Extensions posées dans la partie et remise d'amélioration acquise par les paliers (PT-61).
var extensions_posees: int = 0
var remise_amelioration: float = 0.0
var nb_vagues: int:
	get:
		return vagues.size()
var pv_max: int = regles.pv_horloge
var pv_horloge: int = pv_max
var choix_par_draft: int = regles.choix_par_draft
var bonus_cadence: float = 1.0
var engrenages_gagnes: int = 0
var _rente: int
var _relance_offerte: bool
var _relance_disponible: bool
var prix_relance: int:
	get:
		return 0 if _relance_disponible else regles.prix_relance
var phase: Phase = Phase.DRAFT
var vague_actuelle: int = 0
var deplacements_pause: int = 0
## Chance (benchmark D4) : favorise les raretés des coffres. Gagnée par les vagues sans dégât, le porte-bonheur, l'Établi.
var chance: int = 0
var _porte_bonheur_achete: bool = false
var ressorts: int = regles.ressorts_depart
var ennemis_casses: int = 0
var ressorts_gagnes: int = 0
var derniere_recompense: int = 0
var vitesse: float = 1.0
## Somme des rentes des extensions posées, versée à chaque fin de vague.
var revenu_extensions: int = 0
var _pv_debut_vague: int


func _ready() -> void:
	reinitialiser()


## Crédite les ressorts reçus et les compte dans les gains de la partie.
func gagner(n: int) -> void:
	if n < 0:
		return
	ressorts += n
	ressorts_gagnes += n
	Events.ressorts_changes.emit(ressorts)


## Prélève le prix si le solde permet de le payer en entier.
func depenser(n: int) -> bool:
	if n < 0 or ressorts < n:
		return false
	ressorts -= n
	Events.ressorts_changes.emit(ressorts)
	return true


## Prix actuel d'une rotation de pièce posée : gratuite pendant la préparation (avant la vague 1), payante ensuite.
## Pourquoi : on démarre à 0 ressort ; une rotation payante dès le départ était refusée sans un mot (playtest 1 :
## « la rotation a disparu »). Avant la vague 1, on peut encore tout réorganiser librement.
var prix_rotation: int:
	get:
		return 0 if vague_actuelle == 0 else regles.prix_rotation


## Calcule le coût de la prochaine reprise depuis le lancement de la dernière vague.
var prix_deplacement: int:
	get:
		if vague_actuelle == 0:
			return 0
		return regles.prix_deplacement + regles.prix_deplacement_pas * deplacements_pause


## Calcule le prix du passage au niveau suivant, ou zéro si la pièce ne peut plus évoluer.
func prix_amelioration(plateau: Plateau, case: Vector2i) -> int:
	var piece: Plateau.PieceDef = plateau.piece_de(case)
	var niveau: int = plateau.niveau_de(case)
	if piece == null or piece.type == Plateau.PieceDef.Type.HORLOGE or niveau >= piece.niveau_max:
		return 0
	return ceili(piece.prix_amelioration * niveau * (1.0 - remise_amelioration))


## Achète un niveau pour une pièce posée pendant la construction ou la vague.
func ameliorer_piece(plateau: Plateau, case: Vector2i) -> bool:
	if phase != Phase.CONSTRUCTION and phase != Phase.VAGUE:
		return false
	var piece: Plateau.PieceDef = plateau.piece_de(case)
	if piece == null or piece.type == Plateau.PieceDef.Type.HORLOGE or plateau.niveau_de(case) >= piece.niveau_max:
		return false
	var prix: int = prix_amelioration(plateau, case)
	if ressorts < prix:
		Events.message_joueur.emit(tr("Améliorer coûte %d ressorts") % prix)
		return false
	if prix < 0:
		return false
	# Les observateurs du plateau voient déjà le solde après achat.
	ressorts -= prix
	plateau.ameliorer(case)
	Events.ressorts_changes.emit(ressorts)
	return true


## Rend une pièce posée à la réserve et paie son déplacement.
func reprendre_piece(plateau: Plateau, case: Vector2i) -> bool:
	if phase != Phase.CONSTRUCTION and phase != Phase.VAGUE:
		return false
	var piece: Plateau.PieceDef = plateau.piece_de(case)
	if piece == null or piece.type == Plateau.PieceDef.Type.HORLOGE:
		return false
	if not depenser(prix_deplacement):
		return false
	plateau.retirer(case)
	deplacements_pause += 1
	reserve.ajouter(piece, 1)
	Events.piece_reprise.emit(case, piece)
	return true


## Tourne une pièce posée (jamais l'horloge) et prélève le prix si la rotation a abouti.
func tourner_piece(plateau: Plateau, case: Vector2i) -> bool:
	var prix: int = prix_rotation
	var piece: Plateau.PieceDef = plateau.piece_de(case)
	if piece == null or piece.type == Plateau.PieceDef.Type.HORLOGE:
		return false
	if prix < 0 or ressorts < prix or not plateau.tourner(case):
		return false
	return depenser(prix)


## Ajoute des points de chance, dans la limite de `regles.chance_max`.
func ajouter_chance(n: int) -> void:
	chance = clampi(chance + n, 0, regles.chance_max)
	Events.ressorts_changes.emit(ressorts)


## Achète le porte-bonheur de la boutique (une fois par pause) : de la chance pour les prochains coffres.
func acheter_porte_bonheur() -> bool:
	if phase != Phase.CONSTRUCTION or _porte_bonheur_achete or chance >= regles.chance_max:
		return false
	if not depenser(regles.prix_porte_bonheur):
		return false
	_porte_bonheur_achete = true
	ajouter_chance(regles.chance_porte_bonheur)
	return true


## Vérifie que tous les ingrédients de la recette sont disponibles en construction.
func peut_assembler(recette: RecetteDef) -> bool:
	if phase != Phase.CONSTRUCTION or recette == null or recette not in regles.recettes:
		return false
	var besoins: Dictionary[StringName, int] = {}
	for lot: Lot in recette.entrees:
		var id: StringName = lot.objet.get("id")
		besoins[id] = besoins.get(id, 0) + lot.quantite
		if reserve.quantite(id) < besoins[id]:
			return false
	return true


## Remplace les ingrédients en réserve par le lot fabriqué.
func assembler(recette: RecetteDef) -> bool:
	if not peut_assembler(recette):
		return false
	# Les observateurs ne doivent voir que la réserve finale.
	var signaux_bloques: bool = reserve.is_blocking_signals()
	reserve.set_block_signals(true)
	for lot: Lot in recette.entrees:
		for i: int in lot.quantite:
			reserve.retirer(lot.objet.get("id"))
	reserve.ajouter(recette.sortie.objet, recette.sortie.quantite)
	reserve.set_block_signals(signaux_bloques)
	reserve.modifiee.emit()
	return true


## Renvoie le gain en ressorts pour une pièce démontable de la réserve.
func valeur_demontage(objet: Resource) -> int:
	var piece := objet as Plateau.PieceDef
	if piece != null:
		match piece.type:
			Plateau.PieceDef.Type.ENGRENAGE:
				return regles.demontage_engrenage
			Plateau.PieceDef.Type.ATELIER:
				return regles.demontage_atelier
			Plateau.PieceDef.Type.TOURELLE, Plateau.PieceDef.Type.GENERATEUR:
				return regles.demontage_tourelle
	return 0


## Démonte un exemplaire en construction et crédite ses ressorts.
func demonter(id: StringName) -> bool:
	if phase != Phase.CONSTRUCTION:
		return false
	var valeur: int = valeur_demontage(reserve.trouver(id))
	if valeur <= 0 or not reserve.retirer(id):
		return false
	gagner(valeur)
	return true


## Achète un lot disponible pour la prochaine vague et le range dans la réserve.
func acheter(i: int) -> bool:
	if phase != Phase.CONSTRUCTION or i < 0 or i >= regles.boutique.size():
		return false
	var lot: Lot = regles.boutique[i]
	if lot.vague_min > vague_actuelle + 1 or not depenser(lot.prix):
		return false
	reserve.ajouter(lot.objet, lot.quantite)
	return true


func _tirer_offre() -> void:
	offre_coffre = vague_actuelle > 0 and vague_actuelle in regles.vagues_coffre
	if offre_coffre:
		# Chaque carte a son tirage pour que la rareté compte même avec trois modèles.
		offre.clear()
		var montres: Array = []
		for i: int in choix_par_draft:
			var carte: Array[Lot] = Draft.tirer(regles.coffre, 1, vague_actuelle + 1, rng, montres, chance,
					Vector2(regles.chance_rare, regles.chance_epique))
			offre.append_array(carte)
			for lot: Lot in carte:
				montres.append(lot.objet)
	else:
		# Playtest 2 : la pioche a aussi ses raretés, et la chance agit dessus (plus seulement dans les coffres).
		offre = Draft.tirer(regles.pioche, choix_par_draft, vague_actuelle + 1, rng, [], chance,
				Vector2(regles.chance_rare, regles.chance_epique))


## Paie un nouveau tirage et présente les lots dans la même phase de draft.
func relancer_offre() -> bool:
	if phase != Phase.DRAFT or not depenser(prix_relance):
		return false
	_relance_disponible = false
	_tirer_offre()
	Events.phase_changee.emit(Phase.DRAFT)
	return true


## Répare l'horloge en construction et publie le solde une fois les PV restaurés.
func reparer_horloge() -> bool:
	if phase != Phase.CONSTRUCTION or pv_horloge >= pv_max:
		return false
	var prix: int = regles.prix_reparation
	if prix < 0 or ressorts < prix:
		return false
	pv_horloge = mini(pv_horloge + regles.pv_reparation, pv_max)
	return depenser(prix)


## Applique les gains d'une extension posée : ressorts immédiats et rente de fin de vague.
func poser_extension(ressorts_pose: int, revenu: int) -> void:
	revenu_extensions += maxi(0, revenu)
	gagner(ressorts_pose)
	extensions_posees += 1
	for palier: Resource in regles.paliers_extension:
		if palier.seuil == extensions_posees:
			_appliquer_palier(palier)


# Bonus créatif d'un palier d'extension (PT-61), annoncé au joueur.
func _appliquer_palier(palier: Resource) -> void:
	match palier.effet:
		&"choix_draft":
			choix_par_draft += int(palier.valeur)
		&"remise_amelioration":
			remise_amelioration = clampf(remise_amelioration + palier.valeur, 0.0, 0.9)
		&"chance":
			ajouter_chance(int(palier.valeur))
		&"piece":
			if palier.objet != null:
				reserve.ajouter(palier.objet, 1)
	Events.message_joueur.emit(tr("%s : %s") % [tr(palier.titre), tr(palier.description)])


## Vagues après lesquelles un tiroir s'ouvre dans cette partie (Longue route ou chapitre qui le prévoit).
func tiroirs() -> Array[int]:
	if chapitre >= 0 and not regles.chapitres[chapitre].tiroirs.is_empty():
		return regles.chapitres[chapitre].tiroirs
	return regles.tiroirs_longue_route if _longue_route_active() else ([] as Array[int])


func _longue_route_active() -> bool:
	return regles.chapitres[chapitre].longue_route if chapitre >= 0 else (longue_route and not defi_du_jour)


## Comptabilise un ennemi cassé et verse le butin de son modèle.
func casser_ennemi(def: UniteDef, position: Vector2) -> void:
	ennemis_casses += 1
	gagner(def.butin)
	Events.ennemi_casse.emit(position)


## Bascule entre le rythme normal et le rythme accéléré de la simulation.
func basculer_vitesse() -> void:
	vitesse = regles.multiplicateur_acceleration if vitesse == 1.0 else 1.0


## Ajoute le lot choisi à la réserve et ouvre la construction.
func choisir_lot(i: int) -> void:
	if phase != Phase.DRAFT or i < 0 or i >= offre.size():
		return
	var lot: Lot = offre[i]
	offre.clear()
	reserve.ajouter(lot.objet, lot.quantite)
	changer_phase(Phase.CONSTRUCTION)


## Change de phase et prévient les systèmes qui en dépendent.
func changer_phase(nouvelle: Phase) -> void:
	if nouvelle != phase:
		phase = nouvelle
		Events.phase_changee.emit(phase)


## Lance la prochaine vague après la construction.
func lancer_vague() -> void:
	if phase != Phase.CONSTRUCTION or vague_actuelle >= nb_vagues:
		return
	vague_actuelle += 1
	deplacements_pause = 0
	_porte_bonheur_achete = false
	_pv_debut_vague = pv_horloge
	changer_phase(Phase.VAGUE)
	Events.vague_commencee.emit(vague_actuelle)


## Retire les PV dus à une arrivée et annonce la défaite au dernier point perdu.
func subir_degats(d: float) -> void:
	if phase != Phase.VAGUE or d <= 0.0:
		return
	pv_horloge = maxi(0, pv_horloge - ceili(d))
	Events.horloge_touchee.emit(pv_horloge)
	if pv_horloge == 0:
		_terminer_partie(false)


## Clôt la vague, puis propose un nouveau tirage ou annonce la victoire.
func terminer_vague() -> void:
	if phase != Phase.VAGUE:
		return
	derniere_recompense = regles.recompense_vague + regles.recompense_par_vague * (vague_actuelle - 1)
	derniere_recompense += revenu_extensions + _rente
	if pv_horloge == _pv_debut_vague:
		derniere_recompense += regles.bonus_sans_degat
		ajouter_chance(regles.chance_par_vague_propre)
	gagner(derniere_recompense)
	Events.vague_terminee.emit(vague_actuelle)
	if vague_actuelle == nb_vagues:
		_terminer_partie(true)
	else:
		_relance_disponible = _relance_offerte
		_tirer_offre()
		changer_phase(Phase.DRAFT)


func _terminer_partie(victoire: bool) -> void:
	if not defi_du_jour:
		var vagues_tenues: int = vague_actuelle if victoire else maxi(0, vague_actuelle - 1)
		Progression.noter_record(depart.nom, difficulte, vagues_tenues)
		var gain: int = vagues_tenues * regles.engrenages_par_vague
		if victoire:
			gain += regles.engrenages_victoire
			if chapitre >= 0:
				Progression.finir_chapitre(regles.chapitres[chapitre].id)
		if Progression.gagner(gain):
			engrenages_gagnes = gain
	changer_phase(Phase.FIN)
	Events.run_terminee.emit(victoire)


## Sélectionne le plateau de la prochaine partie libre.
func choisir_depart(i: int) -> void:
	if i >= 0 and i < regles.departs.size():
		depart = regles.departs[i]
		chapitre = -1
		defi_du_jour = false


## Sélectionne un diorama de campagne d'après son indice dans les règles.
func preparer_chapitre(i: int) -> void:
	if i < 0 or i >= regles.chapitres.size() or i > Progression.chapitres_finis():
		return
	chapitre = i
	depart = regles.chapitres[i].depart
	difficulte = regles.chapitres[i].difficulte
	defi_du_jour = false


## Renvoie la graine commune aux parties jouées pour cette date.
func graine_du_jour(date: String) -> int:
	return hash(date)


## Sélectionne le plateau et mémorise la graine du défi pour le prochain départ.
func preparer_defi(date: String) -> void:
	chapitre = -1
	difficulte = 1
	_graine_defi = graine_du_jour(date)
	depart = regles.departs[posmod(_graine_defi, regles.departs.size())]
	defi_du_jour = true


func _bonus(effet: StringName) -> float:
	return 0.0 if defi_du_jour else Progression.bonus(effet)


## Restaure l'horloge et la réserve, puis propose les lots de la première vague.
func reinitialiser() -> void:
	if defi_du_jour:
		rng.seed = _graine_defi
		seed(_graine_defi)
	else:
		rng.randomize()
		randomize()
	vague_actuelle = 0
	deplacements_pause = 0
	_porte_bonheur_achete = false
	chance = int(_bonus(&"chance"))
	extensions_posees = 0
	remise_amelioration = 0.0
	_vagues_partie = RouteLongue.prolonger(regles.vagues, regles.vagues_longue_route) \
			if _longue_route_active() else ([] as Array[VagueDef])
	pv_max = regles.pv_horloge + regles.difficultes_pv_horloge[difficulte] + int(_bonus(&"pv_horloge"))
	pv_horloge = pv_max
	choix_par_draft = regles.choix_par_draft + int(_bonus(&"choix_draft"))
	bonus_cadence = 1.0 + _bonus(&"cadence_ateliers")
	_rente = int(_bonus(&"rente"))
	_relance_offerte = _bonus(&"relance_offerte") > 0.0
	_relance_disponible = _relance_offerte
	engrenages_gagnes = 0
	_pv_debut_vague = pv_horloge
	ressorts = regles.ressorts_depart + int(_bonus(&"ressorts_depart"))
	ennemis_casses = 0
	ressorts_gagnes = 0
	derniere_recompense = 0
	vitesse = 1.0
	revenu_extensions = 0
	reserve.vider()
	reserve.ajouter_lots(depart.reserve)
	_tirer_offre()
	phase = Phase.DRAFT
	Events.ressorts_changes.emit(ressorts)
	Events.phase_changee.emit(phase)
