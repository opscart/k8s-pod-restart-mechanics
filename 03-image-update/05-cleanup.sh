#!/bin/bash
NS="restart-demos"
echo ""
echo "Cleaning up Lab 03 resources..."
kubectl delete deployment image-demo crash-demo -n $NS --ignore-not-found
echo "✅ Lab 03 resources removed"
echo ""
