extends SceneTree
## Joueur automatique (outil de Claude, pas un test) : joue une vraie partie dans la scène du jeu — tirages, boutique,
## pose des pièces, améliorations, vagues — prend des captures pendant les vagues et note les chiffres de chaque vague.
##
## Pourquoi (playtest 3) : le banc d'équilibrage ne simule ni les tirages, ni la boutique, ni le ressenti. Carlos veut
## un équilibrage « en conditions réelles » : ce script joue comme un joueur (deux styles), et les images montrent ce
## que le joueur verrait (lisibilité, effet « bordel », sensation de vide).
##
## Usage (fenêtré pour les captures) :
##   Godot --path . --windowed --resolution 1600x900 --script res://scripts/joueur_auto.gd -- --fenetre \
##         <dossier> <plateau 0-5> <style spam|tactique|moyen> [graine] [captures 0|1] [vagues_max]
## Sans fenêtre (chiffres seulement) : remplacer `--windowed ...` par `--headless` et mettre captures à 0.
## La progression de Carlos n'est jamais touchée (fichier temporaire) ; les réglages ne sont jamais enregistrés.

const DUREES_CAPTURE := [7.0, 18.0, 32.0]
const ACCELERATION := 12.0

var _dossier: String = ""
var _depart: int = 0
var _style: String = "spam"
var _graine: int = 1
var _captures: bool = true
var _vagues_max: int = 99
var _horloge: Vector2i = Vector2i.ZERO
var Plateau
var Energie
var PieceDef
var Placement


func _initialize() -> void:
	var args: Array = []
	for a: String in OS.get_cmdline_user_args():
		if a != "--fenetre":
			args.append(a)
	_dossier = args[0] if args.size() > 0 else "user://joueur_auto"
	_depart = int(args[1]) if args.size() > 1 else 0
	_style = args[2] if args.size() > 2 else "spam"
	_graine = int(args[3]) if args.size() > 3 else 1
	_captures = (args[4] != "0") if args.size() > 4 else true
	_vagues_max = int(args[5]) if args.size() > 5 else 99
	DirAccess.make_dir_recursive_absolute(_dossier)
	# Sans fenêtre, on ne regarde pas : le temps passe 12 fois plus vite. Godot multiplie le pas physique par
	# `time_scale` : on multiplie donc aussi le nombre de pas par seconde, pour garder des pas de 1/60 s (mêmes
	# résultats qu'en jeu).
	# Avec fenêtre : ×4 seulement (les captures restent des images nettes) ; variable d'environnement VITESSE pour
	# forcer une autre valeur (1 pour filmer avec --write-movie).
	var acceleration: float = ACCELERATION if DisplayServer.get_name() == "headless" else 4.0
	if OS.get_environment("VITESSE") != "":
		acceleration = float(OS.get_environment("VITESSE"))
	Engine.time_scale = acceleration
	Engine.physics_ticks_per_second = roundi(60 * acceleration)
	Engine.max_physics_steps_per_frame = 32
	_jouer.call_deferred()


func _attendre(n: int = 1) -> void:
	for i: int in n:
		await process_frame


func _jouer() -> void:
	await _attendre(2)
	Plateau = load("res://game/board/plateau.gd")
	Energie = load("res://game/board/energie.gd")
	PieceDef = load("res://game/board/piece_def.gd")
	Placement = load("res://game/workshops/placement.gd")
	var progression: GDScript = load("res://game/core/progression.gd")
	progression.chemin = _dossier.path_join("progression_temporaire.cfg")
	var graphismes: Node = root.get_node_or_null("Graphismes")
	if graphismes != null:
		graphismes._arriere_plan = false
	var run: Node = root.get_node("Run")
	run.choisir_depart(_depart)
	run.difficulte = 1
	run.reinitialiser()
	run.rng.seed = _graine
	seed(_graine)
	change_scene_to_file("res://game/main.tscn")
	await _attendre(4)
	# La fenêtre de capture n'écoute ni la souris ni le clavier : un clic de Carlos dessus fermerait une bulle
	# d'astuce, ce qui écrit dans ses réglages (arrivé le 2026-11-27).
	root.gui_disable_input = true
	var tuto: Node = current_scene.find_child("Tutoriel", true, false)
	if tuto != null:
		tuto.queue_free()  # jamais `regler_tutoriel` : il écrirait dans les réglages de Carlos
	# Les bulles d'astuce restent invisibles (les fermer écrirait dans les réglages de Carlos).
	var astuces: GDScript = load("res://game/ui/astuces.gd")
	for bulle: Node in current_scene.find_children("*", "PanelContainer", true, false):
		if bulle.get_script() == astuces:
			bulle.modulate = Color(1, 1, 1, 0)
	var noeud: Node = current_scene.get_node("PlateauNoeud")
	_horloge = run.depart.horloge
	var partie: Node = current_scene.get_node("Partie")
	var bilan: Array[String] = []
	var pv_avant: int = run.pv_horloge
	while run.phase != run.Phase.FIN and run.vague_actuelle < _vagues_max:
		match run.phase:
			run.Phase.DRAFT:
				run.choisir_lot(_choisir_lot(run))
				await _attendre(1)
			run.Phase.CONSTRUCTION:
				_acheter(run)
				_poser_reserve(run, noeud.plateau)
				_ameliorer(run, noeud.plateau)
				if run.depart.maree and _style == "tactique":
					_suivre_la_maree(run, noeud.plateau, partie)
				await _attendre(2)
				if _captures and run.vague_actuelle in [0, 4, 9]:
					await _capturer("V%02d_pause" % (run.vague_actuelle + 1))
				if OS.get_environment("CARTE") == "1":
					_imprimer_carte(noeud)
				pv_avant = run.pv_horloge
				run.vitesse = 1.0
				run.lancer_vague()
				var t: float = 0.0
				var allies_max: int = 0
				var ennemis_max: int = 0
				var prochaines: Array = DUREES_CAPTURE.duplicate()
				var numero: int = run.vague_actuelle
				while run.phase == run.Phase.VAGUE:
					await physics_frame
					t += 1.0 / 60.0
					allies_max = maxi(allies_max, partie.sim.nombre(0))
					# TRACE=<numéro de vague> : toutes les 5 s, effectifs et cases des ennemis (pour comprendre une vague lente).
					if OS.get_environment("TRACE") == str(numero) and fmod(t, 5.0) < 1.0 / 60.0:
						var cases: Dictionary = {}
						for lieu: Vector2 in partie.sim.positions(1):
							var c := Vector2i((lieu / 2.0).round())
							cases[c] = cases.get(c, 0) + 1
						var pv: Array = []
						for k: int in mini(4, partie.sim.positions(1).size()):
							pv.append(int(partie.sim._camps[1].vies[k]))
						print("    t=%3d s  jouets %2d  ennemis %2d  restants %2d  cases %s  pv %s" % [int(t), partie.sim.nombre(0),
								partie.sim.nombre(1), partie.directeur.restants(partie.sim), cases, pv])
					if _style == "tactique" and partie.carillon_attente <= 0.0:
						_sonner_si_utile(partie, noeud.plateau)
					ennemis_max = maxi(ennemis_max, partie.sim.nombre(1))
					if _captures and not prochaines.is_empty() and t >= prochaines[0] and numero in [1, 3, 5, 8, 9, 10]:
						await _capturer("V%02d_%02ds" % [numero, int(prochaines[0])])
						prochaines.pop_front()
					if t > 400.0:
						break
				# Composition alimentée (S soldats, B lance-billes, C canon, K carillon, M mortier) et somme des niveaux.
				var sigles: Dictionary = {&"atelier_soldats": "S", &"atelier_billes": "B", &"tourelle_canon": "C",
						&"tourelle_carillon": "K", &"tourelle_mortier": "M"}
				var compo: Dictionary = {}
				var niveaux: int = 0
				for c: Vector2i in noeud.plateau.coords_pieces():
					var p: Resource = noeud.plateau.piece_de(c)
					if p.consomme() and noeud.alimentees.has(c):
						var sigle: String = sigles.get(p.id, "?")
						compo[sigle] = compo.get(sigle, 0) + 1
						niveaux += noeud.plateau.niveau_de(c)
				var texte_compo: String = ""
				for sigle: String in compo:
					texte_compo += "%s%d " % [sigle, compo[sigle]]
				var en_reserve: String = ""
				for id: StringName in run.reserve.ids():
					en_reserve += "%s×%d " % [String(id).replace("engrenage_", "e_").replace("atelier_", "a_").replace("tourelle_", "t_"), run.reserve.quantite(id)]
				bilan.append("V%d : -%d PV, %d s, jouets max %d, ennemis max %d, %sniv %d, dents %d/%d, %d ressorts, réserve [%s]" % [numero,
						pv_avant - run.pv_horloge, int(t), allies_max, ennemis_max, texte_compo, niveaux,
						noeud.charge_horloge, noeud.dents, run.ressorts, en_reserve.strip_edges()])
			_:
				await _attendre(1)
	var resultat: String = "victoire" if run.pv_horloge > 0 else "défaite"
	var texte: String = "Plateau %d (%s), style %s, graine %d : %s, %d PV restants\n  %s" % [_depart, run.depart.nom,
			_style, _graine, resultat, run.pv_horloge, "\n  ".join(bilan)]
	print(texte)
	var f := FileAccess.open(_dossier.path_join("bilan_%d_%s_%d.txt" % [_depart, _style, _graine]), FileAccess.WRITE)
	f.store_string(texte + "\n")
	f.close()
	quit(0)


# « tactique » fait sonner le carillon sur le poste de garde où se pressent le plus d'ennemis (au moins 4).
func _sonner_si_utile(partie: Node, plateau) -> void:
	var rayon: float = root.get_node("Run").regles.carillon_rayon
	var ennemis: PackedVector2Array = partie.sim.positions(1)
	var meilleur: Vector2 = Vector2.INF
	var compte_max: int = 3
	for c: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(c).type != PieceDef.Type.ATELIER:
			continue
		var poste: Vector2 = partie.sim.poste(c)
		if poste == Vector2.INF:
			continue
		var compte: int = 0
		for lieu: Vector2 in ennemis:
			if lieu.distance_squared_to(poste) <= rayon * rayon:
				compte += 1
		if compte > compte_max:
			compte_max = compte
			meilleur = poste
	if meilleur != Vector2.INF:
		partie.sonner_carillon(meilleur)


# Plan du plateau en caractères (variable d'environnement CARTE=1) : # route, . herbe, H horloge, lettres = pièces
# (majuscule = alimentée) : S soldats, B billes, C canon, K carillon, M mortier, G générateur, + engrenage.
func _imprimer_carte(noeud: Node) -> void:
	var plateau = noeud.plateau
	var mini := Vector2i(999, 999)
	var maxi := Vector2i(-999, -999)
	for c: Vector2i in plateau.coords_sols():
		mini = mini.min(c)
		maxi = maxi.max(c)
	var sigles: Dictionary = {&"atelier_soldats": "s", &"atelier_billes": "b", &"tourelle_canon": "c",
			&"tourelle_carillon": "k", &"tourelle_mortier": "m", &"generateur": "g", &"horloge": "h", &"pont": "p"}
	for y: int in range(mini.y, maxi.y + 1):
		var ligne: String = ""
		for x: int in range(mini.x, maxi.x + 1):
			var c := Vector2i(x, y)
			var piece: Resource = plateau.piece_de(c)
			if piece != null:
				var sigle: String = sigles.get(piece.id, "+")
				ligne += sigle.to_upper() if noeud.alimentees.has(c) and sigle != "+" else ("+" if noeud.alimentees.has(c) else ("-" if sigle == "+" else sigle))
			elif plateau.sol_de(c) == Plateau.Sol.CHEMIN:
				ligne += "#"
			elif plateau.a_sol(c):
				ligne += "."
			else:
				ligne += " "
		print("    ", ligne)
	var drapeaux: String = ""
	for c: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(c).type == PieceDef.Type.ATELIER:
			drapeaux += "%s→%s " % [c, current_scene.get_node("Partie").sim.poste(c) / 2.0]
	print("    --- vague ", root.get_node("Run").vague_actuelle + 1, "  postes : ", drapeaux)


func _capturer(nom: String) -> void:
	# Les bulles d'astuce sont masquées le temps de la photo (les fermer écrirait dans les réglages de Carlos).
	var astuces: GDScript = load("res://game/ui/astuces.gd")
	for bulle: Node in current_scene.find_children("*", "PanelContainer", true, false):
		if bulle.get_script() == astuces:
			bulle.visible = false
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(_dossier.path_join("%d_%s_%s.png" % [_depart, _style, nom]))


# --- Décisions du joueur automatique (playtest 3, énergie comptée) ---
# « spam »     : la mono-stratégie d'avant — rien que des ateliers de soldats, puis des améliorations d'ateliers.
# « tactique » : compose (soldats, canon, lance-billes, carillon…), améliore tout, soigne ses placements.
# « moyen »    : mêmes envies que « tactique », mais place au petit bonheur et n'améliore qu'au niveau 2.
const ENVIES := [&"atelier_soldats", &"atelier_soldats", &"tourelle_canon", &"tourelle_canon", &"tourelle_carillon",
		&"tourelle_mortier", &"tourelle_canon", &"atelier_billes", &"atelier_soldats"]


# « masse » : soldats et lance-billes seulement, sans tourelle (la quantité avec le minimum de variété).
const ENVIES_MASSE := [&"atelier_soldats", &"atelier_soldats", &"atelier_billes", &"atelier_soldats", &"atelier_billes"]


# Nombre d'exemplaires d'une pièce (posés + en réserve).
func _possedes(run: Node, id: StringName) -> int:
	var total: int = run.reserve.quantite(id)
	var plateau = current_scene.get_node("PlateauNoeud").plateau
	for c: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(c).id == id:
			total += 1
	return total


# Dents encore libres sur l'Horloge (bâtiments posés seulement : ceux de la réserve ne sont pas un engagement).
func _dents_libres(run: Node) -> int:
	if run.dents < 0:
		return 99
	var plateau = current_scene.get_node("PlateauNoeud").plateau
	return run.dents - Energie.analyser(plateau, run.dents).charge_horloge


# Le style accepte-t-il de poser cette pièce ? (« spam » : ateliers de soldats seulement ; « masse » : pas de tourelle.)
func _style_accepte(objet: Resource) -> bool:
	if _style == "spam":
		return objet.id == &"atelier_soldats"
	if _style == "masse":
		return objet.type == PieceDef.Type.ATELIER
	return true


# Vrai tant que le style « tactique » garde deux dents pour son premier atelier de lance-billes.
func _attend_billes(_run: Node) -> bool:
	return false  # abandonné : avec les postes de garde, deux canons répondent aux libellules aussi bien


# Prochain bâtiment voulu (identifiant), ou &"" si rien ne rentre dans les dents libres.
func _envie(run: Node) -> StringName:
	var libres: int = _dents_libres(run)
	if _style == "spam":
		return &"atelier_soldats" if libres >= 2 else &""
	# Un joueur attentif garde deux dents pour l'atelier de lance-billes avant les libellules de la vague 6.
	var attend_billes: bool = _attend_billes(run)
	var comptes: Dictionary = {}
	for id: StringName in (ENVIES_MASSE if _style == "masse" else ENVIES):
		comptes[id] = comptes.get(id, 0) + 1
		if _possedes(run, id) >= comptes[id]:
			continue
		if id == &"atelier_billes" and run.vague_actuelle < 2:
			continue  # en boutique à partir de la préparation de la vague 3
		var piece: Resource = _piece(run, id)
		if piece == null or not run.autorise(piece):
			continue
		if attend_billes and id != &"atelier_billes" and libres - piece.cout_energie < 2:
			continue
		if piece.cout_energie <= libres:
			return id
	return &""


func _piece(run: Node, id: StringName) -> Resource:
	for lots: Array in [run.regles.boutique, run.regles.pioche, run.regles.coffre]:
		for lot: Resource in lots:
			if lot.objet is PieceDef and lot.objet.id == id:
				return lot.objet
	return null


func _choisir_lot(run: Node) -> int:
	var meilleur: int = 0
	var score_max: float = -INF
	var envie: StringName = _envie(run)
	var libres: int = _dents_libres(run)
	for i: int in run.offre.size():
		var objet: Resource = run.offre[i].objet
		var score: float = -5.0  # extensions : le joueur automatique ne les pose pas
		if objet is PieceDef:
			if objet.sur_route:
				score = 1.0
			elif objet.type == PieceDef.Type.GENERATEUR:
				score = 9.0 if _style != "spam" else 1.0
			elif objet.type == PieceDef.Type.ENGRENAGE:
				score = 4.0 + objet.rarete
			elif objet.id == envie:
				score = 10.0
			elif objet.cout_energie <= libres and (_style != "spam" or objet.id == &"atelier_soldats") \
					and (_style != "masse" or objet.type == PieceDef.Type.ATELIER):
				score = 6.0 + objet.rarete
			else:
				score = 1.5  # pas de dents pour lui : il resterait éteint
		score += run.offre[i].quantite * 0.5
		if score > score_max:
			score_max = score
			meilleur = i
	return meilleur


func _acheter(run: Node) -> void:
	var boutique: Array = run.regles.boutique
	for essai: int in 4:
		var envie: StringName = _envie(run)
		# Rien à acheter, ou un bâtiment attend déjà une prise : d'abord le poser.
		if envie == &"" or _batiment_en_attente(run):
			break
		var achete: bool = false
		for i: int in boutique.size():
			# On garde de quoi acheter l'engrenage qui reliera ce bâtiment.
			if boutique[i].objet is PieceDef and boutique[i].objet.id == envie \
					and run.ressorts >= boutique[i].prix + 7 and run.acheter(i):
				achete = true
				break
		if not achete:
			break


# Bâtiments de la réserve que le style veut poser maintenant, dans l'ordre de priorité (lance-billes d'abord tant
# qu'on les attend), en respectant les dents libres et la place gardée pour les lance-billes.
func _batiments_a_poser(run: Node, plateau) -> Array[StringName]:
	var libres: int = _dents_libres(run)
	var attend: bool = _attend_billes(run)
	var billes_poses: bool = false
	for c: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(c).id == &"atelier_billes":
			billes_poses = true
	var resultat: Array[StringName] = []
	for id: StringName in run.reserve.ids():
		var objet: Resource = run.reserve.trouver(id)
		if not objet is PieceDef or objet.sur_route or objet.type == PieceDef.Type.ENGRENAGE or not _style_accepte(objet):
			continue
		if objet.type == PieceDef.Type.GENERATEUR:
			resultat.append(id)
			continue
		if objet.cout_energie > libres and not _generateur_pose(plateau):
			continue
		if attend and not billes_poses and id != &"atelier_billes" and libres - objet.cout_energie < 2:
			continue
		if id == &"atelier_billes":
			resultat.push_front(id)
		else:
			resultat.append(id)
	return resultat


func _generateur_pose(plateau) -> bool:
	for c: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(c).type == PieceDef.Type.GENERATEUR:
			return true
	return false


# Vrai si un bâtiment voulu attend encore dans la réserve faute de prise d'engrenage (et non faute de dents).
func _batiment_en_attente(run: Node) -> bool:
	return not _batiments_a_poser(run, current_scene.get_node("PlateauNoeud").plateau).is_empty()


# Achète un engrenage à plusieurs sorties (T, sinon croix) pour ouvrir des prises, comme le ferait un joueur.
func _acheter_engrenage(run: Node) -> bool:
	var boutique: Array = run.regles.boutique
	# Un engrenage à plusieurs sorties attend déjà sans trouver de place : en racheter n'y changerait rien.
	if run.reserve.quantite(&"engrenage_t") > 0 or run.reserve.quantite(&"engrenage_croix") > 0:
		return false
	for voulu: StringName in [&"engrenage_t", &"engrenage_croix"]:
		for i: int in boutique.size():
			if boutique[i].objet is PieceDef and boutique[i].objet.id == voulu and run.acheter(i):
				return true
	return false


# Améliorations : la moins chère d'abord. « spam » n'améliore que ses ateliers ; « moyen » s'arrête au niveau 2.
# On garde de côté le prix du prochain bâtiment voulu s'il rentre dans les dents.
func _ameliorer(run: Node, plateau) -> void:
	var garde: int = 0
	var envie: StringName = _envie(run)
	# Un joueur attentif économise pour l'atelier de lance-billes avant les libellules de la vague 6.
	if _style == "masse" and run.vague_actuelle >= 2 and _possedes(run, &"atelier_billes") == 0:
		envie = &"atelier_billes"
	if envie != &"":
		for lot: Resource in run.regles.boutique:
			if lot.objet is PieceDef and lot.objet.id == envie:
				garde = lot.prix + 7
	var al: Dictionary = Energie.calculer(plateau, run.dents)
	for essai: int in 12:
		var cible: Vector2i = Vector2i(9999, 9999)
		var prix_min: int = 999999
		for c: Vector2i in plateau.coords_pieces():
			var p: Resource = plateau.piece_de(c)
			if not al.has(c) or not p.consomme():
				continue
			if _style in ["spam", "masse"] and p.type != PieceDef.Type.ATELIER:
				continue
			if _style == "moyen" and plateau.niveau_de(c) >= 2:
				continue
			var prix: int = run.prix_amelioration(plateau, c)
			if prix > 0 and prix < prix_min:
				prix_min = prix
				cible = c
		if cible.x == 9999 or run.ressorts < prix_min + garde or not run.ameliorer_piece(plateau, cible):
			return


# Pose ce qui doit l'être, comme un joueur attentif :
# 1. pour chaque bâtiment voulu, il repère la meilleure case du plateau (alimentée ou non) ;
# 2. si une case alimentée fait presque aussi bien, il pose le bâtiment ; sinon il prolonge son réseau d'un
#    engrenage en croix vers la bonne case (croix fabriquée avec deux engrenages droits, ou achetée) ;
# 3. (« tactique ») les engrenages restants vont là où ils donnent un bonus à un bâtiment voisin.
func _poser_reserve(run: Node, plateau) -> void:
	for passe: int in 60:
		var pose: bool = false
		for id: StringName in _batiments_a_poser(run, plateau):
			var objet: Resource = run.reserve.trouver(id)
			var ideal: Array = _case_ideale(plateau, objet, run.dents)
			var choix: Array = _meilleure_place(plateau, objet, true, run.dents)
			if not choix.is_empty() and (ideal.is_empty() or choix[2] >= ideal[1] - 3.0):
				pose = plateau.poser(choix[0], objet, choix[1])
			elif not ideal.is_empty() and _relier(run, plateau, ideal[0]):
				pose = true
				break
			elif not choix.is_empty():
				pose = plateau.poser(choix[0], objet, choix[1])
			if pose:
				run.reserve.retirer(id)
				_planter_drapeaux(plateau)
				break
		if not pose and _style == "tactique":
			pose = _poser_engrenage(run, plateau, true, _prises_libres(plateau, Energie.calculer(plateau, run.dents)))
		if not pose:
			if OS.get_environment("CARTE") == "1":
				for id: StringName in _batiments_a_poser(run, plateau):
					var objet: Resource = run.reserve.trouver(id)
					print("    non posé : ", id, " idéal ", _case_ideale(plateau, objet, run.dents), " alimenté ",
							_meilleure_place(plateau, objet, true, run.dents), " sans garde ",
							_meilleure_place(plateau, objet, false, run.dents))
			return


# Carte à marée : avant chaque vague, « tactique » replante chaque fanion sur la route par où la vague arrivera
# (la case à portée la plus éloignée de l'Horloge sur ce trajet : on se bat le plus loin possible).
func _suivre_la_maree(run: Node, plateau, partie: Node) -> void:
	var ChampFlux: GDScript = load("res://game/swarm/champ_flux.gd")
	var distances: Dictionary = ChampFlux.calculer(plateau)
	var trajet: Dictionary = {}
	for entree: Vector2i in partie.entrees_de_la_vague(run.vague_actuelle + 1):
		var case: Vector2i = entree
		var garde_fou: int = 0
		while distances.get(case, 0) > 0 and garde_fou < 300:
			trajet[case] = true
			var suivante: Vector2i = case
			for d: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				if distances.get(case + d, 99999) < distances[suivante]:
					suivante = case + d
			if suivante == case:
				break
			case = suivante
			garde_fou += 1
	for a: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(a).type != PieceDef.Type.ATELIER:
			continue
		var meilleur: Vector2i = Vector2i(9999, 9999)
		for route: Vector2i in trajet:
			if plateau.poste_possible(a, route) and distances[route] >= 2 \
					and (meilleur.x == 9999 or distances[route] > distances[meilleur]):
				meilleur = route
		if meilleur.x != 9999:
			plateau.definir_poste(a, meilleur)


# « tactique » déplace le drapeau de chaque atelier vers la case de route la plus passante à sa portée.
func _planter_drapeaux(plateau) -> void:
	if _style != "tactique":
		return
	var passage: Dictionary = _passages(plateau)
	var trajets: Array = _trajets(plateau)
	var postes: Array[Vector2i] = []
	for a: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(a).type == PieceDef.Type.ATELIER and plateau.poste_de(a) != plateau.SANS_POSTE:
			postes.append(plateau.poste_de(a))
	for a: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(a).type == PieceDef.Type.ATELIER and plateau.poste_de(a) == plateau.SANS_POSTE:
			var poste: Vector2i = _poste_probable(plateau, a, passage, trajets, postes)
			if poste.x != 9999 and plateau.definir_poste(a, poste):
				postes.append(poste)


# Meilleure case pour ce bâtiment parmi celles que le réseau de l'Horloge peut atteindre en posant des engrenages
# (l'herbe de l'autre côté d'une route n'en fait pas partie) : [case, score] ou [].
func _case_ideale(plateau, piece, dents: int = -1) -> Array:
	if piece.type == PieceDef.Type.GENERATEUR:
		return []
	var contexte: Dictionary = _contexte(plateau)
	var meilleure: Array = []
	for c: Vector2i in _atteignables(plateau, dents):
		if not plateau.peut_poser(c, piece):
			continue
		var score: float = _score_case(plateau, piece, c, contexte)
		if score > -INF and (meilleure.is_empty() or score > meilleure[1]):
			meilleure = [c, score]
	return meilleure


# Cases d'herbe libres que le réseau de l'Horloge peut atteindre : case → prise de départ (la case libre devant un
# port ouvert d'une pièce qui tourne) par laquelle on y arrive au plus court.
func _atteignables(plateau, dents: int) -> Dictionary:
	var croix: Resource = load("res://data/tuiles/engrenage_croix.tres")
	var al: Dictionary = Energie.calculer(plateau, dents)
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var origines: Dictionary = {}
	var file: Array[Vector2i] = []
	for c: Vector2i in al:
		var p: Resource = plateau.piece_de(c)
		if p == null or not p.transmet or Energie.energie_faible(al, c):
			continue
		var ports: int = plateau.ports_de(c)
		for d: int in 4:
			var v: Vector2i = c + directions[d]
			if ports & (1 << d) and plateau.peut_poser(v, croix) and not origines.has(v):
				origines[v] = v
				file.append(v)
	var tete: int = 0
	while tete < file.size():
		var case: Vector2i = file[tete]
		tete += 1
		for d: Vector2i in directions:
			var v: Vector2i = case + d
			if not origines.has(v) and plateau.peut_poser(v, croix):
				origines[v] = origines[case]
				file.append(v)
	return origines


# Prolonge le réseau de l'Horloge d'un engrenage en croix vers `cible` (une case d'herbe libre). Vrai si posé.
func _relier(run: Node, plateau, cible: Vector2i) -> bool:
	var croix: Resource = load("res://data/tuiles/engrenage_croix.tres")
	var origines: Dictionary = _atteignables(plateau, run.dents)
	# La prise de départ du plus court chemin vers une voisine de la cible (ou vers la cible elle-même si elle est
	# déjà une prise : l'engrenage s'y pose, et le bâtiment ira juste à côté).
	var depart: Vector2i = Vector2i(9999, 9999)
	if origines.get(cible, Vector2i(9999, 9999)) == cible:
		depart = cible
	else:
		for d: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if origines.has(cible + d) and depart.x == 9999:
				depart = origines[cible + d]
	if depart.x == 9999 or not _obtenir_croix(run):
		return false
	if plateau.poser(depart, croix, 0):
		run.reserve.retirer(&"engrenage_croix")
		return true
	return false


# S'assure d'avoir un engrenage en croix en réserve : déjà là, fabriqué (2 engrenages droits) ou acheté.
func _obtenir_croix(run: Node) -> bool:
	if run.reserve.quantite(&"engrenage_croix") > 0:
		return true
	for recette: Resource in run.regles.recettes:
		if recette.id == &"engrenage_croix" and run.assembler(recette):
			return true
	for i: int in run.regles.boutique.size():
		var objet: Resource = run.regles.boutique[i].objet
		if objet is PieceDef and objet.id == &"engrenage_croix" and run.acheter(i):
			return true
	return false


# Pose le meilleur engrenage de la réserve. `pour_bonus` faux : celui qui ouvre le plus de prises (gain strict) ;
# vrai : celui qui donne le plus de bonus à des bâtiments voisins alimentés, sans fermer la dernière prise.
func _poser_engrenage(run: Node, plateau, pour_bonus: bool, prises_avant: float) -> bool:
	var meilleur: Array = []
	var score_max: float = 0.0
	for id: StringName in run.reserve.ids():
		var piece: Resource = run.reserve.trouver(id)
		if not piece is PieceDef or piece.type != PieceDef.Type.ENGRENAGE:
			continue
		for c: Vector2i in plateau.coords_sols():
			if not plateau.peut_poser(c, piece):
				continue
			for r: int in 4:
				if r > 0 and piece.ports == 15:
					break
				var copie = plateau.dupliquer()
				copie.poser(c, piece, r)
				var al: Dictionary = Energie.calculer(copie, run.dents)
				if not al.has(c) or Energie.energie_faible(al, c):
					continue
				var prises: float = _prises_libres(copie, al)
				# Gain en valeur de prises : un engrenage est utile s'il ouvre des prises ou les rapproche de la route.
				var score: float = prises - prises_avant
				if score < 0.15:
					score = 0.0
				if pour_bonus:
					if prises < 1.0:
						continue
					score = 0.0
					for d: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
						var voisin: Resource = copie.piece_de(c + d)
						if voisin == null or not al.has(c + d):
							continue
						if voisin.type == PieceDef.Type.ATELIER and (piece.bonus_voisins_cadence > 0.0 or piece.bonus_voisins_plafond > 0):
							score += 1.0
						elif voisin.type == PieceDef.Type.TOURELLE and piece.bonus_voisins_tourelle > 0.0:
							score += 1.0
				if score > score_max:
					score_max = score
					meilleur = [id, c, r]
	if meilleur.is_empty():
		return false
	if plateau.poser(meilleur[1], run.reserve.trouver(meilleur[0]), meilleur[2]):
		run.reserve.retirer(meilleur[0])
		return true
	return false


# Ce qu'il faut savoir du plateau pour noter une case : routes, postes de garde probables, passages des entrées.
func _contexte(plateau) -> Dictionary:
	var routes: Array[Vector2i] = []
	for s: Vector2i in plateau.coords_sols():
		if plateau.sol_de(s) == Plateau.Sol.CHEMIN:
			routes.append(s)
	# Postes de garde probables de chaque atelier posé (là où l'on se battra).
	var passage: Dictionary = _passages(plateau)
	var trajets: Array = _trajets(plateau)
	var postes: Array[Vector2i] = []
	for a: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(a).type == PieceDef.Type.ATELIER:
			var poste: Vector2i = _poste_probable(plateau, a, passage, trajets, postes)
			if poste.x != 9999:
				postes.append(poste)
	return {"routes": routes, "postes": postes, "passage": passage, "trajets": trajets}


# Poste de garde qu'aurait un atelier posé sur `c` : le drapeau choisi s'il y en a un ; sinon, pour « tactique »,
# la case de route à portée de drapeau qui couvre le plus d'entrées pas encore gardées (puis la plus passante,
# pas collée à l'Horloge) ; pour les autres styles, la route voisine la plus passante (le poste par défaut du jeu).
func _poste_probable(plateau, c: Vector2i, passage: Dictionary, trajets: Array = [], postes: Array[Vector2i] = []) -> Vector2i:
	if plateau.poste_de(c) != plateau.SANS_POSTE:
		return plateau.poste_de(c)
	var meilleur: Vector2i = Vector2i(9999, 9999)
	var note_max: float = -INF
	var portee: int = plateau.PORTEE_POSTE if _style == "tactique" else 1
	for dx: int in range(-portee, portee + 1):
		for dy: int in range(-portee, portee + 1):
			var route: Vector2i = c + Vector2i(dx, dy)
			if absi(dx) + absi(dy) > portee or absi(dx) + absi(dy) == 0 or plateau.sol_de(route) != Plateau.Sol.CHEMIN:
				continue
			var note: float = passage.get(route, 0.0) * 4.0 - (absi(dx) + absi(dy)) * 0.5
			# Un joueur attentif ne plante pas son fanion sur la voie du train (carte « Le Rail »).
			if portee > 1 and route in root.get_node("Run").depart.rail:
				note -= 20.0
			if portee > 1:
				# Entrées que ce drapeau serait le premier à garder.
				for trajet: Dictionary in trajets:
					if not trajet.has(route):
						continue
					var deja: bool = false
					for poste: Vector2i in postes:
						if trajet.has(poste):
							deja = true
					if not deja:
						note += 10.0
				# Collé à l'Horloge : un ennemi qui se faufile n'aurait plus qu'un pas à faire.
				if absi(route.x - _horloge.x) + absi(route.y - _horloge.y) < 2:
					note -= 6.0
			if note > note_max:
				note_max = note
				meilleur = route
	return meilleur


# Cases de route parcourues depuis chaque entrée jusqu'à l'Horloge (un dictionnaire de cases par entrée).
func _trajets(plateau) -> Array:
	var ChampFlux: GDScript = load("res://game/swarm/champ_flux.gd")
	var distances: Dictionary = ChampFlux.calculer(plateau)
	var resultat: Array = []
	for entree: Vector2i in ChampFlux.entrees(plateau, distances):
		var trajet: Dictionary = {}
		var case: Vector2i = entree
		var garde_fou: int = 0
		while distances.get(case, 0) > 0 and garde_fou < 300:
			trajet[case] = true
			var suivante: Vector2i = case
			for d: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				if distances.get(case + d, 99999) < distances[suivante]:
					suivante = case + d
			if suivante == case:
				break
			case = suivante
			garde_fou += 1
		resultat.append(trajet)
	return resultat


# Note d'une case pour un bâtiment (sans regarder l'énergie) ; -INF si la case ne convient pas.
func _score_case(plateau, piece, c: Vector2i, contexte: Dictionary) -> float:
	var score: float = -INF
	var postes: Array[Vector2i] = contexte["postes"]
	match piece.type:
		PieceDef.Type.ATELIER:
			# Un atelier se pose au bord de la route : son escouade tient la route devant lui, là où tout passe.
			if Placement.cote_route(plateau, c) == Vector2i.ZERO:
				return -INF
			var mon_poste: Vector2i = _poste_probable(plateau, c, contexte["passage"], contexte["trajets"], postes)
			score = 10.0 + 8.0 * contexte["passage"].get(mon_poste, 0.0)
			if root.get_node("Run").depart.maree and _style == "tactique":
				# Carte à marée : l'atelier idéal peut planter son fanion sur chacune des routes, à tour de rôle.
				for trajet: Dictionary in contexte["trajets"]:
					for route: Vector2i in trajet:
						if plateau.poste_possible(c, route) and absi(route.x - _horloge.x) + absi(route.y - _horloge.y) >= 2:
							score += 14.0
							break
			# Une entrée de plus gardée vaut plus que tout le reste.
			for trajet: Dictionary in contexte["trajets"]:
				if trajet.has(mon_poste):
					var deja: bool = false
					for poste: Vector2i in postes:
						if trajet.has(poste):
							deja = true
					if not deja:
						score += 12.0
			if piece.unite_produite != null and piece.unite_produite.portee >= 1.0:
				# Les tireurs se rangent sur un poste déjà tenu par des soldats, ou juste à côté.
				for poste: Vector2i in postes:
					if absi(poste.x - mon_poste.x) + absi(poste.y - mon_poste.y) <= 1:
						score += 4.0
			elif postes.has(mon_poste):
				score -= 2.0  # deux escouades de soldats sur la même case se gênent : on étale un peu la ligne
		PieceDef.Type.TOURELLE:
			# Une tourelle doit couvrir la route, et d'abord les postes de garde (la zone de tir).
			var couvertes: int = 0
			for s: Vector2i in contexte["routes"]:
				if Vector2(s - c).length() * 2.0 <= piece.portee_tir:
					couvertes += 1
			if couvertes < 2:
				return -INF
			score = couvertes * 0.5
			for poste: Vector2i in postes:
				if Vector2(poste - c).length() * 2.0 <= piece.portee_tir:
					score += 6.0
			if Placement.cote_route(plateau, c) != Vector2i.ZERO:
				score += 2.0
		PieceDef.Type.GENERATEUR:
			score = 5.0 if Placement.cote_route(plateau, c) != Vector2i.ZERO else 0.0
	score -= Vector2(c).length() * 0.05
	if _style == "moyen" and score > -INF:
		score += randf() * 8.0  # un joueur moyen ne trouve pas toujours la meilleure case
	return score


# Meilleure place ALIMENTÉE pour une pièce : [case, rotation, score] ou [].
# `garder_prise` : refuse une place qui boucherait la dernière prise libre du réseau.
func _meilleure_place(plateau, piece, garder_prise: bool = false, dents: int = -1) -> Array:
	var meilleur: Array = []
	var contexte: Dictionary = _contexte(plateau)
	for c: Vector2i in plateau.coords_sols():
		if not plateau.peut_poser(c, piece):
			continue
		var score: float = _score_case(plateau, piece, c, contexte)
		if score == -INF:
			continue
		for r: int in 4:
			if piece.type != PieceDef.Type.GENERATEUR and r > 0 and piece.ports == 15:
				break
			var copie = plateau.dupliquer()
			copie.poser(c, piece, r)
			var al: Dictionary = Energie.calculer(copie, dents)
			if piece.type == PieceDef.Type.GENERATEUR:
				if al.has(c) and not Energie.energie_faible(al, c):
					continue  # relié à l'Horloge, il ne servirait à rien
			elif not al.has(c):
				continue
			elif garder_prise and _prises_libres(copie, al, false) < 1.0:
				continue
			if meilleur.is_empty() or score > meilleur[2]:
				meilleur = [c, r, score]
	return meilleur


# Pour chaque case de route : part des entrées (0 à 1) dont le plus court trajet vers l'horloge y passe.
func _passages(plateau) -> Dictionary:
	var ChampFlux: GDScript = load("res://game/swarm/champ_flux.gd")
	var distances: Dictionary = ChampFlux.calculer(plateau)
	var entrees: Array = ChampFlux.entrees(plateau, distances)
	var passage: Dictionary = {}
	for entree: Vector2i in entrees:
		var case: Vector2i = entree
		var garde_fou: int = 0
		while distances.get(case, 0) > 0 and garde_fou < 300:
			passage[case] = passage.get(case, 0.0) + 1.0 / entrees.size()
			var suivante: Vector2i = case
			for d: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				if distances.get(case + d, 99999) < distances[suivante]:
					suivante = case + d
			if suivante == case:
				break
			case = suivante
			garde_fou += 1
	return passage


# Cases d'herbe libres où un consommateur posé serait alimenté (une prise d'engrenage ouverte y mène), bord de route ×2.
func _prises_libres(plateau, al: Dictionary, pondere: bool = true) -> float:
	var total: float = 0.0
	var vues: Dictionary = {}
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for c: Vector2i in al:
		var p: Resource = plateau.piece_de(c)
		# Seules comptent les prises du réseau de l'Horloge : celles d'un générateur ne font pas tourner d'engrenage.
		if p == null or not p.transmet or Energie.energie_faible(al, c):
			continue
		var ports: int = plateau.ports_de(c)
		for d: int in 4:
			var v: Vector2i = c + directions[d]
			if ports & (1 << d) and plateau.sol_de(v) == Plateau.Sol.HERBE and plateau.piece_de(v) == null \
					and not vues.has(v):
				vues[v] = true
				# Une prise vaut par sa place : 2 au bord de la route, 1 à deux cases, presque rien plus loin.
				if not pondere:
					total += 1.0
				elif Placement.cote_route(plateau, v) != Vector2i.ZERO:
					total += 2.0
				else:
					total += 1.0 if Placement.distance_route(plateau, v) <= 2 else 0.3
	return total
