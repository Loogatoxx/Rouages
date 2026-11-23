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
| 2 | Caméra dessus/3D, pose et rotation à la souris, tuiles greybox, engrenages animés si alimentés | Codex | Carlos construit une chaîne et voit l’énergie passer | 🧪 code relu, 11 tests verts — test manuel de Carlos en attente |
| 2b | Matériaux DA, lumière fin d'après-midi, kit greybox Blender (tuile, engrenage, atelier, scarabée, jouet) | Antigravity | Capture comparée à `art_refs/plateau_maquette_v1.jpg` | 🧪 livré (9 matériaux, ambiance, kit de 8 assets, 0 crédit) — avis DA de Carlos en attente |
| 3 | SwarmSim : champ de flux, grille spatiale, combats, rendu MultiMesh | Codex (spec Claude) | 300 contre 300 à 60 FPS | ✅ (T03 : 60 FPS en fenêtre, 3,2 ms/pas, 20 tests) |
| 4 | Ateliers alimentés → jouets ; vagues de scarabées ; PV horloge ; défaite | Codex | Une vague jouable de bout en bout | à faire |
| 5 | Draft 1 parmi 3, machine à états de la run, UI minimale, victoire/défaite/rejouer, données de 10 vagues | Codex + Claude (équilibrage) | Run complète de 15 min | à faire |
| 6 | 🚦 Playtest Carlos + équilibrage. **Aucun crédit Hyper3D avant ce feu vert.** | Carlos + Claude | « C'est fun » | à faire |
| 7 | Horloge : image → validation Carlos → Image-to-3D (1 crédit) → Blender → intégration ; 4-5 sons locaux | Antigravity | Horloge à l'échelle en jeu | à faire |
| 8 | Builds Mac + Windows, test sur le PC Windows | Claude + Carlos | Deux `.zip` qui se lancent | à faire |
