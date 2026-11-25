#!/bin/sh
# Lit le rapport JSON de trivy et décide si l'image peut être publiée.
# Refusée si :
#   - sa distribution est en fin de vie (EOSL) : plus personne ne publie de
#     failles pour elle, donc « 0 faille trouvée » ne veut plus rien dire ;
#   - il reste une faille HIGH ou CRITICAL pour laquelle un correctif existe.
# Usage : scripts/verdict-scan.sh trivy.json
set -eu
RAPPORT=${1:?usage : $0 trivy.json}

echo "Distribution : $(jq -r '.Metadata.OS | "\(.Family) \(.Name)"' "$RAPPORT")"
jq -r '.Results[] | .Target as $t | (.Vulnerabilities // [])[]
	| "  \(.Severity)\t\(.VulnerabilityID)\t\(.PkgName) \(.InstalledVersion) -> \(.FixedVersion // "pas de correctif")"' "$RAPPORT"

if jq -e '.Metadata.OS.EOSL == true' "$RAPPORT" >/dev/null; then
	echo "REFUSÉ : distribution en fin de vie, plus aucune faille n'y est signalée"
	exit 1
fi

GRAVES=$(jq '[.Results[] | (.Vulnerabilities // [])[]
	| select(.Severity == "HIGH" or .Severity == "CRITICAL")
	| select((.FixedVersion // "") != "")] | length' "$RAPPORT")
if [ "$GRAVES" -gt 0 ]; then
	echo "REFUSÉ : $GRAVES faille(s) grave(s) avec un correctif disponible"
	exit 1
fi
echo "ACCEPTÉ"
