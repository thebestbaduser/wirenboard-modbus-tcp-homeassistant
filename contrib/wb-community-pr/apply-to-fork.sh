#!/usr/bin/env bash
# Применить шаблоны к форку wirenboard/wb-community.
# Использование:
#   1. На GitHub: Fork https://github.com/wirenboard/wb-community
#   2. git clone https://github.com/YOUR_USER/wb-community.git && cd wb-community
#   3. git checkout -b add-rilheva-m1w2-mrm2-map3et-templates
#   4. bash /path/to/apply-to-fork.sh
#   5. git add templates/rilheva-modbus-poll/ && git commit && git push -u origin HEAD
#   6. Открыть PR в wirenboard/wb-community (текст — PR_BODY.md)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-.}"

if [[ ! -d "$DEST/.git" ]]; then
  echo "Ошибка: запусти из корня клона wb-community (где есть .git)" >&2
  exit 1
fi

cp -r "$SCRIPT_DIR/templates/rilheva-modbus-poll/"* "$DEST/templates/rilheva-modbus-poll/"
echo "OK: файлы скопированы в $DEST/templates/rilheva-modbus-poll/"
echo "Дальше: git add, commit, push, PR → wirenboard/wb-community"
