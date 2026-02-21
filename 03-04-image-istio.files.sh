#!/bin/bash
# Run from repo root to create all scripts for Lab 03 and Lab 04
# Usage: bash this-file.sh

# ============================================================
# LAB 03 — Image Update
# ============================================================

mkdir -p 03-image-update

# ── manifests ─────────────────────────────────────────────────
cat > 03-image-update/deployment-v1.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-demo
  namespace: restart-demos
spec:
  replicas: 2
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

# ── 01-setup.sh ───────────────────────────────────────────────
cat > 03-image-update/01-setup.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 03-image-update / 01-setup.sh
# PURPOSE: Deploy app running nginx 1.25 (simulates current prod)
# WHAT YOU WILL LEARN: Image changes ALWAYS require pod recreation
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 03: Container Image Update"
echo "========================================================"
echo ""
echo "We will deploy an app running nginx:1.25"
echo "Then update it to nginx:1.27 and watch what happens."
echo ""
echo "Unlike ConfigMap or Secret changes — an image change"
echo "ALWAYS requires pod recreation. There is no hot-reload."
echo ""

kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl apply -f 03-image-update/deployment-v1.yaml
echo "✅ Deployment created: image-demo (nginx:1.25, 2 replicas)"

echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=image-demo \
  -n $NS --timeout=60s

echo ""
echo "--- Pods running now ---"
kubectl get pods -l app=image-demo -n $NS -o wide

echo ""
echo "--- Current image ---"
kubectl get deployment image-demo -n $NS \
  -o jsonpath='{.spec.template.spec.containers[0].image}' && echo

echo ""
echo "--- ReplicaSet created for this version ---"
kubectl get rs -l app=image-demo -n $NS

echo ""
echo "========================================================"
echo "  SETUP COMPLETE"
echo "========================================================"
echo ""
echo "App is running nginx:1.25 on 2 pods."
echo ""
echo "Next step: Run  bash 03-image-update/02-check-baseline.sh"
echo ""
EOF

# ── 02-check-baseline.sh ──────────────────────────────────────
cat > 03-image-update/02-check-baseline.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 03-image-update / 02-check-baseline.sh
# PURPOSE: Record pod names and image before the update
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  BASELINE: Current pod state before image update"
echo "========================================================"
echo ""

echo "--- Running pods ---"
kubectl get pods -l app=image-demo -n $NS
echo ""

echo "--- Confirm image version ---"
echo "Run: kubectl get pods -l app=image-demo -n $NS -o jsonpath='{.items[*].spec.containers[0].image}'"
kubectl get pods -l app=image-demo -n $NS \
  -o jsonpath='{.items[*].spec.containers[0].image}' && echo
echo ""

echo "--- Pod UIDs (these will change after update — proves recreation) ---"
echo "Run: kubectl get pods -l app=image-demo -n $NS -o jsonpath='{.items[*].metadata.uid}'"
kubectl get pods -l app=image-demo -n $NS \
  -o jsonpath='{.items[*].metadata.uid}' && echo
echo ""

echo "--- ReplicaSet before update ---"
kubectl get rs -l app=image-demo -n $NS
echo ""

echo "Write down the pod names and UIDs above."
echo "After the update, NEW pods with NEW UIDs will replace them."
echo "This proves recreation — not restart."
echo ""
echo "Next step: Run  bash 03-image-update/03-update-image.sh"
echo ""
EOF

# ── 03-update-image.sh ────────────────────────────────────────
cat > 03-image-update/03-update-image.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 03-image-update / 03-update-image.sh
# PURPOSE: Update image to nginx:1.27, watch rolling update
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  UPDATING IMAGE: nginx:1.25 → nginx:1.27"
echo "========================================================"
echo ""
echo "This triggers a rolling update."
echo "Kubernetes will create NEW pods (new UIDs, new IPs)"
echo "before terminating the old ones."
echo ""

kubectl set image deployment/image-demo \
  app=nginx:1.27 -n $NS

echo "✅ Image update triggered"
echo ""
echo "--- Watch the rolling update happen in real time ---"
echo "Run: kubectl rollout status deployment/image-demo -n $NS"
kubectl rollout status deployment/image-demo -n $NS
echo ""

echo "========================================================"
echo "  RESULTS"
echo "========================================================"
echo ""

echo "--- New pods (notice different names from baseline) ---"
kubectl get pods -l app=image-demo -n $NS
echo ""

echo "--- New image version confirmed ---"
echo "Run: kubectl get pods -l app=image-demo -n $NS -o jsonpath='{.items[*].spec.containers[0].image}'"
kubectl get pods -l app=image-demo -n $NS \
  -o jsonpath='{.items[*].spec.containers[0].image}' && echo
echo ""

echo "--- New pod UIDs (compare with baseline — all different) ---"
kubectl get pods -l app=image-demo -n $NS \
  -o jsonpath='{.items[*].metadata.uid}' && echo
echo ""

echo "--- Two ReplicaSets now exist ---"
echo "Run: kubectl get rs -l app=image-demo -n $NS"
kubectl get rs -l app=image-demo -n $NS
echo ""
echo "Old RS: 0 replicas (pods terminated)"
echo "New RS: 2 replicas (pods running nginx:1.27)"
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  Image change = pod RECREATION, not restart"
echo "  New pods get new UIDs and new IPs"
echo "  Old pods are terminated only after new ones are ready"
echo "  This is why your app needs graceful shutdown handling"
echo ""
echo "Next step: Run  bash 03-image-update/04-rollback.sh"
echo "           (Bonus: roll back to nginx:1.25 if needed)"
echo ""
EOF

# ── 04-rollback.sh ────────────────────────────────────────────
cat > 03-image-update/04-rollback.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 03-image-update / 04-rollback.sh
# PURPOSE: Show rollback — also a rolling update, same mechanics
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  ROLLBACK: nginx:1.27 → nginx:1.25"
echo "========================================================"
echo ""
echo "Rollback is just another rolling update in reverse."
echo "Kubernetes reuses the old ReplicaSet — no new RS created."
echo ""

echo "--- Rollout history before rollback ---"
kubectl rollout history deployment/image-demo -n $NS
echo ""

kubectl rollout undo deployment/image-demo -n $NS

echo "Waiting for rollback to complete..."
kubectl rollout status deployment/image-demo -n $NS --timeout=60s

echo ""
echo "--- Image after rollback ---"
kubectl get pods -l app=image-demo -n $NS \
  -o jsonpath='{.items[*].spec.containers[0].image}' && echo
echo ""

echo "--- ReplicaSets after rollback ---"
kubectl get rs -l app=image-demo -n $NS
echo ""
echo "Notice: old RS scaled back up, new RS scaled to 0"
echo "Kubernetes keeps RS history for fast rollbacks."
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
kubectl delete deployment image-demo -n $NS --ignore-not-found
echo "✅ Lab 03 resources removed"
echo ""
EOF

chmod +x 03-image-update/*.sh
echo "✅ Lab 03 scripts created"

# ============================================================
# LAB 04 — Istio Routing (Zero Pod Restarts)
# ============================================================

mkdir -p 04-istio-routing

# ── 01-setup.sh ───────────────────────────────────────────────
cat > 04-istio-routing/01-setup.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 04-istio-routing / 01-setup.sh
# PURPOSE: Deploy two app versions with Istio routing
# WHAT YOU WILL LEARN: Istio routing changes NEVER restart pods
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 04: Istio Routing — Zero Pod Restarts"
echo "========================================================"
echo ""
echo "We will deploy two versions of an app behind Istio."
echo "Then change routing rules and prove no pod restarts."
echo ""
echo "Istio updates Envoy's in-memory route table via xDS."
echo "No file write. No process signal. No pod restart. Ever."
echo ""

# Check Istio is installed
kubectl get ns istio-system > /dev/null 2>&1 || {
  echo "❌ Istio not installed. Run: minikube addons enable istio-provision"
  exit 1
}
echo "✅ Istio detected"

kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - > /dev/null

kubectl apply -f 04-istio-routing/deployment.yaml
kubectl apply -f 04-istio-routing/service.yaml
kubectl apply -f 04-istio-routing/destination-rule.yaml
kubectl apply -f 04-istio-routing/virtual-service-v1.yaml

echo "✅ echo-v1 deployed (2 replicas)"
echo "✅ echo-v2 deployed (2 replicas)"
echo "✅ Service created: echo"
echo "✅ DestinationRule created"
echo "✅ VirtualService created: 100% traffic → v1"

echo ""
echo "Waiting for pods..."
kubectl wait --for=condition=ready pod -l app=echo,version=v1 \
  -n $NS --timeout=90s
kubectl wait --for=condition=ready pod -l app=echo,version=v2 \
  -n $NS --timeout=90s

echo ""
echo "--- All pods running ---"
kubectl get pods -l app=echo -n $NS
echo ""

echo "--- Current routing: 100% → v1 ---"
kubectl get virtualservice echo -n $NS -o yaml | grep -A10 "route:"
echo ""

echo "========================================================"
echo "  SETUP COMPLETE"
echo "========================================================"
echo ""
echo "Both app versions are running."
echo "All traffic currently routes to v1."
echo ""
echo "Next step: Run  bash 04-istio-routing/02-check-baseline.sh"
echo ""
EOF

# ── 02-check-baseline.sh ──────────────────────────────────────
cat > 04-istio-routing/02-check-baseline.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 04-istio-routing / 02-check-baseline.sh
# PURPOSE: Record restart counts BEFORE routing change
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  BASELINE: Record restart counts before routing change"
echo "========================================================"
echo ""
echo "We record restart counts NOW."
echo "After changing the VirtualService, we compare."
echo "If counts are the same — zero restarts occurred."
echo ""

echo "--- All echo pods and their restart counts ---"
kubectl get pods -l app=echo -n $NS \
  -o custom-columns="NAME:.metadata.name,VERSION:.metadata.labels.version,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp"
echo ""

echo "--- Current VirtualService (100% to v1) ---"
echo "Run: kubectl get virtualservice echo -n $NS"
kubectl get virtualservice echo -n $NS
echo ""

echo "Write down the restart counts above — all should be 0."
echo "They must stay the same after we change the routing rule."
echo ""
echo "Next step: Run  bash 04-istio-routing/03-change-routing.sh"
echo ""
EOF

# ── 03-change-routing.sh ──────────────────────────────────────
cat > 04-istio-routing/03-change-routing.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 04-istio-routing / 03-change-routing.sh
# PURPOSE: Change routing 100%→v1 to 80/20 canary split
#          Prove ZERO pod restarts occur
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  CHANGING ROUTING: 100% v1 → 80% v1 / 20% v2"
echo "========================================================"
echo ""
echo "This simulates a canary deployment."
echo "20% of traffic shifts to v2 — without touching any pod."
echo ""

# Record restart counts before
echo "--- Restart counts BEFORE ---"
kubectl get pods -l app=echo -n $NS \
  -o custom-columns="NAME:.metadata.name,VERSION:.metadata.labels.version,RESTARTS:.status.containerStatuses[0].restartCount"
echo ""

kubectl apply -f 04-istio-routing/virtual-service-canary.yaml
echo "✅ VirtualService updated: 80% v1 / 20% v2"
echo ""

echo "Waiting 3 seconds for xDS push to propagate..."
sleep 3

echo ""
echo "--- Verify new routing rule ---"
echo "Run: kubectl get virtualservice echo -n $NS -o yaml | grep -A15 route:"
kubectl get virtualservice echo -n $NS -o yaml | grep -A15 "route:"
echo ""

echo "========================================================"
echo "  RESULTS — Did any pod restart?"
echo "========================================================"
echo ""

echo "--- Restart counts AFTER ---"
kubectl get pods -l app=echo -n $NS \
  -o custom-columns="NAME:.metadata.name,VERSION:.metadata.labels.version,RESTARTS:.status.containerStatuses[0].restartCount"
echo ""

echo "--- Pod ages unchanged (same pods, still running) ---"
kubectl get pods -l app=echo -n $NS
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  Routing changed: 100% v1 → 80/20 split"
echo "  Pod restart count: unchanged"
echo "  Pod ages: unchanged — same pods still running"
echo ""
echo "  WHY: Istiod pushed the new route config to Envoy"
echo "  via a persistent gRPC stream (xDS protocol)."
echo "  Envoy swapped its in-memory route table."
echo "  No file write. No process signal. No restart."
echo ""
echo "Next step: Run  bash 04-istio-routing/04-full-cutover.sh"
echo "           (Send 100% traffic to v2)"
echo ""
EOF

# ── 04-full-cutover.sh ────────────────────────────────────────
cat > 04-istio-routing/04-full-cutover.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 04-istio-routing / 04-full-cutover.sh
# PURPOSE: Move 100% traffic to v2 — still zero restarts
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  FULL CUTOVER: 100% traffic → v2"
echo "========================================================"
echo ""

# Record before
BEFORE=$(kubectl get pods -l app=echo -n $NS \
  -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}')

kubectl patch virtualservice echo -n $NS \
  --type=json \
  -p='[
    {"op":"replace","path":"/spec/http/0/route/0/destination/subset","value":"v2"},
    {"op":"replace","path":"/spec/http/0/route/0/weight","value":100}
  ]' 2>/dev/null || \
kubectl apply -f - << 'VSEOF'
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: echo
  namespace: restart-demos
spec:
  hosts:
  - echo
  http:
  - route:
    - destination:
        host: echo
        subset: v2
      weight: 100
VSEOF

echo "✅ All traffic now routed to v2"
sleep 3

AFTER=$(kubectl get pods -l app=echo -n $NS \
  -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}')

echo ""
echo "--- Final restart count comparison ---"
echo "BEFORE: $BEFORE"
echo "AFTER:  $AFTER"
echo ""

if [ "$BEFORE" = "$AFTER" ]; then
  echo "✅ CONFIRMED: Three routing changes. Zero pod restarts."
  echo "   100%→v1, then 80/20 split, then 100%→v2."
  echo "   Same pods running throughout."
else
  echo "⚠️  Unexpected restart — check kubectl describe pod"
fi

echo ""
echo "--- All pods still running, ages unchanged ---"
kubectl get pods -l app=echo -n $NS
echo ""
echo "Done with Lab 04."
echo "Run  bash 04-istio-routing/05-cleanup.sh  to remove lab resources"
echo ""
EOF

# ── 05-cleanup.sh ─────────────────────────────────────────────
cat > 04-istio-routing/05-cleanup.sh << 'EOF'
#!/bin/bash
NS="restart-demos"
echo ""
echo "Cleaning up Lab 04 resources..."
kubectl delete deployment echo-v1 echo-v2 -n $NS --ignore-not-found
kubectl delete service echo -n $NS --ignore-not-found
kubectl delete virtualservice echo -n $NS --ignore-not-found
kubectl delete destinationrule echo -n $NS --ignore-not-found
echo "✅ Lab 04 resources removed"
echo ""
EOF

chmod +x 04-istio-routing/*.sh
echo "✅ Lab 04 scripts created"
echo ""
echo "========================================================"
echo "  ALL DONE"
echo "========================================================"
echo ""
echo "Lab 03 — Image Update:"
echo "  bash 03-image-update/01-setup.sh"
echo ""
echo "Lab 04 — Istio Routing:"
echo "  bash 04-istio-routing/01-setup.sh"
echo ""