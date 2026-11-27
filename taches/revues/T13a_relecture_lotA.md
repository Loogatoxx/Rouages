# T13a — Relecture statique du lot A (`08ca566`)

1. **Moyen** — `game/workshops/production.gd:39`. En vague, déplacer un atelier plein de A en B lui rend tout son quota. Un autre atelier posé en A hérite du quota occupé par les survivants. À la reprise, rappeler les jouets de A ou transférer leur rattachement avec le bâtiment.

2. **Moyen** — `game/swarm/swarm_sim.gd:381`. Sur un S, un soldat voit un scarabée sur le tronçon parallèle à quatre mètres, hors de portée de frappe. Il traverse l’herbe en ligne droite et contourne aussi la limite du poste. Suivre la piste jusqu’au même tronçon avant d’autoriser l’approche directe.

3. **Moyen** — `game/swarm/swarm_sim.gd:427`. À une fourche située exactement à la limite, une piste vers l’entrée A est refusée. Le choix de patrouille peut envoyer le jouet vers B. Dès la frontière franchie, la piste le ramène à la fourche, où le cycle recommence tant que l’ennemi reste loin. Immobiliser le jouet quand le pas sortant est interdit.

4. **Moyen** — `game/swarm/swarm_sim.gd:429`. Après une extension, un atelier débouche dans un cul-de-sac au-delà du poste. Sans cible, le garde reste sur place malgré le retour calculé ligne 132. Autoriser le pas vers l’horloge depuis une case inutile avant d’appliquer l’arrêt.

5. **Moyen** — `game/core/graphismes.gd:123`. Ajouter un émetteur ponctuel initialement éteint avec les particules activées déclenche l’effet dès son entrée. Modifier les FPS peut le redéclencher. Préserver sa visibilité et son émission, et limiter leur restauration aux changements de l’option particules.

6. **Mineur** — `game/workshops/production.gd:43`. Avec une progression de 2,2 et deux places libres, deux jouets apparaissent au même point pendant le même pas. Émettre au plus un jouet par appel et plafonner le reliquat à un.

**Rien à signaler** — Origines et effectifs concordent après ajout, retrait par échange et vidage. Les pistes distinguent sol et vol et projettent les ennemis sur herbe cartographiée. La progression stockée reste plafonnée à un. La fin de vague vide les alliés, puis production, simulation et tourelles s’arrêtent. Le HUD masque le compteur ennemi. Lumières et environnements préconfigurés conservent leurs valeurs d’origine. La perte de focus plafonne à 15 images/s sans sauvegarde. Énergie et dents visibles utilisent les mêmes ports, et l’aperçu exclut la pose sur route.
