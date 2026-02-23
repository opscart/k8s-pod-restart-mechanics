# When Kubernetes Restarts Your Pod — And When It Doesn't

Companion repository for the OpsCart article:
**[When Kubernetes Restarts Your Pod — And When It Doesn't](https://opscart.com/when-kubernetes-restarts-your-pod)**

Hands-on lab scripts organized by scenario. Each lab is self-contained with numbered scripts that teach one concept at a time. Run them in order, read what each step tells you, and you will understand the internals — not just the outcome.

---

## Quick Reference

```
✅ ALWAYS RESTART     Image change, env var change (any source)
⚡ APP DECIDES        ConfigMap/Secret volume mounts
❌ NEVER              Istio routing rules, NetworkPolicy, RBAC
🆕 K8s 1.35+ GA      CPU resize = NO restart
                      Memory = per your resizePolicy choice
```

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| minikube | 1.38+ | `brew upgrade minikube` |
| kubectl | 1.28+ | Matches cluster version |
| Helm | 3.x | Lab 07 only |
| Kubernetes | 1.28+ | Labs 01–04, 07 |
| Kubernetes | 1.35+ | Lab 05 (in-place resize) |
| Istio | 1.5+ | Lab 04 only |

**Start your cluster:**
```bash
# Labs 01–04, 07
minikube start -p opscart --cpus=4 --memory=8g

# Lab 05 only (in-place resize)
minikube start -p k8s-135 --kubernetes-version=v1.35.0 --cpus=4 --memory=6g
minikube profile k8s-135
```

**Check versions:**
```bash
bash scripts/version-check.sh
```

---

## Lab Structure

Each lab follows the same pattern — numbered scripts, one job each:

```
00-install.sh       # One-time tool installation (where needed)
01-setup.sh         # Deploy everything, explain what was created
02-check-baseline.sh # Confirm starting state, show manual verify commands
03-*.sh             # The key scenario — do the thing, explain what happened
04-*.sh             # Follow-up or fix
05-cleanup.sh       # Remove lab resources (optional, each lab is isolated)
```

Every script tells you what command it ran and why. You can run commands manually to verify results yourself — the scripts show you exactly what to type.

---

## Labs

### Lab 01 — ConfigMap: Env Var vs Volume Mount

**What you will learn:** The same ConfigMap update behaves completely differently depending on how your pod consumes it.

**Key proof:**
```
ConfigMap updated: APP_COLOR blue → red

Pod A (env var):      APP_COLOR=blue  ← frozen at startup, zero restarts
Pod B (volume mount): APP_COLOR=red   ← kubelet synced, zero restarts
```

**Why:** kubelet watches the pod spec, not ConfigMaps. Env vars are baked into process memory at startup and cannot be changed externally. Volume mounts are synced via an atomic symlink swap — the same pod, same process, file updated on disk.

```bash
bash 01-configmap/01-setup.sh
bash 01-configmap/02-check-baseline.sh
bash 01-configmap/03-update-configmap.sh
bash 01-configmap/04-restart-fix.sh
bash 01-configmap/05-cleanup.sh   # optional
```

---

### Lab 02 — Secret: Env Var vs Volume Mount

**What you will learn:** Secrets use the exact same kubelet symlink-swap mechanism as ConfigMaps. Same behavior, same rules.

**Key proof:**
```
Secret updated: DB_PASSWORD db-password → env-db-password

Pod A (env var):      DB_PASSWORD=db-password      ← frozen
Pod B (volume mount): DB_PASSWORD=env-db-password  ← synced

After restarting Pod A:
Pod A (env var):      DB_PASSWORD=env-db-password  ← fixed
```

**Bonus:** Shows base64 decode verification and the projected ServiceAccount token symlink structure — kubelet auto-rotates it, zero restarts ever.

```bash
bash 02-secret/01-setup.sh
bash 02-secret/02-check-baseline.sh
bash 02-secret/03-update-secret.sh
bash 02-secret/04-restart-fix.sh
bash 02-secret/05-cleanup.sh   # optional
```

---

### Lab 03 — Image Update: Three Scenarios

**What you will learn:** Not all image-related failures look the same. Understanding the difference between pod recreation and container restart is essential for production debugging.

**Scenario A — Good image update:**
```
BEFORE: Pod name abc123, UID aaa-bbb, IP 10.244.1.5, nginx:1.25
AFTER:  Pod name def456, UID xxx-yyy, IP 10.244.1.6, nginx:1.27
                ↑ everything changed — this is RECREATION, not restart
```

**Scenario B — Bad image (ImagePullBackOff):**
```
Old pod: still Running  ← Kubernetes protects it
New pod: ImagePullBackOff ← stuck, cannot pull
Kubernetes never kills the old pod until the new one is healthy
```

**Scenario C — CrashLoopBackOff:**
```
Pod name:      SAME  ← same pod object
Pod UID:       SAME
Restart count: 0 → 1 → 2 → 3  ← climbing, same pod
                ↑ this is RESTART, not recreation
```

```bash
bash 03-image-update/01-setup.sh
bash 03-image-update/02-scenario-a-good-image.sh
bash 03-image-update/03-scenario-b-bad-image.sh
bash 03-image-update/04-scenario-c-crashloop.sh
bash 03-image-update/05-cleanup.sh   # optional
```

---

### Lab 04 — Istio Routing: Zero Pod Restarts

**What you will learn:** Istio routing changes never restart pods. Istiod pushes route updates to Envoy via a persistent gRPC stream — in-memory swap, milliseconds, no pod touched.

**Requires:** Istio installed in your cluster.
```bash
minikube addons enable istio-provision -p opscart
```

**Key proof:**
```
Four echo pods. Three routing changes:
  100% → v1
  80% v1 / 20% v2 (canary)
  100% → v2

Restart counts: BEFORE 0 0 0 0
                AFTER  0 0 0 0

Pod ages: unchanged throughout all three changes.
✅ Three routing changes. Zero pod restarts.
```

```bash
bash 04-istio-routing/01-setup.sh
bash 04-istio-routing/02-check-baseline.sh
bash 04-istio-routing/03-change-routing.sh
bash 04-istio-routing/04-full-cutover.sh
bash 04-istio-routing/05-cleanup.sh   # optional
```

---

### Lab 05 — In-Place Resource Resize (K8s 1.35+)

**Requires:** Kubernetes 1.35+
```bash
minikube start -p k8s-135 --kubernetes-version=v1.35.0 --cpus=4 --memory=6g
minikube profile k8s-135
```

**What you will learn:** K8s 1.35 GA allows CPU and memory to be resized without pod recreation. Pod UID and IP never change. What happens to the container depends on your `resizePolicy` — not Kubernetes.

**Key proof:**
```
BASELINE: UID d7c99204, IP 10.244.0.7, CPU 200m, Memory 256Mi, Restarts 0

CPU resize 200m → 500m (NotRequired policy):
  UID:      d7c99204  ← unchanged
  IP:       10.244.0.7 ← unchanged
  Restarts: 0         ← unchanged
  Process:  never touched, cgroup quota updated only

Memory resize 256Mi → 512Mi (RestartContainer policy):
  UID:      d7c99204  ← unchanged (K8s 1.35 GA)
  IP:       10.244.0.7 ← unchanged (K8s 1.35 GA)
  Restarts: 1         ← our resizePolicy choice, not forced by K8s
```

> ⚠️ The default resizePolicy for memory is `NotRequired`. If you do not set it explicitly, memory resize will update the cgroup limit without restarting the container — and your JVM/Python process will not benefit from the new headroom. Always define `resizePolicy` explicitly.

```bash
bash 05-resource-resize/00-prereq-check.sh
bash 05-resource-resize/01-setup.sh
bash 05-resource-resize/02-check-baseline.sh
bash 05-resource-resize/03-resize-cpu.sh
bash 05-resource-resize/04-resize-memory.sh
bash 05-resource-resize/05-cleanup.sh   # optional
```

---

### Lab 06 — StatefulSet maxUnavailable

Coming soon. Requires K8s 1.35+ (beta graduation).

Will demonstrate configuring `maxUnavailable` on StatefulSet rolling updates to reduce update time while controlling disruption. Theory is covered in the companion article.

---

### Lab 07 — Stakater Reloader

**What you will learn:** Reloader automates the `kubectl rollout restart` step that engineers forget. ConfigMap changes — detect, restart, done. No manual intervention.

**Requires:** Helm

```bash
# Install Reloader once
bash 07-stakater-reloader/00-install-reloader.sh
```

> ⚠️ **Critical:** Install with `watchGlobally=true`. The default `watchGlobally=false` means Reloader only watches its own namespace and silently ignores annotated Deployments in all other namespaces. No error is thrown — it just does nothing.

**Key proof:**
```
ConfigMap updated: APP_MESSAGE → "Hello from OpsCart v2 — auto reloaded!"

Without Reloader: engineer must remember kubectl rollout restart
With Reloader:    rolling restart triggered automatically

New pod: APP_MESSAGE=Hello from OpsCart v2 — auto reloaded! ✅
```

```bash
bash 07-stakater-reloader/01-setup.sh
bash 07-stakater-reloader/02-check-baseline.sh
bash 07-stakater-reloader/03-update-configmap.sh
bash 07-stakater-reloader/04-verify-result.sh
bash 07-stakater-reloader/05-cleanup.sh   # optional
```

---

## Key Concepts

### Restart vs Recreation — The Most Important Distinction

| | Container Restart | Pod Recreation |
|---|---|---|
| Pod UID | Same | Different |
| Pod IP | Same | Different |
| Restart count | +1 | Resets to 0 |
| Cause | CrashLoopBackOff, OOMKill, liveness probe | Image update, node drain, rolling update |
| Debugging | `kubectl describe pod` → Events | `kubectl get rs` → ReplicaSets |

### The kubelet Reconciliation Loop

kubelet watches the **pod spec** — not ConfigMaps, not Secrets, not Istio CRDs. If the pod spec did not change, kubelet did not fire. This single fact explains the majority of "why didn't my config update?" investigations in production.

### resizePolicy for Memory (K8s 1.35+)

```yaml
resizePolicy:
- resourceName: cpu
  restartPolicy: NotRequired      # always use this for CPU
- resourceName: memory
  restartPolicy: RestartContainer # use this when process allocates heap at startup
                                  # (JVM, Python, Node.js)
```

If you omit `resizePolicy`, the default is `NotRequired` for both. A memory resize will silently update the cgroup without restarting the container — and your JVM will not use the new headroom.

---

## Cleanup Everything

```bash
kubectl delete namespace restart-demos
helm uninstall reloader -n reloader   # if installed
minikube stop -p opscart
minikube stop -p k8s-135              # if used
```

---

## Article

Full internals guide with evidence, diagrams, and decision flowchart:
**[opscart.com/when-kubernetes-restarts-your-pod](https://opscart.com/when-kubernetes-restarts-your-pod)**

---

## Author

**Shamsher Khan** — Senior DevOps Engineer, IEEE Senior Member
[OpsCart.com](https://opscart.com) · [DZone](https://dzone.com/users/opscart) · [GitHub](https://github.com/opscart)