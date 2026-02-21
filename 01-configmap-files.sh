#!/bin/bash
# Run from repo root to create all numbered scripts for 01-configmap
# Usage: bash this-file.sh

# ── 01-setup.sh ───────────────────────────────────────────────
cat > 01-configmap/01-setup.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 01-configmap / 01-setup.sh
# PURPOSE: Deploy everything needed for the ConfigMap lab
# WHAT YOU WILL LEARN: How two pods consume the same ConfigMap
#                      differently — env var vs volume mount
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 01: ConfigMap — Env Var vs Volume Mount"
echo "========================================================"
echo ""
echo "We will deploy:"
echo "  1. A ConfigMap holding an app color value"
echo "  2. Pod A — reads the ConfigMap as an ENV VAR"
echo "  3. Pod B — reads the ConfigMap as a VOLUME MOUNT (file)"
echo ""
echo "Same ConfigMap. Two different consumption methods."
echo "We will see how each behaves when the ConfigMap changes."
echo ""

kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - > /dev/null

kubectl apply -f 01-configmap/configmap.yaml
echo "✅ ConfigMap created: app-config (APP_COLOR=blue)"

kubectl apply -f 01-configmap/deployment-env.yaml
echo "✅ Pod A deployed: config-demo-env (reads via ENV VAR)"

kubectl apply -f 01-configmap/deployment-volume.yaml
echo "✅ Pod B deployed: config-demo-volume (reads via VOLUME MOUNT)"

echo ""
echo "Waiting for both pods to be ready..."
kubectl wait --for=condition=ready pod -l app=config-demo-env \
  -n $NS --timeout=60s
kubectl wait --for=condition=ready pod -l app=config-demo-volume \
  -n $NS --timeout=60s

echo ""
echo "========================================================"
echo "  SETUP COMPLETE"
echo "========================================================"
echo ""
echo "Both pods are running. Both currently see APP_COLOR=blue"
echo ""
echo "Want to verify? Run:"
echo "  kubectl get configmap app-config -n $NS -o yaml"
echo ""
kubectl get configmap app-config -n $NS -o yaml | grep -A5 "data:"
echo ""
echo "Next step: Run  bash 01-configmap/02-check-baseline.sh"
echo ""
EOF

# ── 02-check-baseline.sh ──────────────────────────────────────
cat > 01-configmap/02-check-baseline.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 01-configmap / 02-check-baseline.sh
# PURPOSE: Confirm both pods see the original value
# ==========================================================

NS="restart-demos"

ENV_POD=$(kubectl get pod -l app=config-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=config-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  BASELINE: What do both pods see right now?"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR ]"
echo "Run: kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR"
kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR
echo ""

echo "[ Pod B — VOLUME MOUNT ]"
echo "Run: kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR"
kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR && echo
echo ""

echo "Both pods see blue. Makes sense — nothing changed yet."
echo ""

echo "========================================================"
echo "  VERIFY THE CONFIGMAP YOURSELF"
echo "========================================================"
echo ""
echo "Want to check what Kubernetes stores in the ConfigMap?"
echo ""
echo "  kubectl get configmap app-config -n $NS \\"
echo "    -o jsonpath='{.data.APP_COLOR}' && echo"
echo ""
echo "Output:"
kubectl get configmap app-config -n $NS \
  -o jsonpath='{.data.APP_COLOR}' && echo
echo ""

echo "========================================================"
echo "  HOW Pod B STORES THE CONFIGMAP ON DISK"
echo "========================================================"
echo ""
echo "Run this inside Pod B to see the actual file structure:"
echo ""
echo "  kubectl exec $VOL_POD -n $NS -- ls -la /etc/config/"
echo ""
kubectl exec $VOL_POD -n $NS -- ls -la /etc/config/
echo ""
echo "Notice the ..data symlink pointing to a timestamped directory."
echo "When the ConfigMap changes, kubelet swaps THAT symlink atomically."
echo "The file on disk updates. No pod restart needed."
echo ""
echo "Next step: Run  bash 01-configmap/03-update-configmap.sh"
echo ""
EOF

# ── 03-update-configmap.sh ────────────────────────────────────
cat > 01-configmap/03-update-configmap.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 01-configmap / 03-update-configmap.sh
# PURPOSE: Update the ConfigMap, wait for sync, check both pods
# THIS IS THE KEY MOMENT — same ConfigMap, two different outcomes
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  UPDATING THE CONFIGMAP: blue → red"
echo "========================================================"
echo ""
echo "Imagine a config change was pushed — APP_COLOR changed to red."
echo "Kubernetes ConfigMap is updated. What do the pods see?"
echo ""

kubectl patch configmap app-config -n $NS \
  -p '{"data":{"APP_COLOR":"red"}}'

echo "✅ ConfigMap updated in Kubernetes"
echo ""
echo "--- Verify the ConfigMap was updated ---"
echo "Run this yourself to confirm:"
echo ""
echo "  kubectl get configmap app-config -n $NS \\"
echo "    -o jsonpath='{.data.APP_COLOR}' && echo"
echo ""
echo "Output:"
kubectl get configmap app-config -n $NS \
  -o jsonpath='{.data.APP_COLOR}' && echo
echo ""
echo "Kubernetes now stores: red"
echo "But what do the RUNNING PODS actually see? That is the question."
echo ""
echo "Waiting 90 seconds for kubelet to sync the volume mount..."
echo "(kubelet syncs volume-mounted ConfigMaps on a periodic schedule)"
echo ""

for i in $(seq 90 -10 10); do
  echo "  ...${i}s remaining"
  sleep 10
done

# Re-query pod names fresh after wait
ENV_POD=$(kubectl get pod -l app=config-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=config-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  RESULTS — What do the pods see now?"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR ]"
echo "Run: kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR"
kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR
echo ""
echo "  ⚠️  Still showing blue (the old value)."
echo "  The env var was baked into the process at startup."
echo "  Kubernetes cannot reach into process memory and change it."
echo "  This pod is showing the WRONG color and doesn't know it."
echo ""

echo "[ Pod B — VOLUME MOUNT ]"
echo "Run: kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR"
kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR && echo
echo ""
echo "  ✅ Now showing red (the new value)."
echo "  kubelet swapped the file on disk automatically."
echo "  No restart. No human intervention. Just works."
echo ""

echo "--- Verify the symlink swap happened ---"
echo "Run: kubectl exec $VOL_POD -n $NS -- ls -la /etc/config/"
kubectl exec $VOL_POD -n $NS -- ls -la /etc/config/
echo ""
echo "The timestamp on ..data directory changed — that is the swap."
echo ""

echo "========================================================"
echo "  CONCLUSION"
echo "========================================================"
echo ""
echo "  Kubernetes ConfigMap:  red   (updated)"
echo "  Pod A (env var):       blue  (WRONG — stuck on old value)"
echo "  Pod B (volume mount):  red   (CORRECT — synced automatically)"
echo ""
echo "In production: Pod A would render the wrong color, use the wrong"
echo "feature flag, or connect to the wrong endpoint — silently."
echo ""
echo "Next step: Run  bash 01-configmap/04-restart-fix.sh"
echo "           (Fix Pod A by restarting it)"
echo ""
EOF

# ── 04-restart-fix.sh ─────────────────────────────────────────
cat > 01-configmap/04-restart-fix.sh << 'EOF'
#!/bin/bash
# ==========================================================
# 01-configmap / 04-restart-fix.sh
# PURPOSE: Restart the env pod and prove it now reads red
# THE FIX: A restart is the only way to update env vars
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  FIXING Pod A — Restart to pick up new value"
echo "========================================================"
echo ""
echo "Pod A is stuck on blue."
echo "The only fix is a restart — the process must re-read"
echo "env vars from the pod spec, which now reflects red."
echo ""

kubectl rollout restart deployment/config-demo-env -n $NS

echo "Waiting for new pod to be ready..."
kubectl rollout status deployment/config-demo-env -n $NS --timeout=60s

# Fresh pod name after restart
ENV_POD=$(kubectl get pod -l app=config-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=config-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  AFTER RESTART"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR — after restart ]"
echo "Run: kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR"
kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR
echo "  ✅ Now reading red — restart picked up the new ConfigMap value"
echo ""

echo "[ Pod B — VOLUME MOUNT — untouched ]"
echo "Run: kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR"
kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR && echo
echo "  ✅ Still red — never needed a restart"
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  ENV VAR:      ConfigMap updated → pod sees old value"
echo "                → must restart → restart picks up new value"
echo ""
echo "  VOLUME MOUNT: ConfigMap updated → kubelet syncs file"
echo "                → pod reads new value automatically"
echo "                → no restart ever needed"
echo ""
echo "Choose volume mounts for config that changes at runtime."
echo "Use env vars only for values set once at deploy time."
echo ""
echo "Done with Lab 01."
echo "Run  bash 01-configmap/05-cleanup.sh  to remove lab resources"
echo ""
EOF

# ── 05-cleanup.sh ─────────────────────────────────────────────
cat > 01-configmap/05-cleanup.sh << 'EOF'
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
EOF

chmod +x 01-configmap/01-setup.sh
chmod +x 01-configmap/02-check-baseline.sh
chmod +x 01-configmap/03-update-configmap.sh
chmod +x 01-configmap/04-restart-fix.sh
chmod +x 01-configmap/05-cleanup.sh

echo ""
echo "✅ All 01-configmap scripts created"
echo ""
echo "Old demo.sh still exists — remove it?"
echo "  rm 01-configmap/demo.sh"
echo ""
echo "Run the lab:"
echo "  bash 01-configmap/01-setup.sh"