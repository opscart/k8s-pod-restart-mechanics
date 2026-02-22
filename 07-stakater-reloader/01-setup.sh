#!/bin/bash
# ==========================================================
# 07-stakater-reloader / 01-setup.sh
# PURPOSE: Deploy demo app with Reloader annotation
# WHAT YOU WILL LEARN: How Reloader automates rolling restarts
#                      on ConfigMap changes — no manual steps
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 07: Stakater Reloader"
echo "========================================================"
echo ""
echo "Problem this lab solves:"
echo "  ConfigMap env vars require a pod restart to take effect."
echo "  Engineers must manually run 'kubectl rollout restart'."
echo "  In production, this step is easy to forget."
echo ""
echo "Solution:"
echo "  Stakater Reloader watches ConfigMaps automatically."
echo "  When a ConfigMap changes, Reloader triggers the restart."
echo "  Engineers just update the ConfigMap — nothing else needed."
echo ""

# Check Reloader is installed
kubectl get deployment reloader-reloader -n reloader \
  > /dev/null 2>&1 || {
  echo "❌ Reloader not installed."
  echo "   Run first: bash 07-stakater-reloader/00-install-reloader.sh"
  exit 1
}
echo "✅ Reloader is running"

kubectl create namespace $NS --dry-run=client -o yaml | \
  kubectl apply -f - > /dev/null

kubectl apply -f 07-stakater-reloader/configmap.yaml
echo "✅ ConfigMap created: reloader-demo-config"
echo "   APP_MESSAGE=Hello from OpsCart"

kubectl apply -f 07-stakater-reloader/deployment.yaml
echo "✅ Deployment created: reloader-demo"
echo "   Annotation: reloader.stakater.com/auto: 'true'"

echo ""
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod -l app=reloader-demo \
  -n $NS --timeout=60s

echo ""
echo "--- What was deployed ---"
kubectl get configmap reloader-demo-config -n $NS
echo ""
kubectl get deployment reloader-demo -n $NS
echo ""

echo "--- The key annotation on the Deployment ---"
echo "Run: kubectl get deploy reloader-demo -n $NS -o jsonpath='{.metadata.annotations}'"
kubectl get deploy reloader-demo -n $NS \
  -o jsonpath='{.metadata.annotations}' | python3 -m json.tool 2>/dev/null || \
kubectl get deploy reloader-demo -n $NS \
  -o jsonpath='{.metadata.annotations}'
echo ""
echo ""
echo "This annotation tells Reloader to watch this Deployment."
echo "Any change to its referenced ConfigMap triggers auto-restart."
echo ""
echo "Next step: Run  bash 07-stakater-reloader/02-check-baseline.sh"
echo ""
