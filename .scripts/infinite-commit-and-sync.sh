#!/bin/bash
# Infinite commit script: randomly updates dummy.txt in a random app-*/values.yaml and commits/pushes
set -e

cd "$(dirname "$0")/.."


ARGOCD_NAMESPACE="argocd"
ARGOCD_SERVER_URL="http://localhost:8888"

cd "$(dirname "$0")/.."

# Get ArgoCD admin password and login to get token
ARGOCD_ADMIN_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8888 --username admin --password $ARGOCD_ADMIN_PASSWORD --insecure --plaintext > /dev/null
ARGOCD_TOKEN=$(argocd account generate-token)

while true; do
    APPS=(app-*/)
    NUM_APPS=${#APPS[@]}
    if [ "$NUM_APPS" -lt 10 ]; then
        echo "Not enough app-* folders found! Need at least 10."
        exit 1
    fi

    IDX=$((RANDOM % NUM_APPS))
    APP=${APPS[$IDX]%/}
    VALUES_FILE="$APP/values.yaml"
    if [ ! -f "$VALUES_FILE" ]; then
        echo "$VALUES_FILE not found!"
        exit 1
    fi
    RANDOM_TEXT=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 13)
    echo $RANDOM_TEXT
    echo "Updating $VALUES_FILE: configmaps.data[\"dummy.txt\"] = $RANDOM_TEXT"
    yq e ".configmaps.data[\"dummy.txt\"] = \"$RANDOM_TEXT\"" -i "$VALUES_FILE"
    git add "$VALUES_FILE"
    git commit -m "Randomize dummy.txt in $APP on $(date)"
    git push
    echo "Syncing $APP"
    curl -s -X POST "$ARGOCD_SERVER_URL/api/v1/applications/$APP/sync" \
        -H "Authorization: Bearer $ARGOCD_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{}'
done
