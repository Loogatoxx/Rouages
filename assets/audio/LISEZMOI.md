# Sons de Rouages

Tous les sons sont **synthétisés** par `scripts/generer_sons.py` (Python, bibliothèque standard, puis ffmpeg pour l'encodage
Ogg Vorbis). Aucun service payant, aucun échantillon externe : pas de licence à vérifier, et on peut tout regénérer.

```bash
python3 scripts/generer_sons.py
```

| Fichier | Quand | Recette |
|---|---|---|
| `pose.ogg` | pose d'une tuile | bloc de bois grave (320 Hz) + petit cliquet |
| `rotation.ogg` | rotation | trois crans de cliquet aigus |
| `jouet_sort.ogg` | un jouet sort d'un atelier | « pling » de boîte à musique, deux notes (mi-si) |
| `scarabee_casse.ogg` | un ennemi est cassé | craquement de laiton bref, hauteur variée au hasard en jeu |
| `horloge_touchee.ogg` | l'horloge perd des PV | cloche douce, deux notes descendantes (ré-la) |
| `vague_debut.ogg` | début de vague | arpège montant do-mi-sol-do |
| `victoire.ogg` | victoire | petite ritournelle en do majeur |
| `defaite.ogg` | défaite | boîte à musique qui ralentit (jamais lugubre) |
| `clic.ogg` | boutons d'interface | tic de bois très court |
| `ressorts.ogg` | fin de vague (ressorts gagnés) | « tintin » clair |
| `musique_vague.ogg` | pendant les vagues, en boucle (fondu enchaîné) | ostinato en ré mineur doux, 112 bpm, blocs de bois en rythme |
| `musique.ogg` | construction et menus, en boucle | boîte à musique en fa majeur, 84 bpm, ~46 s, raccord sans couture |

Le volume relatif de chaque son et l'anti-répétition sont réglés dans `game/core/sons.gd`.
