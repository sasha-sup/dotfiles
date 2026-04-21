#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <NAMESPACE> <POD_PREFIX>"
    exit 1
fi

NAMESPACE="$1"
POD_PREFIX="$2"

# Сначала проверим, существует ли под с таким именем напрямую
if kubectl get pod -n "$NAMESPACE" "$POD_PREFIX" >/dev/null 2>&1; then
    POD_NAME="$POD_PREFIX"
else
    # Если точного совпадения нет, ищем по префиксу "POD_PREFIX-"
    # Обычно у подов с хешем имя вида: <prefix>-<hash>
    mapfile -t MATCHING_PODS < <(
        kubectl get pods -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
        | grep "^${POD_PREFIX}-"
    )

    if [ "${#MATCHING_PODS[@]}" -eq 0 ]; then
        echo "No pods found in namespace '$NAMESPACE' matching prefix '${POD_PREFIX}-'"
        exit 1
    elif [ "${#MATCHING_PODS[@]}" -gt 1 ]; then
        echo "Multiple pods match prefix '${POD_PREFIX}-' in namespace '$NAMESPACE':"
        for p in "${MATCHING_PODS[@]}"; do
            echo "  $p"
        done
        echo "Please provide a more specific prefix."
        exit 1
    else
        POD_NAME="${MATCHING_PODS[0]}"
    fi
fi

echo "Executing into pod: $POD_NAME (namespace: $NAMESPACE)"

kubectl exec -it -n "$NAMESPACE" "$POD_NAME" -- sh -c "clear; (bash || ash || sh)"
