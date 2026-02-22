#!/bin/bash
# ==========================================================
# 07-stakater-reloader / 00-install-reloader.sh
# PURPOSE: Install Stakater Reloader via Helm (run once)
# NOTE: Run this ONCE before starting the lab.
#       No need to re-run between lab attempts.
# ==========================================================

echo ""
echo "========================================================"
echo "  INSTALLING: Stakater Reloader"
echo "========================================================"
echo ""
echo "Stakater Reloader is a Kubernetes controller that watches"
echo "ConfigMaps and Secrets. When they change, it automatically"
echo "triggers a rolling restart on annotated Deployments."
echo ""
echo "Without Reloader: engineers must remember to run"
echo "  kubectl rollout restart deployment/x"
echo "after every ConfigMap change. Easy to forget in production."
echo ""

# Check Helm is available
command -v helm > /dev/null 2>&1 || {
  echo "❌ Helm not installed."
  echo "   Install: https://helm.sh/docs/intro/install/"
  exit 1
}

helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update

helm install reloader stakater/reloader \
  --namespace reloader \
  --create-namespace \
  --set reloader.watchGlobally=true

echo ""
echo "Waiting for Reloader to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=reloader -n reloader --timeout=60s 2>/dev/null || \
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=reloader \
  -n reloader --timeout=60s

echo ""
echo "--- Reloader is running ---"
kubectl get pods -n reloader
echo ""
echo "========================================================"
echo "  INSTALL COMPLETE"
echo "========================================================"
echo ""
echo "Reloader is watching for annotated Deployments."
echo "Any Deployment with annotation:"
echo "  reloader.stakater.com/auto: 'true'"
echo "will be automatically restarted when its ConfigMap changes."
echo ""
echo "Next step: Run  bash 07-stakater-reloader/01-setup.sh"
echo ""
