#!/bin/bash
# ==========================================================
# 07-stakater-reloader / 02-check-baseline.sh
# PURPOSE: Record current pod state before ConfigMap update
# ==========================================================

NS="restart-demos"

POD=$(kubectl get pod -l app=reloader-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  BASELINE: Current state before ConfigMap change"
echo "========================================================"
echo ""

echo "--- Current pod ---"
kubectl get pod $POD -n $NS
echo ""

echo "--- APP_MESSAGE inside pod ---"
echo "Run: kubectl exec $POD -n $NS -- env | grep APP_MESSAGE"
kubectl exec $POD -n $NS -- env | grep APP_MESSAGE
echo ""

echo "--- ConfigMap current value ---"
echo "Run: kubectl get configmap reloader-demo-config -n $NS -o jsonpath='{.data.APP_MESSAGE}' && echo"
kubectl get configmap reloader-demo-config -n $NS \
  -o jsonpath='{.data.APP_MESSAGE}' && echo
echo ""

echo "--- No Reloader annotation on pod template yet ---"
echo "Run: kubectl get deploy reloader-demo -n $NS -o jsonpath='{.spec.template.metadata.annotations}'"
ANNOTATIONS=$(kubectl get deploy reloader-demo -n $NS \
  -o jsonpath='{.spec.template.metadata.annotations}' 2>/dev/null)
echo "${ANNOTATIONS:-'(none yet — Reloader adds this after first change)'}"
echo ""

echo "Write down the pod name: $POD"
echo "After ConfigMap update, a NEW pod will replace it."
echo ""
echo "Next step: Run  bash 07-stakater-reloader/03-update-configmap.sh"
echo ""
