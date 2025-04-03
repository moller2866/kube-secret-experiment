#!/bin/bash
# filepath: /home/moller/code/kube-secret-experiment/ci/key-renewal.sh

SEALED_SECRETS_NAMESPACE="kube-system"
SEALED_SECRETS_LABEL="sealedsecrets.bitnami.com/sealed-secrets-key"

CURRENT_TIMESTAMP=$(date -R)

echo "Setting SEALED_SECRETS_KEY_CUTOFF_TIME to: $CURRENT_TIMESTAMP"

kubectl -n "$SEALED_SECRETS_NAMESPACE" set env deployment/sealed-secrets-controller SEALED_SECRETS_KEY_CUTOFF_TIME="$CURRENT_TIMESTAMP"

if [ $? -ne 0 ]; then
  echo "Error: Failed to set SEALED_SECRETS_KEY_CUTOFF_TIME."
  exit 1
fi

echo "Waiting for the sealed-secrets controller to generate a new key..."
sleep 10

NEW_KEY=$(kubectl get secret -n "$SEALED_SECRETS_NAMESPACE" -l "$SEALED_SECRETS_LABEL" -o json | jq -r '.items | max_by(.metadata.creationTimestamp) | .metadata.creationTimestamp')
NEW_KEY_SECONDS=$(date -d "$NEW_KEY" +%s)
CURRENT_TIMESTAMP_SECONDS=$(date -d "$CURRENT_TIMESTAMP" +%s)

if [ $NEW_KEY_SECONDS -le $CURRENT_TIMESTAMP_SECONDS ]; then
    echo "Error: No new key was created or key timestamp is not newer than cutoff time."
    exit 1
fi

echo "New key created with timestamp: $NEW_KEY"
echo "Key renewal process completed successfully."