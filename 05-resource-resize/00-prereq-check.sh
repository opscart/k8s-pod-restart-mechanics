#!/bin/bash
NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 05: In-Place Pod Resize — Prerequisites"
echo "========================================================"
echo ""

K8S_MINOR=$(kubectl version -o json 2>/dev/null | \
  python3 -c "import json,sys; v=json.load(sys.stdin); \
  print(v['serverVersion']['minor'])" 2>/dev/null | tr -d '+')

echo "Detected Kubernetes version: 1.$K8S_MINOR"
echo ""

if [ -z "$K8S_MINOR" ] || [ "$K8S_MINOR" -lt 35 ] 2>/dev/null; then
  echo "❌ This lab requires Kubernetes 1.35+"
  echo "   minikube start -p k8s-135 --kubernetes-version=v1.35.0 --cpus=4 --memory=6g"
  exit 1
fi

echo "✅ K8s 1.35+ confirmed — in-place resize available"
echo ""
echo "========================================================"
echo "  WHAT THIS LAB PROVES"
echo "========================================================"
echo ""
echo "Before K8s 1.35: changing CPU or memory required pod recreation"
echo "                 Pod UID changed. Pod IP changed."
echo ""
echo "After  K8s 1.35: CPU and memory can be changed IN-PLACE"
echo "                 Pod UID stays same. Pod IP stays same."
echo "                 No pod recreation. Ever."
echo ""
echo "IMPORTANT — what happens to the CONTAINER depends on resizePolicy:"
echo ""
echo "  resizePolicy: NotRequired"
echo "    → cgroup quota updated silently"
echo "    → container process untouched"
echo "    → restart count: unchanged"
echo "    → use for: CPU always, memory if process reads cgroup limits dynamically"
echo ""
echo "  resizePolicy: RestartContainer"
echo "    → cgroup quota updated"
echo "    → container restarted inside same pod"
echo "    → restart count: +1"
echo "    → pod UID and IP: still unchanged"
echo "    → use for: memory when process allocates heap at startup (JVM, Python)"
echo ""
echo "This lab demonstrates BOTH policies on the same pod."
echo ""
echo "Next step: Run  bash 05-resource-resize/01-setup.sh"
echo ""
