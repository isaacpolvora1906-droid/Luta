#!/usr/bin/env bash
# Roda os testes de lógica e um teste de fumaça da cena de luta, tudo headless.
# Uso: tests/run_tests.sh   (GODOT=/caminho/do/godot para outro binário)
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

# Gera o cache de classes (class_name) e importa os recursos.
"$GODOT" --headless --import >/dev/null 2>&1

echo "== Testes de lógica"
"$GODOT" --headless --script res://tests/run_tests.gd 2>&1 | tee "$log"
status=${PIPESTATUS[0]}

echo "== Teste de fumaça: cena de luta por 300 frames"
"$GODOT" --headless --quit-after 300 2>&1 | tee -a "$log"

if grep -qE "SCRIPT ERROR|Parse Error|ERROR:" "$log"; then
	echo "Erros do Godot encontrados na saída."
	status=1
fi
exit "$status"
