# Registre des icônes — `assets/ui/icones/`

> **Règle d'unicité** : **1 fichier = 1 concept unique**. Une icône ne doit jamais être réutilisée pour deux idées distinctes dans l'interface. Toute création suit `art_refs/charte_icones.md` et est validée sur `art_refs/planche_icones_v2.png`.

---

## 1. Icônes disponibles (`assets/ui/icones/*.png` — 20 fichiers)

| Fichier | Statut | Concept unique | Où il sert |
|---|---|---|---|
| `ressort.png` | **Refaite** *(v2)* | **Ressorts** (monnaie d'énergie horlogère) | Compteur HUD ressources, coûts d'achat et d'amélioration |
| `horloge_pv.png` | **Refaite** *(v2)* | **PV de l'horloge** (vie de la base centrale) | Compteur HUD vie de l'horloge (cœur corail serti laiton + aiguilles) |
| `vague.png` | **Nouvelle** *(v2)* | **Vague d'ennemis** (numéro / progression de vague) | Badge / bandeau de vague HUD, lancement de vague (sans chiffre intégré) |
| `ennemis_restants.png` | **Nouvelle** *(v2)* | **Ennemis restants** (scarabée + sablier) | Compteur HUD des scarabées encore actifs dans la vague |
| `entree.png` | **Nouvelle** *(v2)* | **Point d'entrée ennemis** (panneau-flèche sur poteau) | Repère directionnel d'arrivée des scarabées |
| `chance.png` | **Nouvelle** *(v2)* | **Chance** (trèfle 4 feuilles émaillé menthe) | Statistique / bonus de chance (récompenses, tirages) |
| `deplacer.png` | **Nouvelle** *(v2)* | **Déplacer une tuile** (pince d'horloger soulevant une tuile) | Action contextuelle de déplacement sur le plateau |
| `ameliorer.png` | **Nouvelle** *(v2)* | **Améliorer** (chevron laiton vers le haut sur une clé) | Action d'amélioration d'atelier ou de tourelle |
| `boutique.png` | **Nouvelle** *(v2)* | **Boutique / achats** (petite échoppe à pièce) | Accès boutique / panneau d'achat de pièces |
| `menu.png` | **Nouvelle** *(v2)* | **Menu / réglages** (engrenage bois 6 dents, distinct d'`engrenage_or.png`) | Bouton options / menu principal HUD |
| `tourner.png` | **Nouvelle** *(v2)* | **Pivoter une tuile** (flèche circulaire laiton) | Action de rotation avant ou pendant la pose |
| `relancer.png` | **Nouvelle** *(v2)* | **Relancer le tirage** (deux flèches en boucle sur une carte) | Bouton relance des choix de récompense ou boutique |
| `engrenage_or.png` | Conservée | **Réseau d'énergie / engrenages** | Indicateur de liaison mécanique / onglet engrenages *(voir audit § 2)* |
| `vitesse_x1.png` | Conservée | **Vitesse normale (×1)** | Bouton contrôle du temps HUD (lecture normale) |
| `vitesse_x2.png` | Conservée | **Vitesse accélérée (×2)** | Bouton contrôle du temps HUD (accélération) |
| `pause.png` | Conservée | **Pause** | Bouton pause HUD |
| `coffre.png` | Conservée | **Récompense de fin de vague** | Écran / bouton de choix de récompense (coffre) |
| `rarete_commune.png` | Conservée | **Rareté Commune** | Badge de rareté sur cartes et infobulles |
| `rarete_rare.png` | Conservée | **Rareté Rare** | Badge de rareté sur cartes et infobulles |
| `rarete_epique.png` | Conservée | **Rareté Épique** | Badge de rareté sur cartes et infobulles |

---

## 2. Audit des doublons et ambiguïtés (état final T11a)

1. **Doublon résolu — `engrenage_or.png`** : `assets/ui/LISEZMOI.md` lui attribuait trois usages (*« réseau d'énergie / amélioration / onglet ateliers »*). Désormais réservée au seul concept **réseau d'énergie / engrenages** ; les autres usages disposent de `ameliorer.png`, `boutique.png` et `menu.png`.
2. **Ambiguïté corrigée — `horloge_pv.png`** : l'ancien cadran d'horloge rond prêtait à confusion avec le temps ou les vagues → refaite en **cœur rouge corail serti de laiton + aiguilles** (PV de l'horloge uniquement).
3. **Lisibilité corrigée — `ressort.png`** : l'ancienne spirale plate a été remplacée par un **ressort hélicoïdal de laiton vu de 3/4**.
4. **Concepts séparés — `vague.png` vs `ennemis_restants.png`** : `vague.png` désigne la **vague d'ennemis** (3 scarabées + fanion, sans chiffre) et `ennemis_restants.png` le **décompte d'ennemis actifs** (1 scarabée + sablier).

**Bilan d'unicité** : **20 fichiers disponibles = 20 concepts strictement disjoints** (0 doublon).
