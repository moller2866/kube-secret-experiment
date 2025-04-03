#!/bin/bash

SEALED_SECRETS_NAMESPACE="kube-system"
SEALED_SECRETS_LABEL="sealedsecrets.bitnami.com/sealed-secrets-key"
LATEST_KEY_TIMESTAMP=$(kubectl get secret -n "$SEALED_SECRETS_NAMESPACE" -l "$SEALED_SECRETS_LABEL" -o json | jq -r '.items | max_by(.metadata.creationTimestamp) | .metadata.creationTimestamp')

if [ -z "$LATEST_KEY_TIMESTAMP" ]; then
  echo "Error: Could not retrieve the latest sealed-secrets key."
  exit 1
fi

SEALED_SECRETS=$(kubectl get sealedsecrets --all-namespaces -o json)

echo "Checking SealedSecrets..."

ALL_PASSED=true

while IFS= read -r SECRET; do
    SECRET_NAME=$(echo "$SECRET" | jq -r '.metadata.name')
    SECRET_NAMESPACE=$(echo "$SECRET" | jq -r '.metadata.namespace')
    SECRET_TIMESTAMP=$(echo "$SECRET" | jq -r '.status.conditions[0].lastUpdateTime')

    if [[ $(date -d "$SECRET_TIMESTAMP" +%s) -gt $(date -d "$LATEST_KEY_TIMESTAMP" +%s) ]]; then
        echo "$SECRET_NAMESPACE/$SECRET_NAME --> Passed"
    else
        echo "$SECRET_NAMESPACE/$SECRET_NAME --> Failed"
        ALL_PASSED=false
    fi
done < <(echo "$SEALED_SECRETS" | jq -c '.items[]')

if $ALL_PASSED; then
    exit 0
else
    exit 1
fi
