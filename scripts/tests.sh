#!/usr/bin/env bash
# Lance les tests de logique sans ouvrir l'éditeur (Godot en mode headless).
# Code de sortie 0 = tout est vert.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

# Import des ressources si le cache .godot/ n'existe pas encore (premier lancement).
[ -d "$ROOT/.godot" ] || "$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true

"$GODOT" --headless --path "$ROOT" --script res://tests/run_tests.gd 2>&1 | grep -vE "^Godot Engine|^$"
exit "${PIPESTATUS[0]}"
