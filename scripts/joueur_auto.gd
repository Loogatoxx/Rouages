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
##         <dossier> <plateau 0-5> <style spam|tactique> [graine] [captures 0|1] [vagues_max]
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
				await _attendre(2)
				if _captures and run.vague_actuelle in [0, 4, 9]:
					await _capturer("V%02d_pause" % (run.vague_actuelle + 1))
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
					ennemis_max = maxi(ennemis_max, partie.sim.nombre(1))
					if _captures and not prochaines.is_empty() and t >= prochaines[0] and numero in [1, 3, 4, 5, 8, 10]:
						await _capturer("V%02d_%02ds" % [numero, int(prochaines[0])])
						prochaines.pop_front()
					if t > 400.0:
						break
				var consommateurs: int = 0
				for c: Vector2i in noeud.plateau.coords_pieces():
					var p: Resource = noeud.plateau.piece_de(c)
					if p.type == PieceDef.Type.ATELIER or p.type == PieceDef.Type.TOURELLE:
						consommateurs += 1
				bilan.append("V%d : -%d PV, %d s, jouets max %d, ennemis max %d, %d bâtiments, %d ressorts" % [numero,
						pv_avant - run.pv_horloge, int(t), allies_max, ennemis_max, consommateurs, run.ressorts])
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


func _capturer(nom: String) -> void:
	# Les bulles d'astuce sont masquées le temps de la photo (les fermer écrirait dans les réglages de Carlos).
	var astuces: GDScript = load("res://game/ui/astuces.gd")
	for bulle: Node in current_scene.find_children("*", "PanelContainer", true, false):
		if bulle.get_script() == astuces:
			bulle.visible = false
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(_dossier.path_join("%d_%s_%s.png" % [_depart, _style, nom]))


# Tirage : le style « spam » prend des ateliers puis des engrenages ; le style « tactique » équilibre ateliers,
# tourelles et engrenages selon ce qui manque. Les extensions sont évitées (le joueur automatique ne les pose pas).
func _choisir_lot(run: Node) -> int:
	var meilleur: int = 0
	var score_max: float = -INF
	for i: int in run.offre.size():
		var objet: Resource = run.offre[i].objet
		var score: float = 0.0
		if objet is PieceDef:
			match objet.type:
				PieceDef.Type.ATELIER:
					score = 10.0 if _style == "spam" else 6.0
				PieceDef.Type.TOURELLE:
					score = 2.0 if _style == "spam" else 8.0 + objet.rarete
				PieceDef.Type.ENGRENAGE:
					score = 4.0 + objet.rarete
				PieceDef.Type.GENERATEUR:
					score = 9.0
			if objet.sur_route:
				score = 1.0
		else:
			score = -5.0
		score += run.offre[i].quantite * 0.5
		if score > score_max:
			score_max = score
			meilleur = i
	return meilleur


func _acheter(run: Node) -> void:
	var boutique: Array = run.regles.boutique
	_acheter_engrenages(run)
	for essai: int in 6:
		var achete: bool = false
		for i: int in boutique.size():
			var objet: Resource = boutique[i].objet
			if not objet is PieceDef:
				continue
			var veut: bool = false
			# Les libellules arrivent en V6 : tout joueur prend alors un atelier de lance-billes (seuls à les toucher).
			if objet.id == &"atelier_billes" and run.vague_actuelle >= 4 and _billes_possedes(run) < (2 if run.vague_actuelle >= 7 else 1):
				veut = true
			elif _style == "spam":
				veut = objet.type == PieceDef.Type.ATELIER and objet.id == &"atelier_soldats"
			else:
				veut = objet.type == PieceDef.Type.TOURELLE and run.ressorts >= boutique[i].prix + 10
			# On garde de quoi acheter l'engrenage qui reliera ce bâtiment.
			if veut and run.ressorts >= boutique[i].prix + 7 and run.acheter(i):
				achete = true
				break
		if not achete:
			break
	_acheter_engrenages(run)


func _acheter_engrenages(run: Node) -> void:
	var boutique: Array = run.regles.boutique
	# Des bâtiments attendent dans la réserve sans engrenage pour les relier : on achète un engrenage à plusieurs
	# sorties (T, sinon croix), comme le ferait un joueur.
	var en_attente: int = 0
	var engrenages: int = 0
	for id: StringName in run.reserve.ids():
		var objet: Resource = run.reserve.trouver(id)
		if objet is PieceDef and (objet.type == PieceDef.Type.ATELIER or objet.type == PieceDef.Type.TOURELLE):
			en_attente += run.reserve.quantite(id)
		elif objet is PieceDef and objet.type == PieceDef.Type.ENGRENAGE and objet.ports != 5:
			engrenages += run.reserve.quantite(id)
	while engrenages < mini(en_attente, 2):
		var achat: bool = false
		for voulu: StringName in [&"engrenage_t", &"engrenage_croix"]:
			for i: int in boutique.size():
				if not achat and boutique[i].objet is PieceDef and boutique[i].objet.id == voulu and run.acheter(i):
					achat = true
		if not achat:
			break
		engrenages += 1


func _billes_possedes(run: Node) -> int:
	var total: int = run.reserve.quantite(&"atelier_billes")
	var plateau = current_scene.get_node("PlateauNoeud").plateau
	for c: Vector2i in plateau.coords_pieces():
		if plateau.piece_de(c).id == &"atelier_billes":
			total += 1
	return total


func _ameliorer(run: Node, plateau) -> void:
	if _style == "spam":
		return
	for essai: int in 8:
		var cible: Vector2i = Vector2i(9999, 9999)
		var prix_min: int = 999999
		for c: Vector2i in plateau.coords_pieces():
			var p: Resource = plateau.piece_de(c)
			if p.type != PieceDef.Type.ATELIER and p.type != PieceDef.Type.TOURELLE:
				continue
			var prix: int = run.prix_amelioration(plateau, c)
			if prix > 0 and prix < prix_min:
				prix_min = prix
				cible = c
		if cible.x == 9999 or run.ressorts < prix_min or not run.ameliorer_piece(plateau, cible):
			return


# Pose tout ce qui peut l'être, comme un joueur attentif : il garde toujours une prise d'engrenage libre pour la
# suite (sinon le réseau est bouché), donc il pose un engrenage dès que les prises manquent.
func _poser_reserve(run: Node, plateau) -> void:
	for passe: int in 40:
		var engrenages: Array[StringName] = []
		var batiments: Array[StringName] = []
		for id: StringName in run.reserve.ids():
			var objet: Resource = run.reserve.trouver(id)
			if not objet is PieceDef or objet.sur_route:
				continue
			if objet.type == PieceDef.Type.ENGRENAGE:
				engrenages.append(id)
			else:
				batiments.append(id)
		var prises: float = _prises_libres(plateau, Energie.calculer(plateau))
		var ordre: Array[StringName] = []
		if not engrenages.is_empty() and prises <= 1.0:
			ordre.append_array(engrenages)
			ordre.append_array(batiments)
		else:
			ordre.append_array(batiments)
			ordre.append_array(engrenages)
		var pose: bool = false
		for id: StringName in ordre:
			var objet: Resource = run.reserve.trouver(id)
			var choix: Array = _meilleure_place(plateau, objet, true)
			if not choix.is_empty() and plateau.poser(choix[0], objet, choix[1]):
				run.reserve.retirer(id)
				pose = true
				break
		if not pose:
			return


# `garder_prise` : refuse une place qui boucherait la dernière prise libre du réseau.
func _meilleure_place(plateau, piece, garder_prise: bool = false) -> Array:
	var meilleur: Array = []
	var score_max: float = -INF
	var routes: Array[Vector2i] = []
	for s: Vector2i in plateau.coords_sols():
		if plateau.sol_de(s) == Plateau.Sol.CHEMIN:
			routes.append(s)
	for c: Vector2i in plateau.coords_sols():
		if not plateau.peut_poser(c, piece):
			continue
		for r: int in 4:
			if piece.type != PieceDef.Type.GENERATEUR and r > 0 and piece.ports == 15:
				break
			var copie = plateau.dupliquer()
			copie.poser(c, piece, r)
			var al: Dictionary = Energie.calculer(copie)
			var score: float
			match piece.type:
				PieceDef.Type.ATELIER:
					if not al.has(c):
						continue
					score = 10.0 if Placement.cote_route(copie, c) != Vector2i.ZERO else 0.0
					var prises: float = _prises_libres(copie, al)
					if garder_prise and prises < 1.0:
						continue
					score += 4.0 * minf(prises, 2.0)
				PieceDef.Type.TOURELLE:
					if not al.has(c):
						continue
					score = 0.0
					for s: Vector2i in routes:
						if Vector2(s - c).length() * 2.0 <= piece.portee_tir:
							score += 1.0
					var prises_t: float = _prises_libres(copie, al)
					if garder_prise and prises_t < 1.0:
						continue
					score += 4.0 * minf(prises_t, 2.0)
				PieceDef.Type.GENERATEUR:
					score = 5.0 if Placement.cote_route(copie, c) != Vector2i.ZERO else 0.0
					score -= 3.0 if al.has(c) else 0.0
				_:
					if not al.has(c):
						continue
					score = _prises_libres(copie, al) * 1.0
					if garder_prise and score < 1.0:
						continue
			score -= Vector2(c).length() * 0.05
			if score > score_max:
				score_max = score
				meilleur = [c, r]
	return meilleur


# Cases d'herbe libres où un consommateur posé serait alimenté (une prise d'engrenage ouverte y mène), bord de route ×2.
func _prises_libres(plateau, al: Dictionary) -> float:
	var total: float = 0.0
	var vues: Dictionary = {}
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for c: Vector2i in al:
		var p: Resource = plateau.piece_de(c)
		if p == null or not p.transmet:
			continue
		var ports: int = plateau.ports_de(c)
		for d: int in 4:
			var v: Vector2i = c + directions[d]
			if ports & (1 << d) and plateau.sol_de(v) == Plateau.Sol.HERBE and plateau.piece_de(v) == null \
					and not vues.has(v):
				vues[v] = true
				total += 2.0 if Placement.cote_route(plateau, v) != Vector2i.ZERO else 1.0
	return total
