#!/usr/bin/env bash
## Erzeugt das kombinierte Typeshed für den ty-Checker aus den installierten
## MicroPython-Stubs im .venv:
##   * micropython-stdlib-stubs liefert site-packages/stdlib/ (asyncio, sys, ...),
##     enthält aber kein time.pyi - das liegt nur top-level (für Pyright/Pylance
##     über den "stubPath"-Mechanismus).
##   * ty kennt keinen stubPath, kann aber über [tool.ty.environment].typeshed
##     ein komplettes Typeshed-Verzeichnis nutzen -> hier zusammenbauen.
##
## Wichtig: Das Zielverzeichnis darf NICHT "typings" heißen - das ist ty's
## implizites Stub-Verzeichnis, die Doppelauflösung führt zu einem Panic
## (ty 0.0.65: "dependency graph cycle").
##
## Nach einem Update von micropython-esp32-stubs erneut ausführen:
##   ./tools/update-typeshed.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SITE_PACKAGES=.venv/lib/python3.11/site-packages

rm -rf .typeshed
mkdir -p .typeshed
cp -r "$SITE_PACKAGES/stdlib" .typeshed/

## Einige stdlib-Module (time, _thread, ...) liegen nur als top-level .pyi in
## den site-packages (für Pyrights stubPath) und fehlen im stdlib/-Verzeichnis.
## Alle nachtragen, deren Name in der VERSIONS-Liste des Typesheds steht:
for pyi in "$SITE_PACKAGES"/*.pyi; do
    name=$(basename "$pyi" .pyi)
    if grep -q "^${name}: " .typeshed/stdlib/VERSIONS && [ ! -e ".typeshed/stdlib/${name}.pyi" ] && [ ! -d ".typeshed/stdlib/${name}" ]; then
        cp "$pyi" ".typeshed/stdlib/${name}.pyi"
        echo "  + stdlib/${name}.pyi (aus top-level Stub ergänzt)"
    fi
done

echo ".typeshed aus $SITE_PACKAGES aktualisiert."
