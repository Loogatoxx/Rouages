#!/usr/bin/env python3
"""Génère les sons de Rouages par synthèse procédurale (bibliothèque standard Python + ffmpeg).

Pourquoi la synthèse plutôt qu'un service : zéro coût, zéro licence à vérifier, et le son est reproductible
(on relance le script pour retoucher un réglage). Le timbre visé : boîte à musique, bois, laiton doux.

Usage : python3 scripts/generer_sons.py   → écrit assets/audio/*.ogg (44,1 kHz, Vorbis stéréo (canaux identiques), encodeur natif de ffmpeg : libvorbis absent ici).
"""
import math
import os
import random
import struct
import subprocess
import tempfile
import wave

TAUX = 44100
RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SORTIE = os.path.join(RACINE, "assets", "audio")
random.seed(7)  # même graine = mêmes sons à chaque génération


def silence(duree):
    return [0.0] * int(duree * TAUX)


def mixer(base, son, debut, gain=1.0):
    """Ajoute `son` dans `base` à partir de `debut` secondes (agrandit `base` si besoin)."""
    i0 = int(debut * TAUX)
    if len(base) < i0 + len(son):
        base.extend([0.0] * (i0 + len(son) - len(base)))
    for i, v in enumerate(son):
        base[i0 + i] += v * gain
    return base


def note(freq, duree, declin=4.0, partiels=((1, 1.0), (3, 0.25), (6.2, 0.08)), attaque=0.003):
    """Lame de boîte à musique : quelques partiels sinusoïdaux qui s'éteignent en exponentielle."""
    n = int(duree * TAUX)
    sortie = []
    for i in range(n):
        t = i / TAUX
        env = math.exp(-declin * t) * min(1.0, t / attaque)
        v = 0.0
        for mult, amp in partiels:
            # Les partiels aigus s'éteignent plus vite : c'est ce qui donne le « pling » doux.
            v += amp * math.sin(2 * math.pi * freq * mult * t) * math.exp(-declin * (mult - 1) * 0.35 * t)
        sortie.append(v * env)
    return sortie


def bois(freq=900, duree=0.12, declin=45.0, bruit=0.35):
    """Bloc de bois : sinus amorti très court + un peu de bruit filtré pour l'attaque."""
    n = int(duree * TAUX)
    sortie = []
    filtre = 0.0
    for i in range(n):
        t = i / TAUX
        filtre += 0.25 * (random.uniform(-1, 1) - filtre)  # passe-bas simple : bruit moins agressif
        v = math.sin(2 * math.pi * freq * t) + bruit * filtre * math.exp(-200 * t)
        v += 0.4 * math.sin(2 * math.pi * freq * 2.3 * t) * math.exp(-90 * t)
        sortie.append(v * math.exp(-declin * t))
    return sortie


def normaliser(son, crete=0.89):
    m = max(abs(v) for v in son) or 1.0
    # Petit fondu de sortie (5 ms) pour éviter le clic final.
    fondu = int(0.005 * TAUX)
    son = [v * crete / m for v in son]
    for k in range(min(fondu, len(son))):
        son[-1 - k] *= k / fondu
    return son


SEULEMENT = set()  # noms passés en arguments : `python3 scripts/generer_sons.py carillon` ne refait que celui-là


def ecrire(nom, son, qualite=4):
    if SEULEMENT and nom not in SEULEMENT:
        return
    son = normaliser(son)
    os.makedirs(SORTIE, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        chemin_wav = tmp.name
    with wave.open(chemin_wav, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(TAUX)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in son))
    cible = os.path.join(SORTIE, nom + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", chemin_wav, "-c:a", "vorbis", "-strict", "-2", "-ac", "2",
                    "-b:a", f"{48 + 16 * qualite}k", cible], check=True)
    os.remove(chemin_wav)
    print(f"  {nom}.ogg  {len(son) / TAUX:.2f} s")


def hz(nom):
    """Nom de note (ex. 'C5', 'F#4') → fréquence en Hz."""
    nom = nom.replace("Bb", "A#")
    noms = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    return 440.0 * 2 ** ((noms[nom[:-1]] + 12 * (int(nom[-1]) + 1) - 69) / 12)


def melodie(notes, pas, declin=3.5, duree_note=1.2):
    son = []
    for k, n in enumerate(notes):
        if n:
            mixer(son, note(hz(n), duree_note, declin), k * pas)
    return son


def musique():
    """Boucle de boîte à musique (~34 s) en fa majeur, 84 bpm : mélodie + basse douce, raccord sans couture."""
    pas = 60 / 84 / 2  # croches
    mel = ("A5 . C6 A5 G5 . F5 . | G5 A5 G5 F5 D5 . C5 . | F5 . A5 C6 D6 . C6 A5 | G5 . . . C5 . . . |"
           "A5 . C6 A5 G5 . F5 . | G5 A5 Bb5 A5 G5 . E5 . | F5 G5 A5 G5 F5 . D5 E5 | F5 . . . . . . . |"
           "D6 . C6 A5 C6 . A5 G5 | A5 . G5 F5 D5 . F5 . | G5 . A5 G5 F5 . D5 C5 | D5 . F5 . G5 . . . |"
           "A5 . C6 A5 G5 . F5 . | G5 A5 G5 F5 D5 . C5 . | F5 G5 A5 C6 G5 . E5 . | F5 . . . . . . . ")
    basse = ["F3", "C3", "D3", "C3", "F3", "C3", "Bb2", "F3", "D3", "A2", "Bb2", "C3", "F3", "C3", "Bb2", "F3"]
    jetons = [j.replace("Bb", "A#") for j in mel.replace("|", " ").split()]
    son = silence(len(jetons) * pas + 0.01)
    for k, j in enumerate(jetons):
        if j != ".":
            mixer(son, note(hz(j), 1.6, 2.6), k * pas, 0.55)
    for k, b in enumerate(basse):
        b = b.replace("Bb", "A#")
        mixer(son, note(hz(b), 3.0, 1.2, ((1, 1.0), (2, 0.3))), k * 8 * pas, 0.35)
        mixer(son, note(hz(b) * 1.5, 1.5, 2.0, ((1, 1.0),)), k * 8 * pas + 4 * pas, 0.15)
    longueur = int(len(jetons) * pas * TAUX)
    # Raccord : la traîne qui dépasse la boucle est repliée au début, pour que la reprise soit invisible.
    queue = son[longueur:]
    son = son[:longueur]
    for i, v in enumerate(queue):
        if i < len(son):
            son[i] += v
    return son


def musique_vague():
    """Boucle de vague (~26 s) en ré mineur doux, 112 bpm : ostinato de boîte à musique + blocs de bois en rythme.
    Plus vive que la musique de construction pour porter la tension, mais toujours « jouet » (pas de batterie agressive)."""
    pas = 60 / 112 / 2  # croches
    mesures = 12
    accords = [["D5", "F5", "A5"], ["A#4", "D5", "F5"], ["C5", "E5", "G5"], ["A4", "C#5", "E5"]]
    basses = ["D3", "A#2", "C3", "A2"]
    son = silence(mesures * 8 * pas + 0.01)
    for m in range(mesures):
        accord = accords[m % 4]
        t0 = m * 8 * pas
        # Ostinato : arpège montant-descendant en croches.
        motif = [0, 1, 2, 1, 0, 1, 2, 1] if m % 2 == 0 else [0, 2, 1, 2, 0, 2, 1, 2]
        for k, i in enumerate(motif):
            mixer(son, note(hz(accord[i]), 0.8, 5.0), t0 + k * pas, 0.42)
        # Mélodie aiguë toutes les deux mesures.
        if m % 2 == 1:
            haut = accord[2][:-1] + str(int(accord[2][-1]) + 1)
            mixer(son, note(hz(haut), 1.4, 2.6), t0, 0.35)
            mixer(son, note(hz(accord[1][:-1] + str(int(accord[1][-1]) + 1)), 1.2, 2.8), t0 + 3 * pas, 0.3)
        b = basses[m % 4]
        mixer(son, note(hz(b), 1.8, 1.8, ((1, 1.0), (2, 0.35))), t0, 0.45)
        mixer(son, note(hz(b), 1.0, 2.5, ((1, 1.0), (2, 0.3))), t0 + 4 * pas, 0.3)
        # Percussions bois : grave sur les temps 1 et 3, aigu en contretemps.
        for k in range(8):
            if k in (0, 4):
                mixer(son, bois(260, 0.18, 24, 0.5), t0 + k * pas, 0.5)
            elif k % 2 == 1:
                mixer(son, bois(1700, 0.05, 90, 0.4), t0 + k * pas, 0.18)
    longueur = int(mesures * 8 * pas * TAUX)
    queue = son[longueur:]
    son = son[:longueur]
    for i, v in enumerate(queue):
        if i < len(son):
            son[i] += v
    return son


def main():
    import sys
    SEULEMENT.update(sys.argv[1:])
    print("Génération des sons dans assets/audio/ :")
    # Pose d'une tuile : « toc » de bois grave + petit cliquet métallique.
    s = bois(320, 0.25, 22, 0.6)
    mixer(s, bois(1900, 0.06, 80, 0.2), 0.012, 0.25)
    ecrire("pose", s)
    # Rotation : trois crans de cliquet rapides.
    s = []
    for k in range(3):
        mixer(s, bois(2400 - k * 150, 0.05, 110, 0.5), k * 0.055, 0.8)
    ecrire("rotation", s)
    # Un jouet sort de l'atelier : petit « pling » de deux notes.
    s = note(hz("E6"), 0.35, 9)
    mixer(s, note(hz("B6"), 0.3, 11), 0.06, 0.6)
    ecrire("jouet_sort", s)
    # Scarabée cassé : petit craquement de laiton (bloc aigu + bruit court), discret.
    s = bois(1300, 0.09, 60, 1.2)
    mixer(s, note(hz("G6"), 0.15, 25, ((1, 1.0), (2.7, 0.4))), 0.0, 0.35)
    ecrire("scarabee_casse", s)
    # Horloge touchée : « bong » de cloche doux, deux notes descendantes.
    s = note(hz("D5"), 1.4, 2.5, ((1, 1.0), (2.4, 0.35), (5.1, 0.12)))
    mixer(s, note(hz("A4"), 1.2, 2.8, ((1, 1.0), (2.4, 0.3))), 0.12, 0.8)
    mixer(s, bois(180, 0.3, 14, 0.3), 0.0, 0.5)
    ecrire("horloge_touchee", s)
    # Coup de carillon (playtest 3) : trois cloches claires qui montent, longue résonance de laiton.
    s = note(hz("G5"), 1.6, 2.2, ((1, 1.0), (2.76, 0.45), (5.4, 0.2), (8.9, 0.08)))
    mixer(s, note(hz("C6"), 1.5, 2.4, ((1, 1.0), (2.76, 0.4), (5.4, 0.15))), 0.09, 0.85)
    mixer(s, note(hz("E6"), 1.4, 2.6, ((1, 1.0), (2.76, 0.35))), 0.18, 0.7)
    ecrire("carillon", s)
    # Début de vague : arpège montant + bloc de bois.
    s = melodie(["C5", "E5", "G5", "C6"], 0.11, 4.0, 0.9)
    mixer(s, bois(500, 0.2, 25), 0.0, 0.5)
    ecrire("vague_debut", s)
    # Victoire : petite ritournelle joyeuse.
    s = melodie(["C5", "E5", "G5", "C6", None, "G5", "C6", "E6", None, "D6", "E6", "G6"], 0.12, 2.8, 1.4)
    mixer(s, note(hz("C4"), 2.0, 1.5, ((1, 1), (2, 0.3))), 0.0, 0.4)
    ecrire("victoire", s)
    # Défaite : la boîte à musique ralentit et descend (jamais lugubre).
    s = []
    t = 0.0
    for k, n in enumerate(["G5", "E5", "D5", "C5", "A4", "G4"]):
        mixer(s, note(hz(n), 1.3, 2.4), t)
        t += 0.16 + k * 0.07
    ecrire("defaite", s)
    # Clic d'interface.
    ecrire("clic", bois(1500, 0.05, 90, 0.3))
    # Ressorts gagnés : « tintin » clair.
    s = note(hz("A6"), 0.4, 8)
    mixer(s, note(hz("E7"), 0.35, 10), 0.07, 0.5)
    ecrire("ressorts", s)
    # Musique de fond en boucle (qualité un peu plus haute : écoutée longtemps).
    ecrire("musique", musique(), qualite=5)
    ecrire("musique_vague", musique_vague(), qualite=5)


if __name__ == "__main__":
    main()
