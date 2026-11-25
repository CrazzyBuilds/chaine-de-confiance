# chaine-de-confiance

L'API `sysinfo` du TP « Programmer le Cloud », et sa chaîne d'approvisionnement
sécurisée pas à pas : on détourne d'abord un tag d'image, puis on ajoute le
scan, le SBOM, la signature keyless et la provenance, et on rejoue l'attaque.

Explications, résultats et pièges rencontrés : **[FICHE.md](FICHE.md)**.

| Étape | Ce qui est ajouté | Fichiers |
|---|---|---|
| 1 | l'attaque : une image piégée sous le même tag | `attaque/demo-tag.sh`, `attaque/Dockerfile.piege` |
| 2 | SBOM et scan ; image de base maintenue et épinglée par digest | `Dockerfile`, `scripts/verdict-scan.sh` |
| 3 | la CI ne publie que si le scan est bon ; actions épinglées ; Dependabot | `.github/workflows/publication.yml`, `.github/dependabot.yml` |
| 4 | signature keyless (cosign + OIDC GitHub) et vérification avant lancement | `scripts/verifier.sh`, `attaque/demo-signature.sh` |
| 5 | SBOM et provenance joints à l'image, signés | `scripts/inspecter.sh` |

Vérifier puis lancer l'image publiée :

```sh
scripts/verifier.sh ghcr.io/crazzybuilds/chaine-de-confiance:latest -p 8000:8000
scripts/inspecter.sh ghcr.io/crazzybuilds/chaine-de-confiance:latest
```

Outils : `cosign`, `syft`, `trivy`, `crane`, `gh`, Docker.
