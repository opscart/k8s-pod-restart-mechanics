#!/bin/bash
# Scenario 01: ConfigMap — Env Var vs Volume Mount
# Demonstrates: env var changes are invisible; volume mounts sync automatically

set -e
NS="restart-demos"
echo "=============================================="
echo " Scenario 01: ConfigMap Restart Behavior"
echo "=============================================="

# Deploy both modes
kubectl apply -f 01-configmap/configmap.yaml
kubectl apply -f 01-configmap/deployment-env.yaml
kubectl apply -f 01-configmap/deployment-volume.yaml

echo "Waiting for pods..."
kubectl wait --for=condition=ready pod -l scenario=configmap-env \
  -n $NS --timeout=60s
kubectl wait --for=condition=ready pod -l scenario=configmap-volume \
  -n $NS --timeout=60s

ENV_POD=$(kubectl get pod -l app=config-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=config-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "--- BASELINE: env var pod reads APP_COLOR ---"
kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR

echo ""
echo "--- BASELINE: volume pod reads APP_COLOR from file ---"
kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR

echo ""
echo "--- Updating ConfigMap: blue → red ---"
kubectl patch configmap app-config -n $NS \
  -p '{"data":{"APP_COLOR":"red"}}'

echo "Waiting 90s for kubelet sync..."
sleep 90

echo ""
echo "=== EVIDENCE CAPTURE ==="
echo ""
echo "[ENV POD] APP_COLOR after ConfigMap update:"
kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR
echo "  ^ Expected: still 'blue' (frozen at startup)"

echo ""
echo "[VOL POD] APP_COLOR after ConfigMap update:"
kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR
echo "  ^ Expected: 'red' (kubelet synced file on disk)"

echo ""
ENV_RESTARTS=$(kubectl get pod $ENV_POD -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
VOL_RESTARTS=$(kubectl get pod $VOL_POD -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo "Restart count — env pod:    $ENV_RESTARTS (should be 0)"
echo "Restart count — volume pod: $VOL_RESTARTS (should be 0)"
echo ""
echo "CONCLUSION: Volume mount updated without restart."
echo "            Env var still frozen. Manual rollout restart needed."
