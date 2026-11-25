#!/bin/sh
# Vérifie qu'une image a bien été signée par la CI de ce repo, puis la lance
# par son digest. Un tag est d'abord traduit en digest : c'est ce digest
# qu'on vérifie et qu'on lance, pour qu'il ne puisse pas changer entre les deux.
# Usage : scripts/verifier.sh ghcr.io/crazzybuilds/chaine-de-confiance:latest [docker run args...]
set -eu
REF=${1:?usage : $0 image[:tag] [arguments de docker run...]}
shift

# L'identité attendue : le workflow publication.yml de ce repo, sur main,
# authentifié par le fournisseur OIDC de GitHub Actions.
IDENTITE=https://github.com/CrazzyBuilds/chaine-de-confiance/.github/workflows/publication.yml@refs/heads/main
EMETTEUR=https://token.actions.githubusercontent.com

DIGEST=$(crane digest "$REF")
IMAGE=${REF%:*}@$DIGEST
echo "$REF -> $DIGEST"

if ! cosign verify --certificate-identity "$IDENTITE" --certificate-oidc-issuer "$EMETTEUR" \
	"$IMAGE" >/dev/null 2>"${TMPDIR:-/tmp}/cosign-$$.log"; then
	sed 's/^/  /' "${TMPDIR:-/tmp}/cosign-$$.log" | tail -3
	rm -f "${TMPDIR:-/tmp}/cosign-$$.log"
	echo "REFUSÉ : pas de signature valide de $IDENTITE"
	exit 1
fi
rm -f "${TMPDIR:-/tmp}/cosign-$$.log"
echo "signature valide : $IDENTITE"

[ $# -gt 0 ] && exec docker run "$@" "$IMAGE"
