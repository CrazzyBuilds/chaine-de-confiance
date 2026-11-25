#!/bin/sh
# Ce que les attestations signées disent d'une image :
#   - provenance : de quel commit, de quel workflow elle vient ;
#   - SBOM : ce qu'elle contient.
# Les deux sont vérifiées (signature + identité de la CI) avant d'être lues.
# Usage : scripts/inspecter.sh ghcr.io/crazzybuilds/chaine-de-confiance:latest
set -eu
REF=${1:?usage : $0 image[:tag]}
REPO=CrazzyBuilds/chaine-de-confiance
IDENTITE=https://github.com/$REPO/.github/workflows/publication.yml@refs/heads/main
EMETTEUR=https://token.actions.githubusercontent.com

IMAGE=${REF%:*}@$(crane digest "$REF")
echo "Image : $IMAGE"

echo
echo "== Provenance (vérifiée par gh attestation verify)"
gh attestation verify "oci://$IMAGE" -R "$REPO" --format json 2>/dev/null | jq -r '.[0].verificationResult.statement.predicate as $p
	| "  dépôt    : \\($p.buildDefinition.externalParameters.workflow.repository)",
	  "  workflow : \\($p.buildDefinition.externalParameters.workflow.path)",
	  "  branche  : \\($p.buildDefinition.externalParameters.workflow.ref)",
	  "  commit   : \\($p.buildDefinition.resolvedDependencies[0].digest.gitCommit)",
	  "  exécution: \\($p.runDetails.metadata.invocationId)"'

echo
echo "== SBOM (vérifié par cosign verify-attestation)"
cosign verify-attestation --type spdxjson \\
	--certificate-identity "$IDENTITE" --certificate-oidc-issuer "$EMETTEUR" \\
	"$IMAGE" 2>/dev/null | jq -r '.payload | @base64d | fromjson | .predicate.packages[]
	| select(.name | test("^(nodejs|musl|libssl3|busybox|systeminformation)$"))
	| "  \\(.name) \\(.versionInfo)"' | sort -u
