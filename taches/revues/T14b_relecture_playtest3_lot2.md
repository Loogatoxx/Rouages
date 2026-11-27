## T14b — Relecture des lots 1 et 2

1. **High · bloquant** — Un atelier alimenté mais encerclé produit quand même. Si sa sortie vaut `INF`, le jouet apparaît sur un port, entre deux pièces occupées. `_contenir` autorise alors le passage d’une pièce occupée à l’autre. Suspendre la sortie et garder un jouet prêt jusqu’à l’ouverture d’un passage. [production.gd:74](/Users/carlos/Developer/Rouages/game/workshops/production.gd:74) · [swarm_sim.gd:402](/Users/carlos/Developer/Rouages/game/swarm/swarm_sim.gd:402)

2. **High · bloquant** — Un garde choisit l’ennemi le plus proche avant de vérifier le trajet. Si cet ennemi est derrière un virage, le garde retourne au poste, même si un second ennemi peut être rejoint sur la ligne défendue. Filtrer les cibles de poursuite avant de les départager. [swarm_sim.gd:659](/Users/carlos/Developer/Rouages/game/swarm/swarm_sim.gd:659) · [swarm_sim.gd:692](/Users/carlos/Developer/Rouages/game/swarm/swarm_sim.gd:692)

3. **Medium · moyen** — Un bâtiment refusé par l’Horloge reste éteint même si un générateur autonome dispose des dents et des ports nécessaires. L’exclusion `surcharge_horloge.has(voisine)` empêche cette relève. Essayer la seconde source avant de publier la surcharge. [energie.gd:132](/Users/carlos/Developer/Rouages/game/board/energie.gd:132)

4. **Medium · moyen** — Pour six ennemis, des paquets de quatre et un intervalle de 1 s, le dernier arrive à 4,35 s contre 5 s en cadence régulière. Sous 0,35 s, la pause minimale allonge aussi les cycles complets. Calculer les échéances selon l’effectif réel du dernier paquet et l’intervalle configuré. [directeur_vagues.gd:119](/Users/carlos/Developer/Rouages/game/waves/directeur_vagues.gd:119)

5. **Medium · moyen** — Perdre la vague 2 fait compter cette vague comme tenue en phase `FIN` et programme l’annonce « +1 dent ». Calculer les dents sur les vagues effectivement gagnées et rattacher le minuteur au plateau. [run.gd:367](/Users/carlos/Developer/Rouages/game/core/run.gd:367) · [plateau_noeud.gd:26](/Users/carlos/Developer/Rouages/game/board/plateau_noeud.gd:26)

6. **Low · mineur** — Un Pont sans repère bleu accepte pourtant le clic de poste. Employer le même prédicat pour le surlignage et la validation. [pose_controleur.gd:70](/Users/carlos/Developer/Rouages/game/board/pose_controleur.gd:70) · [plateau.gd:142](/Users/carlos/Developer/Rouages/game/board/plateau.gd:142)

7. **Low · mineur** — Une rotation surchargeant plusieurs bâtiments annonce uniquement le premier, puis mémorise tous les autres comme déjà signalés. Regrouper les nouvelles surcharges dans un message. [plateau_noeud.gd:45](/Users/carlos/Developer/Rouages/game/board/plateau_noeud.gd:45)

8. **Low · mineur** — Panneau du générateur ouvert, chaque variation de ressorts relance l’analyse complète du réseau. Réutiliser les charges calculées par `PlateauNoeud`. [panneau_piece.gd:127](/Users/carlos/Developer/Rouages/game/ui/panneau_piece.gd:127) · [energie.gd:65](/Users/carlos/Developer/Rouages/game/board/energie.gd:65)

**Rien à signaler** sur l’ordre après copie, rotation ou repose, les dents illimitées, le rappel par origine, les lots visuels par `id`, l’exemption des volants et l’annulation du poste.

**Fichiers créés ou modifiés** — Aucun. **Reste à brancher** — Rien. **Écarts** — Rapport livré ici, dépôt en lecture seule. Lot 2 relu sur `8f2da21`, `HEAD` contenant la fiche. Objectif de 60 images/s à 300 contre 300 non mesuré.