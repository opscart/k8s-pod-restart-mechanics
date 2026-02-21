#!/bin/bash
# Run this from inside your k8s-pod-restart-mechanics repo
# Creates all files for 02-secret scenario

mkdir -p 02-secret/app

# ── secret.yaml ──────────────────────────────────────────────
cat > 02-secret/secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: restart-demos
type: Opaque
stringData:
  DB_PASSWORD: "supersecret-v1"
  API_KEY: "apikey-v1"
  tls.key: |
    -----BEGIN PRIVATE KEY-----
    fake-key-for-demo-purposes-only
    -----END PRIVATE KEY-----
EOF

# ── deployment-env.yaml ───────────────────────────────────────
cat > 02-secret/deployment-env.yaml << 'EOF'
# Secret consumed as ENV VAR — requires restart to pick up changes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secret-demo-env
  namespace: restart-demos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secret-demo-env
  template:
    metadata:
      labels:
        app: secret-demo-env
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Started with DB_PASSWORD=$DB_PASSWORD"
          while true; do sleep 30; done
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: DB_PASSWORD
        resources:
          requests: {cpu: "50m", memory: "32Mi"}
          limits:   {cpu: "100m", memory: "64Mi"}
EOF

# ── deployment-volume.yaml ────────────────────────────────────
cat > 02-secret/deployment-volume.yaml << 'EOF'
# Secret consumed as VOLUME MOUNT — same symlink swap as ConfigMap
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secret-demo-volume
  namespace: restart-demos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secret-demo-volume
  template:
    metadata:
      labels:
        app: secret-demo-volume
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Started. Watching /etc/secrets/"
          while true; do
            echo "[$(date)] DB_PASSWORD=$(cat /etc/secrets/DB_PASSWORD 2>/dev/null)"
            sleep 15
          done
        volumeMounts:
        - name: secret
          mountPath: /etc/secrets
          readOnly: true
        resources:
          requests: {cpu: "50m", memory: "32Mi"}
          limits:   {cpu: "100m", memory: "64Mi"}
      volumes:
      - name: secret
        secret:
          secretName: app-secret
EOF

# ── demo.sh ───────────────────────────────────────────────────
cat > 02-secret/demo.sh << 'EOF'
#!/bin/bash
# Scenario 02: Secret — Env Var vs Volume Mount
set -e
NS="restart-demos"

echo "=============================================="
echo " Scenario 02: Secret Restart Behavior"
echo "=============================================="

kubectl apply -f 02-secret/secret.yaml
kubectl apply -f 02-secret/deployment-env.yaml
kubectl apply -f 02-secret/deployment-volume.yaml

echo "Waiting for pods..."
kubectl wait --for=condition=ready pod -l app=secret-demo-env \
  -n $NS --timeout=60s
kubectl wait --for=condition=ready pod -l app=secret-demo-volume \
  -n $NS --timeout=60s

ENV_POD=$(kubectl get pod -l app=secret-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=secret-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "--- BASELINE ---"
echo "[ENV POD] DB_PASSWORD from env:"
kubectl exec $ENV_POD -n $NS -- env | grep DB_PASSWORD

echo "[VOL POD] DB_PASSWORD from file:"
kubectl exec $VOL_POD -n $NS -- cat /etc/secrets/DB_PASSWORD

echo ""
echo "--- Secret symlink structure (same as ConfigMap) ---"
kubectl exec $VOL_POD -n $NS -- ls -la /etc/secrets/

echo ""
echo "--- Updating Secret: v1 → v2 ---"
kubectl patch secret app-secret -n $NS \
  -p '{"stringData":{"DB_PASSWORD":"supersecret-v2"}}'

echo "Waiting 90s for kubelet sync..."
sleep 90

# Re-query pod names after wait
ENV_POD=$(kubectl get pod -l app=secret-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=secret-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "=== EVIDENCE CAPTURE ==="

echo "[ENV POD] DB_PASSWORD after Secret update:"
kubectl exec $ENV_POD -n $NS -- env | grep DB_PASSWORD
echo "  ^ Expected: still 'supersecret-v1' (frozen at startup)"

echo ""
echo "[VOL POD] DB_PASSWORD after Secret update:"
kubectl exec $VOL_POD -n $NS -- cat /etc/secrets/DB_PASSWORD
echo "  ^ Expected: 'supersecret-v2' (kubelet synced)"

echo ""
ENV_RESTARTS=$(kubectl get pod $ENV_POD -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
VOL_RESTARTS=$(kubectl get pod $VOL_POD -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo "Restart count — env pod:    $ENV_RESTARTS (should be 0)"
echo "Restart count — volume pod: $VOL_RESTARTS (should be 0)"

echo ""
echo "--- Projected ServiceAccount token (never restarts) ---"
kubectl exec $VOL_POD -n $NS -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/
echo "  ^ kubelet auto-rotates this token. Zero restarts. Ever."

echo ""
echo "CONCLUSION: Same as ConfigMap."
echo "  Secret via env var = frozen until restart"
echo "  Secret via volume  = kubelet syncs automatically (60-90s)"
EOF
chmod +x 02-secret/demo.sh

echo "✅ 02-secret files created"
echo ""
echo "Now run:"
echo "  make demo-secret"