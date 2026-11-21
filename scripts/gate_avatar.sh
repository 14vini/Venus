#!/bin/bash
# Gate de validação do redesign (Venus em código + tab bar customizada).
# Uso: bash scripts/gate_avatar.sh

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

LOG_DIR="build/gate-logs"
mkdir -p "$LOG_DIR"

PASS=0
FAIL=0
FAILED=()

registrar_pass() { echo "PASS $1"; PASS=$((PASS + 1)); }
registrar_fail() { echo "FAIL $1 — $2"; FAIL=$((FAIL + 1)); FAILED+=("$1"); }

# --- 1. Venus antiga restaurada (sem componente 3D em uso) ------------------
refs_3d=$(grep -rl "VenusAvatar3DView" Venus --include='*.swift' 2>/dev/null || true)
if [ -z "$refs_3d" ]; then
  registrar_pass "sem-3d"
else
  registrar_fail "sem-3d" "ainda há referências: $refs_3d"
fi

if grep -rq "refletindo\|Venus está pensando\|Venus está refletindo" Venus --include='*.swift' 2>/dev/null; then
  registrar_fail "sem-texto-pensamento" "texto de processo da IA ainda presente"
else
  registrar_pass "sem-texto-pensamento"
fi

# --- 2. Build ---------------------------------------------------------------
build_log="$LOG_DIR/avatar-build.log"
xcodebuild -project Venus.xcodeproj \
  -scheme Venus \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$PWD/build/DerivedData" \
  -quiet CODE_SIGNING_ALLOWED=NO build > "$build_log" 2>&1
code=$?
if [ "$code" -eq 0 ]; then
  registrar_pass "build"
else
  registrar_fail "build" "exit $code — $build_log"
fi

# --- 3. Áreas vetadas intactas ---------------------------------------------
veto=$(git status --short -- \
  'Venus/Core/AI' \
  'Venus/Core/DI' \
  'Venus/Features/DailyPlanning/Domain' \
  'Venus/Features/Chat/Domain' \
  'Config.xcconfig' \
  'Config.xcconfig.example' \
  'Venus.xcodeproj')
if [ -z "$veto" ]; then
  registrar_pass "areas-vetadas"
else
  registrar_fail "areas-vetadas" "mudanças detectadas:\n$veto"
fi

echo "==== RESULTADO: $PASS pass / $FAIL fail ===="
if [ "$FAIL" -gt 0 ]; then
  echo "Falharam: ${FAILED[*]}"
  exit 1
fi
exit 0
