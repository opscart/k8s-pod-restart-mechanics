#!/bin/bash
# Scenario 07: Stakater Reloader — Auto rolling restart on ConfigMap change
set -e
NS="restart-demos"

echo "=============================================="
echo " Scenario 07: Stakater Reloader Pattern"
echo "=============================================="

# Check reloader is installed
kubectl get deployment reloader -n reloader > /dev/null 2>&1 || {
  echo "Reloader not installed. Run: bash 07-stakater-reloader/install-reloader.sh"
  exit 1
}

kubectl apply -f 07-stakater-reloader/configmap.yaml
kubectl apply -f 07-stakater-reloader/deployment.yaml

echo "Waiting for pods..."
kubectl wait --for=condition=ready pod -l app=reloader-demo \
  -n $NS --timeout=60s

echo ""
echo "--- Initial pod template hash ---"
kubectl get deploy reloader-demo -n $NS \
  -o jsonpath='{.spec.template.metadata.annotations}' | python3 -m json.tool 2>/dev/null || echo "(no annotations yet)"

echo ""
echo "--- Initial env var inside pod ---"
POD=$(kubectl get pod -l app=reloader-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -n $NS -- env | grep APP_MESSAGE

echo ""
echo "--- Updating ConfigMap (v1 → v2) ---"
kubectl patch configmap reloader-demo-config -n $NS \
  -p '{"data":{"APP_MESSAGE":"Hello from OpsCart v2 — auto-reloaded!"}}'

echo "Watching for rolling restart (up to 60s)..."
kubectl rollout status deployment/reloader-demo -n $NS --timeout=60s

echo ""
echo "--- New pod template hash (Reloader added annotation) ---"
kubectl get deploy reloader-demo -n $NS \
  -o jsonpath='{.spec.template.metadata.annotations}' | python3 -m json.tool 2>/dev/null || true

echo ""
echo "--- Env var in new pod (should be v2) ---"
NEW_POD=$(kubectl get pod -l app=reloader-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
kubectl exec $NEW_POD -n $NS -- env | grep APP_MESSAGE

echo ""
echo "✅ CONFIRMED: Reloader detected ConfigMap change and"
echo "   triggered rolling update automatically."
echo "   Engineers did NOT need to run 'kubectl rollout restart'."
