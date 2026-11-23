#!/usr/bin/env bash
# Pont Claude -> Codex, via `codex exec` non interactif (adapté de RobloxVibe pour Godot).
#
# Usage :
#   ./scripts/codex_bridge.sh ecrire <modele> <effort> taches/T01_xxx.md
#   ./scripts/codex_bridge.sh relire <modele> <effort> taches/T01_xxx.md [sortie.md]
#
# - ecrire : Codex travaille directement dans le dépôt (sandbox workspace-write, pas de réseau,
#            aucun MCP), mais UNIQUEMENT sur les fichiers listés dans la section « Fichiers autorisés »
#            de la fiche. Claude relit ensuite le `git diff` et lance ./scripts/tests.sh.
#            Pourquoi pas un dossier drafts/ comme sur Roblox : dans Godot, les scènes et scripts se
#            référencent par chemin (res://…). Un brouillon ailleurs casserait ces liens ; git sert de filet.
# - relire : Codex lit le dépôt sans rien modifier (sandbox read-only) ; sa revue va dans
#            taches/revues/<fiche>.md.
#
# Garde-fou : en mode ecrire, game/ data/ et tests/ doivent être propres (rien de non commité),
# pour que le diff relu par Claude contienne exactement le travail de Codex.
#
# Variables : CODEX_BIN (binaire), CODEX_TIMEOUT (secondes, défaut 1500), CODEX_FORCE=1 (ignorer le garde-fou).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_BIN="${CODEX_BIN:-/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex}"
DELAI="${CODEX_TIMEOUT:-1500}"

MODE="${1:-}"
MODELE="${2:-}"
EFFORT="${3:-}"
CONSIGNE="${4:-}"
SORTIE="${5:-}"

erreur() {
  echo "codex_bridge: $*" >&2
  exit 2
}

[ -x "$CODEX_BIN" ] || erreur "binaire Codex introuvable : $CODEX_BIN (app ChatGPT installée ?)"
case "$MODE" in ecrire | relire) ;; *) erreur "mode attendu : ecrire | relire" ;; esac
[ -n "$MODELE" ] || erreur "modèle obligatoire (ex. gpt-6.2-astra) — jamais de modèle implicite"
case "$EFFORT" in low | medium | high | xhigh | max | ultra) ;; *) erreur "effort attendu : low|medium|high|xhigh|max|ultra" ;; esac
[ -f "$CONSIGNE" ] || erreur "fichier de consigne introuvable : $CONSIGNE"
grep -q "^## Fichiers autorisés" "$CONSIGNE" || erreur "la fiche doit contenir une section « ## Fichiers autorisés »"

# Le modèle doit exister dans le catalogue Codex de la machine (évite une faute de frappe silencieuse).
CATALOGUE="$("$CODEX_BIN" debug models 2>/dev/null || true)"
case "$CATALOGUE" in
  *"\"slug\":\"$MODELE\""*) ;;
  *) erreur "modèle inconnu : $MODELE (liste : \"$CODEX_BIN\" debug models)" ;;
esac

if [ "$MODE" = "ecrire" ] && [ "${CODEX_FORCE:-0}" != "1" ]; then
  if [ -n "$(git -C "$ROOT" status --porcelain -- game data tests 2>/dev/null)" ]; then
    erreur "game/, data/ ou tests/ contiennent des changements non commités : commite ou mets de côté d'abord (ou CODEX_FORCE=1)"
  fi
fi

mkdir -p "$ROOT/.codex-log" "$ROOT/taches/revues"
NOM="$(basename "$CONSIGNE" .md)"
HORO="$(date +%Y%m%d-%H%M%S)"
JOURNAL="$ROOT/.codex-log/$HORO-$MODE-$NOM.log"

if [ "$MODE" = "ecrire" ]; then
  SANDBOX="workspace-write"
  SORTIE="${SORTIE:-$ROOT/.codex-log/$HORO-$NOM.dernier-message.md}"
  PREAMBULE="MODE SOUS-TRAITANCE (Codex, appelé par Claude via scripts/codex_bridge.sh) sur le jeu Godot 4.7 « Rouages ». Lis AGENTS.md puis la fiche ci-dessous. Ne crée ou ne modifie QUE les fichiers de la section « Fichiers autorisés ». Ne touche jamais à assets/, docs/, project.godot, .mcp.json ni scripts/. N'appelle aucun MCP. Commentaires de code en français. Termine par : la liste des fichiers créés ou modifiés, ce qui reste à brancher, et les écarts éventuels par rapport à la fiche."
else
  SANDBOX="read-only"
  SORTIE="${SORTIE:-$ROOT/taches/revues/$NOM.md}"
  PREAMBULE="MODE RELECTURE (Codex, appelé par Claude via scripts/codex_bridge.sh). Tu ne modifies RIEN. Lis AGENTS.md puis uniquement les fichiers cités. Classe chaque trouvaille par sévérité (Critical, High, Medium, Low) avec fichier:ligne, scénario concret de défaillance et correctif proposé. Ne signale que ce que tu as vérifié dans le code."
fi

PROMPT="$PREAMBULE

$(cat "$CONSIGNE")"

echo "codex_bridge: $MODE | $MODELE | effort $EFFORT | sandbox $SANDBOX"
echo "codex_bridge: journal $JOURNAL"

# perl sert de minuteur portable (macOS n'a pas `timeout`).
# `</dev/null` est indispensable : sans lui `codex exec` attend indéfiniment des données sur stdin.
perl -e 'alarm shift; exec @ARGV' "$DELAI" \
  "$CODEX_BIN" exec \
  -m "$MODELE" \
  -c "model_reasoning_effort=\"$EFFORT\"" \
  -s "$SANDBOX" \
  -C "$ROOT" \
  --ephemeral \
  --color never \
  -o "$SORTIE" \
  "$PROMPT" </dev/null >"$JOURNAL" 2>&1 || {
  code=$?
  echo "codex_bridge: ÉCHEC (code $code, 142 = délai dépassé). Fin du journal :" >&2
  tail -n 15 "$JOURNAL" >&2
  exit "$code"
}

echo "codex_bridge: terminé. Dernier message : $SORTIE"
grep -E "^tokens used" -A1 "$JOURNAL" | tr '\n' ' ' && echo
