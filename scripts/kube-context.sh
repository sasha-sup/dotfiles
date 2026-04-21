#!/bin/bash
kubectl config get-contexts
echo
mapfile -t contexts < <(kubectl config get-contexts --no-headers -o name)

echo "Available contexts:"
for i in "${!contexts[@]}"; do
  short="${contexts[i]#*@}"
  printf "%2d) %s\n" $((i+1)) "$short"
done

echo
read -rp "Select kube-context (1–${#contexts[@]}): " choice

if [[ $choice =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#contexts[@]} )); then
  selected="${contexts[choice-1]}"
  echo "Switching to: $selected..."
  kubectl config use-context "$selected" || {
    echo "Error switching context: $selected" >&2
    exit 1
  }
else
  echo "Wrong number: $choice" >&2
  exit 1
fi
