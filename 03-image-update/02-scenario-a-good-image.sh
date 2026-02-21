#!/bin/bash
# ==========================================================
# 03-image-update / 02-scenario-a-good-image.sh
# SCENARIO A: Update to a valid image (nginx:1.25 → nginx:1.27)
# PROVES: Image change = pod RECREATION (new name, UID, IP)
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  SCENARIO A: Successful Image Update"
echo "========================================================"
echo ""
echo "Updating image from nginx:1.25 to nginx:1.27"
echo "This is a valid image — pull will succeed."
echo ""

# Record BEFORE
POD_BEFORE=$(kubectl get pod -l app=image-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
UID_BEFORE=$(kubectl get pod $POD_BEFORE -n $NS \
  -o jsonpath='{.metadata.uid}')
IP_BEFORE=$(kubectl get pod $POD_BEFORE -n $NS \
  -o jsonpath='{.status.podIP}')

echo "--- BEFORE ---"
echo "Pod name: $POD_BEFORE"
echo "Pod UID:  $UID_BEFORE"
echo "Pod IP:   $IP_BEFORE"
echo "Image:    nginx:1.25"
echo ""

kubectl set image deployment/image-demo app=nginx:1.27 -n $NS
echo "✅ Image update triggered"
echo ""
echo "Watching rolling update..."
kubectl rollout status deployment/image-demo -n $NS --timeout=90s

# Record AFTER
POD_AFTER=$(kubectl get pod -l app=image-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
UID_AFTER=$(kubectl get pod $POD_AFTER -n $NS \
  -o jsonpath='{.metadata.uid}')
IP_AFTER=$(kubectl get pod $POD_AFTER -n $NS \
  -o jsonpath='{.status.podIP}')

echo ""
echo "--- AFTER ---"
echo "Pod name: $POD_AFTER"
echo "Pod UID:  $UID_AFTER"
echo "Pod IP:   $IP_AFTER"
echo "Image:    nginx:1.27"

echo ""
echo "========================================================"
echo "  COMPARISON"
echo "========================================================"
echo ""
echo "  BEFORE                    AFTER"
echo "  Pod: $POD_BEFORE"
echo "  →    $POD_AFTER"
echo "  UID: $UID_BEFORE"
echo "  →    $UID_AFTER"
echo "  IP:  $IP_BEFORE  →  $IP_AFTER"
echo ""
echo "Everything changed — name, UID, IP."
echo "This is NOT a restart. This is RECREATION."
echo "The old pod was deleted. A brand new pod was created."
echo ""
echo "--- Two ReplicaSets (old RS kept for rollback) ---"
kubectl get rs -l app=image-demo -n $NS
echo ""
echo "The old RS (nginx:1.25) has 0 pods but still exists."
echo "Kubernetes keeps it so you can roll back instantly."
echo ""
echo "Want to roll back? Run:"
echo "  kubectl rollout undo deployment/image-demo -n $NS"
echo ""
echo "Next step: Run  bash 03-image-update/03-scenario-b-bad-image.sh"
echo ""
