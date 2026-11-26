# Roadmap — MVP (semaine 1)

**Périmètre du MVP** : le plateau qui pousse (draft de 3 tuiles entre les vagues) · chaîne d'engrenages qui transporte
l'énergie depuis l'horloge · défense uniquement par des ateliers producteurs de jouets alliés · nuées des deux côtés ·
run de ~15 min / 10 vagues · greybox aux couleurs de la DA + **horloge en vraie 3D (1 crédit Hyper3D)**.

**Critère de réussite** : Carlos joue une run complète sur son Mac ; ses choix de tuiles et de chaînes changent visiblement
l'issue ; les deux nuées sont lisibles en vue de dessus ; l'horloge 3D est à la bonne échelle ; 1 seul crédit dépensé.

| # | Étape | Qui | Critère de fin | État |
|---|---|---|---|---|
| 0 | Installation, MCP, bridges, squelette, docs, git | Claude | Le projet s'ouvre, les tests passent, les deux bridges répondent | ✅ |
| 1 | Grille, tuiles, rotation, propagation d'énergie (logique pure) | Codex (contrat Claude) | Tests headless au vert | ✅ (T01, 9 tests) |
| 2 | Caméra dessus/3D, pose et rotation à la souris, tuiles greybox, engrenages animés si alimentés | Codex | Carlos construit une chaîne et voit l’énergie passer | ✅ (T02) |
| 2b | Matériaux DA, lumière fin d'après-midi, kit greybox Blender (tuile, engrenage, atelier, scarabée, jouet) | Antigravity | Capture comparée à `art_refs/plateau_maquette_v1.jpg` | ✅ (T02b : 9 matériaux, ambiance, 8 assets, 0 crédit) |
| 3 | SwarmSim : champ de flux, grille spatiale, combats, rendu MultiMesh | Codex (spec Claude) | 300 contre 300 à 60 FPS | ✅ (T03 : 60 FPS en fenêtre, 3,2 ms/pas, 20 tests) |
| 4 | Ateliers alimentés → jouets ; vagues de scarabées ; PV horloge ; défaite | Codex | Une vague jouable de bout en bout | ✅ (T04 : 27 tests, 3 vagues provisoires) |
| 5 | Draft 1 parmi 3, machine à états de la run, UI minimale, victoire/défaite/rejouer, données de 10 vagues | Codex + Claude (équilibrage) | Run complète de 15 min | ✅ (T05a draft/réserve, T05b extensions, T05c 10 vagues + remontage ; 40 tests) |
| 6 | 🚦 Playtest Carlos + équilibrage. **Aucun crédit Hyper3D avant ce feu vert.** | Carlos + Claude | « C'est fun » | ✅ (T06a contraste des jouets, V2-V4 adoucies, horloge 30 PV, aperçu de pose bleu ; 43 tests) |
| 7 | Horloge : image → validation Carlos → Image-to-3D (1 crédit) → Blender → intégration ; 4-5 sons locaux | Antigravity | Horloge à l'échelle en jeu | ✅ (modèle Hyper3D, 1 crédit ; 11 sons synthétisés + musique, `scripts/generer_sons.py`) |
| 7b | Rush jouabilité : menus titre/pause/fin, ressorts + boutique, tutoriel, survol, vitesse x2, cuirassé, lance-billes, rente des extensions, passe visuelle (lumière, grille, vitrine 3D) | Codex (T08a-c) + Claude | Run complète du menu à l'écran de fin | ✅ (52 tests) |
| 9 | Retours d'un testeur externe : ennemis visibles (garde), pose en vague, rotation payante, aide à la pose d'extension, 3 plateaux, défi du jour, fourmi, traduction FR/EN/PT, rééquilibrage, icône, musique de vague, sensations d'impact | Codex (T09a-c) + Claude | Le testeur rejoue avec plaisir | 🟡 fait, à rejouer par le testeur |
| 8 | Builds Mac + Windows, test sur le PC Windows | Claude + Carlos | Deux `.zip` qui se lancent | 🟡 `builds/Rouages_mac.zip` testé (se lance, horloge 3D OK) ; `builds/Rouages_windows.zip` exporté sans erreur, à tester sur le PC |
