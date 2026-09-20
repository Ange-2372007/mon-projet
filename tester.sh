#!/bin/bash
# Verifie qu'une image durcie demarre encore et repond correctement.
# A executer apres chaque construction, AVANT de lancer collecter.sh

# Usage : ./tester.sh nom-image

set -u

IMAGE=${1:-}
PORT=18080
CONTENEUR="test-${RANDOM}"

if [ -z "$IMAGE" ]; then
    echo "Utilisation : ./tester.sh nom-image"
    exit 1
fi

# Arrete et supprime le conteneur quoi qu'il arrive
nettoyer() {
    docker rm -f "$CONTENEUR" >/dev/null 2>&1
}

trap nettoyer EXIT

echo "Demarrage de $IMAGE..."
if ! docker run -d --name "$CONTENEUR" -p "${PORT}:8080" "$IMAGE" >/dev/null; then
    echo "ECHEC : le conteneur n'a pas pu demarrer."
    exit 1
fi

# Attend que l'application reponde, jusqu'a 15 secondes
echo -n "Attente de la reponse"
for i in $(seq 1 15); do
    if curl -sf "http://localhost:${PORT}/health" >/dev/null 2>&1; then
        echo " ok"
        break
    fi
    echo -n "."
    sleep 1
done

# Verifie la route /health
REPONSE=$(curl -sf "http://localhost:${PORT}/health" 2>/dev/null)
if [ -z "$REPONSE" ]; then
    echo
    echo "ECHEC : aucune reponse sur /health."
    echo "Journaux du conteneur :"
    docker logs "$CONTENEUR" 2>&1 | tail -20
    exit 1
fi

if ! echo "$REPONSE" | grep -q '"status"'; then
    echo "ECHEC : reponse inattendue sur /health -> $REPONSE"
    exit 1
fi

# Verifie la route racine
ACCUEIL=$(curl -sf "http://localhost:${PORT}/" 2>/dev/null)
if ! echo "$ACCUEIL" | grep -q "fonctionnelle"; then
    echo "ECHEC : reponse inattendue sur / -> $ACCUEIL"
    exit 1
fi

echo "SUCCES : $IMAGE demarre et repond sur / et /health."
echo "  /health -> $REPONSE"
exit 0
