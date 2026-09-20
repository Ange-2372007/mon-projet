#!/bin/bash
# Collecte des metriques de securite d'une image Docker.
# Usage : ./collecter.sh nom-image etape
# Exemple : ./collecter.sh projet:h0 H0

set -u

IMAGE=${1:-}
ETAPE=${2:-}

# Verifie que les deux arguments ont ete fournis
if [ -z "$IMAGE" ] || [ -z "$ETAPE" ]; then
    echo "Utilisation : ./collecter.sh nom-image etape"
    echo "Exemple : ./collecter.sh projet:h0 H0"
    exit 1
fi

# Verifie que l'image Docker existe reellement
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Erreur : l'image $IMAGE n'existe pas."
    exit 1
fi

# Verifie que les outils necessaires sont disponibles
for outil in trivy jq; do
    if ! command -v "$outil" >/dev/null 2>&1; then
        echo "Erreur : $outil n'est pas installe."
        exit 1
    fi
done

echo "Analyse de l'image $IMAGE..."

TAILLE_OCTETS=$(docker image inspect "$IMAGE" --format='{{.Size}}')
TAILLE_MO=$(LC_ALL=C awk "BEGIN {printf \"%.2f\", $TAILLE_OCTETS / 1024 / 1024}")
IMAGE_ID=$(docker image inspect "$IMAGE" --format='{{.Id}}')

TRIVY_VERSION=$(trivy --version | head -1 | awk '{print $2}')
DATE_SCAN=$(date +%Y-%m-%d)

# Dossier qui contient les rapports detailles de Trivy
mkdir -p resultats
RAPPORT_JSON="resultats/rapport_${ETAPE}.json"

# Scanne l'image avec Trivy et enregistre le rapport en JSON
trivy image --scanners vuln --format json "$IMAGE" > "$RAPPORT_JSON"

# Compte tous les paquets inventories par Trivy
PAQUETS=$(jq '[.Results[]?.Packages[]?] | length' "$RAPPORT_JSON")

# Compte les vulnerabilites par niveau de severite.
# ATTENTION : Trivy emet CINQ severites, pas quatre. UNKNOWN doit etre comptee,
CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$RAPPORT_JSON")
HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$RAPPORT_JSON")
MEDIUM=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$RAPPORT_JSON")
LOW=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "$RAPPORT_JSON")
UNKNOWN=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "UNKNOWN")] | length' "$RAPPORT_JSON")

TOTAL=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$RAPPORT_JSON")


SOMME=$((CRITICAL + HIGH + MEDIUM + LOW + UNKNOWN))
if [ "$TOTAL" -ne "$SOMME" ]; then
    echo "AVERTISSEMENT : total ($TOTAL) different de la somme des severites ($SOMME)."
    echo "Une severite non prevue est presente dans le rapport."
fi

# Affiche les resultats obtenus dans le terminal
echo "Etape      : $ETAPE"
echo "Image      : $IMAGE"
echo "Taille     : $TAILLE_MO Mo"
echo "Paquets    : $PAQUETS"
echo "CVE total  : $TOTAL"
echo "Critical   : $CRITICAL"
echo "High       : $HIGH"
echo "Medium     : $MEDIUM"
echo "Low        : $LOW"
echo "Unknown    : $UNKNOWN"
echo "Image ID   : $IMAGE_ID"
echo "Trivy      : $TRIVY_VERSION"

FICHIER_CSV="evolution.csv"
ENTETE="etape,image,taille_mo,paquets,cve_total,critical,high,medium,low,unknown,image_id,trivy_version,date_scan"

if [ ! -f "$FICHIER_CSV" ]; then
    echo "$ENTETE" > "$FICHIER_CSV"
fi


if grep -q "^${ETAPE}," "$FICHIER_CSV"; then
    grep -v "^${ETAPE}," "$FICHIER_CSV" > "${FICHIER_CSV}.tmp"
    mv "${FICHIER_CSV}.tmp" "$FICHIER_CSV"
    echo "Ligne existante pour $ETAPE remplacee."
fi

echo "$ETAPE,$IMAGE,$TAILLE_MO,$PAQUETS,$TOTAL,$CRITICAL,$HIGH,$MEDIUM,$LOW,$UNKNOWN,$IMAGE_ID,$TRIVY_VERSION,$DATE_SCAN" >> "$FICHIER_CSV"

{ head -1 "$FICHIER_CSV"; tail -n +2 "$FICHIER_CSV" | sort; } > "${FICHIER_CSV}.tmp"
mv "${FICHIER_CSV}.tmp" "$FICHIER_CSV"

echo
echo "Resultats enregistres dans $FICHIER_CSV"

