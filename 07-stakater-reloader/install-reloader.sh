#!/bin/bash
# Install Stakater Reloader via Helm
echo "Installing Stakater Reloader..."
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
helm install reloader stakater/reloader \
  --namespace reloader \
  --create-namespace \
  --set reloader.watchGlobally=false
echo "✅ Reloader installed in namespace: reloader"
kubectl get pods -n reloader
