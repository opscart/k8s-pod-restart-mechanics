#!/bin/bash
# ==========================================================
# 01-configmap / 05-cleanup.sh
# PURPOSE: Remove all lab 01 resources
# ==========================================================

NS="restart-demos"

echo ""
echo "Cleaning up Lab 01 resources..."

kubectl delete deployment config-demo-env config-demo-volume \
  -n $NS --ignore-not-found
kubectl delete configmap app-config \
  -n $NS --ignore-not-found

echo "✅ Lab 01 resources removed"
echo ""
