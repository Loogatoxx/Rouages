extends RefCounted
## Vérifie les transactions en ressorts et les statistiques d'une partie.

const CUIRASSE = preload("res://data/unites/scarabee_cuirasse.tres")


func _commencer_vague() -> void:
	Run.choisir_lot(0)
	Run.lancer_vague()


## Observe la prime dès la fin de chaque vague, y compris avec une horloge déjà abîmée.
func test_recompense_de_vague() -> String:
	Run.reinitialiser()
	var primes: Array[int] = []
	var soldes: Array[int] = []
	var noter: Callable = func(_numero: int) -> void:
		primes.append(Run.derniere_recompense)
		soldes.append(Run.ressorts)
	Events.vague_terminee.connect(noter)
	_commencer_vague()
	Run.subir_degats(1)
	Run.terminer_vague()
	_commencer_vague()
	Run.terminer_vague()
	Run.terminer_vague()
	Events.vague_terminee.disconnect(noter)
	if primes != [6, 13] or soldes != [6, 19] or Run.ressorts_gagnes != 19:
		return "Les primes doivent être versées une fois, avec le bonus pour la deuxième vague intacte."
	return ""


## La boutique exige la construction, un indice valide et le prix du lot entier.
func test_achat_en_boutique() -> String:
	Run.reinitialiser()
	Run.choisir_lot(0)
	var id: StringName = &"engrenage_droit"
	var stock: int = Run.reserve.quantite(id)
	if Run.acheter(0) or Run.reserve.quantite(id) != stock:
		return "Un solde nul doit laisser le lot en boutique."
	Run.gagner(4)
	if Run.acheter(-1) or Run.acheter(Run.regles.boutique.size()):
		return "Un indice hors boutique doit être refusé."
	if not Run.acheter(0) or Run.reserve.quantite(id) != stock + 2 or Run.ressorts != 0:
		return "Quatre ressorts doivent acheter deux engrenages droits."
	if Run.ressorts_gagnes != 4:
		return "Une dépense doit conserver le cumul des gains."
	Run.lancer_vague()
	Run.gagner(4)
	return "" if not Run.acheter(0) and Run.ressorts == 4 else "La boutique doit fermer en vague."


## L'atelier de lance-billes devient achetable pendant la préparation de la troisième vague.
func test_vague_min_boutique() -> String:
	Run.reinitialiser()
	Run.gagner(22)
	# Indice cherché par objet : ajouter un lot en boutique ne doit pas casser le test.
	var indice: int = -1
	for i: int in Run.regles.boutique.size():
		if Run.regles.boutique[i].objet.get("id") == &"atelier_billes":
			indice = i
	if Run.acheter(indice):
		return "La boutique doit être fermée pendant le draft."
	for numero: int in [1, 2]:
		Run.choisir_lot(0)
		var solde: int = Run.ressorts
		if Run.acheter(indice) or Run.ressorts != solde:
			return "L'atelier doit rester verrouillé avant la vague %d." % numero
		Run.lancer_vague()
		Run.terminer_vague()
	Run.choisir_lot(0)
	var stock: int = Run.reserve.quantite(&"atelier_billes")
	var solde_avant: int = Run.ressorts
	if not Run.acheter(indice) or Run.ressorts != solde_avant - 22 or Run.reserve.quantite(&"atelier_billes") != stock + 1:
		return "L'atelier doit coûter 22 ressorts dès la préparation de la vague 3."
	return ""


## Une relance payée tire de nouveaux lots et les annonce pendant le draft.
func test_relance_payante() -> String:
	Run.reinitialiser()
	var offre_initiale: Array = Run.offre.duplicate()
	if Run.relancer_offre() or Run.offre != offre_initiale:
		return "Une relance sans ressorts doit conserver l'offre."
	Run.gagner(5)
	var etat: int = Run.rng.state
	var phases: Array[int] = []
	var noter: Callable = func(phase: int) -> void: phases.append(phase)
	Events.phase_changee.connect(noter)
	var acceptee: bool = Run.relancer_offre()
	Events.phase_changee.disconnect(noter)
	if not acceptee or phases != [Run.Phase.DRAFT] or Run.ressorts != 0 or Run.rng.state == etat:
		return "La relance doit coûter cinq ressorts, tirer à nouveau et annoncer le draft."
	if Run.offre.size() != Run.regles.choix_par_draft:
		return "L'offre relancée doit proposer un tirage complet."
	Run.choisir_lot(0)
	Run.gagner(5)
	return "" if not Run.relancer_offre() and Run.ressorts == 5 else "Relance acceptée hors draft."


## Le paiement annonce les PV réparés, plafonnés au maximum de l'horloge.
func test_reparation_plafonnee() -> String:
	Run.reinitialiser()
	_commencer_vague()
	Run.subir_degats(7)
	Run.gagner(20)
	if Run.reparer_horloge():
		return "La réparation doit attendre la construction."
	Run.terminer_vague()
	Run.choisir_lot(0)
	var pv_annonces: Array[int] = []
	var impacts: Array[int] = []
	var noter_solde: Callable = func(_solde: int) -> void: pv_annonces.append(Run.pv_horloge)
	var noter_impact: Callable = func(pv: int) -> void: impacts.append(pv)
	Events.ressorts_changes.connect(noter_solde)
	Events.horloge_touchee.connect(noter_impact)
	var premiere: bool = Run.reparer_horloge()
	var seconde: bool = Run.reparer_horloge()
	var intacte: bool = Run.reparer_horloge()
	Events.ressorts_changes.disconnect(noter_solde)
	Events.horloge_touchee.disconnect(noter_impact)
	if not premiere or not seconde or intacte or pv_annonces != [28, 30] or not impacts.is_empty():
		return "Les deux paiements doivent annoncer les PV restaurés sans signaler de dégât."
	return "" if Run.ressorts == 6 else "Chaque réparation effective doit coûter dix ressorts."


## Un ennemi cassé crédite son butin et annonce le lieu de sa mort.
func test_butin_et_reinitialisation() -> String:
	Run.reinitialiser()
	var lieux: Array[Vector2] = []
	var soldes: Array[int] = []
	var noter_lieu: Callable = func(position: Vector2) -> void: lieux.append(position)
	var noter_solde: Callable = func(total: int) -> void: soldes.append(total)
	Events.ennemi_casse.connect(noter_lieu)
	Events.ressorts_changes.connect(noter_solde)
	Run.casser_ennemi(CUIRASSE, Vector2.LEFT)
	var butin: int = CUIRASSE.butin
	var butin_correct: bool = Run.ressorts == butin and Run.ressorts_gagnes == butin and Run.ennemis_casses == 1
	Run.reinitialiser()
	Events.ennemi_casse.disconnect(noter_lieu)
	Events.ressorts_changes.disconnect(noter_solde)
	if not butin_correct or lieux != [Vector2.LEFT] or soldes != [butin, 0]:
		return "Le cuirassé doit rapporter son butin et annoncer sa position une fois."
	if Run.ennemis_casses != 0 or Run.ressorts_gagnes != 0 or Run.derniere_recompense != 0:
		return "Les statistiques doivent repartir de zéro."
	return ""


## La bascule alterne les deux vitesses et une nouvelle partie reprend au rythme normal.
func test_basculer_vitesse() -> String:
	Run.reinitialiser()
	Run.basculer_vitesse()
	if Run.vitesse != Run.regles.multiplicateur_acceleration:
		return "La première bascule doit accélérer la simulation."
	Run.basculer_vitesse()
	if Run.vitesse != 1.0:
		return "La deuxième bascule doit rétablir la vitesse normale."
	Run.basculer_vitesse()
	Run.reinitialiser()
	return "" if Run.vitesse == 1.0 else "La nouvelle partie doit démarrer à vitesse normale."


## Une extension posée verse ses ressorts tout de suite, puis sa rente à chaque fin de vague.
func test_rente_des_extensions() -> String:
	Run.reinitialiser()
	Run.poser_extension(15, 3)
	if Run.ressorts != 15 or Run.revenu_extensions != 3:
		return "La pose doit créditer 15 ressorts et ouvrir une rente de 3."
	_commencer_vague()
	Run.terminer_vague()
	var attendu: int = Run.regles.recompense_vague + Run.regles.bonus_sans_degat + 3
	if Run.derniere_recompense != attendu:
		return "La rente doit s'ajouter à la prime de fin de vague."
	Run.reinitialiser()
	if Run.revenu_extensions != 0:
		return "Une nouvelle partie repart sans rente."
	return ""
