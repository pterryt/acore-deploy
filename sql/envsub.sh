#!/usr/bin/env bash
set -euo pipefail
: "${SERVICE_NAME:?Missing environment variables. Run via Make. Use 'make help' for options.}"

find . -type f -name '*.sql.dist' -print0 |
while IFS= read -r -d '' template; do
    output="${template%.dist}"

    echo "Rendering $template -> $output"

    envsubst < "$template" > "$output"
done
