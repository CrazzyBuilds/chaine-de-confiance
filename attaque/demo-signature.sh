#!/bin/sh
# Étape 4 : la même attaque qu'à l'étape 1, mais la victime vérifie la
# signature avant de lancer l'image (scripts/verifier.sh).
# Usage : attaque/demo-signature.sh   (depuis la racine du repo)
set -u

REG=localhost:5000
IMG=$REG/sysinfo-api
VRAIE=ghcr.io/crazzybuilds/chaine-de-confiance:latest
CLES=$(mktemp -d)

docker run -d --rm --name registre-local -p 127.0.0.1:5000:5000 registry:2.8.3 >/dev/null
trap 'docker rm -f registre-local >/dev/null 2>&1; rm -rf "$CLES"' EXIT
sleep 1

echo "== 1. La vraie image (signée par la CI), copiée avec sa signature"
# La signature est rangée à côté de l'image, sous un tag spécial
# « sha256-<digest de l'image> » : on copie l'image, puis ce tag.
D=$(crane digest "$VRAIE")
crane copy "$VRAIE" "$IMG:1.0" 2>/dev/null
crane copy "${VRAIE%:*}:sha256-${D#sha256:}" "$IMG:sha256-${D#sha256:}" 2>/dev/null
scripts/verifier.sh "$IMG:1.0"

echo
echo "== 2. L'attaquant pousse une image piégée sous le même tag"
docker build -q -t "$IMG:1.0" --build-arg ORIGINALE="$VRAIE" -f attaque/Dockerfile.piege attaque >/dev/null
docker push -q "$IMG:1.0" >/dev/null
scripts/verifier.sh "$IMG:1.0"

echo
echo "== 3. L'attaquant signe son image, avec sa propre clé"
COSIGN_PASSWORD= cosign generate-key-pair --output-key-prefix "$CLES/attaquant" >/dev/null 2>&1
# --tlog-upload=false : on n'inscrit pas cette fausse signature dans le
# journal public de Sigstore (c'est une démo).
COSIGN_PASSWORD= cosign sign --yes --key "$CLES/attaquant.key" --tlog-upload=false \
	"$IMG@$(crane digest "$IMG:1.0")" >/dev/null 2>&1
if cosign verify --key "$CLES/attaquant.pub" --insecure-ignore-tlog=true "$IMG:1.0" >/dev/null 2>&1; then
	echo "(sa signature est valide... pour SA clé)"
fi
scripts/verifier.sh "$IMG:1.0"
# La démo a réussi si les deux images piégées ont été refusées.
exit 0
