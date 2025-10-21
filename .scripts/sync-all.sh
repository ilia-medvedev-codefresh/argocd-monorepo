#!/bin/bash

set -e

ARGOCD_NAMESPACE="argocd"
ARGOCD_SERVER_URL="http://localhost:8888"

cd "$(dirname "$0")/.."

# Get ArgoCD admin password and login to get token
ARGOCD_ADMIN_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8888 --username admin --password $ARGOCD_ADMIN_PASSWORD --insecure --plaintext > /dev/null
ARGOCD_TOKEN=$(argocd account generate-token)

if [ -z "$ARGOCD_TOKEN" ]; then
    echo "Failed to get ARGOCD_TOKEN"
    exit 1
fi

while true; do
    APPS=(app-*)
    NUM_APPS=${#APPS[@]}
    if [ "$NUM_APPS" -eq 0 ]; then
        echo "No app-* folders found!"
        exit 1
    fi

    echo "Syncing all $NUM_APPS apps using ArgoCD API via curl..."

    pids=()
    for APP in "${APPS[@]}"; do
        APP_NAME="${APP%/}"
        echo "Syncing $APP_NAME"
        curl -s -X POST "$ARGOCD_SERVER_URL/api/v1/applications/$APP_NAME/sync" \
            -H "Authorization: Bearer $ARGOCD_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{}' &
        pids+=("$!")
    done

    # Wait for all backgrounded syncs to finish
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    echo "All sync requests sent (parallel)."
done
