#!/bin/bash
NS="restart-demos"

echo ""
echo "========================================================"
echo "  SCENARIO B: Memory Resize"
echo "========================================================"
echo ""
echo "Changing memory limit: 256Mi → 512Mi"
echo ""
echo "resizePolicy for memory: RestartContainer"
echo "We set this explicitly because nginx (and most runtimes)"
echo "allocates memory at startup. Without a restart, the process"
echo "cannot benefit from the increased memory limit."
echo ""
echo "IMPORTANT: This is OUR choice via resizePolicy."
echo "Kubernetes 1.35 does NOT force a container restart for memory."
echo "We are asking for it because our app needs it."
echo ""
echo "What will NOT change regardless:"
echo "  Pod UID  — pod object is never recreated"
echo "  Pod IP   — same network identity throughout"
echo ""

RESTARTS_BEFORE=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
UID_BEFORE=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.metadata.uid}')
IP_BEFORE=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.podIP}')

echo "--- BEFORE ---"
echo "Memory limit:  256Mi"
echo "Restart count: $RESTARTS_BEFORE"
echo "Pod UID:       $UID_BEFORE"
echo "Pod IP:        $IP_BEFORE"
echo ""

kubectl patch pod resize-demo -n $NS \
  --subresource resize \
  -p '{"spec":{"containers":[{"name":"app","resources":{"requests":{"cpu":"250m","memory":"256Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}'

echo "✅ Memory resize patch applied"
echo ""
echo "Container restarting per RestartContainer policy..."
sleep 10

RESTARTS_AFTER=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
UID_AFTER=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.metadata.uid}')
IP_AFTER=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.podIP}')

echo ""
echo "--- AFTER ---"
kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.spec.containers[0].resources}' | python3 -m json.tool
echo ""

echo "========================================================"
echo "  COMPARISON"
echo "========================================================"
echo ""
echo "  Pod UID BEFORE:       $UID_BEFORE"
echo "  Pod UID AFTER:        $UID_AFTER"
echo ""
echo "  Pod IP BEFORE:        $IP_BEFORE"
echo "  Pod IP AFTER:         $IP_AFTER"
echo ""
echo "  Restart count BEFORE: $RESTARTS_BEFORE"
echo "  Restart count AFTER:  $RESTARTS_AFTER"
echo ""

if [ "$UID_BEFORE" = "$UID_AFTER" ] && \
   [ "$IP_BEFORE" = "$IP_AFTER" ]; then
  echo "✅ Pod NOT recreated — UID and IP unchanged"
  echo "   This is what K8s 1.35 GA enables for memory resize"
fi

if [ "$RESTARTS_AFTER" -gt "$RESTARTS_BEFORE" ] 2>/dev/null; then
  echo "✅ Container restarted — because we set RestartContainer policy"
  echo "   This was our explicit choice, not forced by Kubernetes"
fi

echo ""
echo "========================================================"
echo "  FULL PICTURE: Three Operations Compared"
echo "========================================================"
echo ""
echo "  CPU resize (NotRequired policy):"
echo "    Pod UID:       unchanged"
echo "    Pod IP:        unchanged"
echo "    Restart count: unchanged"
echo "    Process:       never touched"
echo ""
echo "  Memory resize (RestartContainer policy):"
echo "    Pod UID:       unchanged  ← K8s 1.35 GA"
echo "    Pod IP:        unchanged  ← K8s 1.35 GA"
echo "    Restart count: +1         ← our resizePolicy choice"
echo "    Process:       restarted inside same pod"
echo ""
echo "  Image update (rolling update):"
echo "    Pod UID:       CHANGED    ← new pod object"
echo "    Pod IP:        CHANGED    ← new network identity"
echo "    Restart count: 0          ← fresh pod, count resets"
echo "    Process:       new process in new pod"
echo ""
echo "Done with Lab 05."
echo "Run  bash 05-resource-resize/05-cleanup.sh  when done"
echo ""
