#!/bin/bash
NS="restart-demos"
echo ""
echo "Cleaning up Lab 07 resources..."
kubectl delete deployment reloader-demo -n $NS --ignore-not-found
kubectl delete configmap reloader-demo-config -n $NS --ignore-not-found
echo ""
echo "Note: Reloader itself (namespace: reloader) is NOT removed."
echo "To fully uninstall Reloader run:"
echo "  helm uninstall reloader -n reloader"
echo ""
echo "✅ Lab 07 resources removed"
echo ""
