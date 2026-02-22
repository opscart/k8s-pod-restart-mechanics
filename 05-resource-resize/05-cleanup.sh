#!/bin/bash
NS="restart-demos"
echo ""
echo "Cleaning up Lab 05 resources..."
kubectl delete pod resize-demo -n $NS --ignore-not-found
echo "✅ Lab 05 resources removed"
echo ""
echo "To switch back to your main cluster:"
echo "  minikube profile opscart"
echo "  kubectl config use-context opscart"
echo ""
