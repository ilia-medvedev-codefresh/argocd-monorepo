#!/bin/bash
# Infinite commit script: randomly updates dummy.txt in a random app-*/values.yaml and commits/pushes
set -e

cd "$(dirname "$0")/.."


while true; do
    APPS=(app-*/)
    NUM_APPS=${#APPS[@]}
    if [ "$NUM_APPS" -lt 10 ]; then
        echo "Not enough app-* folders found! Need at least 10."
        exit 1
    fi

    # Pick 10 unique random apps
    SELECTED_APPS=()
    while [ ${#SELECTED_APPS[@]} -lt 10 ]; do
        IDX=$((RANDOM % NUM_APPS))
        APP=${APPS[$IDX]%/}
        # Check for uniqueness
        if [[ ! " ${SELECTED_APPS[@]} " =~ " $APP " ]]; then
            SELECTED_APPS+=("$APP")
        fi
    done

    for SELECTED_APP in "${SELECTED_APPS[@]}"; do
        VALUES_FILE="$SELECTED_APP/values.yaml"
        if [ ! -f "$VALUES_FILE" ]; then
            echo "$VALUES_FILE not found!"
            exit 1
        fi
        RANDOM_TEXT=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 13)
        echo $RANDOM_TEXT
        echo "Updating $VALUES_FILE: configmaps.data[\"dummy.txt\"] = $RANDOM_TEXT"
        yq e ".configmaps.data[\"dummy.txt\"] = \"$RANDOM_TEXT\"" -i "$VALUES_FILE"
        git add "$VALUES_FILE"
        git commit -m "Randomize dummy.txt in $SELECTED_APP on $(date)"
    done

    git push
done
