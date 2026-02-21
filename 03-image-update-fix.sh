#!/bin/bash
# Run from repo root
# Usage: bash this-file.sh

mkdir -p 03-image-update

# ── Manifests ─────────────────────────────────────────────────

cat > 03-image-update/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-demo
  namespace: restart-demos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: image-demo
  template:
    metadata:
      labels:
        app: image-demo
    spec:
      containers:
      - name: app
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests: {cpu: "50m", memory: "32Mi"}
          limits:   {cpu: "100m", memory: "64Mi"}
EOF

cat > 03-image-update/deployment-crashloop.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crash-demo
  namespace: restart-demos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: crash-demo
  template:
    metadata:
      labels:
        app: crash-demo
    spec:
      containers:
      - name: app
        image: nginx:1.25
        command: ["/bin/sh", "-c", "echo Starting && exit 1"]
        resources:
          requests: {cpu: "50m", memory: "32Mi"}
          limits:   {cpu: "100m", memory: "64Mi"}
EOF

# ── 01-setup.sh ───────────────────────────────────────────────
cat > 03-image-update/01-setup.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 03-image-update / 01-setup.sh
# PURPOSE: Deploy app with nginx:1.25 — record pod identity
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 03: Image Update — Three Scenarios"
echo "========================================================"
echo ""
echo "This lab covers three scenarios:"
echo "  Scenario A: Successful image update"
echo "  Scenario B: Bad image (does not exist)"
echo "  Scenario C: Image exists but container crashes"
echo ""
echo "Key question for each: does the pod restart or get recreated?"
echo "The difference matters — name, UID, and IP all tell the story."
echo ""

kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl apply -f 03-image-update/deployment.yaml
echo "✅ Deployment created: image-demo (nginx:1.25, 1 replica)"

echo ""
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod -l app=image-demo \
  -n $NS --timeout=60s

echo ""
echo "========================================================"
echo "  RECORD THESE — compare them after each scenario"
echo "========================================================"
echo ""

POD=$(kubectl get pod -l app=image-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo "Pod name:     $POD"
echo "Pod UID:      $(kubectl get pod $POD -n $NS -o jsonpath='{.metadata.uid}')"
echo "Pod IP:       $(kubectl get pod $POD -n $NS -o jsonpath='{.status.podIP}')"
echo "Image:        $(kubectl get pod $POD -n $NS -o jsonpath='{.spec.containers[0].image}')"
echo "Restart count: $(kubectl get pod $POD -n $NS -o jsonpath='{.status.containerStatuses[0].restartCount}')"

echo ""
echo "--- ReplicaSet ---"
kubectl get rs -l app=image-demo -n $NS
echo ""
echo "Next step: Run  bash 03-image-update/02-scenario-a-good-image.sh"
echo ""
EOF

# ── 02-scenario-a-good-image.sh ───────────────────────────────
cat > 03-image-update/02-scenario-a-good-image.sh << 'EOF'
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
EOF

# ── 03-scenario-b-bad-image.sh ────────────────────────────────
cat > 03-image-update/03-scenario-b-bad-image.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 03-image-update / 03-scenario-b-bad-image.sh
# SCENARIO B: Update to an image that does not exist
# PROVES: Kubernetes protects old pods until new ones are healthy
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  SCENARIO B: Bad Image (does not exist)"
echo "========================================================"
echo ""
echo "Updating image to nginx:this-tag-does-not-exist"
echo "The pull will fail. What happens to the running pod?"
echo ""

# Record current running pod
POD_BEFORE=$(kubectl get pod -l app=image-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo "Current running pod: $POD_BEFORE"
echo "Current image:       nginx:1.27"
echo ""

kubectl set image deployment/image-demo \
  app=nginx:this-tag-does-not-exist -n $NS
echo "✅ Bad image update triggered"
echo ""
echo "Waiting 30 seconds to observe behavior..."
sleep 30

echo ""
echo "========================================================"
echo "  RESULTS"
echo "========================================================"
echo ""
echo "--- All pods in namespace ---"
kubectl get pods -l app=image-demo -n $NS
echo ""
echo "--- Is the original pod still running? ---"
kubectl get pod $POD_BEFORE -n $NS 2>/dev/null && \
  echo "✅ YES — original pod still running" || \
  echo "original pod gone"
echo ""
echo "--- New pod status (should be ImagePullBackOff) ---"
NEW_POD=$(kubectl get pod -l app=image-demo -n $NS \
  --field-selector=status.phase!=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$NEW_POD" ]; then
  kubectl describe pod $NEW_POD -n $NS | grep -A5 "State:"
fi
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  Bad image → new pod stuck in ImagePullBackOff"
echo "  Old pod:   STILL RUNNING (Kubernetes safety net)"
echo ""
echo "  Kubernetes will NOT kill the old pod until the"
echo "  new pod is healthy. Your app stays available."
echo ""
echo "Rolling back to fix this..."
kubectl rollout undo deployment/image-demo -n $NS
kubectl rollout status deployment/image-demo -n $NS --timeout=60s
echo "✅ Rolled back — original image restored"
echo ""
echo "Next step: Run  bash 03-image-update/04-scenario-c-crashloop.sh"
echo ""
EOF

# ── 04-scenario-c-crashloop.sh ────────────────────────────────
cat > 03-image-update/04-scenario-c-crashloop.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 03-image-update / 04-scenario-c-crashloop.sh
# SCENARIO C: Image exists but container crashes immediately
# PROVES: Crash = restart in SAME pod (name/UID unchanged)
#         This is different from image update (recreation)
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  SCENARIO C: Container Crash (CrashLoopBackOff)"
echo "========================================================"
echo ""
echo "Deploying a pod that exits immediately on startup."
echo "Watch what happens — does Kubernetes recreate or restart?"
echo ""

kubectl apply -f 03-image-update/deployment-crashloop.yaml
echo "✅ crash-demo deployed"
echo ""
echo "Waiting 40 seconds to observe crash behavior..."
sleep 40

echo ""
echo "========================================================"
echo "  RESULTS"
echo "========================================================"
echo ""

CRASH_POD=$(kubectl get pod -l app=crash-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo "--- Pod status ---"
kubectl get pod $CRASH_POD -n $NS
echo ""

echo "--- Restart count (watch it climb) ---"
RESTARTS=$(kubectl get pod $CRASH_POD -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
echo "Restart count: $RESTARTS"
echo ""

echo "--- Pod name and UID ---"
echo "Pod name: $CRASH_POD"
echo "Pod UID:  $(kubectl get pod $CRASH_POD -n $NS -o jsonpath='{.metadata.uid}')"
echo ""

echo "--- What happened inside ---"
kubectl describe pod $CRASH_POD -n $NS | grep -A8 "State:"
echo ""

echo "========================================================"
echo "  COMPARISON: Crash vs Image Update"
echo "========================================================"
echo ""
echo "  IMAGE UPDATE (Scenario A):"
echo "    Pod name:     CHANGED  (new pod created)"
echo "    Pod UID:      CHANGED  (different object)"
echo "    Pod IP:       CHANGED  (new network identity)"
echo "    Restart count: 0       (fresh pod)"
echo ""
echo "  CONTAINER CRASH (Scenario C):"
echo "    Pod name:     SAME     (same pod object)"
echo "    Pod UID:      SAME     (same object)"
echo "    Pod IP:       SAME     (same network identity)"
echo "    Restart count: $RESTARTS      (climbs with each crash)"
echo ""
echo "This is the core distinction:"
echo "  Recreation = new pod, new identity, restart count resets"
echo "  Restart    = same pod, same identity, restart count climbs"
echo ""
echo "When someone says 'the pod restarted' — ask which one."
echo "The answer changes your entire debugging approach."
echo ""
echo "Done with Lab 03."
echo "Run  bash 03-image-update/05-cleanup.sh  to remove lab resources"
echo ""
EOF

# ── 05-cleanup.sh ─────────────────────────────────────────────
cat > 03-image-update/05-cleanup.sh << 'EOF'
#!/bin/bash
NS="restart-demos"
echo ""
echo "Cleaning up Lab 03 resources..."
kubectl delete deployment image-demo crash-demo -n $NS --ignore-not-found
echo "✅ Lab 03 resources removed"
echo ""
EOF

chmod +x 03-image-update/*.sh
echo ""
echo "✅ Lab 03 scripts created"
echo ""
echo "Run the lab:"
echo "  bash 03-image-update/01-setup.sh"
echo "  bash 03-image-update/02-scenario-a-good-image.sh"
echo "  bash 03-image-update/03-scenario-b-bad-image.sh"
echo "  bash 03-image-update/04-scenario-c-crashloop.sh"
echo "  bash 03-image-update/05-cleanup.sh"