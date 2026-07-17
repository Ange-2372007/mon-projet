#!/bin/bash
#Recuepration du nom de l'image et de l'etape
IMAGE=$1
ETAPE=$2
# verifie que les deux arguments ont ete fournis
if [ -z "$IMAGE" ] || [ -z "$ETAPE" ]; then
    echo "Utilisation : ./collecter.sh nom-image etape"
    echo "Exemple : ./collecter.sh projet:h0 H0"
    exit 1
fi

# Vérifie que l'image Docker existe réellement
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Erreur : l'image $IMAGE n'existe pas."
    exit 1
fi

echo "Analyse de l'image $IMAGE..."
TAILLE_OCTETS=$(docker image inspect "$IMAGE" --format='{{.Size}}')
TAILLE_MO=$(LC_ALL=C awk "BEGIN {printf \"%.2f\", $TAILLE_OCTETS / 1024 / 1024}")
IMAGE_ID=$(docker image inspect "$IMAGE" --format='{{.Id}}')

# Dossier qui contient les rapports détaillés de Trivy
mkdir -p resultats

# Chemin du rapport JSON de l'étape analysée
RAPPORT_JSON="resultats/rapport_${ETAPE}.json"
#Scanne de l'image avec trivy et enregistre  le rapport en JSON
trivy image --scanners vuln --format json "$IMAGE" > "$RAPPORT_JSON"

#Compte tout les paquets contenus dans le rapport
PAQUETS=$(jq '[.Results[]?.Packages[]?] | length' "$RAPPORT_JSON")

#Compte les vulnerabilites selon leur niveau de severite et affiche le total
CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$RAPPORT_JSON")
HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$RAPPORT_JSON")
MEDIUM=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$RAPPORT_JSON")
LOW=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "$RAPPORT_JSON")

TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

#Affiche les resultats obtenus dans le terminal
echo "Étape : $ETAPE"
echo "Image : $IMAGE"
echo "Taille : $TAILLE_MO Mo"
echo "Paquets : $PAQUETS"
echo "CVE total : $TOTAL"
echo "Critical : $CRITICAL"
echo "High : $HIGH"
echo "Medium : $MEDIUM"
echo "Low : $LOW"
echo "Image ID : $IMAGE_ID"

#Nom du fichier utilise pour comparer les etapes ho a h7
FICHIER_CSV="evolution.csv"

if [ ! -f "$FICHIER_CSV" ]; then
    echo "etape,image,taille_mo,paquets,cve_total,critical,high,medium,low,image_id" > "$FICHIER_CSV"
fi
#Ajouter les resultats de l'etape actuelle au fichier csv
echo "$ETAPE,$IMAGE,$TAILLE_MO,$PAQUETS,$TOTAL,$CRITICAL,$HIGH,$MEDIUM,$LOW,$IMAGE_ID" >> "$FICHIER_CSV"

echo
echo "Résultats enregistrés dans $FICHIER_CSV"
