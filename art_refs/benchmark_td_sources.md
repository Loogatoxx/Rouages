# Benchmark game design Tower Defense — Synthèse documentée (PT-34)

Synthèse web des principes qui rendent un tower defense profond, lisible et rejouable : cinq axes classiques et apports des roguelikes récents. Chaque principe cite un jeu et une source vérifiée en fin de document.

## 1. Décisions à fort impact

- **Rendre les emplacements rares pour imposer des arbitrages.** En limitant la construction à quelques points fixes près des routes, *Kingdom Rush* fait de chaque tour un choix exclusif (dégâts, blocage ou zone) tout en gardant la carte lisible [S2][S7].
- **Spécialiser par branches mutuellement exclusives.** Dans *Bloons TD 6*, chaque tour propose trois voies dont une seule atteint le palier final : orienter un *Alchemist* vers le soutien (*Berserker Brew*) ou l'économie (*Lead to Gold*) engage toute la partie [S9][S10].
- **Relier chaque geste tactique à une stratégie durable.** Un bon TD évite la suite de micro-puzzles isolés [S3] : *Defense Grid: The Awakening* oblige à arbitrer entre améliorer une tour, allonger le labyrinthe ou préserver l'intérêt cumulé des ressources jusqu'aux vagues finales [S4][S6].

## 2. Rythme des vagues et temps morts

- **Alterner pics de tension et introduction graduée.** Dans sa conférence GDC sur *Plants vs. Zombies*, George Fan montre comment des respirations calibrées et l'ajout d'une seule mécanique à la fois maintiennent le joueur dans le flux sans surcharge [S1].
- **Transformer l'attente en prise de risque volontaire.** *Kingdom Rush* permet d'appeler la vague suivante plus tôt contre un bonus d'or proportionnel au temps économisé et un rechargement accéléré des sorts : le joueur régule son propre rythme [S2].
- **Structurer l'entre-vagues et lisser les longueurs.** *Thronefall* sépare nettement un jour calme dédié aux choix économiques et une nuit dédiée au combat [S14]. Pendant les vagues longues, l'avance rapide de *Defense Grid* supprime les temps morts sans réduire la maîtrise [S6].

## 3. Espace et placement : positions privilégiées, terrain et mazing

- **Mazing hybride contre solution unique.** Le mazing maximise le temps d'exposition au feu [S12], mais une grille libre encourage un serpentin identique partout. *Defense Grid* combine couloirs imposés et plaines ouvertes où les tours façonnent le trajet sans jamais bloquer la sortie [S6].
- **Différencier les cases par la topographie.** Dans *Rogue Tower*, l'altitude octroie directement dégâts et portée supplémentaires aux tours surélevées, incitant à réserver les meilleurs emplacements aux tours tardives [S13].
- **Faire du chemin un levier tactique.** Les coudes et carrefours de *Kingdom Rush* créent des goulots rentables [S2], tandis qu'*Isle of Arrows* fait poser les tuiles de route au joueur : allonger la boucle renforce la défense, mais une erreur ouvre un raccourci fatal [S15].

## 4. Synergies entre tours

- **Coupler blocage physique et dégâts de zone.** La caserne (*Barracks*) de *Kingdom Rush* immobilise les ennemis au corps à corps, créant un point de fixation qui démultiplie la valeur de l'artillerie de zone [S2][S7].
- **Privilégier les multiplicateurs de soutien au spam.** Dans *Bloons TD 6*, le *Monkey Village* (portée, détection, *MIB*) et l'*Alchemist* (cadence, perforation, percée du plomb) rendent un petit noyau synergique bien supérieur à l'empilement d'une même tour [S9][S10].
- **Associer contrôle de foule et bonus d'adjacence.** La tour *Temporal* de *Defense Grid* ralentit les aliens pour doubler leur exposition aux tours *Laser* ou *Cannon* [S6]. *Isle of Arrows* matérialise la synergie dans l'espace : une taverne adjacente renforce directement les tours d'archers voisines [S15].

## 5. Contre-jeu : punir le spam d'une seule tour

- **Croiser résistances et contournement du sol.** *Kingdom Rush* oppose armure physique (percée par la magie), résistance magique (qui punit le spam de mages) et ennemis volants qui ignorent les casernes [S7][S8].
- **Empiler les immunités par paliers.** *Bloons TD 6* introduit séparément *Camo* (invisible sans détection, v. 24), *Purple* (immunisé énergie/feu/plasma, v. 25) et *Lead* (immunisé projectiles tranchants, v. 28), puis les fusionne dans le *DDT* (*Camo* + *Lead* + *Black*), punissant toute mono-stratégie [S11].
- **Imposer des rôles utilitaires via boucliers et furtivité.** *Defense Grid* mêle unités à bouclier (*Bulwark*, *Spire* protégeant ses alliés, sensibles aux *Tesla*/*Cannon*) et furtifs (*Lurker*, *Decoy* camouflant son escorte) exigeant des tours *Command* de détection [S6].
- **Clarifier les contres par une matrice lisible.** *Legion TD 2* croise quatre types d'attaque (*Piercing*, *Impact*, *Magic*, *Pure*) et cinq défenses (*Swift*, *Fortified*, *Natural*, *Arcane*, *Immaterial*) entre 75 % et 125 %, imposant une composition variée face aux vagues annoncées [S16].

## 6. TD roguelike récents : draft, rareté, chance et méta-progression

- **Hasard pré-action par le draft.** *Isle of Arrows* tire des tuiles façon *Carcassonne* avant l'assaut [S15] ; *Rogue Tower* lie le draft de cartes à l'expansion progressive des routes [S13]. Le hasard crée des dilemmes d'adaptation avant l'action plutôt qu'une punition subie.
- **Rareté orientée synergies plutôt que chiffres bruts.** Dans *Ballionaire*, les *Triggers* communs forment le socle du plateau tandis que les *Boons* et objets rares réécrivent les règles de déclenchement pour bâtir des combos [S17].
- **Encadrer la chance et éviter la dilution du pool.** *Legion TD 2* canalise l'aléa via ses modes *Mastermind* (*Lock-In*, *Chaos*, *Yolo*) et des règles de *Reroll* [S16]. *Ballionaire* ajoute relances et gestion des tirages pour éviter qu'un pool trop débloqué ne noie les synergies [S17].
- **Méta-progression horizontale et défis optionnels.** *Game Developer* alerte contre les méta-couches qui noient le puzzle sous le grind chiffré [S5]. Contrairement à l'arbre permanent parfois punitif de *Rogue Tower* [S13], *Thronefall* mise sur des *Perks* qui varient le style de jeu et des *Mutators* volontaires pour le défi et le score [S14].

## Sources

- **[S1]** George Fan, *How I Got My Mom to Play Through Plants vs. Zombies* (GDC) — https://www.gdcvault.com/play/1015541/How-I-Got-My-Mom
- **[S2]** D. Harlow, *Kingdom Rush - The Wonderful Campaign Level Design* — https://www.gamedeveloper.com/design/kingdom-rush---the-wonderful-campaign-level-design
- **[S3]** M. Brough, *Adding Strategy to Your Tactics* — https://www.gamedeveloper.com/design/adding-strategy-to-your-tactics
- **[S4]** *The Art of Defense Grid: The Awakening* — https://www.gamedeveloper.com/design/from-concept-to-execution-the-art-of-defense-grid-the-awakening
- **[S5]** *The Pitfalls of Meta-Game Design* — https://www.gamedeveloper.com/design/the-pitfalls-of-meta-game-design
- **[S6]** *Defense Grid: The Awakening* — https://en.wikipedia.org/wiki/Defense_Grid:_The_Awakening ; https://store.steampowered.com/app/18500/
- **[S7]** Kingdom Rush Wiki, *Barracks* — https://kingdomrushtd.fandom.com/wiki/Barracks
- **[S8]** Kingdom Rush Wiki, *Armor and Magic resistance* — https://kingdomrushtd.fandom.com/wiki/Armor_and_Magic_resistance
- **[S9]** Bloons Wiki, *Alchemist* — https://bloons.fandom.com/wiki/Alchemist
- **[S10]** Bloons Wiki, *Monkey Village* — https://bloons.fandom.com/wiki/Monkey_Village
- **[S11]** Bloons Wiki, *Camo / Lead / Purple / DDT* — https://bloons.fandom.com/wiki/Camo_Bloon ; https://bloons.fandom.com/wiki/Lead_Bloon ; https://bloons.fandom.com/wiki/Purple_Bloon ; https://bloons.fandom.com/wiki/Dark_Dirigible_Titan_(DDT)
- **[S12]** *Mazing: The Complete Guide* — https://maultactics.com/mazing-the-complete-guide-to-maze-tower-defense
- **[S13]** Rogue Tower Wiki — https://rogue-tower.fandom.com/wiki/Upgrade_Cards ; https://rogue-tower.fandom.com/wiki/Map_features ; https://rogue-tower.fandom.com/wiki/Permanent_Upgrades
- **[S14]** Thronefall Wiki & Steam — https://thronefall.wiki/ ; https://store.steampowered.com/app/2239150/Thronefall/
- **[S15]** Interview D. Lutz (*Isle of Arrows*) & Steam — https://www.galaxus.ch/en/s1/page/interview-with-daniel-lutz-swiss-game-developer-based-in-montreal-23652 ; https://store.steampowered.com/app/1946970/Isle_of_Arrows/
- **[S16]** Legion TD 2 Wiki — https://legiontd2.fandom.com/wiki/Attack_%26_Defense_Types ; https://legiontd2.fandom.com/wiki/Mastermind_Playstyle ; https://legiontd2.fandom.com/wiki/Reroll
- **[S17]** Ballionaire Wiki & Steam — https://ballionaire.fandom.com/wiki/Ballionaire_Wiki ; https://store.steampowered.com/app/2667120/Ballionaire/
