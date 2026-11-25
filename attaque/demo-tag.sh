#!/bin/sh
# Étape 1 : un tag n'est qu'une étiquette, qu'on peut déplacer.
# Un registre local joue Docker Hub ; un « attaquant » qui aurait volé le
# token pousse une image piégée sous le même tag que la vraie.
# Usage : attaque/demo-tag.sh   (depuis la racine du repo)
set -eu

REG=localhost:5000
IMG=$REG/sysinfo-api

docker run -d --rm --name registre-local -p 127.0.0.1:5000:5000 registry:2.8.3 >/dev/null
trap 'docker rm -f registre-local api-victime >/dev/null 2>&1 || true' EXIT
sleep 1

digest() { docker inspect -f '{{index .RepoDigests 0}}' "$1" | cut -d@ -f2; }

echo "== 1. La CI publie la vraie image"
docker build -q -t "$IMG:1.0" . >/dev/null
docker push -q "$IMG:1.0" >/dev/null
VRAI=$(digest "$IMG:1.0")
echo "   $IMG:1.0 -> $VRAI"

echo "== 2. L'attaquant pousse une image piégée sous le MÊME tag"
docker build -q -t "$IMG:1.0" --build-arg ORIGINALE="$IMG@$VRAI" -f attaque/Dockerfile.piege attaque >/dev/null
docker push -q "$IMG:1.0" >/dev/null
PIEGE=$(digest "$IMG:1.0")
echo "   $IMG:1.0 -> $PIEGE"

echo "== 3. La victime fait un pull du tag, comme d'habitude"
docker rmi -f "$IMG:1.0" >/dev/null
docker pull -q "$IMG:1.0" >/dev/null
echo "   reçu : $(digest "$IMG:1.0")"
docker run -d --name api-victime -e DB_PASSWORD=x -e AWS_SECRET_ACCESS_KEY=y "$IMG:1.0" >/dev/null
sleep 2
docker logs api-victime 2>&1 | sed 's/^/   /'

echo "== 4. Avec le digest, on obtient exactement ce qu'on a demandé"
docker pull -q "$IMG@$VRAI" >/dev/null
echo "   $IMG@$VRAI : CMD = $(docker inspect -f '{{json .Config.Cmd}}' "$IMG@$VRAI")"
